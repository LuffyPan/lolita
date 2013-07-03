--
-- Lolita Server God Main
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/05/06 21:42:50
--

local function pf(fmt, ...)
  print(string.format(fmt, ...))
end

--LoliSrvGod = {}

function LoliSrvGod:Init()
  self.Dconf = assert(LoliCore.Config:GetDefault())
  self.Uconf = assert(LoliCore.Config:GetUserDefine())
  self:Srv_Init()
  self:InitTraceLevel()
  self.Logic:Init()
  self:LOGO()
  self:Srv_Dump()
end

function LoliSrvGod:InitTraceLevel()
  local Lv = LoliCore.Arg:Get("tracelv")
  Lv = Lv and tonumber(Lv) or 0
  core.base.settracelv(Lv)
end

function LoliSrvGod:LOGO()
  local SrvId = self.Uconf.SrvId or assert(self.Dconf.SrvId)
  local SrvName = self.Uconf.SrvName or assert(self.Dconf.SrvName)
  local SrvDesc = self.Uconf.SrvDesc or assert(self.Dconf.SrvDesc)
  pf("               %d -- %s -- %s", SrvId, SrvName, SrvDesc)
  pf("               Based On %s %s", LoliCore.Info:GetName(), LoliCore.Info:GetReposVersion())
  pf("                             %s", "Chamz Lau Original")
end

function LoliSrvGod:OnBorn()
  print("OnBorn")
  self:Init()
end

function LoliSrvGod:OnDie()
  print("OnDie")
  debug.debug()
end

LoliCore.Avatar:Attach(LoliSrvGod)