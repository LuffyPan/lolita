--
-- Lolita Server Souler Agency Main
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/04/23 15:13:53
--

local function pf(fmt, ...)
  print(string.format(fmt, ...))
end

function LoliSrvSA:Init()
  core.base.settracelv(4)
  self.SoulerMgr:Init()
  self.SoulerNet:Init()
  self.LoginNet:Init()
  self.Logic:Init()
  self:LOGO()
end

function LoliSrvSA:LOGO()
  pf("               Lolita SoulerAgency Server.")
  pf("               Based On %s %s", LoliCore.Info:GetName(), LoliCore.Info:GetReposVersion())
  pf("                             %s", "Works Of Chamz Lau's")
end

LoliSrvSA:Init()