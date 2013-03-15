--
--LoliCore script net
--Chamz Lau, Copyright (C) 2013-2017
--2013/03/15 00:15:44
--

local onp = core.api.net.push

function core.api.net.pushtb(id, attaid, tbdata)
  return onp(id, attaid, core.serialize(tbdata)) 
end