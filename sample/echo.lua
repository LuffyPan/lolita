--
-- Echo
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/09/02 19:48:57
--

assert(_VERSION == "Lua 5.2", string.format("Lua5.2+ please!, %s", _VERSION))
print(core)
for k, v in pairs(core) do
  print(k,v)
end

print(core.net.info)
print(core.net.info.mode)
print(core.net.info.fdsetsize)

local echo = {}

function echo:init()
  --set trace level
  local tracelv = tonumber(core.arg.tracelv) or 0
  core.base.settracelv(tracelv)

  --set max mem can be alloc to 100M
  core.base.setmaxmem(1024 * 1024 * 100)

  --register os signal
  assert(core.os.register(self.sig, self))

  --initialize net environment
  core.net.ids = {}
  --register net event
  assert(core.net.register(self.ev, self))

  --get ip and port from arg
  local ip = core.arg.ip or "127.0.0.1"
  local port = tonumber(core.arg.port) or 7000

  --get srv or client flag
  self.bsrv = core.arg.bsrv
  self.clientcnt = 0

  if self.bsrv then
    --listen @ ip:port
    self.netid = core.net.listen(ip, port)
    assert(self.netid, "listen failed")
    print(string.format("listening @ %s:%s", ip, port))
  else
    --connect to ip:port
    self.maxclientcnt = core.arg.maxconnection or 120 --128 limits a process
    self.netids = {}
    for i = 1, self.maxclientcnt do
      local netid = core.net.connect(ip, port)
      assert(netid, "connect failed")
      self.netids[netid] = 1
      self.clientcnt = self.clientcnt + 1
      print(string.format("connecting to %s:%s", ip, port))
      core.os.active(100)
    end
  end
end

function echo:run()
  self.brun = 1
  while self.brun do
    core.net.active()
    core.os.active(1)
  end
end

function echo:uninit()
end

--signal process
function echo:sig()
  self.brun = nil
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

echo:init()
echo:run()
echo:uninit()
