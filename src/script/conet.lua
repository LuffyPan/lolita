--
--LoliCore script net
--Chamz Lau, Copyright (C) 2013-2017
--2013/03/15 00:15:44
--

core.net = {}
local net = core.net
net.ids = {}

function net:born()
  self.netstateset = {}
end

function net:die()
end

function net:connect(addr, port)
  local netid = core.api.net.connect(addr, port)
  if netid then
    self.netstateset[netid] = {bconnect = 1,}
  end
  return netid
end

function net:listen(addr, port)
  local netid = core.api.net.listen(addr, port)
  if netid then
    self.netstateset[netid] = {bconnect = 0,}
  end
  return netid
end

function net:pushtb(id, attaid, tbdata)
  core.api.net.push(id, attaid, core.misc:serialize(tbdata))
end

function net:close(id, attaid)
  self.netstateset[id] = nil
  return core.api.net.close(id, attaid)
end

function net:registerproc(id, proc, procparam)
  local netstate = self.netstateset[id]
  netstate.proc = proc
  netstate.procparam = procparam
end

function net:dispatchconnect(netid, extra)
  local netstate = self.netstateset[netid]
  if netstate.proc and netstate.proc.onconnect then
    assert(netstate.bconnect == 1)
    netstate.proc.onconnect(netstate.procparam, netid, extra)
  else
    core.avatar:onconnect(netid, extra)
  end
end

function net:dispatchaccept(netid, attanetid, extra)
  local netstate = self.netstateset[netid]
  if netstate.proc and netstate.proc.onaccept then
    assert(netstate.bconnect == 0)
    netstate.proc.onaccept(netstate.procparam, attanetid)
  else
    core.avatar:onaccept(netid, attanetid, extra)
  end
end

function net:dispatchpack(netid, attanetid, data, extra)
  local pack = assert(core.misc:deserialize(data))
  assert(type(pack) == "table", "not table pack")
  local netstate = self.netstateset[netid]
  if netstate.proc and netstate.proc.onpack then
    if netstate.bconnect == 1 then
      assert(attanetid == 0)
      netstate.proc.onpack(netstate.procparam, netid, pack)
    else
      assert(attanetid > 0)
      netstate.proc.onpack(netstate.procparam, attanetid, pack)
    end
  else
    core.avatar:onpack(netid, attanetid, pack, extra)
  end
end

function net:dispatchclose(netid, attanetid, extra)
  local netstate = self.netstateset[netid]
  if netstate.proc and netstate.proc.onclose then
    if netstate.bconnect == 1 then
      assert(attanetid == 0)
      netstate.proc.onclose(netstate.procparam, netid)
      self.netstateset[netid] = nil
    else
      assert(attanetid > 0)
      netstate.proc.onclose(netstate.procparam, attanetid)
    end
  else
    core.avatar:onclose(netid, attanetid, extra)
  end
end
