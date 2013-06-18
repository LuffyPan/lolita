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
  self.Default = nil
  self.UserDefine = nil
  self.ConfigPath = "./"
  local N = LoliCore.Arg:Get("conf")
  if N then self:SetUserDefine(N) end
end

function Config:SetUserDefine(FileName)
  local F, E = Io:LoadFile(FileName)
  assert(F, E)
  assert(not self.UserDefine)
  self.UserDefine = F
  return 1
end

function Config:SetDefault(C)
  assert(not self.Default)
  self.Default = C
  return 1
end

function Config:GetDefault()
  return assert(self.Default)
end

function Config:GetUserDefine()
  return self.UserDefine or {}
end

Config:Extend()
print("LoliCore.Config Extended")
