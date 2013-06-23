--
-- God Net
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/05/18 14:30:16
--

LoliSrvSa = {}
LoliSrvSa.GodNet = {}

local GodNet = LoliSrvSa.GodNet

function GodNet:Init()
  self.LogicFuncs = {}
  self.LogicParam = nil
  self.Connected = 0
  self.NetId = assert(LoliCore.Net:Connect("127.0.0.1", 7700, self:__GetEventFuncs()))
end

function GodNet:UnInit()
  if self.NetId > 0 then LoliCore.Net:Close(self.NetId) end
end

function GodNet:RegisterLogic(LogicFuncs, LogicParam)
  for k, v in pairs(LogicFuncs) do
    self.LogicFuncs[k] = v
  end
  self.LogicParam = LogicParam
end

function GodNet:PushPackage(Pack)
  assert(self.NetId > 0)
  if not LoliCore.Net:PushPackage(self.NetId, Pack) then
    assert(LoliCore.Net:Close(self.NetId))
    return
  end
  return 1
end

function GodNet:EventConnect(NetId, Result)
  assert(NetId == self.NetId)
  self.Connected = Result
end

function GodNet:EventPackage(NetId, Pack)
  assert(NetId == self.NetId)
  local Fn = assert(self.LogicFuncs[Pack.ProcId])
  local R, E = pcall(Fn, self.LogicParam, NetId, Pack)
  if not R then
    print(E)
  end
end

function GodNet:EventClose(NetId)
  assert(NetId == self.NetId)
  self.NetId = 0
  self.Connected = 0
end

function GodNet:__GetEventFuncs()
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
