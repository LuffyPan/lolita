--
-- Lolita Server God Main
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/05/06 21:42:50
--

local Base = LoliSrvGod.Base
local SrvRepos = LoliSrvGod.SrvRepos
local Proc = LoliSrvGod.Proc
local PersonRepos = LoliSrvGod.PersonRepos

function LoliSrvGod:OnBorn()
  print("OnBorn")
  Base:Init()
  SrvRepos:Init()
  PersonRepos:Init()
  Proc:Init()
  SrvRepos:Dump()
  Base:Logo()
end

function LoliSrvGod:OnDie()
  print("OnDie")
  debug.debug()
end

LoliCore.Avatar:Attach(LoliSrvGod)
