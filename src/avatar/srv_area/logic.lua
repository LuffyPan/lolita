--
-- Lolita Area Server Main Logic
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/05/18 20:32:40
--

LoliSrvArea.Logic = {}

local Logic = LoliSrvArea.Logic

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
  SoulerRepos:Init()
end

function Logic:OnRequestArrival(NetId, Pack)
  print("OnRequestDeparture")
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
