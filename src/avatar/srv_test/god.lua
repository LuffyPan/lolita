--
-- Test God, God Server test about
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/07/04 11:56:52
--

local Executor = assert(LoliSrvTest.Executor)
local God = assert(LoliSrvTest.God)

function God:Init()
  self:_SetProcs()
  Executor:AttachTarget("god", God)
end

function God:Execute()
  print("God Execute")
  self:Connect()
end

function God:Connect()
  self.Id = assert(LoliCore.Net:Connect("127.0.0.1", 7700, self:_GetEventFuncs()))
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
  LoliCore.Net:PushPackage(self.Id, Pack)
end

function God:ReqSrvLogout()
  local Pack =
  {
    ProcId = "RequestSrvLogout",
  }
  LoliCore.Net:PushPackage(self.Id, Pack)
end

function God:ReqQuerySouler()
  local Pack =
  {
    ProcId = "RequestQuerySouler",
    SoulId = 1,
  }
  LoliCore.Net:PushPackage(self.Id, Pack)
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
  LoliCore.Net:PushPackage(self.Id, Pack)
end

function God:ReqDestroySouler()
  local Pack =
  {
    ProcId = "RequestDestroySouler",
    SoulId = 1,
  }
  LoliCore.Net:PushPackage(self.Id, Pack)
end

function God:ReqSelectSouler()
  local Pack =
  {
    ProcId = "RequestSelectSouler",
    SoulId = 1,
  }
  LoliCore.Net:PushPackage(self.Id, Pack)
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
  LoliCore.Net:PushPackage(self.Id, Pack)
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
  LoliCore.Net:PushPackage(self.Id, Pack)
end

function God:ResSrvLogin(Pack)
  LoliCore.Imagination:Begin(16, self.ReqQuerySouler, self)
end

function God:ResSrvLogout(Pack)
  print("All Steps Is Finished!!")
  LoliCore.Avatar:Detach()
end

function God:ResQuerySouler(Pack)
  LoliCore.Imagination:Begin(16, self.ReqCreateSouler, self)
end

function God:ResCreateSouler(Pack)
  LoliCore.Imagination:Begin(16, self.ReqDestroySouler, self)
end

function God:ResDestroySouler(Pack)
  LoliCore.Imagination:Begin(16, self.ReqSelectSouler, self)
end

function God:ResSelectSouler(Pack)
  LoliCore.Imagination:Begin(16, self.ReqSetEx, self)
end

function God:ResSetEx(Pack)
  LoliCore.Imagination:Begin(16, self.ReqGetEx, self)
end

function God:ResGetEx(Pack)
  LoliCore.Imagination:Begin(16, self.ReqSrvLogout, self)
end

function God:OnNetConnect(NetId, Result)
  if Result == 1 then
    LoliCore.Imagination:Begin(16, self.ReqSrvLogin, self)
  end
end

function God:OnNetPackage(NetId, Pack)
  assert(NetId == self.Id)
  local Proc = assert(self.Proc[Pack.ProcId])
  Proc(self, Pack)
end

function God:OnNetClose(NetId)
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

function God:_SetProcs()
  self.Proc =
  {
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
