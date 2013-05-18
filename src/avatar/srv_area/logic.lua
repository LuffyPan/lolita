--
-- Lolita Area Server Main Logic
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/05/18 20:32:40
--

LoliSrvArea.Logic = {}

local Logic = LoliSrvArea.Logic
local GovNet = LoliSrvArea.GovNet

function Logic:Init()
  GovNet:RegisterLogic(self:__GetLogic(), self)
end

function Logic:OnRequestArrival(NetId, Pack)
  print("OnRequestArrival")
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
