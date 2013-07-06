--
-- Server Test Main
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/04/13 01:12:40
--

local Base = LoliSrvTest.Base
local Login = LoliSrvTest.Login
local God = LoliSrvTest.God
local Sa = LoliSrvTest.Sa
local Executor = LoliSrvTest.Executor

function LoliSrvTest:OnBorn()
  print("OnBorn")
  Base:Init()
  Executor:Init()
  Login:Init()
  God:Init()
  Sa:Init()
  Executor:Execute(LoliCore.Arg:Get("target"))
end

function LoliSrvTest:OnDie()
  print("OnDie")
end

LoliCore.Avatar:Attach(LoliSrvTest)
