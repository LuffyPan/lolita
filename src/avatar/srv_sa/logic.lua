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
}

function Logic:Init()
  SoulerNet:RegisterLogic(self:__GetSoulerLogic(), self)
  LoginNet:RegisterLogic(self:__GetLoginLogic(), self)
end

function Logic:SoulerAccept(Souler)
  for k, v in pairs(Souler) do
    print(k, v)
  end
  print(string.format("Souler[%u] Accept", Souler.Id))
  print(string.format("Set Souler's State to [%s]", self.SS.NORMAL))
  Souler.State = self.SS.NORMAL
end

function Logic:SoulerClose(Souler)
  for k, v in pairs(Souler) do
    print(k, v)
  end
  print(string.format("Souler[%u] Close", Souler.Id))
  print(string.format("Souler's State is [%s]", Souler.State))
end

function Logic:SoulerAuth(Souler)
  for k, v in pairs(Souler) do
    print(k, v)
  end
  print(string.format("Souler[%u] Auth", Souler.Id))
  print(string.format("Souler's State is [%s]", Souler.State))
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
  for k, v in pairs(Souler) do
    print(k, v)
  end
  print(string.format("Souler[%u] Register", Souler.Id))
  print(string.format("Souler's State is [%s]", Souler.State))
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
  print(string.format("Souler[%u] Login Auth", Souler.Id))
  print(string.format("Souler's State is [%s]", Souler.State))
  if Souler.State ~= self.SS.AUTH then
    print(string.format("Souler's State is not [%s], but [%s]", self.SS.AUTH, Souler.State))
    return
  end
  Souler.State = self.SS.NORMAL
  local AuthPack = {ProcId = "Auth"}
  AuthPack.Account = Souler.Pack.Account
  AuthPack.Password = Souler.Pack.Password
  assert(SoulerNet:PushPackage(Souler, AuthPack))
end

function Logic:LoginRegister(Souler)
  print(string.format("Souler[%u] Login Register", Souler.Id))
  print(string.format("Souler's State is [%s]", Souler.State))
  if Souler.State ~= self.SS.REGISTER then
    print(string.format("Souler's State is not [%s], but [%s]", self.SS.REGISTER, Souler.State))
    return
  end
  Souler.State = self.SS.NORMAL
  local RegisterPack = {ProcId = "Register"}
  RegisterPack.Account = Souler.Pack.Account
  RegisterPack.Password = Souler.Pack.Password
  RegisterPack.Age = Souler.Pack.Age
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

