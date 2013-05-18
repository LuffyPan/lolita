--
-- Goverment Main Logic
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/04/28 15:38:45
--

LoliSrvGoverment.Logic = {}

local Logic = LoliSrvGoverment.Logic
local SaNet = LoliSrvGoverment.SaNet
local AreaNet = LoliSrvGoverment.AreaNet

function Logic:Init()
  self.Logh = assert(LoliCore.Io:OpenLog("srv_gov.log"))
  SaNet:RegisterLogic(self:__GetSaLogic(), self)
  AreaNet:RegisterLogic(self:__GetAreaLogic(), self)
end

function Logic:Log(fmt, ...)
  LoliCore.Io:Log(self.Logh, fmt, ...)
end

function Logic:OnRequestArrival(NetId, Pack)
  self:Log("OnRequestArrival")
end

function Logic:OnRequestDeparture(NetId, Pack)
  self:Log("OnRequestDeparture")
end

function Logic:OnRequestClose(NetId, Pack)
  self:Log("OnRequestClose")
  LoliCore.Avatar:Detach()
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
  }
  return self.__AreaLogic
end
