--
-- Global Souler State Net
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/04/28 08:46:44
--

LoliSrvSA.GNet = {}

local GNet = LoliSrvSA.GNet
local SoulerMgr = LoliSrvSA.SoulerMgr

function GNet:Init()
  self.LogicFuncs = {}
  self.LogicParam = nil
  self.Connected = 0
  self.Id = assert(LoliCore.Net:Connect("127.0.0.1", 7200, self:__GetEventFuncs()))
end

function GNet:UnInit()
  if self.Id > 0 then LoliCore.Net:Close(self.Id) end
end

function GNet:RegisterLogic(LogicFuncs, LogicParam)
  for k, v in pairs(LogicFuncs) do
    self.LogicFuncs[k] = v
  end
  self.LogicParam = LogicParam
end

function GNet:PushPackage(Souler, Pack)
  -- Set Id Auto
  Pack.Id = Souler.Id
  Pack.SoulId = Souler.SoulId
  if not LoliCore.Net:PushPackage(self.Id, Pack) then
    assert(LoliCore.Net:Close(self.Id))
    return
  end
  return 1
end

function GNet:EventConnect(Id, Result)
  assert(Id == self.Id)
  self.Connected = Result
end

function GNet:EventPackage(Id, Pack)
  assert(Id == self.Id)
  local Souler = SoulerMgr:GetById(Pack.Id)
  if not Souler then
    print(string.format("Souler Id[%u] Is Not Already Agency", Pack.Id))
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

function GNet:EventClose(Id)
  assert(Id == self.Id)
  self.Id = 0
  self.Connected = 0
end

function GNet:__GetEventFuncs()
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
