--
-- Lolita Area Server Main
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/05/18 20:25:47
--

local function pf(fmt, ...)
  print(string.format(fmt, ...))
end

function LoliSrvArea:Init()
  self:InitTraceLevel()
  self.GovNet:Init()
  self.Logic:Init()
  self:LOGO()
end

function LoliSrvArea:InitTraceLevel()
  local Lv = LoliCore.Arg:Get("tracelv")
  Lv = Lv and tonumber(Lv) or 0
  core.base.settracelv(Lv)
end

function LoliSrvArea:LOGO()
  pf("               Lolita Area Server.")
  pf("               Based On %s %s", LoliCore.Info:GetName(), LoliCore.Info:GetReposVersion())
  pf("                             %s", "Chamz Lau Original")
end

LoliSrvArea:Init()
