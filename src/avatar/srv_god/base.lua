--
-- God Base
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/07/03 20:57:32
--

local Base = LoliSrvGod.Base

function Base:Init()
  self.DefaultConfig = assert(LoliCore.Config:GetDefault())
  self.UserConfig = assert(LoliCore.Config:GetUserDefine())
  self:InitTraceLevel()
end

function Base:Logo()
  local D = self:GetDefaultConfig()
  local U = self:GetUserConfig()
  local SrvId = U.SrvId or assert(D.SrvId)
  local SrvName = U.SrvName or assert(D.SrvName)
  local SrvDesc = U.SrvDesc or assert(D.SrvDesc)
  print(string.format("               %d -- %s -- %s", SrvId, SrvName, SrvDesc))
  print(string.format("               Based On %s %s", LoliCore.Info:GetName(), LoliCore.Info:GetReposVersion()))
  print(string.format("                             %s", "Chamz Lau Original"))
end

function Base:GetDefaultConfig()
  return self.DefaultConfig
end

function Base:GetUserConfig()
  return self.UserConfig
end

function Base:InitTraceLevel()
  local Lv = LoliCore.Arg:Get("tracelv")
  Lv = Lv and tonumber(Lv) or 0
  core.base.settracelv(Lv)
end
