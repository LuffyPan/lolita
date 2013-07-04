--
-- Test Gov
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/07/04 12:16:42
--

local Executor = assert(LoliSrvTest.Executor)
local Gov = assert(LoliSrvTest.Gov)

function Gov:Init()
  Executor:AttachTarget("gov", Gov)
end

function Gov:Execute()
  print("Gov Execute")
end
