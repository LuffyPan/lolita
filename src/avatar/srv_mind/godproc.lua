--
-- Mind's GodProc
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/07/06 13:03:09
--

local GodProc = LoliSrvMind.GodProc
local PersonProc = LoliSrvMind.PersonProc
local PersonRepos = LoliSrvMind.PersonRepos

function GodProc:Init()
  local ConnectExParam = {}
  ConnectExParam.Procs = self:_GetProcs()
  self.NetId = LoliCore.Net:ConnectEx("127.0.0.1", 7700, ConnectExParam)
end

function GodProc:PushPackage(Pack)
  return LoliCore.Net:PushPackage(self.NetId, Pack)
end

function GodProc:OnConnect(NetId, Result)
  if Result == 0 then
    print("Connect To God Is Failed, Don't Request SrvLogin")
    return
  end
  local Pack = LoliCore.Net:GenPackage("ReqSrvLogin", {Key = "20000901", Extra = {}})
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
end

function GodProc:ResRegister(NetId, Pack)
  print(string.format("Person NetId[%s] Register Result[%s], ErrorCode[%s]", Pack.PersonNetId, Pack.Result, Pack.ErrorCode))
  local Person = PersonRepos:GetByNetId(Pack.PersonNetId)
  if not Person then
    --Person Already Disconnect
    return
  end
  assert(PersonProc:PushPackage(Person.NetId, Pack))
end

function GodProc:ResAuth(NetId, Pack)
  print(string.format("Person NetId[%s] Auth Result[%s], ErrorCode[%s]", Pack.PersonNetId, Pack.Result, Pack.ErrorCode))
  local Person = PersonRepos:GetByNetId(Pack.PersonNetId)
  if not Person then
    return
  end
  if Person.Id > 0 then
    Pack.Result = 0
    Pack.ErrorCode = 0 --Person Already Authed!
    assert(PersonProc:PushPackage(Person.NetId, Pack))
    return
  end
  if Pack.Result == 1 then
    Person.Id = assert(Pack.PersonId)
  end
  print(string.format("Person NId[%d], PId[%d], SId[%d]", Person.NetId, Person.Id, Person.SoulerId))
  assert(PersonProc:PushPackage(Person.NetId, Pack))
end

function GodProc:_GetProcs()
  return
  {
    Param = self,
    Connect = self.OnConnect,
    Close = self.OnClose,
    ResSrvLogin = self.ResSrvLogin,
    ResSrvLogout = self.ResSrvLogout,
    --Login
    ResRegister = self.ResRegister,
    ResAuth = self.ResAuth,
  }
end
