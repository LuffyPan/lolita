--
-- LoliCore script
-- Chamz Lau
-- 2013/03/02 23:27:09
--

--[=====[
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

  local corepath = self.arg.corepath or "."
  local corelst = dofile(corepath .. "/colst.lua");
  for _, s in ipairs(corelst) do
    dofile(corepath .. "/" .. s)
  end

  --todo:get avatar's path, should provide a function to get a filepath's path party
  local s = 0
  local e = nil
  local laste = nil
  while 1 do
    s, e = string.find(self.arg.avatar, "/", s + 1)
    if not s then break end
    laste = e - 1
  end
  if laste then
    self.avatarpath = string.sub(self.arg.avatar, 1, laste)
  else
    self.avatarpath = "."
  end

  local avatarscript = self.arg.avatar
  if avatarscript then
    dofile(self.arg.avatar)
    --assert(loadfile(self.arg.avatar, "t", self.avatar))()
  end

  self.image:born()
  self.net:born()
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
  self.net:die()
end

function core:onconnect(netid, extra)
  self.net:dispatchconnect(netid, extra)
end

function core:onaccept(netid, attanetid, extra)
  self.net:dispatchaccept(netid, attanetid, extra)
end

function core:onpack(netid, attanetid, data, extra)
  self.net:dispatchpack(netid, attanetid, data, extra)
end

function core:onclose(netid, attanetid, extra)
  self.net:dispatchclose(netid, attanetid, extra)
end
--]=====]

print("fuck")
for k, v in pairs(_G) do
  print(k, v)
end
print("")
for k, v in pairs(core) do
  print(k, v)
end
for k, v in pairs(core.info) do
  print(k, v)
end
for k, v in pairs(core.arg) do
  print(k, v)
end
for k, v in pairs(core.base) do
  print(k, v)
end
for k, v in pairs(core.os) do
  print(k, v)
end
print(string.format("mem:%u/%u", core.base.getmem()))

for i = 1, 100 do
  print(string.format("mem:%u/%u", core.base.getmem()))
end
