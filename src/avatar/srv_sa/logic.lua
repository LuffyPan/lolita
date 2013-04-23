--
-- Logic
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/04/23 16:09:44
--

LoliSrvSA.Logic = {}

local Logic = LoliSrvSA.Logic
local SoulerNet = LoliSrvSA.SoulerNet
local LoginNet = LoliSrvSA.LoginNet

function Logic:Init()
  SoulerNet:RegisterLogic(self:__GetSoulerLogic(), self)
  LoginNet:RegisterLogic(self:__GetLoginLogic(), self)
end

function Logic:SoulerAccept(Souler)
  print("SoulerAccept")
end

function Logic:SoulerClose(Souler)
  print("SoulerClose")
end

function Logic:SoulerAuth(Souler)
  print("SoulerAuth")
end

function Logic:SoulerRegister(Souler)
  print("SoulerRegister")
end

function Logic:LoginAuth(Souler)
  print("LoginAuth")
end

function Logic:LoginRegister(Souler)
  print("LoginRegister")
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
