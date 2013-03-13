--
-- LoliCore script
-- Chamz Lau
-- 2013/03/02 23:27:09
--

core.c = {}
avatar = {}

local n = 0

function core.c.born()
  print("core.c.born")
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

  local corepath = core.arg.corepath or "."
  local corelst = dofile(corepath .. "/colst.lua");
  for _, s in ipairs(corelst) do
    dofile(corepath .. "/" .. s)
  end

  local avatarscript = core.arg.avatar
  if avatarscript then
    dofile(core.arg.avatar)
  end

  avatar.born()
end

function core.c.active()
  n = n + 1
  if n > 10 then
    core.api.base.kill()
    return
  end
  print(string.format("core.c.active, n = %d", n))
  avatar.active()
end

function core.c.die()
  avatar.die()
  print("core.c.die")
end

function core.c.onconnect(id, extra)
  print("core.c.onconnect", id, extra)
  if avatar.onconnect then
    avatar.onconnect(id, extra)
  end
end

function core.c.onaccept(id, attaid, extra)
  print("core.c.onaccept", id, attaid, extra)
  if avatar.onaccept then
    avatar.onaccept(id, attaid, extra)
  end
end

function core.c.onpack(id, attaid, data, extra)
  print("core.c.onpack", id, attaid, data, extra)
  if avatar.onpack then
    avatar.onpack(id, attaid, data, extra)
  end
end

function core.c.onclose(id, attaid, extra)
  print("core.c.onclose", id, attaid, extra)
  if avatar.onclose then
    avatar.onclose(id, attaid, extra)
  end
end
