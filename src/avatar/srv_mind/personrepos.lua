--
-- Mind's PersonRepos 
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/07/07 22:24:03
--

local PersonRepos = LoliSrvMind.PersonRepos

function PersonRepos:Init()
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
  self._SoulerId2Person[Person.SoulerId] = nil
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

function PersonRepos:GetByNetId(NetId)
  return self._NetId2Person[NetId]
end

function PersonRepos:GetBySoulerId(SoulerId)
  return self._SoulerId2Person[SoulerId]
end
