--
-- Area's GodProc
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/07/05 19:42:52
--

local GodProc = LoliSrvArea.GodProc

function GodProc:Init()
  --通过配置表读取God的信息
  local ConnectExParam = {}
  ConnectExParam.Procs = self:_GetProcs()
  self.NetId = LoliCore.Net:ConnectEx("127.0.0.1", 7700, ConnectExParam)
end

function GodProc:OnConnect(NetId, Result)
  if Result == 0 then
    print("Connect To God Is Failed, Don't Request SrvLogin")
    return
  end
  local Pack = LoliCore.Net:GenPackage("ReqSrvLogin", {Key = "20030901", Extra = {}})
  LoliCore.Net:PushPackage(self.NetId, Pack)
end

function GodProc:OnClose(NetId)
  print("Connection To God Is Disconnect")
end

function GodProc:ResSrvLogin(NetId, Pack)
  print(string.format("Login To God, Result : %s", Pack.Result))
  if Pack.Result == 1 then
    print(string.format("SrvId[%s], Type[%s]", Pack.Basic.Id, Pack.Basic.Type))
  end
end

function GodProc:ResSrvLogout(NetId, Pack)
  --暂时不触发
end

function GodProc:ReqArrival(NetId, Pack)
  Pack.ProcId = "ResArrival"
  Pack.Result = 1
  local Souler = Pack.Souler
  Pack.Souler = nil
  print(string.format("Welcome To The Area[%s], %s", "Unknown", Souler.Name))
  print(string.format("Sex[%s], Job[%s], Level[%s], AreaId[%s], CurrentAreaId[%s]", Souler.Sex, Souler.Job, Souler.Level, Souler.AreaId, Souler.CurrentAreaId))
  LoliCore.Net:PushPackage(self.NetId, Pack)
end

function GodProc:ReqDeparture(NetId, Pack)
  Pack.ProcId = "ResDeparture"
  Pack.Result = 1
  LoliCore.Net:PushPackage(self.NetId, Pack)
end

function GodProc:PreProc(NetId, Pack)
  print(string.format("NetId[%s], %s", NetId, Pack.ProcId))
  return 1
end

function GodProc:_GetProcs()
  return
  {
    Param = self,
    Pre = self.PreProc,
    Connect = self.OnConnect,
    Close = self.OnClose,
    ResSrvLogin = self.ResSrvLogin,
    ResSrvLogout = self.ResSrvLogout,
    ReqArrival = self.ReqArrival,
    ReqDeparture = self.ReqDeparture,
  }
end

