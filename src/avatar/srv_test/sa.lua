--
-- Test Sa
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/07/04 12:17:21
--

local Executor = assert(LoliSrvTest.Executor)
local Mind = assert(LoliSrvTest.Mind)

function Mind:Init()
  Executor:AttachTarget("mind", Mind)
end

function Mind:Execute()
  print("Mind Execute")
end
