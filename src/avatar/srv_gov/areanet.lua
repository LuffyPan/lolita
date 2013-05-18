--
-- Goverment's Area Server Net
-- Area Server Connects
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/05/17 19:54:52
--

LoliSrvGoverment.AreaNet = {}

local AreaNet = LoliSrvGoverment.AreaNet

function AreaNet:Init()
  self.LogicFuncs = {}
  self.LogicFuncParam = nil
  self.NetId = assert(LoliCore.Net:Listen("", 7400, self:__GetEventFuncs()))
end

function AreaNet:UnInit()
  -- Is Not Supported Very Good.. So ToDo
  assert()
end

function AreaNet:RegisterLogic(LogicFuncs, LogicParam)
  for k, v in pairs(LogicFuncs) do
    self.LogicFuncs[k] = v
  end
  self.LogicParam = LogicParam
end

function AreaNet:PushPackage(NetId, Pack)
  if not LoliCore.Net:PushPackage(NetId, Pack) then
    -- May Be Full, Close It
    assert(LoliCore.Net:Close(NetId))
  end
  return 1
end

function AreaNet:EventAccept(NetId)
  local Fn = self.LogicFuncs.Accept
  if not Fn then return end
  local R, E = pcall(Fn, self.LogicParam, NetId)
  if not R then
    print(E)
  end
end

function AreaNet:EventPackage(NetId, Pack)
  local Fn = self.LogicFuncs[Pack.ProcId]
  if not Fn then
    -- Log this
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

function AreaNet:EventClose(NetId)
  if NetId == self.NetId then
    -- ToDo
    return
  end
  local Fn = self.LogicFuncs.Close
  if not Fn then return end
  local R, E = pcall(Fn, self.LogicParam, NetId)
  if not R then
    print(E)
  end
end

function AreaNet:__GetEventFuncs()
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
