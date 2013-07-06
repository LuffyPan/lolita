--
-- Test God, God Server test about
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/07/04 11:56:52
--

local Executor = assert(LoliSrvTest.Executor)
local God = assert(LoliSrvTest.God)

function God:Init()
  Executor:AttachTarget("god", God)
end

function God:Execute()
  self:Connect()
end

function God:Connect()
  local ConnectParam = {}
  ConnectParam.Procs = self:_GetProcs()
  --ConnectParam.EventFuncs = self:_GetEventFuncs()
  --ConnectParam.SendBack = 1
  self.GodNetId = assert(LoliCore.Net:ConnectEx("127.0.0.1", 7700, ConnectParam))
end

function God:ReqSrvLogin()
  local Pack =
  {
    ProcId = "RequestSrvLogin",
    Key = "19870805",
    Extra =
    {
      SaIp = "127.0.0.1",
      SaPort = 7000,
    },
  }
  LoliCore.Net:PushPackage(self.GodNetId, Pack)
end

function God:ReqSrvLogout()
  local Pack =
  {
    ProcId = "RequestSrvLogout",
  }
  LoliCore.Net:PushPackage(self.GodNetId, Pack)
end

function God:ReqQuerySouler()
  local Pack =
  {
    ProcId = "RequestQuerySouler",
    SoulId = 1,
  }
  LoliCore.Net:PushPackage(self.GodNetId, Pack)
end

function God:ReqCreateSouler()
  local Pack =
  {
    ProcId = "RequestCreateSouler",
    SoulId = 1,
    SoulInfo = 
    {
      Sex = 1,
      Job = 110,
      Name = "Chamz",
      GovId = 1,
    },
  }
  LoliCore.Net:PushPackage(self.GodNetId, Pack)
end

function God:ReqDestroySouler()
  local Pack =
  {
    ProcId = "RequestDestroySouler",
    SoulId = 1,
  }
  LoliCore.Net:PushPackage(self.GodNetId, Pack)
end

function God:ReqSelectSouler()
  local Pack =
  {
    ProcId = "RequestSelectSouler",
    SoulId = 1,
  }
  LoliCore.Net:PushPackage(self.GodNetId, Pack)
end

function God:ReqSetEx()
  local Pack =
  {
    ProcId = "RequestSetEx",
    SoulId = 1,
    Conds =
    {
      xixi = 0,
      haha = 0,
      hehe = 0,
    },
    Values =
    {
      xixi = 1,
      haha = 2,
      hehe = 3,
    },
  }
  LoliCore.Net:PushPackage(self.GodNetId, Pack)
end

function God:ReqGetEx()
  local Pack =
  {
    ProcId = "RequestGetEx",
    SoulId = 1,
    Conds =
    {
      xixi = 0,
      haha = 0,
      hehe = 0,
    },
  }
  LoliCore.Net:PushPackage(self.GodNetId, Pack)
end

function God:ResSrvLogin(NetId, Pack)
  LoliCore.Imagination:Begin(16, self.ReqQuerySouler, self)
end

function God:ResSrvLogout(NetId, Pack)
  print("All Steps Is Finished!!")
  LoliCore.Avatar:Detach()
end

function God:ResQuerySouler(NetId, Pack)
  LoliCore.Imagination:Begin(16, self.ReqCreateSouler, self)
end

function God:ResCreateSouler(NetId, Pack)
  LoliCore.Imagination:Begin(16, self.ReqDestroySouler, self)
end

function God:ResDestroySouler(NetId, Pack)
  LoliCore.Imagination:Begin(16, self.ReqSelectSouler, self)
end

function God:ResSelectSouler(NetId, Pack)
  LoliCore.Imagination:Begin(16, self.ReqSetEx, self)
end

function God:ResSetEx(NetId, Pack)
  LoliCore.Imagination:Begin(16, self.ReqGetEx, self)
end

function God:ResGetEx(NetId, Pack)
  LoliCore.Imagination:Begin(16, self.ReqSrvLogout, self)
end

function God:OnNetConnect(NetId, Result)
  if Result == 1 then
    LoliCore.Imagination:Begin(16, self.ReqSrvLogin, self)
  else
    print("Connect To God Is Failed!!")
  end
end

function God:OnNetClose(NetId)
  print("Steps Is Unfinished By God Closed!!")
  LoliCore.Avatar:Detach()
end

function God:OnNetPackage(NetId, Pack)
  print("Package Come From God")
end

function God:_GetEventFuncs()
  return
  {
    Param = self,
    Connect = self.OnNetConnect,
    Package = self.OnNetPackage,
    Close = self.OnNetClose,
  }
end

function God:_GetProcs()
  return
  {
    Param = self,
    Connect = self.OnNetConnect,
    Close = self.OnNetClose,
    RequestSrvLogin = self.ResSrvLogin,
    RequestSrvLogout = self.ResSrvLogout,
    RequestQuerySouler = self.ResQuerySouler,
    RequestCreateSouler = self.ResCreateSouler,
    RequestDestroySouler = self.ResDestroySouler,
    RequestSelectSouler = self.ResSelectSouler,
    RequestSetEx = self.ResSetEx,
    RequestGetEx = self.ResGetEx,
  }
end
