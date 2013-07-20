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
  print("Person Connected", NetId)
  local Person = assert(PersonRepos:New(NetId))
  print(string.format("Person NetId[%u], Id[%s], SoulerId[%s]", Person.NetId, Person.Id, Person.SoulerId))
end

function PersonProc:OnClose(NetId)
  print("Person DisConnected", NetId)
  local Person = assert(PersonRepos:Delete(NetId))
  print(string.format("Person NetId[%u], Id[%s], SoulerId[%s]", Person.NetId, Person.Id, Person.SoulerId))
end

function PersonProc:ReqRegister(NetId, Pack)
  local Person = assert(PersonRepos:GetByNetId(NetId))
  print(string.format("Person NetId[%u], Id[%s], SoulerId[%s] Request Register", Person.NetId, Person.Id, Person.SoulerId))
  Pack.PersonNetId = Person.NetId
  assert(GodProc:PushPackage(Pack))
end

function PersonProc:ReqAuth(NetId, Pack)
  local Person = assert(PersonRepos:GetByNetId(NetId))
  print(string.format("Person NetId[%u], Id[%s], SoulerId[%s] Request Auth", Person.NetId, Person.Id, Person.SoulerId))
  if Person.Id > 0 then
    Pack.Result = 0
    Pack.ErrorCode = 1
    assert(LoliCore.Net:PushPackage(Person.NetId, Pack))
    return
  end
  Pack.PersonNetId = Person.NetId
  assert(GodProc:PushPackage(Pack))
end

function PersonProc:ReqQuerySouler(NetId, Pack)
  print("Person Request QuerySouler")
end

function PersonProc:ReqCreateSouler(NetId, Pack)
  print("Person Request CreateSouler")
end

function PersonProc:ReqDestroySouler(NetId, Pack)
  print("Person Request DestroySouler")
end

function PersonProc:ReqSelectSouler(NetId, Pack)
  print("Person Request SelectSouler")
end

function PersonProc:ReqArrival(NetId, Pack)
  print("Person Request Arrival")
end

function PersonProc:ReqDeparture(NetId, Pack)
  print("Person Request Departure")
end

function PersonProc:_GetProcs()
  return
  {
    Param = self,
    Accept = self.OnAccept,
    Close = self.OnClose,
    --Login
    ReqRegister = self.ReqRegister,
    ReqAuth = self.ReqAuth,
    --God
    ReqQuerySouler = self.ReqQuerySouler,
    ReqCreateSouler = self.ReqCreateSouler,
    ReqDestroySouler = self.ReqDestroySouler,
    ReqSelectSouler = self.ReqSelectSouler,
    --Area
    ReqArrival = self.ReqArrival,
    ReqDeparture = self.ReqDeparture,
  }
end
