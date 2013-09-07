--
-- sample and test for main loop.
-- the different between of main loop in by C and Lua
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/09/07 22:49:49
--

-- on macosx, it's almost the same

local loop = {}

function loop:born()
  self.count = 0
  print("loop born")
end

function loop:active()
  local sum = 0
  for i = 1, 10000 do
    sum = sum + i
  end
  self.count = self.count + 1
  if self.count >= 100000 then
    return 0
  end
  return 1
end

function loop:die()
  print("loop die")
end

local function main()
  if lolita.core.arg.c then
    lolita.core.base.attach(loop)
  else
    loop:born()
    while 1 do
      if 0 == loop:active() then
        break
      end
    end
    loop:die()
  end
end

main()
