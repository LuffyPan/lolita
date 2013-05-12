--
-- God Logic SoulerAgency
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/05/06 21:54:55
--

LoliSrvGod.LogicSA= {}

local LogicSA = LoliSrvGod.LogicSA
local SANet = LoliSrvGod.SANet

function LogicSA:Init()
  self.Logh = assert(LoliCore.Io:OpenLog("srv_god.log"))
  SANet:RegisterLogic(self:__GetLogic(), self)
end

function LogicSA:Log(fmt, ...)
  LoliCore.Io:Log(self.Logh, fmt, ...)
end

function LogicSA:OnRequestQuerySouler(SAState)
  self:Log("OnRequestQuerySouler")
end

function LogicSA:OnRequestCreateSouler(SAState)
  self:Log("OnRequestCreateSouler")
end

function LogicSA:OnRequestDestroySouler(SAState)
  self:Log("OnRequestDestroySouler")
end

function LogicSA:OnRequestSelectSouler(SAState)
  self:Log("OnRequestSelectSouler")
end

function LogicSA:OnRequestClose(SAState)
  self:Log("OnRequestClose")
  LoliCore.Avatar:Detach()
end

function LogicSA:__GetLogic()
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
