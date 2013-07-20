--
-- Lolita Server Mind
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/04/23 15:13:53
--

local Base = LoliSrvMind.Base
local PersonRepos = LoliSrvMind.PersonRepos
local PersonProc = LoliSrvMind.PersonProc
local GodProc = LoliSrvMind.GodProc

function LoliSrvMind:OnBorn()
  Base:Init()
  PersonRepos:Init()
  PersonProc:Init()
  GodProc:Init()
  Base:Logo()
end

function LoliSrvMind:OnDie()
end

LoliCore.Avatar:Attach(LoliSrvMind)
