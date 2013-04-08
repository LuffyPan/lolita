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

for k, v in pairs(_G) do
  print(k, v)
end
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


LoliCore = {}
LoliCore.ExtendManifest =
{
  "coext.lua",
  "coosext.lua",
  "coimext.lua",
  "conext.lua",
  "coavext.lua",
}

function LoliCore.Extend()
  local s = 0
  local e = nil
  local laste = nil
  local corepath
  while 1 do
    s, e = string.find(core.arg.core, "/", s + 1)
    if not s then break end
    laste = e - 1
  end
  if laste then
    corepath = string.sub(core.arg.core, 1, laste)
  else
    corepath = "."
  end

  for _, fn in ipairs(LoliCore.ExtendManifest) do
    dofile(corepath .. "/" .. fn)
  end
end

LoliCore.Extend()
LoliCore.Avatar.Attach()

--[[
LoliCore = {}
lolicore.avatar = {}
LoliCore.Born()
Core.Net.PushPackage()
core.net.listen()

local SaNet = LoliCore.Net.Listen("127.0.0.1", 7000)
LoliCore.Net.PushPackage(SaNet)
LoliCore.Net.Connect()
LoliCore.Net.Register()

LoliCore.Os.Sleep()

LoliCore.Base.GetMem()

LoliCore.Arg.Get()

LoliCore.Info.GetAuthor()

LoliCore.Avatar.Attach()
--]]
