--
-- Lolita Area Server GovermentNet
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/05/18 20:30:23
--

LoliSrvArea.GovNet = {}

local GovNet = LoliSrvArea.GovNet

function GovNet:Init()
  self.LogicFuncs = {}
  self.LogicParam = nil
  self.Connected = 0
  self.NetId = assert(LoliCore.Net:Connect("127.0.0.1", 7400, self:__GetEventFuncs()))
end

function GovNet:UnInit()
  if self.NetId > 0 then LoliCore.Net:Close(self.NetId) end
end

function GovNet:RegisterLogic(LogicFuncs, LogicParam)
  for k, v in pairs(LogicFuncs) do
    self.LogicFuncs[k] = v
  end
  self.LogicParam = LogicParam
end

function GovNet:PushPackage(Pack)
  assert(self.NetId > 0)
  if not LoliCore.Net:PushPackage(self.NetId, Pack) then
    assert(LoliCore.Net:Close(self.NetId))
    return
  end
  return 1
end

function GovNet:EventConnect(NetId, Result)
  assert(NetId == self.NetId)
  self.Connected = Result
end

function GovNet:EventPackage(NetId, Pack)
  assert(NetId == self.NetId)
  local Fn = assert(self.LogicFuncs[Pack.ProcId])
  local R, E = pcall(Fn, self.LogicParam, NetId, Pack)
  if not R then
    print(E)
  end
end

function GovNet:EventClose(NetId)
  assert(NetId == self.NetId)
  self.NetId = 0
  self.Connected = 0
end

function GovNet:__GetEventFuncs()
  if self.__EventFuncs then return self.__EventFuncs end
  self.__EventFuncs =
  {
    Param = self,
    Connect = self.EventConnect,
    Package = self.EventPackage,
    Close = self.EventClose,
  }
  return self.__EventFuncs
end

