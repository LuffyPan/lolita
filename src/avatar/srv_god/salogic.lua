--
-- God Logic SoulerAgency
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/05/06 21:54:55
--

LoliSrvGod.LogicSA= {}

local LogicSA = LoliSrvGod.LogicSA
local SANet = LoliSrvGod.SANet
local LogicSouler = LoliSrvGod.LogicSouler

function LogicSA:Init()
  self.Logh = assert(LoliCore.Io:OpenLog("srv_god.log"))
  SANet:RegisterLogic(self:__GetLogic(), self)
end

function LogicSA:Log(fmt, ...)
  LoliCore.Io:Log(self.Logh, fmt, ...)
end

function LogicSA:OnRequestQuerySouler(SAState)
  self:Log("OnRequestQuerySouler")
  local Souler = LogicSouler:Query(SAState.Pack.SoulId)
  SAState.Pack.Result = 1
  SAState.Pack.HasSouler = 0
  if Souler then
    SAState.Pack.HasSouler = 1
    SAState.Pack.Souler = Souler
  end
end

function LogicSA:OnRequestCreateSouler(SAState)
  self:Log("OnRequestCreateSouler")
  SAState.Pack.Result = 0
  SAState.Pack.ErrorCode = 0
  if LogicSouler:Create(SAState.Pack.SoulId, SAState.Pack.SoulInfo) then
    SAState.Pack.Result = 1
  end
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
