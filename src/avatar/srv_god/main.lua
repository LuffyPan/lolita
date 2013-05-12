--
-- Lolita Server God Main
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/05/06 21:42:50
--

local function pf(fmt, ...)
  print(string.format(fmt, ...))
end

function LoliSrvGod:Init()
  self:InitTraceLevel()
  self.SANet:Init()
  self.LogicSA:Init()
  self:LOGO()
end

function LoliSrvGod:InitTraceLevel()
  local Lv = LoliCore.Arg:Get("tracelv")
  Lv = Lv and tonumber(Lv) or 0
  core.base.settracelv(Lv)
end

function LoliSrvGod:LOGO()
  pf("               Lolita God Server.")
  pf("               Based On %s %s", LoliCore.Info:GetName(), LoliCore.Info:GetReposVersion())
  pf("                             %s", "Chamz Lau Original")
end

LoliSrvGod:Init()
