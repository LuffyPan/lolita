--
-- Main Logic
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/04/25 00:18:50
--

LoliSrvGSS.Logic = {}

local Logic = LoliSrvGSS.Logic
local SrvNet = LoliSrvGSS.SrvNet
local GMgr = LoliSrvGSS.GMgr

function Logic:Init()
  self.Logh = assert(LoliCore.Io:OpenLog("srv_gss.log"))
  SrvNet:RegisterLogic(self:__GetLogic(), self)
end

function Logic:Log(fmt, ...)
  LoliCore.Io:Log(self.Logh, fmt, ...)
end

function Logic:OnRequestLock(Srv)
  self:Log("SoulerId[%u], RequestLock", Srv.Pack.SoulerId)
  local LockKey, ec, ed = GMgr:Lock(Srv.Pack.SoulerId)
  if not LockKey then
    Srv.Pack.ErrorCode = ec
    Srv.Pack.ErrorDesc = ed
    self:Log("Lock Failed, [%u], [%s]", ec, ed)
    return
  end
  Srv.Pack.LockKey = LockKey
  Srv.Pack.Result = 1
  self:Log("Lock Succeed, LockKey[%u]", LockKey)
end

function Logic:OnRequestUnlock(Srv)
  self:Log("SoulerId[%u], RequestUnlock", Srv.Pack.SoulerId)
  local r, ec, ed = GMgr:Unlock(Srv.Pack.SoulerId, Srv.Pack.LockKey)
  if not r then
    Srv.Pack.ErrorCode = ec
    Srv.Pack.ErrorDesc = ed
    self:Log("Unlock Failed, [%u], [%s]", ec, ed)
    return
  end
  Srv.Pack.Result = 1
  self:Log("Unlock Succeed")
end

function Logic:OnRequestGet(Srv)
  self:Log("SoulerId[%u], RequestGet", Srv.Pack.SoulerId)
  local r, ec, ed = GMgr:Get(Srv.Pack.SoulerId, Srv.Pack.LockKey, Srv.Pack.Field)
  if not r then
    Srv.Pack.ErrorCode = ec
    Srv.Pack.ErrorDesc = ed
    self:Log("Get Failed, [%u], [%s]", ec, ed)
    return
  end
  Srv.Pack.Value = r
  Srv.Pack.Result = 1
  self:Log("Get Succeed, Field[%s], Value[%s]", tostring(Srv.Pack.Field), tostring(r))
end

function Logic:OnRequestSet(Srv)
  self:Log("SoulerId[%u], RequestSet", Srv.Pack.SoulerId)
  local r, ec, ed = GMgr:Set(Srv.Pack.SoulerId, Srv.Pack.LockKey, Srv.Pack.Field, Srv.Pack.Value)
  if not r then
    Srv.Pack.ErrorCode = ec
    Srv.Pack.ErrorDesc = ed
    self:Log("Set Failed, [%u], [%s]", ec, ed)
    return
  end
  Srv.Pack.Result = 1
  self:Log("Set Succeed, Field[%s], Value[%s]", tostring(Srv.Pack.Field), tostring(Srv.Pack.Value))
end

function Logic:OnRequestClose(Srv)
  self:Log("OnRequestClose")
  LoliCore.Avatar:Detach()
end

function Logic:__GetLogic()
  if self.__Logic then return self.__Logic end
  self.__Logic =
  {
    RequestLock = self.OnRequestLock,
    RequestUnlock = self.OnRequestUnlock,
    RequestGet = self.OnRequestGet,
    RequestSet = self.OnRequestSet,
    RequestClose = self.OnRequestClose,
  }
  return self.__Logic
end