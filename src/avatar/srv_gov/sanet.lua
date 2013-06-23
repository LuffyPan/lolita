--
-- Goverment's SoulerAgency Server Net
-- SoulerAgency Connects
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/04/28 13:46:21
--

LoliSrvGoverment = {}
LoliSrvGoverment.SaNet = {}

local SaNet = LoliSrvGoverment.SaNet

function SaNet:Init()
  self.LogicFuncs = {}
  self.LogicFuncParam = nil
  self.NetId = assert(LoliCore.Net:Listen("", 7300, self:__GetEventFuncs()))
end

function SaNet:UnInit()
  -- Is Not Supported Very Good.. So ToDo
  assert()
end

function SaNet:RegisterLogic(LogicFuncs, LogicParam)
  for k, v in pairs(LogicFuncs) do
    self.LogicFuncs[k] = v
  end
  self.LogicParam = LogicParam
end

function SaNet:PushPackage(NetId, Pack)
  if not LoliCore.Net:PushPackage(NetId, Pack) then
    -- May Be Full, Close It
    assert(LoliCore.Net:Close(NetId))
  end
  return 1
end

function SaNet:EventAccept(NetId)
  local Fn = self.LogicFuncs.Accept
  if not Fn then return end
  local R, E = pcall(Fn, self.LogicParam, NetId)
  if not R then
    print(E)
  end
end

function SaNet:EventPackage(NetId, Pack)
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
  --self:PushPackage(NetId, Pack)
end

function SaNet:EventClose(NetId)
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

function SaNet:__GetEventFuncs()
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
