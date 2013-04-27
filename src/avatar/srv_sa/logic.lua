--
-- Logic
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/04/23 16:09:44
--

LoliSrvSA.Logic = {}

local Logic = LoliSrvSA.Logic
local SoulerNet = LoliSrvSA.SoulerNet
local LoginNet = LoliSrvSA.LoginNet

Logic.SS =
{
  NORMAL = "Normal",
  REGISTER = "Register",
  AUTH = "Auth",
  SOULER =
  {
    QUERY = "QuerySoulers",
    CREATE = "CreateSouler",
    DESTROY = "DestroySouler",
    SELECT = "SelectSouler",
  },
}

function Logic:Init()
  SoulerNet:RegisterLogic(self:__GetSoulerLogic(), self)
  LoginNet:RegisterLogic(self:__GetLoginLogic(), self)
end

function Logic:SoulerAccept(Souler)
  --for k, v in pairs(Souler) do print(k,v) end
  assert(not Souler.Souler)
  assert(not Souler.State)
  print(string.format("Souler Id[%u], SoulId[%s], State[%s] RequestAccept", Souler.Id, Souler.SoulId, Souler.State))
  Souler.State = self.SS.NORMAL
  print(string.format("Set State To [%s]", Souler.State))
end

function Logic:SoulerClose(Souler)
  print(string.format("Souler Id[%u], SoulId[%s], State[%s] RequestClose", Souler.Id, Souler.SoulId, Souler.State))
end

function Logic:SoulerAuth(Souler)
  print(string.format("Souler Id[%u], SoulId[%s], State[%s] RequestAuth", Souler.Id, Souler.SoulId, Souler.State))
  if Souler.State ~= self.SS.NORMAL then
    --Send Back
    --Just assert, ToDo
    Souler.Pack.Result = 0
    Souler.Pack.ErrorCode = 1
    assert(SoulerNet:PushPackage(Souler, Souler.Pack))
    return
  end
  local AuthPack = {}
  AuthPack.ProcId = "Auth"
  AuthPack.Account = Souler.Pack.Account
  AuthPack.Password = Souler.Pack.Password
  assert(LoginNet:PushPackage(Souler, AuthPack))
  Souler.State = self.SS.AUTH
end

function Logic:SoulerRegister(Souler)
  print(string.format("Souler Id[%u], SoulId[%s], State[%s] RequestRegister", Souler.Id, Souler.SoulId, Souler.State))
  if Souler.State ~= self.SS.NORMAL then
    Souler.Pack.Result = 0
    Souler.Pack.ErrorCode = 2
    assert(SoulerNet:PushPackage(Souler, Souler.Pack))
    return
  end
  local RegisterPack = {ProcId = "Register"}
  RegisterPack.Account = Souler.Pack.Account
  RegisterPack.Password = Souler.Pack.Password
  RegisterPack.Age = Souler.Pack.Age
  assert(LoginNet:PushPackage(Souler, RegisterPack))
  Souler.State = self.SS.REGISTER
end

function Logic:LoginAuth(Souler)
  print(string.format("Souler Id[%u], SoulId[%s], State[%s] Login ResponedAuth", Souler.Id, Souler.SoulId, Souler.State))
  if Souler.State ~= self.SS.AUTH then
    print(string.format("State[%s] Is Not [%s]", Souler.State, self.SS.AUTH))
    return
  end
  if Souler.Pack.Result == 1 then
    Souler.State = self.SS.SOULER.QUERY
    Souler.SoulId = Souler.Pack.SoulId
    print(string.format("Auth Succeed, SoulId[%s]", Souler.SoulId))
  else
    Souler.State = self.SS.NORMAL
    print(string.format("Auth Failed, ErrorCode[%s]", Souler.Pack.ErrorCode))
  end
  local AuthPack = {ProcId = "Auth"}
  AuthPack.Account = Souler.Pack.Account
  AuthPack.Password = Souler.Pack.Password
  AuthPack.Result = Souler.Pack.Result
  AuthPack.ErrorCode = Souler.Pack.ErrorCode
  assert(SoulerNet:PushPackage(Souler, AuthPack))
end

function Logic:LoginRegister(Souler)
  print(string.format("Souler Id[%u], SoulId[%s], State[%s] Login RespondRegister", Souler.Id, Souler.SoulId, Souler.State))
  if Souler.State ~= self.SS.REGISTER then
    print(string.format("State[%s] Is Not [%s]", Souler.State, self.SS.REGISTER))
    return
  end
  if Souler.Pack.Result == 1 then
    print(string.format("Register Succedd, Account[%s], SoulId[%s]", Souler.Pack.Account, Souler.Pack.SoulId))
  else
    print(string.format("Register Failed, ErrorCode[%s]", Souler.Pack.ErrorCode))
  end
  Souler.State = self.SS.NORMAL
  local RegisterPack = {ProcId = "Register"}
  RegisterPack.Account = Souler.Pack.Account
  RegisterPack.Password = Souler.Pack.Password
  RegisterPack.Age = Souler.Pack.Age
  RegisterPack.Result = Souler.Pack.Result
  RegisterPack.ErrorCode = Souler.Pack.ErrorCode
  assert(SoulerNet:PushPackage(Souler, RegisterPack))
end

function Logic:__GetSoulerLogic()
  self.__SoulerLogic =
  {
    Accept = self.SoulerAccept,
    Close = self.SoulerClose,
    Auth = self.SoulerAuth,
    Register = self.SoulerRegister,
  }
  return self.__SoulerLogic
end

function Logic:__GetLoginLogic()
  self.__LoginLogic =
  {
    Auth = self.LoginAuth,
    Register = self.LoginRegister,
  }
  return self.__LoginLogic
end

