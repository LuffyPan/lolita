--
-- Lolita Server Goverment Main
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/04/28 13:31:35
--

local function pf(fmt, ...)
  print(string.format(fmt, ...))
end

--AreaSrvNet and SaSrvNet almost is same, so, them can be provide by LoliCore.Net
function LoliSrvGoverment:Init()
  self:InitTraceLevel()
  self.SaSrvNet:Init()
  self.AreaSrvNet:Init()
  self.Logic:Init()
  self:LOGO()
end

function LoliSrvGoverment:InitTraceLevel()
  local Lv = LoliCore.Arg:Get("tracelv")
  Lv = Lv and tonumber(Lv) or 0
  core.base.settracelv(Lv)
end

function LoliSrvGoverment:LOGO()
  pf("               Lolita Goverment Server.")
  pf("               Based On %s %s", LoliCore.Info:GetName(), LoliCore.Info:GetReposVersion())
  pf("                             %s", "Chamz Lau Original")
end

LoliSrvGoverment:Init()
