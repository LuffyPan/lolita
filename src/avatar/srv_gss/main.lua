--
-- Lolita Server Global Souler State Main
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/04/24 21:13:29
--

local function pf(fmt, ...)
  print(string.format(fmt, ...))
end

function LoliSrvGSS:Init()
  self:InitTraceLevel()
  self.GMgr:Init()
  self.SrvMgr:Init()
  self.SrvNet:Init()
  self.Logic:Init()
  self:LOGO()
end

function LoliSrvGSS:InitTraceLevel()
  local Lv = LoliCore.Arg:Get("tracelv")
  Lv = Lv and tonumber(Lv) or 0
  core.base.settracelv(Lv)
end

function LoliSrvGSS:LOGO()
  pf("               Lolita Global Souler State Server.")
  pf("               Based On %s %s", LoliCore.Info:GetName(), LoliCore.Info:GetReposVersion())
  pf("                             %s", "Works Of Chamz Lau's")
end

LoliSrvGSS:Init()
