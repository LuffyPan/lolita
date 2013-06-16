--
-- Lolita Area Server Main Logic
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/05/18 20:32:40
--

LoliSrvArea.Logic = {}

local Logic = LoliSrvArea.Logic
local GovNet = LoliSrvArea.GovNet

local SoulerRepos = {}

function SoulerRepos:Init()
  self._SoulId2Soulers = {}
end

function SoulerRepos:New(SoulId)
  assert(not self._SoulId2Soulers[SoulId])
  local Souler =
  {
    SoulId = SoulId,
  }
  self._SoulId2Soulers[SoulId] = Souler
  return Souler
end

function SoulerRepos:Delete(SoulId)
  local Souler = assert(self._SoulId2Soulers[SoulId])
  assert(Souler.SoulId == SoulId)
  self._SoulId2Soulers[Souler.SoulId] = nil
  return Souler
end

function SoulerRepos:GetBySoulId(SoulId)
  local Souler = self._SoulId2Soulers[SoulId]
  return Souler
end

function Logic:Init()
  GovNet:RegisterLogic(self:__GetLogic(), self)
  SoulerRepos:Init()
end

function Logic:OnRequestArrival(NetId, Pack)
  print(string.format("Souler SoulId[%u] RequestArrival", Pack.SoulId))
  local Souler = assert(SoulerRepos:New(Pack.SoulId))
  Souler.Fragments = Pack.Souler
  for k, v in pairs(Pack.Souler) do
    print(k, v)
  end
  local ArrivalPack =
  {
    ProcId = "RequestArrival",
    SoulId = Souler.SoulId,
    GovId = Pack.Souler.GovId,
    Result = 1,
    ErrorCode = 0,
  }
  assert(GovNet:PushPackage(ArrivalPack))
end

function Logic:OnRequestDeparture(NetId, Pack)
  print("OnRequestDeparture")
end

function Logic:__GetLogic()
  if self.__Logic then return self.__Logic end
  self.__Logic =
  {
    RequestArrival = self.OnRequestArrival,
    RequestDeparture = self.OnRequestDeparture,
  }
  return self.__Logic
end
