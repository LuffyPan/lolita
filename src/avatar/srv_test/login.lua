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
  local ConnectExParam = {}
  ConnectExParam.Procs = self:_GetProcs()
  self.SaNetId = assert(LoliCore.Net:ConnectEx("127.0.0.1", 7000, ConnectExParam))
  self.AuthCount = 0
end

function Login:OnConnect(NetId, Result)
  LoliCore.Imagination:Begin(16, self.ReqRegister, self)
end

function Login:OnClose(NetId)
  print("Finished By Sa Server Closed")
  LoliCore.Avatar:Detach()
end

function Login:ResRegister(NetId, Pack)
  LoliCore.Imagination:Begin(16, self.ReqAuth, self)
end

function Login:ResAuth(NetId, Pack)
  self.AuthCount = self.AuthCount + 1
  if self.AuthCount >= 2 then
    --print("Finished!!")
    --LoliCore.Avatar:Detach()
    LoliCore.Imagination:Begin(16, self.ReqSouler, self)
    return
  end
  LoliCore.Imagination:Begin(16, self.ReqAuth, self)
end

function Login:ResQuerySouler(NetId, Pack)
end

function Login:ResCreateSouler(NetId, Pack)
end

function Login:ResDestroySouler(NetId, Pack)
end

function Login:ResSelectSouler(NetId, Pack)
end

function Login:ReqRegister()
  local Pack = LoliCore.Net:GenPackage("ReqRegister", {Account = "LoliAccount", Password = "LoliPassword", Age = 19})
  LoliCore.Net:PushPackage(self.SaNetId, Pack)
end

function Login:ReqAuth()
  local Pack = LoliCore.Net:GenPackage("ReqAuth", {Account = "LoliAccount", Password = "LoliPassword"})
  LoliCore.Net:PushPackage(self.SaNetId, Pack)
end

function Login:ReqSouler()
  local Pack = LoliCore.Net:GenPackage("ReqQuerySouler", {})
  LoliCore.Net:PushPackage(self.SaNetId, Pack)

  Pack = LoliCore.Net:GenPackage("ReqCreateSouler", {})
  Pack.SoulerInfo = {}
  LoliCore.Net:PushPackage(self.SaNetId, Pack)

  Pack = LoliCore.Net:GenPackage("ReqDestroySouler", {})
  Pack.SoulerId = 110
  LoliCore.Net:PushPackage(self.SaNetId, Pack)

  Pack = LoliCore.Net:GenPackage("ReqSelectSouler", {})
  Pack.SoulerId = 110
  LoliCore.Net:PushPackage(self.SaNetId, Pack)
end

function Login:PreProc(NetId, Pack)
  print(string.format("Net[%s], %s, Result[%s]", NetId, Pack.ProcId, Pack.Result))
  return 1
end

function Login:_GetProcs()
  return
  {
    Param = self,
    Pre = self.PreProc,
    Connect = self.OnConnect,
    Close = self.OnClose,
    ResRegister = self.ResRegister,
    ResAuth = self.ResAuth,
    ResQuerySouler = self.ResQuerySouler,
    ResCreateSouler = self.ResCreateSouler,
    ResDestroySouler = self.ResDestroySouler,
    ResSelectSouler = self.ResSelectSouler,
  }
end
