--
-- Test Login, Login Servers test about
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/07/04 11:56:03
--

local Executor = assert(LoliSrvTest.Executor)
local Login = assert(LoliSrvTest.Login)

function Login:Init()
  Executor:AttachTarget("login", Login)
end

function Login:Execute()
  local ConnectParam = {}
  ConnectParam.Procs = self:_GetProcs()
  self.LoginNetId = assert(LoliCore.Net:ConnectEx("127.0.0.1", 7000, ConnectParam))
end

function Login:OnConnect(NetId, Result)
  LoliCore.Imagination:Begin(16, self.ReqRegister, self)
end

function Login:OnClose(NetId)
  print("Finished By Login Server Closed")
  LoliCore.Avatar:Detach()
end

function Login:ResRegister(NetId, Pack)
  LoliCore.Imagination:Begin(16, self.ReqAuth, self)
end

function Login:ResAuth(NetId, Pack)
  print("Finished!!")
  LoliCore.Avatar:Detach()
end

function Login:ReqRegister()
  local Pack =
  {
    ProcId = "ReqRegister",
    Account = "LoliAccount",
    Password = "LoliPassword",
    Age = 19,
  }
  LoliCore.Net:PushPackage(self.LoginNetId, Pack)
end

function Login:ReqAuth()
  local Pack =
  {
    ProcId = "ReqAuth",
    Account = "LoliAccount",
    Password = "LoliPassword",
  }
  LoliCore.Net:PushPackage(self.LoginNetId, Pack)
end

function Login:_GetProcs()
  return
  {
    Param = self,
    Connect = self.OnConnect,
    Close = self.OnClose,
    ResRegister = self.ResRegister,
    ResAuth = self.ResAuth,
  }
end
