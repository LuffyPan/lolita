--
-- Goverment Main Logic
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/04/28 15:38:45
--

LoliSrvGoverment.Logic = {}

local Logic = LoliSrvGoverment.Logic
local SrvNet = LoliSrvGoverment.SrvNet

function Logic:Init()
  self.Logh = assert(LoliCore.Io:OpenLog("srv_gov.log"))
  SrvNet:RegisterLogic(self:__GetLogic(), self)
end

function Logic:Log(fmt, ...)
  LoliCore.Io:Log(self.Logh, fmt, ...)
end

function Logic:OnRequestQuerySouler(Srv)
  self:Log("OnRequestQuerySouler")
end

function Logic:OnRequestCreateSouler(Srv)
  self:Log("OnRequestCreateSouler")
end

function Logic:OnRequestDestroySouler(Srv)
  self:Log("OnRequestDestroySouler")
end

function Logic:OnRequestSelectSouler(Srv)
  self:Log("OnRequestSelectSouler")
end

function Logic:OnRequestClose(Srv)
  self:Log("OnRequestClose")
  LoliCore.Avatar:Detach()
end

function Logic:__GetLogic()
  if self.__Logic then return self.__Logic end
  self.__Logic =
  {
    RequestQuerySouler = self.OnRequestQuerySouler,
    RequestCreateSouler = self.OnRequestCreateSouler,
    RequestDestroySouler = self.OnRequestDestroySouler,
    RequestSelectSouler = self.OnRequestSelectSouler,
    RequestClose = self.OnRequestClose,
  }
  return self.__Logic
end
