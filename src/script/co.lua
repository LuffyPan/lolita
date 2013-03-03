--
-- LoliCore script
-- Chamz Lau
-- 2013/03/02 23:27:09
--

core.c = {}

local n = 0

function core.c.born()
  print("core.c.born")
end

function core.c.active()
  n = n + 1
  if n > 1000000000 then
    core.api.base.kill()
    return
  end
  print(string.format("core.c.active, n = %d", n))
end

function core.c.die()
  print("core.c.die")
end

print(core.info.version)
print(core.info.reposversion)
print(core.info.author)
print(core.info.copyright)
for k,v in pairs(core.arg) do
  print(string.format("arg[%s]=%s", k, v))
end

print(core.api.base)
for k,v in pairs(core.api.base) do
  print(k, v);
end

print(core.api.net)
for k,v in pairs(core.api.net) do
  print(k, v);
end

local scriptpath = core.arg.scriptpath or "."
local scriptlst = dofile(scriptpath .. "/colst.lua");
for _, s in ipairs(scriptlst) do
  dofile(scriptpath .. "/" .. s)
end
