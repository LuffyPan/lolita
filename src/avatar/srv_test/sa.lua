--
-- Test Sa
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/07/04 12:17:21
--

local Executor = assert(LoliSrvTest.Executor)
local Sa = assert(LoliSrvTest.Sa)

function Sa:Init()
  Executor:AttachTarget("sa", Sa)
end

function Sa:Execute()
  print("Sa Execute")
end
