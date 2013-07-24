--
-- Area's Souler Repository
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/07/23 18:44:25

local SoulerRepos = LoliSrvArea.SoulerRepos

function SoulerRepos:Init()
  self.Id2Souler = {}
end

function SoulerRepos:New(Id, SoulerFile)
  assert(not self.Id2Souler[Id])
  local Souler =
  {
    File = SoulerFile,
    Id = SoulerFile.Id,
  }
  self.Id2Souler[Souler.Id] = Souler
  return Souler
end

function SoulerRepos:Delete(Id)
  local Souler = assert(self.Id2Souler[Id])
  self.Id2Souler[Id] = nil
  return Souler
end

function SoulerRepos:GetById(Id)
  return self.Id2Souler[Id]
end
