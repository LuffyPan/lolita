--
-- Goverment Main Logic
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/04/28 15:38:45
--

LoliSrvGoverment.Logic = {}

local Logic = LoliSrvGoverment.Logic
local SaSrvNet = LoliSrvGoverment.SaSrvNet
local AreaSrvNet = LoliSrvGoverment.AreaSrvNet

function Logic:Init()
  self.Logh = assert(LoliCore.Io:OpenLog("srv_gov.log"))
  SaSrvNet:RegisterLogic(self:__GetSaLogic(), self)
  AreaSrvNet:RegisterLogic(self:__GetAreaLogic(), self)
end

function Logic:Log(fmt, ...)
  LoliCore.Io:Log(self.Logh, fmt, ...)
end

function Logic:OnRequestArrival(Srv)
  self:Log("OnRequestArrival")
end

function Logic:OnRequestDeparture(Srv)
  self:Log("OnRequestDeparture")
end

function Logic:OnRequestClose(Srv)
  self:Log("OnRequestClose")
  LoliCore.Avatar:Detach()
end

function Logic:__GetSaLogic()
  if self.__Logic then return self.__Logic end
  self.__Logic =
  {
    RequestArrival = self.OnRequestArrival,
    RequestDeparture = self.OnRequestDeparture,
    RequestClose = self.OnRequestClose,
  }
  return self.__Logic
end

function Logic:__GetAreaLogic()
  if self.__Logic then return self.__Logic end
  self.__Logic =
  {
  }
  return self.__Logic
end
