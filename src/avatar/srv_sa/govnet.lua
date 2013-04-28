--
-- Goverment Net
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/04/28 16:53:23
--

LoliSrvSA.GovermentNet = {}

local GovermentNet = LoliSrvSA.GovermentNet
local SoulerMgr = LoliSrvSA.SoulerMgr

function GovermentNet:Init()
  self.LogicFuncs = {}
  self.LogicParam = nil
  self.Connected = 0
  self.Id = assert(LoliCore.Net:Connect("127.0.0.1", 7300, self:__GetEventFuncs()))
end

function GovermentNet:UnInit()
  if self.Id > 0 then LoliCore.Net:Close(self.Id) end
end

function GovermentNet:RegisterLogic(LogicFuncs, LogicParam)
  for k, v in pairs(LogicFuncs) do
    self.LogicFuncs[k] = v
  end
  self.LogicParam = LogicParam
end

function GovermentNet:PushPackage(Souler, Pack)
  -- Set Id Auto
  Pack.Id = Souler.Id
  Pack.SoulId = Souler.SoulId
  if not LoliCore.Net:PushPackage(self.Id, Pack) then
    assert(LoliCore.Net:Close(self.Id))
    return
  end
  return 1
end

function GovermentNet:EventConnect(Id, Result)
  assert(Id == self.Id)
  self.Connected = Result
end

function GovermentNet:EventPackage(Id, Pack)
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

function GovermentNet:EventClose(Id)
  assert(Id == self.Id)
  self.Id = 0
  self.Connected = 0
end

function GovermentNet:__GetEventFuncs()
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
