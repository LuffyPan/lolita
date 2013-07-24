--
-- Area's GodProc
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/07/05 19:42:52
--

local GodProc = LoliSrvArea.GodProc
local SoulerRepos = LoliSrvArea.SoulerRepos

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
  local Souler = SoulerRepos:New(Pack.Souler.Id, Pack.Souler)
  Pack.Souler = nil
  print(string.format("Welcome To The Area[%s], %s", "Unknown", Souler.File.Name))
  print(string.format("Sex[%s], Job[%s], Level[%s], AreaId[%s], CurrentAreaId[%s]", Souler.File.Sex, Souler.File.Job, Souler.File.Level, Souler.File.AreaId, Souler.File.CurrentAreaId))
  LoliCore.Net:PushPackage(self.NetId, Pack)
end

function GodProc:ReqDeparture(NetId, Pack)
  Pack.ProcId = "ResDeparture"
  Pack.Result = 1
  local Souler = SoulerRepos:GetById(Pack.PersonSoulerId)
  if Souler then
    local Souler = SoulerRepos:Delete(Pack.PersonSoulerId)
    print("Souler Departured!")
  else
    print(string.format("Souler Is Not Arrival Already!"))
  end
  LoliCore.Net:PushPackage(self.NetId, Pack)
end

function GodProc:PreProc(NetId, Pack)
  local Souler = SoulerRepos:GetById(Pack.PersonSoulerId)
  if Souler then
    print(string.format("Souler[%s], %s", Souler.Id, Pack.ProcId))
    return Souler
  else
    if Pack.ProcId == "ReqDeparture" or Pack.ProcId == "ReqArrival" then
      return 1
    end
    print(string.format("Souler[%s] Invalid, %s!!", Pack.PersonSoulerId, Pack.ProcId))
    return
  end
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

