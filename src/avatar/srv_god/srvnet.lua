--
-- God's Server Nets
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/05/17 13:43:20
--

local SrvNet = LoliSrvGod.SrvNet

-- Add Session to extend logic process
function SrvNet:UnInit()
  -- Is not supported very good.. ToDo
  assert()
end

function SrvNet:Init(Ip, Port, LogicFuncs, LogicParam)
  self.LogicFuncs = {}
  for k, v in pairs(LogicFuncs) do
    self.LogicFuncs[k] = v
  end
  self.LogicParam = assert(LogicParam)
  self.NetId = assert(LoliCore.Net:Listen(Ip, Port, self:__GetEventFuncs()))
end

function SrvNet:PushPackage(NetId, Pack)
  if not LoliCore.Net:PushPackage(NetId, Pack) then
    -- May be full, Close it.
    assert(LoliCore.Net:Close(NetId))
  end
  return 1
end

function SrvNet:EventAccept(NetId)
  local Fn = self.LogicFuncs.Accept
  if not Fn then return end
  local R, E = pcall(Fn, self.LogicParam, NetId)
  if not R then
    print(E)
  end
end

function SrvNet:EventPackage(NetId, Pack)
  local Fn = self.LogicFuncs[Pack.ProcId]
  if not Fn then
    --Log this
    print(string.format("ProcId[%s] Is Not Register", tostring(Pack.ProcId)))
    assert()
    return
  end
  Pack.Result = 0
  Pack.ErrorCode = 0
  local R, E = pcall(Fn, self.LogicParam, NetId, Pack)
  if not R then
    print(E)
  end
  self:PushPackage(NetId, Pack)
end

function SrvNet:EventClose(NetId)
  if NetId == self.NetId then
    --ToDo
    return
  end
  local Fn = self.LogicFuncs.Close
  if not Fn then return end
  local R, E = pcall(Fn, self.LogicParam, NetId)
  if not R then
    print(E)
  end
end

function SrvNet:__GetEventFuncs()
  if self.__EventFuncs then return self.__EventFuncs end
  self.__EventFuncs =
  {
    Param = self,
    Accept = self.EventAccept,
    Package = self.EventPackage,
    Close = self.EventClose,
  }
  return self.__EventFuncs
end
