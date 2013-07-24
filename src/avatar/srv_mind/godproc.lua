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

function GodProc:ResRegister(NetId, Pack, Person)
  assert(PersonProc:PushPackage(Person.NetId, Pack))
end

function GodProc:ResAuth(NetId, Pack, Person)
  if Person.Id > 0 then
    print("Auth Failed, Already Authed!")
    Pack.Result = 0
    Pack.ErrorCode = 0 --Person Already Authed!
    assert(PersonProc:PushPackage(Person.NetId, Pack))
    return
  end
  if Pack.Result == 1 then
    PersonRepos:AttachId(Person.NetId, Pack.AuthPersonId)
    print(string.format("Auth Succeed With Id[%s]!", Person.Id))
  end
  assert(PersonProc:PushPackage(Person.NetId, Pack))
end

function GodProc:ResQuerySouler(NetId, Pack, Person)
  assert(PersonProc:PushPackage(Person.NetId, Pack))
end

function GodProc:ResCreateSouler(NetId, Pack, Person)
  assert(PersonProc:PushPackage(Person.NetId, Pack))
end

function GodProc:ResDestroySouler(NetId, Pack, Person)
  assert(PersonProc:PushPackage(Person.NetId, Pack))
end

function GodProc:ResSelectSouler(NetId, Pack, Person)
  if Pack.Result == 1 then
    PersonRepos:AttachSoulerId(Person.NetId, Pack.SelectSoulerId)
    print(string.format("Attach Net[%s] With Souler[%s]", Person.NetId, Person.SoulerId))
  end
  assert(PersonProc:PushPackage(Person.NetId, Pack))
end

function GodProc:ResQueryArea(NetId, Pack, Person)
  assert(PersonProc:PushPackage(Person.NetId, Pack))
end

function GodProc:ResArrival(NetId, Pack, Person)
  assert(PersonProc:PushPackage(Person.NetId, Pack))
end

function GodProc:ResDeparture(NetId, Pack, Person)
  if Person.Lost then
    PersonRepos:Delete(Person.NetId)
  else
    assert(PersonProc:PushPackage(Person.NetId, Pack))
    PersonRepos:DetachSoulerId(Person.NetId)
    PersonRepos:DetachId(Person.NetId)
  end
end

function GodProc:PreProc(NetId, Pack)
  local Person
  if (not Person) and Pack.PersonSoulerId then
    Person = PersonRepos:GetBySoulerId(Pack.PersonSoulerId)
  end
  if (not Person) and Pack.PersonId then
    Person = PersonRepos:GetById(Pack.PersonId)
  end
  if (not Person) and Pack.PersonNetId then
    Person = PersonRepos:GetByNetId(Pack.PersonNetId)
  end
  if not Person then
    --可以通过返回值告诉底层，不进行后续调用
    print(string.format("Net[%s], Attached Person Already Disconnected Before This Time!", Pack.PersonNetId))
    return
  end
  print(string.format("Person[%s,%s,%s], %s, RAE[%s,%s]", Person.NetId, Person.Id, Person.SoulerId, Pack.ProcId, Pack.Result, Pack.ErrorCode))
  return Person
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
    --Login
    ResRegister = self.ResRegister,
    ResAuth = self.ResAuth,
    --God
    ResQueryArea = self.ResQueryArea,
    ResQuerySouler = self.ResQuerySouler,
    ResCreateSouler = self.ResCreateSouler,
    ResDestroySouler = self.ResDestroySouler,
    ResSelectSouler = self.ResSelectSouler,
    --Area
    ResArrival = self.ResArrival,
    ResDeparture = self.ResDeparture,
  }
end
