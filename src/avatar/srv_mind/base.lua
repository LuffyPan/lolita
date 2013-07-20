--
-- Mind's Base
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/07/07 23:27:01
--

local Base = LoliSrvMind.Base

function Base:Init()
  self:InitTraceLevel()
end

function Base:InitTraceLevel()
  local Lv = LoliCore.Arg:Get("tracelv")
  Lv = Lv and tonumber(Lv) or 0
  core.base.settracelv(Lv)
end

function Base:Logo()
  print(string.format("               Lolita Mind Server."))
  print(string.format("               Based On %s %s", LoliCore.Info:GetName(), LoliCore.Info:GetReposVersion()))
  print(string.format("                             %s", "Chamz Lau Original"))
end

