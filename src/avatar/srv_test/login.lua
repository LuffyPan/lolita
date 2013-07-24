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
  self.NetIds = {}
  self.NetIdCount = 0
  local ConnectExParam = {}
  ConnectExParam.Procs = self:_GetProcs()
  for i = 1, 10 do
    local NetId = assert(LoliCore.Net:ConnectEx("127.0.0.1", 7000, ConnectExParam))
    self.NetIds[NetId] = 1
    self.NetIdCount = self.NetIdCount + 1
  end
  self.AuthCount = 0
  self.CreateSoulerCount = 0
end

function Login:OnConnect(NetId, Result)
  if Result == 1 then
    LoliCore.Imagination:Begin(16, self.ReqRegister, self, NetId)
  else
    print("Connect Failed")
  end
end

function Login:OnClose(NetId)
  print("Closed By Mind Server")
  self.NetIds[NetId] = nil
  self.NetIdCount = self.NetIdCount - 1
  if self.NetIdCount == 0 then
    LoliCore.Avatar:Detach()
  end
end

function Login:ResRegister(NetId, Pack)
  LoliCore.Imagination:Begin(16, self.ReqAuth, self, NetId)
end

function Login:ResAuth(NetId, Pack)
  self.AuthCount = self.AuthCount + 1
  if self.AuthCount >= 2 then
    --print("Finished!!")
    --LoliCore.Avatar:Detach()
    LoliCore.Imagination:Begin(16, self.ReqQueryArea, self, NetId)
    return
  end
  LoliCore.Imagination:Begin(16, self.ReqAuth, self, NetId)
end

function Login:ResQueryArea(NetId, Pack)
  if Pack.Result == 1 then
    print("The Areas Oooof The World:")
    for _, Area in ipairs(Pack.AreaList) do
      print(string.format("Id[%s], Name[%s], Available[%s]", Area.Id, "Unknown", Area.Available))
    end
  end
  LoliCore.Imagination:Begin(16, self.ReqCreateSouler, self, NetId)
end

function Login:ResCreateSouler(NetId, Pack)
  if Pack.Result == 1 then
    print("CreateSouler Finished!")
  end
  self.CreateSoulerCount = self.CreateSoulerCount + 1
  if self.CreateSoulerCount >=3 then
    LoliCore.Imagination:Begin(16, self.ReqQuerySouler, self, NetId)
    return
  end
  LoliCore.Imagination:Begin(16, self.ReqCreateSouler, self, NetId)
end

function Login:ResQuerySouler(NetId, Pack)
  if Pack.Result == 1 then
    print("QuerySouler Finished!")
  end
  local SoulerId = 0
  for k, v in pairs(Pack.Soulers) do
    SoulerId = k
    print(string.format("Souler ----- %s", SoulerId))
  end
  LoliCore.Imagination:Begin(16, self.ReqSelectSouler, self, {NetId = NetId, SoulerId = SoulerId})
end

function Login:ResDestroySouler(NetId, Pack)
  if Pack.Result == 1 then
    print("DestroySouler Finished!")
  end
  LoliCore.Imagination:Begin(16, self.ReqSelectSouler, self, NetId)
end

function Login:ResSelectSouler(NetId, Pack)
  if Pack.Result == 1 then
    print("SelectSouler Finished!")
  end
  LoliCore.Imagination:Begin(16, self.ReqArrival, self, NetId)
end

function Login:ResArrival(NetId, Pack)
  LoliCore.Imagination:Begin(16, self.ReqDeparture, self, NetId)
end

function Login:ResDeparture(NetId, Pack)
  LoliCore.Net:Close(NetId)
end

function Login:ReqRegister(Im)
  local NetId = Im.UserParam
  local Pack = LoliCore.Net:GenPackage("ReqRegister", {Account = string.format("LoliAccount_%s", NetId), Password = "LoliPassword", Age = 19})
  LoliCore.Net:PushPackage(NetId, Pack)
end

function Login:ReqAuth(Im)
  local NetId = Im.UserParam
  local Pack = LoliCore.Net:GenPackage("ReqAuth", {Account = string.format("LoliAccount_%s", NetId), Password = "LoliPassword"})
  LoliCore.Net:PushPackage(NetId, Pack)
end

function Login:ReqQueryArea(Im)
  local NetId = Im.UserParam
  local Pack = LoliCore.Net:GenPackage("ReqQueryArea", {})
  LoliCore.Net:PushPackage(NetId, Pack)
end

function Login:ReqQuerySouler(Im)
  local NetId = Im.UserParam
  local Pack = LoliCore.Net:GenPackage("ReqQuerySouler", {})
  LoliCore.Net:PushPackage(NetId, Pack)
end

function Login:ReqCreateSouler(Im)
  local NetId = Im.UserParam
  local Pack = LoliCore.Net:GenPackage("ReqCreateSouler", {})
  Pack.SoulerInfo =
  {
    Name = string.format("Fuck_%s", NetId), --不能免俗的名字
    Sex = 1, --不能免俗的性別Id
    Job = 1, --不能免俗的職業Id
    AreaId = 2003, --所屬於的AreaId
  }
  LoliCore.Net:PushPackage(NetId, Pack)
end

function Login:ReqDestroySouler(Im)
  local NetId = Im.UserParam
  local Pack = LoliCore.Net:GenPackage("ReqDestroySouler", {})
  Pack.SoulerId = 1988
  LoliCore.Net:PushPackage(NetId, Pack)
end

function Login:ReqSelectSouler(Im)
  local NetId = Im.UserParam.NetId
  local SoulerId = Im.UserParam.SoulerId
  local Pack = LoliCore.Net:GenPackage("ReqSelectSouler", {})
  Pack.SoulerId = SoulerId
  LoliCore.Net:PushPackage(NetId, Pack)
end

function Login:ReqArrival(Im)
  local NetId = Im.UserParam
  local Pack = LoliCore.Net:GenPackage("ReqArrival", {})
  LoliCore.Net:PushPackage(NetId, Pack)
end

function Login:ReqDeparture(Im)
  local NetId = Im.UserParam
  local Pack = LoliCore.Net:GenPackage("ReqDeparture", {})
  LoliCore.Net:PushPackage(NetId, Pack)
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
