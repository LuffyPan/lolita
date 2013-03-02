--
-- LoliCore script
-- Chamz Lau
-- 2013/03/02 23:27:09
--

core.c = {}
core.ext = {}
core.api = {}

function core.c.born()
  print("core.c.born")
  print(core.info.version)
  print(core.info.reposversion)
  print(core.info.author)
  print(core.info.copyright)
  for k,v in pairs(core.arg) do
    print(string.format("arg[%s]=%s", k, v))
  end
  local scriptpath = core.arg.scriptpath or "."
  local scriptlst = dofile(scriptpath .. "/corelst.lua");
  for _, s in ipairs(scriptlst) do
    dofile(scriptpath .. "/" .. s)
  end
end

function core.c.active()
  print("core.c.active")
end

function core.c.die()
  print("core.c.die")
end
