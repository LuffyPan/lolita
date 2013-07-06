--
-- Area's GodProc
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/07/05 19:42:52
--

LoliSrvArea = {}
LoliSrvArea.GodProc = {}
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
  local Pack =
  {
    ProcId = "RequestSrvLogin",
    Key = "20030901",
    Extra = {},
  }
  LoliCore.Net:PushPackage(self.NetId, Pack)
end

function GodProc:OnClose(NetId)
  print("Connection To God Is Disconnect")
end

function GodProc:ResSrvLogin(NetId, Pack)
  print(string.format("Login To God, Result : %s", Pack.Result))
end

function GodProc:ResSrvLogout(NetId, Pack)
  --暂时不触发
end

function GodProc:_GetProcs()
  return
  {
    Param = self,
    Connect = self.OnConnect,
    Close = self.OnClose,
    RequestSrvLogin = self.ResSrvLogin,
    RequestSrvLogout = self.ResSrvLogout,
  }
end

