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
  self:Log("SoulId[%u], RequestLock", Srv.Pack.SoulId)
  local LockKey, ec, ed = GMgr:Lock(Srv.Pack.SoulId)
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
  self:Log("SoulId[%u], RequestUnlock", Srv.Pack.SoulId)
  local r, ec, ed = GMgr:Unlock(Srv.Pack.SoulId, Srv.Pack.LockKey)
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
  self:Log("SoulId[%u], RequestGet", Srv.Pack.SoulId)
  local r, ec, ed = GMgr:Get(Srv.Pack.SoulId, Srv.Pack.LockKey, Srv.Pack.Field)
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
  self:Log("SoulId[%u], RequestSet", Srv.Pack.SoulId)
  local r, ec, ed = GMgr:Set(Srv.Pack.SoulId, Srv.Pack.LockKey, Srv.Pack.Field, Srv.Pack.Value)
  if not r then
    Srv.Pack.ErrorCode = ec
    Srv.Pack.ErrorDesc = ed
    self:Log("Set Failed, [%u], [%s]", ec, ed)
    return
  end
  Srv.Pack.Result = 1
  self:Log("Set Succeed, Field[%s], Value[%s]", tostring(Srv.Pack.Field), tostring(Srv.Pack.Value))
end

function Logic:OnRequestLockAndGet(Srv)
  self:Log("SoulId[%u], RequestLockAndGet", Srv.Pack.SoulId)
  local LockKey, ec, ed = GMgr:Lock(Srv.Pack.SoulId)
  if not LockKey then
    Srv.Pack.ErrorCode = ec
    Srv.Pack.ErrorDesc = ed
    self:Log("Lock Failed, [%u], [%s]", ec, ed)
    return
  end
  local Value
  Value, ec, ed = GMgr:Get(Srv.Pack.SoulId, LockKey, Srv.Pack.Field)
  assert(Value, "Failed To Get With A New Key?")
  Srv.Pack.LockKey = LockKey
  Srv.Pack.Value = Value
  Srv.Pack.Result = 1
  self:Log("LockAndGet Succeed, LockKey[%u], Field[%s], Value[%s]", LockKey, Srv.Pack.Field, Value)
end

function Logic:OnRequestSetAndUnlock(Srv)
  self:Log("SoulId[%u], RequestSetAndUnlock", Srv.Pack.SoulId)
  local r, ec, ed = GMgr:Set(Srv.Pack.SoulId, Srv.Pack.LockKey, Srv.Pack.Field, Srv.Pack.Value)
  if not r then
    Srv.Pack.ErrorCode = ec
    Srv.Pack.ErrorDesc = ed
    self:Log("Set Failed, [%u], [%s]", ec, ed)
    return
  end
  r, ec, ed = GMgr:Unlock(Srv.Pack.SoulId, Srv.Pack.LockKey)
  assert(r, "Failed To Unlock With A Good Key?")
  Srv.Pack.Result = 1
  self:Log("SetAndUnlock Succeed, LockKey[%u], Field[%s], Value[%s]", Srv.Pack.LockKey, Srv.Pack.Field, Srv.Pack.Value)
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
    RequestLockAndGet = self.OnRequestLockAndGet,
    RequestSetAndUnlock = self.OnRequestSetAndUnlock,
    RequestClose = self.OnRequestClose,
  }
  return self.__Logic
end
