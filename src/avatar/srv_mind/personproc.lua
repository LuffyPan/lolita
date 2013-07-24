--
-- Mind's PersonProc 
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/07/07 20:32:21
--

local PersonRepos = LoliSrvMind.PersonRepos
local PersonProc = LoliSrvMind.PersonProc
local GodProc = LoliSrvMind.GodProc

function PersonProc:Init()
  local Ip = "127.0.0.1"
  local Port = 7000
  local ListenExParam = {}
  ListenExParam.Procs = self:_GetProcs()
  self.NetId = LoliCore.Net:ListenEx(Ip, Port, ListenExParam)
  if not self.NetId then
    print(string.format("Listen Ip[%s], Port[%s] Failed", Ip, Port))
    LoliCore.Avatar:Detach()
  end
end

function PersonProc:PushPackage(NetId, Pack)
  return LoliCore.Net:PushPackage(NetId, Pack)
end

function PersonProc:OnAccept(NetId)
  local Person = assert(PersonRepos:New(NetId))
  print(string.format("Person[%s,%s,%s], Connected!", Person.NetId, Person.Id, Person.SoulerId))
end

function PersonProc:OnClose(NetId)
  local Person = assert(PersonRepos:GetByNetId(NetId))
  print(string.format("Person[%s,%s,%s], Disconnected!", Person.NetId, Person.Id, Person.SoulerId))
  if Person.Id > 0 then
    Person.Lost = 1
    print("Already Authed, ReqDeparture!")
    local Pack = LoliCore.Net:GenPackage("ReqDeparture", {Type="Lost"})
    Pack.PersonId = Person.Id
    assert(GodProc:PushPackage(Pack))
  else
    assert(PersonRepos:Delete(Person.NetId))
    print("Delete Person Completely!")
  end
end

function PersonProc:ReqGodTransmitWithNetId(NetId, Pack, Person)
  Pack.PersonNetId = Person.NetId
  assert(GodProc:PushPackage(Pack))
end

function PersonProc:ReqGodTransmitWithId(NetId, Pack, Person)
  if Person.Id == 0 then
    print("Not Authed!!")
    return
  end
  Pack.PersonNetId = Person.NetId
  Pack.PersonId = Person.Id
  assert(GodProc:PushPackage(Pack))
end

function PersonProc:ReqGodTransmitWithSoulerId(NetId, Pack, Person)
  if Person.SoulerId == 0 then
    print("Not Selected!")
    return
  end
  Pack.PersonSoulerId = Person.SoulerId
  assert(GodProc:PushPackage(Pack))
end

function PersonProc:PreProc(NetId, Pack)
  local Person = assert(PersonRepos:GetByNetId(NetId))
  print(string.format("Person[%s,%s,%s], %s", Person.NetId, Person.Id, Person.SoulerId, Pack.ProcId))
  return Person
end

function PersonProc:_GetProcs()
  return
  {
    Param = self,
    Pre = self.PreProc,
    Accept = self.OnAccept,
    Close = self.OnClose,
    --Login
    ReqRegister = self.ReqGodTransmitWithNetId,
    ReqAuth = self.ReqGodTransmitWithNetId,
    --God
    ReqQueryArea = self.ReqGodTransmitWithId,
    ReqQuerySouler = self.ReqGodTransmitWithId,
    ReqCreateSouler = self.ReqGodTransmitWithId,
    ReqDestroySouler = self.ReqGodTransmitWithId,
    ReqSelectSouler = self.ReqGodTransmitWithId,
    --Area
    ReqArrival = self.ReqGodTransmitWithSoulerId,
    ReqDeparture = self.ReqGodTransmitWithId,
  }
end
