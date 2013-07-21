--
-- God PersonRepos
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/07/21 11:52:14
--


local PersonRepos = LoliSrvGod.PersonRepos

function PersonRepos:Init()
end

function PersonRepos:GetSoulerList(PersonId)
  print("GetSoulerList")
  return {}
end

function PersonRepos:CreateSouler(PersonId, SoulerInfo)
  print("CreateSouler")
  return 1
end

function PersonRepos:DestroySouler(PersonId, SoulerId)
  print("DestroySouler")
  return SoulerId
end

function PersonRepos:SelectSouler(PersonId, SoulerId)
  print("SelectSouler")
  return SoulerId
end
