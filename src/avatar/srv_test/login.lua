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
  self.CreateSoulerCount = 0
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
    LoliCore.Imagination:Begin(16, self.ReqQueryArea, self)
    return
  end
  LoliCore.Imagination:Begin(16, self.ReqAuth, self)
end

function Login:ResQueryArea(NetId, Pack)
  if Pack.Result == 1 then
    print("The Areas Oooof The World:")
    for _, Area in ipairs(Pack.AreaList) do
      print(string.format("Id[%s], Name[%s], Available[%s]", Area.Id, "Unknown", Area.Available))
    end
  end
  LoliCore.Imagination:Begin(16, self.ReqQuerySouler, self)
end

function Login:ResQuerySouler(NetId, Pack)
  if Pack.Result == 1 then
    print("QuerySouler Finished!")
  end
  LoliCore.Imagination:Begin(16, self.ReqCreateSouler, self)
end

function Login:ResCreateSouler(NetId, Pack)
  if Pack.Result == 1 then
    print("CreateSouler Finished!")
  end
  self.CreateSoulerCount = self.CreateSoulerCount + 1
  if self.CreateSoulerCount >=3 then
    LoliCore.Imagination:Begin(16, self.ReqDestroySouler, self)
    return
  end
  LoliCore.Imagination:Begin(16, self.ReqCreateSouler, self)
end

function Login:ResDestroySouler(NetId, Pack)
  if Pack.Result == 1 then
    print("DestroySouler Finished!")
  end
  LoliCore.Imagination:Begin(16, self.ReqSelectSouler, self)
end

function Login:ResSelectSouler(NetId, Pack)
  if Pack.Result == 1 then
    print("SelectSouler Finished!")
  end
  LoliCore.Imagination:Begin(16, self.ReqArrival, self)
end

function Login:ResArrival(NetId, Pack)
  LoliCore.Imagination:Begin(16, self.ReqDeparture, self)
end

function Login:ResDeparture(NetId, Pack)
end

function Login:ReqRegister()
  local Pack = LoliCore.Net:GenPackage("ReqRegister", {Account = "LoliAccount", Password = "LoliPassword", Age = 19})
  LoliCore.Net:PushPackage(self.SaNetId, Pack)
end

function Login:ReqAuth()
  local Pack = LoliCore.Net:GenPackage("ReqAuth", {Account = "LoliAccount", Password = "LoliPassword"})
  LoliCore.Net:PushPackage(self.SaNetId, Pack)
end

function Login:ReqQueryArea()
  local Pack = LoliCore.Net:GenPackage("ReqQueryArea", {})
  LoliCore.Net:PushPackage(self.SaNetId, Pack)
end

function Login:ReqQuerySouler()
  local Pack = LoliCore.Net:GenPackage("ReqQuerySouler", {})
  LoliCore.Net:PushPackage(self.SaNetId, Pack)
end

function Login:ReqCreateSouler()
  local Pack = LoliCore.Net:GenPackage("ReqCreateSouler", {})
  Pack.SoulerInfo =
  {
    Name = "Fuck", --不能免俗的名字
    Sex = 1, --不能免俗的性別Id
    Job = 1, --不能免俗的職業Id
    AreaId = 2003, --所屬於的AreaId
  }
  LoliCore.Net:PushPackage(self.SaNetId, Pack)
end

function Login:ReqDestroySouler()
  local Pack = LoliCore.Net:GenPackage("ReqDestroySouler", {})
  Pack.SoulerId = 1988
  LoliCore.Net:PushPackage(self.SaNetId, Pack)
end

function Login:ReqSelectSouler()
  local Pack = LoliCore.Net:GenPackage("ReqSelectSouler", {})
  Pack.SoulerId = 1987
  LoliCore.Net:PushPackage(self.SaNetId, Pack)
end

function Login:ReqArrival()
  local Pack = LoliCore.Net:GenPackage("ReqArrival", {})
  LoliCore.Net:PushPackage(self.SaNetId, Pack)
end

function Login:ReqDeparture()
  local Pack = LoliCore.Net:GenPackage("ReqDeparture", {})
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
    ResQueryArea = self.ResQueryArea,
    ResQuerySouler = self.ResQuerySouler,
    ResCreateSouler = self.ResCreateSouler,
    ResDestroySouler = self.ResDestroySouler,
    ResSelectSouler = self.ResSelectSouler,
    ResArrival = self.ResArrival,
    ResDeparture = self.ResDeparture,
  }
end
