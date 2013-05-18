--
-- Login Net
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/04/23 15:58:29
--

LoliSrvSa.LoginNet = {}

local LoginNet = LoliSrvSa.LoginNet

function LoginNet:Init()
  self.LogicFuncs = {}
  self.LogicParam = nil
  self.Connected = 0
  self.NetId = assert(LoliCore.Net:Connect("127.0.0.1", 7000, self:__GetEventFuncs()))
end

function LoginNet:UnInit()
  if self.NetId > 0 then LoliCore.Net:Close(self.NetId) end
end

function LoginNet:RegisterLogic(LogicFuncs, LogicParam)
  for k, v in pairs(LogicFuncs) do
    self.LogicFuncs[k] = v
  end
  self.LogicParam = LogicParam
end

function LoginNet:PushPackage(Pack)
  assert(self.NetId > 0)
  if not LoliCore.Net:PushPackage(self.NetId, Pack) then
    --May be full, Close it.
    assert(LoliCore.Net:Close(self.NetId))
    return
  end
  return 1
end

function LoginNet:EventConnect(NetId, Result)
  assert(NetId == self.NetId)
  self.Connected = Result
end

function LoginNet:EventPackage(NetId, Pack)
  assert(NetId == self.NetId)
  local Fn = assert(self.LogicFuncs[Pack.ProcId])
  local R, E = pcall(Fn, self.LogicParam, NetId, Pack)
  if not R then
    print(E)
  end
end

function LoginNet:EventClose(NetId)
  assert(NetId == self.NetId)
  self.NetId = 0
  self.Connected = 0
end

function LoginNet:__GetEventFuncs()
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
