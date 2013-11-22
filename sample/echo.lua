--
-- Echo
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/09/02 19:48:57
--

--[[

the arguments works

bsrv
  1: run as a server
  0 : run as a client

maxconnection
  a number to indicate max connection works both on srv or client

ip
  ip to listen or connect

port
  port to listen or connect


--]]

assert(_VERSION == "Lua 5.2", string.format("Lua5.2+ please!, %s", _VERSION))
assert(lolita)
assert(lolita.core)
print(string.format("lolita:%s", lolita))
for k, v in pairs(lolita) do
  print(k,v)
end

local core = lolita.core

print("original arg:")
for k, v in ipairs(core.arg._original) do
  print(k, v)
end

print("arg:")
for k, v in pairs(core.arg) do
  print(k, v)
end

assert(core.net.info)
print("--------------------------------------------------------------------")
print(string.format("platform:%s", core.info.platform))
print(string.format("embe mode:%s", core.info.embemode))
print(string.format("net mode:%s, fdsetsize:%s", core.net.info.mode, core.net.info.fdsetsize))
print("")

print("--------------------------------------------------------------------")
print(string.format("%s", core.info.lcopyright))
print(string.format("%s", core.info.lauthors))
print("")
print("--------------------------------------------------------------------")
print(string.format("%s", core.info.copyright))
print(string.format("%s", core.info.author))
print(string.format("%s", core.info.reposversion))
print("")

local echo = {}

function echo:born()
  --set trace level
  local tracelv = tonumber(core.arg.tracelv) or 0
  core.base.settracelv(tracelv)

  --set max mem can be alloc to 100M
  core.base.setmaxmem(1024 * 1024 * 100)

  --register os signal
  assert(core.os.register(self.sig, self))

  --initialize net environment
  --core.net.ids = {}
  --build-in initialize

  --register net event
  assert(core.net.register(self.ev, self))

  --get ip and port from arg
  local ip = core.arg.ip or "127.0.0.1"
  local port = tonumber(core.arg.port) or 7000
  local braw = core.arg.braw or 0

  --get srv or client flag
  self.bsrv = core.arg.bsrv
  self.clientcnt = 0

  if self.bsrv then
    --listen @ ip:port
    self.netid = core.net.listen(ip, port, braw)
    assert(self.netid, "listen failed")
    --set max connection can accept.
    core.net.setoption(self.netid, 0, tonumber(core.arg.maxconnection) or 110)
    print(string.format("listening @ %s:%s", ip, port))
  else
    --connect to ip:port
    self.maxclientcnt = tonumber(core.arg.maxconnection) or 120 --128 limits a process
    self.netids = {}
    for i = 1, self.maxclientcnt do
      local netid = core.net.connect(ip, port, braw)
      assert(netid, "connect failed")
      self.netids[netid] = 1
      self.clientcnt = self.clientcnt + 1
      print(string.format("connecting to %s:%s", ip, port))
      core.os.active(100)
    end
  end
  print("oh, i'm born")
  return 1
end

function echo:active()
  core.net.active()
  core.os.active(1)
  return 1;
end

function echo:die()
  print("yeah, i'm die")
end

--signal process
function echo:sig()
  lolita.core.base.detach()
end

function echo:ev(evid, id, attaid, extra)
  --print(evid, id, attaid, extra)
  if self.bsrv then
    self:evsrv(evid, id, attaid, extra)
  else
    self:evclient(evid, id, attaid, extra)
  end
end

function echo:evsrv(evid, id, attaid, extra)
  if evid == 111 then

    -- about 250 connections limit ? fuck?
    -- yes, just set ulimit -n 2048
    self.clientcnt = self.clientcnt + 1
    print(string.format("client[%s] connected!, current connections[%s]", attaid, self.clientcnt))

  elseif evid == 113 then

    self.clientcnt = self.clientcnt - 1
    print(string.format("client[%s] disconnected!, current connections[%s]", attaid, self.clientcnt))

  elseif evid == 112 then

    print(string.format("client[%s] request with data[%s]", attaid, extra))
    core.net.push(id, attaid, tostring(os.date()))

  elseif evid == 122 then
    print(string.format("client[%s] request with rawdata[%s]", attaid, extra))
  end
end

function echo:evclient(evid, id, attaid, extra)
  if evid == 110 then

    print(string.format("client[%s] connect [%s]", id, extra == 1 and "succeed" or "failed"))
    if extra == 1 then
      core.net.push(id, 0, string.format("client[%s] request time", id))
    end

  elseif evid == 113 then

    self.clientcnt = self.clientcnt - 1
    assert(self.netids[id])
    self.netids[id] = nil
    print(string.format("client[%s] disconnected!, current connections[%s]", id, self.clientcnt))

  elseif evid == 112 then

    print(string.format("client[%s] respond with data[%s]", id, extra))
    --core.net.push(id, 0, string.format("client[%s] request time", id))

  end
end

--born, active, die must be the function of echo to attach
lolita.core.base.attach(echo)
