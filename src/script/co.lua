--
-- LoliCore script
-- Chamz Lau
-- 2013/03/02 23:27:09
--

core.avatar = {}

function core:born()
  --print("core.c.born")
  --print(core.info.author)
  --print(core.info.version)
  --[[
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
  --]]
  print(self)

  local corepath = self.arg.corepath or "."
  local corelst = dofile(corepath .. "/colst.lua");
  for _, s in ipairs(corelst) do
    dofile(corepath .. "/" .. s)
  end

  local avatarscript = self.arg.avatar
  if avatarscript then
    dofile(self.arg.avatar)
  end

  self.image:born()
  self.avatar:born()
  print(string.format("\n\n\n/**********************************************************\n\n%s", self.info.copyright))
  print(self.info.author)
  print(self.info.reposversion)
  print(string.format("%s\n\n**********************************************************/\n\n\n", self.info.version))
end

function core:active()
  self.image:active()
  self.avatar:active()
end

function core:die()
  self.avatar:die()
  self.image:die()
end

function core:onconnect(id, extra)
  self.avatar:onconnect(id, extra)
end

function core:onaccept(id, attaid, extra)
  self.avatar:onaccept(id, attaid, extra)
end

function core:onpack(id, attaid, data, extra)
  local tbdata = assert(self.misc:deserialize(data))
  assert(type(tbdata) == "table", "not table pack")
  self.avatar:onpack(id, attaid, tbdata, extra)
end

function core:onclose(id, attaid, extra)
  self.avatar:onclose(id, attaid, extra)
end
