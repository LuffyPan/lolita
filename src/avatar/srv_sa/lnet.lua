--
-- Login Net
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/04/23 15:58:29
--

LoliSrvSA.LoginNet = {}

local LoginNet = LoliSrvSA.LoginNet
local SoulerMgr = LoliSrvSA.SoulerMgr

function LoginNet:Init()
  self.LogicFuncs = {}
  self.LogicParam = nil
  self.Connected = 0
  self.Id = assert(LoliCore.Net:Connect("127.0.0.1", 7000, self:__GetEventFuncs()))
end

function LoginNet:UnInit()
  if self.Id > 0 then LoliCore.Net:Close(self.Id) end
end

function LoginNet:RegisterLogic(LogicFuncs, LogicParam)
  for k, v in pairs(LogicFuncs) do
    self.LogicFuncs[k] = v
  end
  self.LogicParam = LogicParam
end

function LoginNet:PushPackage(Souler, Pack)
  -- Need a number to represent this Pack globally ToDo
  Pack.Id = Souler.Id
  if not LoliCore.Net:PushPackage(self.Id, Pack) then
    --May be full, Close it.
    assert(LoliCore.Net:Close(self.Id))
    return
  end
  return 1
end

function LoginNet:EventConnect(Id, Result)
  assert(Id == self.Id)
  self.Connected = Result
end

function LoginNet:EventPackage(Id, Pack)
  assert(Id == self.Id)
  local Souler = SoulerMgr:GetById(Pack.Id)
  if not Souler then
    --Log this
    print(string.format("Souler[%u] is not already agency", Pack.Id))
    return
  end
  Souler.Pack = Pack
  local Fn = assert(self.LogicFuncs[Pack.ProcId])
  local r, e = pcall(Fn, self.LogicParam, Souler)
  if not r then
    print(e)
  end
  Souler.Pack = nil
end

function LoginNet:EventClose(Id)
  assert(Id == self.Id)
  self.Id = 0
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