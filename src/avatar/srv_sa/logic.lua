--
-- Souler Agency Main Logic
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/04/23 16:09:44
--

LoliSrvSa.Logic = {}

local Logic = LoliSrvSa.Logic
local SoulerNet = LoliSrvSa.SoulerNet

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
    GovId = 0,
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

function Logic:OnRequestQuerySouler(NetId, Pack)
  local Souler = assert(SoulerRepos:GetByNetId(NetId))
  print(string.format("Souler NetId[%u], SoulId[%s], RequestQuerySouler", Souler.NetId, Souler.SoulId))
  if Souler.SoulId == 0 then
    Pack.ErrorCode = 2
    assert(SoulerNet:PushPackage(Souler.NetId, Pack))
    return
  end
  Pack.SoulId = Souler.SoulId
  assert(GodNet:PushPackage(Pack))
end

function Logic:OnRequestCreateSouler(NetId, Pack)
  local Souler = assert(SoulerRepos:GetByNetId(NetId))
  print(string.format("Souler NetId[%u], SoulId[%s], RequestCreateSouler", Souler.NetId, Souler.SoulId))
  if Souler.SoulId == 0 then
    Pack.ErrorCode = 3
    assert(SoulerNet:PushPackage(Souler.NetId, Pack))
    return
  end
  Pack.SoulId = Souler.SoulId
  assert(GodNet:PushPackage(Pack))
end

function Logic:OnRequestSelectSouler(NetId, Pack)
  local Souler = assert(SoulerRepos:GetByNetId(NetId))
  print(string.format("Souler NetId[%u], SoulId[%s], RequestSelectSouler", Souler.NetId, Souler.SoulId))
  if Souler.SoulId == 0 then
    Pack.ErrorCode = 4
    assert(SoulerNet:PushPackage(Souler.NetId, Pack))
    return
  end
  Pack.SoulId = Souler.SoulId
  assert(GodNet:PushPackage(Pack))
end

function Logic:OnRequestArrival(NetId, Pack)
  local Souler = assert(SoulerRepos:GetByNetId(NetId))
  print(string.format("Souler NetId[%u], SoulId[%u], GovId[%u], RequestArrival", Souler.NetId, Souler.SoulId, Souler.GovId))
  if Souler.SoulId == 0 then
    Pack.ErrorCode = 5
    assert(SoulerNet:PushPackage(Souler.NetId, Pack))
    return
  end
  if Souler.GovId == 0 then
    Pack.ErrorCode = 6
    assert(SoulerNet:PushPackage(Souler.NetId, Pack))
    return
  end 
  Pack.SoulId = Souler.SoulId
  Pack.GovId = Souler.GovId
  assert(GovNet:PushPackage(Pack))
end

function Logic:OnRequestDeparture(NetId, Pack)
  local Souler = assert(SoulerRepos:GetByNetId(NetId))
  print(string.format("Souler NetId[%u], SoulId[%u], GovId[%u], RequestDeparture", Souler.NetId, Souler.SoulId, Souler.GovId))
  if Souler.SoulId == 0 then
    Pack.ErrorCode = 5
    assert(SoulerNet:PushPackage(Souler.NetId, Pack))
    return
  end
  if Souler.GovId == 0 then
    Pack.ErrorCode = 6
    assert(SoulerNet:PushPackage(Souler.NetId, Pack))
    return
  end 
  Pack.SoulId = Souler.SoulId
  Pack.GovId = Souler.GovId
  assert(GovNet:PushPackage(Pack))
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

function Logic:OnRespondQuerySouler(NetId, Pack)
  local Souler = assert(SoulerRepos:GetBySoulId(Pack.SoulId))
  print(string.format("Souler NetId[%u], SoulId[%s], RespondQuerySouler", Souler.NetId, Souler.SoulId))
  if Pack.Result == 1 then
    print(string.format("Query Souler Succedd"))
  else
    print(string.format("Query Souler Failed"))
  end
  assert(SoulerNet:PushPackage(Souler.NetId, Pack))
end

function Logic:OnRespondCreateSouler(NetId, Pack)
  local Souler = assert(SoulerRepos:GetBySoulId(Pack.SoulId))
  print(string.format("Souler NetId[%u], SoulId[%s], RespondCreateSouler", Souler.NetId, Souler.SoulId))
  if Pack.Result == 1 then
    print(string.format("Create Souler Succedd"))
  else
    print(string.format("Create Souler Failed"))
  end
  assert(SoulerNet:PushPackage(Souler.NetId, Pack))
end

function Logic:OnRespondSelectSouler(NetId, Pack)
  local Souler = assert(SoulerRepos:GetBySoulId(Pack.SoulId))
  print(string.format("Souler NetId[%u], SoulId[%s], RespondSelectSouler", Souler.NetId, Souler.SoulId))
  if Pack.Result == 1 then
    print(string.format("Select Souler Succedd"))
    Souler.GovId = Pack.GovId
  else
    print(string.format("Select Souler Failed"))
  end
  assert(SoulerNet:PushPackage(Souler.NetId, Pack))
end

function Logic:OnRespondArrival(NetId, Pack)
  local Souler = assert(SoulerRepos:GetBySoulId(Pack.SoulId))
  print(string.format("Souler NetId[%u], SoulId[%s], RespondArrival", Souler.NetId, Souler.SoulId))
  if Pack.Result == 1 then
    print(string.format("Arrival GovId[%u] Succedd", Pack.GovId))
  else
    print(string.format("Arrival GovId[%u] Failed", Pack.GovId))
  end
  assert(SoulerNet:PushPackage(Souler.NetId, Pack))
end

function Logic:OnRespondDeparture(NetId, Pack)
  local Souler = assert(SoulerRepos:GetBySoulId(Pack.SoulId))
  print(string.format("Souler NetId[%u], SoulId[%s], RespondDeparture", Souler.NetId, Souler.SoulId))
  if Pack.Result == 1 then
    print(string.format("Departure GovId[%u] Succedd", Pack.GovId))
  else
    print(string.format("Departure GovId[%u] Failed", Pack.GovId))
  end
  assert(SoulerNet:PushPackage(Souler.NetId, Pack))
end

function Logic:__GetSoulerLogic()
  self.__SoulerLogic =
  {
    Accept = self.OnRequestAccept,
    Close = self.OnRequestClose,
    Auth = self.OnRequestAuth,
    Register = self.OnRequestRegister,

    RequestCreateSouler = self.OnRequestCreateSouler,
    RequestQuerySouler = self.OnRequestQuerySouler,
    RequestSelectSouler = self.OnRequestSelectSouler,

    RequestArrival = self.OnRequestArrival,
    RequestDeparture = self.OnRequestDeparture,
  }
  return self.__SoulerLogic
end
