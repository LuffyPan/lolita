--
-- LoliCore Configuration Extend
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/06/14 11:18:12
-- The times fly!!!!
--

LoliCore.Config = {}

local Config = LoliCore.Config
local Io = LoliCore.Io

function Config:Extend()
  self.ConfigRepos = {}
  self.ConfigPath = "./"
  local N = LoliCore.Arg:Get("conf")
  if N then self:Load(N) end
end

function Config:Load(FileName)
  local F = Io:LoadFile(FileName)
  assert(F and F.Name)
  assert(not self.ConfigRepos[F.Name])
  self.ConfigRepos[F.Name] = F
end

function Config:Get(Name)
  return self.ConfigRepos[Name] or {}
end

Config:Extend()
print("LoliCore.Config Extended")
