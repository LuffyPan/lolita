--
--LoliCore script net
--Chamz Lau, Copyright (C) 2013-2017
--2013/03/15 00:15:44
--

core.net = {}
local net = core.net

function net:pushtb(id, attaid, tbdata)
  core.api.net.push(id, attaid, core.misc:serialize(tbdata))
end

function net:connect(addr, port)
  return core.api.net.connect(addr, port)
end

function net:listen(addr, port)
  return core.api.net.listen(addr, port)
end

function net:close(id, attaid)
  return core.api.net.close(id, attaid)
end
