--
-- Souler Agency Main Logic
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/04/23 16:09:44
--

LoliSrvSa.Logic = {}

local Logic = LoliSrvSa.Logic
local SoulerNet = LoliSrvSa.SoulerNet
local LoginNet = LoliSrvSa.LoginNet
local GovNet = LoliSrvSa.GovNet

local SoulerRepos = {}

function SoulerRepos:Init()
  self._NetId2Soulers = {}
  self._SoulId2Soulers = {}
end

function SoulerRepos:New(NetId)
  assert(not self._NetId2Soulers[NetId])
  local Souler =
  {
    NetId = NetId,
    SoulId = 0,
  }
  self._NetId2Soulers[NetId] = Souler
  return Souler
end

function SoulerRepos:Delete(NetId)
  local Souler = assert(self._NetId2Soulers[NetId])
  assert(Souler.NetId == NetId)
  self._SoulId2Soulers[Souler.SoulId] = nil
  self._NetId2Soulers[Souler.NetId] = nil
  return Souler
end

function SoulerRepos:AttachSoulId(NetId, SoulId)
  local Souler = assert(self._NetId2Soulers[NetId])
  assert(Souler.SoulId == 0)
  Souler.SoulId = SoulId
  assert(not self._SoulId2Soulers[SoulId])
  self._SoulId2Soulers[SoulId] = Souler
  return Souler
end

function SoulerRepos:GetByNetId(NetId)
  local Souler = self._NetId2Soulers[NetId]
  return Souler
end

function SoulerRepos:GetBySoulId(SoulId)
  local Souler = self._SoulId2Soulers[SoulId]
  return Souler
end




function Logic:Init()
  SoulerRepos:Init()
  SoulerNet:RegisterLogic(self:__GetSoulerLogic(), self)
  LoginNet:RegisterLogic(self:__GetLoginLogic(), self)
  GovNet:RegisterLogic(self:__GetGovLogic(), self)
end

function Logic:OnRequestAccept(NetId)
  local Souler = assert(SoulerRepos:New(NetId))
  print(string.format("Souler NetId[%u], SoulId[%s], RequestAccept", Souler.NetId, Souler.SoulId))
end

function Logic:OnRequestClose(NetId)
  local Souler = assert(SoulerRepos:Delete(NetId))
  print(string.format("Souler NetId[%u], SoulId[%s], RequestClose", Souler.NetId, Souler.SoulId))
end

function Logic:OnRequestAuth(NetId, Pack)
  local Souler = assert(SoulerRepos:GetByNetId(NetId))
  print(string.format("Souler NetId[%u], SoulId[%s], RequestAuth", Souler.NetId, Souler.SoulId))
  if Souler.SoulId > 0 then
    --Send Back
    Pack.ErrorCode = 1
    assert(SoulerNet:PushPackage(Souler.NetId, Pack))
    return
  end
  local AuthPack = {}
  AuthPack.ProcId = "Auth"
  AuthPack.Account = Pack.Account
  AuthPack.Password = Pack.Password
  AuthPack.NetId = Souler.NetId
  assert(LoginNet:PushPackage(AuthPack))
end

function Logic:OnRequestRegister(NetId, Pack)
  local Souler = assert(SoulerRepos:GetByNetId(NetId))
  print(string.format("Souler NetId[%u], SoulId[%s], RequestRegister", Souler.NetId, Souler.SoulId))
  local RegisterPack = {}
  RegisterPack.ProcId = "Register"
  RegisterPack.Account = Pack.Account
  RegisterPack.Password = Pack.Password
  RegisterPack.Age = Pack.Age
  RegisterPack.NetId = Souler.NetId
  assert(LoginNet:PushPackage(RegisterPack))
end

function Logic:OnRespondAuth(NetId, Pack)
  local Souler = assert(SoulerRepos:GetByNetId(Pack.NetId))
  local AuthPack = {ProcId = "Auth"}
  AuthPack.Result = Pack.Result
  AuthPack.ErrorCode = Pack.ErrorCode
  print(string.format("Souler NetId[%u], SoulId[%s], ResponedAuth", Souler.NetId, Souler.SoulId))
  if Pack.Result ~= 1 then
    print(string.format("Auth Failed, ErrorCode[%s]", Pack.ErrorCode))
  else
    print(string.format("Auth Succeed, SoulId[%s]", Souler.SoulId))
    SoulerRepos:AttachSoulId(Souler.NetId, Pack.SoulId)
    assert(Souler.SoulId > 0)
  end
  assert(SoulerNet:PushPackage(Souler.NetId, AuthPack))
end

function Logic:OnRespondRegister(NetId, Pack)
  local Souler = assert(SoulerRepos:GetByNetId(Pack.NetId))
  local RegisterPack = {ProcId = "Register"}
  RegisterPack.Account = Pack.Account
  RegisterPack.Password = Pack.Password
  RegisterPack.Age = Pack.Age
  RegisterPack.Result = Pack.Result
  RegisterPack.ErrorCode = Pack.ErrorCode
  print(string.format("Souler NetId[%u], SoulId[%s], RespondRegister", Souler.NetId, Souler.SoulId))
  if Pack.Result == 1 then
    print(string.format("Register Succedd, Account[%s], SoulId[%s]", Pack.Account, Pack.SoulId))
  else
    print(string.format("Register Failed, ErrorCode[%s]", Pack.ErrorCode))
  end
  assert(SoulerNet:PushPackage(Souler.NetId, RegisterPack))
end

function Logic:__GetSoulerLogic()
  self.__SoulerLogic =
  {
    Accept = self.OnRequestAccept,
    Close = self.OnRequestClose,
    Auth = self.OnRequestAuth,
    Register = self.OnRequestRegister,
  }
  return self.__SoulerLogic
end

function Logic:__GetLoginLogic()
  self.__LoginLogic =
  {
    Auth = self.OnRespondAuth,
    Register = self.OnRespondRegister,
  }
  return self.__LoginLogic
end

function Logic:__GetGovLogic()
  self.__GovLogic =
  {
    RequestArrival = self.OnRequestArrival,
    RequestDeparture = self.OnRequestDeparture,
  }
  return self.__GovLogic
end
