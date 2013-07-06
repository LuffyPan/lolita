--
-- Lolita Server Souler Agency Main
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/04/23 15:13:53
--

local function pf(fmt, ...)
  print(string.format(fmt, ...))
end

function LoliSrvSa:OnBorn()
  self:InitTraceLevel()
  self.SoulerNet:Init()
  self.LoginNet:Init()
  self.GovNet:Init()
  self.GodNet:Init()
  self.GodProc:Init()
  self.Logic:Init()
  self:LOGO()
end

function LoliSrvSa:OnDie()
end

function LoliSrvSa:InitTraceLevel()
  local Lv = LoliCore.Arg:Get("tracelv")
  Lv = Lv and tonumber(Lv) or 0
  core.base.settracelv(Lv)
end

function LoliSrvSa:LOGO()
  pf("               Lolita SoulerAgency Server.")
  pf("               Based On %s %s", LoliCore.Info:GetName(), LoliCore.Info:GetReposVersion())
  pf("                             %s", "Chamz Lau Original")
end

LoliCore.Avatar:Attach(LoliSrvSa)
