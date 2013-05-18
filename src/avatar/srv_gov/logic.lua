--
-- Goverment Main Logic
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/04/28 15:38:45
--

LoliSrvGoverment.Logic = {}

local Logic = LoliSrvGoverment.Logic
local SaNet = LoliSrvGoverment.SaNet
local AreaNet = LoliSrvGoverment.AreaNet
local GodNet = LoliSrvGoverment.GodNet

local SoulerRepos = {}

function SoulerRepos:Init()
  self._SoulId2Soulers = {}
end

function SoulerRepos:New(SoulId, SaNetId)
  assert(not self._SoulId2Soulers[SoulId])
  local Souler =
  {
    SaNetId = SaNetId,
    SoulId = SoulId,
    AreaId = 0,
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
  self.Logh = assert(LoliCore.Io:OpenLog("srv_gov.log"))
  SaNet:RegisterLogic(self:__GetSaLogic(), self)
  AreaNet:RegisterLogic(self:__GetAreaLogic(), self)
  GodNet:RegisterLogic(self:__GetGodLogic(), self)
  SoulerRepos:Init()
end

function Logic:Log(fmt, ...)
  LoliCore.Io:Log(self.Logh, fmt, ...)
end

function Logic:OnRequestArrival(NetId, Pack)
  self:Log("Souler SoulId[%u] GovId[%u] RequestArrival", Pack.SoulId, Pack.GovId)
  local Souler = assert(SoulerRepos:New(Pack.SoulId, NetId))
  local RequestGetSouler =
  {
    ProcId = "RequestGetSouler",
    SoulId = Pack.SoulId,
    GovId = Pack.GovId,
  }
  assert(GodNet:PushPackage(RequestGetSouler))
end

function Logic:OnRequestDeparture(NetId, Pack)
  self:Log("Souler SoulId[%u] GovId[%u] RequestDeparture", Pack.SoulId, Pack.GovId)
  local Souler = assert(SoulerRepos:GetBySoulId(Pack.SoulId))
end

function Logic:OnRequestClose(NetId, Pack)
  self:Log("OnRequestClose")
  LoliCore.Avatar:Detach()
end

function Logic:OnRespondGetSouler(NetId, Pack)
  self:Log("Souler SoulId[%u], GovId[%u] RespondGetSouler", Pack.SoulId, Pack.GovId)
  local Souler = assert(SoulerRepos:GetBySoulId(Pack.SoulId))
  local ArrivalPack =
  {
    ProcId = "RequestArrival",
    SoulId = Souler.SoulId,
    GovId = Pack.GovId,
    Result = Pack.Result,
    ErrorCode = Pack.ErrorCode,
  }
  if Pack.Result == 0 then
    assert(SaNet:PushPackage(Souler.SaNetId, ArrivalPack))
    self:Log("GetSouler Failed, ec[%d]", Pack.ErrorCode)
    return
  else
    ArrivalPack.Souler = Pack.Souler
    --assert(AreaNet:PushPackage(Souler.AreaNetId, ArrivalPack))
    self:Log("GetSouler Succeed")
  end
end

function Logic:OnRespondArrival(NetId, Pack)
  self:Log("OnRespondArrival")
end

function Logic:OnRespondDeparture(NetId, Pack)
  self:Log("OnRespondDeparture")
end

function Logic:__GetSaLogic()
  if self.__SaLogic then return self.__SaLogic end
  self.__SaLogic =
  {
    RequestArrival = self.OnRequestArrival,
    RequestDeparture = self.OnRequestDeparture,
    RequestClose = self.OnRequestClose,
  }
  return self.__SaLogic
end

function Logic:__GetAreaLogic()
  if self.__AreaLogic then return self.__AreaLogic end
  self.__AreaLogic =
  {
    Accept = self.OnAreaAccept,
    Close = self.OnAreaClose,
    RequestArrival = self.OnRespondArrival,
    RequestDeparture = self.OnRespondDeparture,
  }
  return self.__AreaLogic
end

function Logic:__GetGodLogic()
  if self.__GodLogic then return self.__GodLogic end
  self.__GodLogic =
  {
    RequestGetSouler = self.OnRespondGetSouler,
  }
  return self.__GodLogic
end
