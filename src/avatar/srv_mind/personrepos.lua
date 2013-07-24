--
-- Mind's PersonRepos 
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/07/07 22:24:03
--

local PersonRepos = LoliSrvMind.PersonRepos

function PersonRepos:Init()
  self._Id2Person = {}
  self._NetId2Person = {}
  self._SoulerId2Person = {}
end

function PersonRepos:New(NetId)
  assert(not self._NetId2Person[NetId])
  local Person = {NetId = NetId, Id = 0, SoulerId = 0}
  self._NetId2Person[NetId] = Person
  return Person
end

function PersonRepos:Delete(NetId)
  local Person = assert(self._NetId2Person[NetId])
  assert(Person.NetId == NetId)
  if Person.SoulerId > 0 then
    self._SoulerId2Person[Person.SoulerId] = nil
  end
  if Person.Id > 0 then
    self._Id2Person[Person.Id] = nil
  end
  self._NetId2Person[Person.NetId] = nil
  return Person
end

function PersonRepos:AttachSoulerId(NetId, SoulerId)
  local Person = assert(self._NetId2Person[NetId])
  assert(Person.SoulerId == 0)
  Person.SoulerId = SoulerId
  assert(not self._SoulerId2Person[SoulerId])
  self._SoulerId2Person[SoulerId] = Person 
  return Person
end

function PersonRepos:AttachId(NetId, Id)
  local Person = assert(self._NetId2Person[NetId])
  assert(Person.Id == 0)
  Person.Id = Id
  assert(not self._Id2Person[Id])
  self._Id2Person[Id] = Person
  return Person
end

function PersonRepos:DetachSoulerId(NetId)
  local Person = assert(self._NetId2Person[NetId])
  if Person.SoulerId > 0 then
    assert(self._SoulerId2Person[Person.SoulerId])
    self._SoulerId2Person[Person.SoulerId] = nil
    Person.SoulerId = 0
  end
  return Person
end

function PersonRepos:DetachId(NetId)
  local Person = assert(self._NetId2Person[NetId])
  if Person.Id > 0 then
    assert(self._Id2Person[Person.Id])
    self._Id2Person[Person.Id] = nil
    Person.Id = 0
  end
  return Person
end

function PersonRepos:GetByNetId(NetId)
  return self._NetId2Person[NetId]
end

function PersonRepos:GetById(Id)
  return self._Id2Person[Id]
end

function PersonRepos:GetBySoulerId(SoulerId)
  return self._SoulerId2Person[SoulerId]
end
