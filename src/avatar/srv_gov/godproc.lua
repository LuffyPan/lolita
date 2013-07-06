--
-- Gov's GodProc
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/07/06 12:42:23
--

LoliSrvGoverment.GodProc = {}
local GodProc = LoliSrvGoverment.GodProc

function GodProc:Init()
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
    Key = "20010928",
    Extra =
    {
      GovIp = "127.0.0.1",
      GovPort = 7400,
    },
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