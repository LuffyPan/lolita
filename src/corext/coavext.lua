--
-- LoliCore Avatar Extend
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/04/08 18:15:58
--

local Avatar = LoliCore:NewExtend("Avatar")

function Avatar:Extend()
  self.Alive = 0
  --Load Avatar Script
  --[[
  local AvatarFile = LoliCore.Arg:Get("avatar")
  local AvatarPath = LoliCore.Arg:Get("avatarpath")
  local AvatarManifest = dofile(AvatarFile)
  assert(type(AvatarManifest) == "table")
  for _, FN in ipairs(AvatarManifest) do
    dofile(AvatarPath .. "/" .. FN)
  end
  --]]
  --LoliCore.Imagination:Begin(16, self.ImageTestIo, self)
  --LoliCore.Imagination:Begin(16, self.ImageTestNet, self)
  --LoliCore.Imagination:Begin(16 * 5, self.ImageMem, self)
  LoliCore.Imagination:Begin(16 * 3600 * 2, self.ImageClose, self)
  LoliCore.Os:RegisterSignal(LoliCore.Os.SIG_INT, Avatar.OnSignal, self)
  print("Avatar Extended")
end

function Avatar:Attach(Av)
  print("LoliCore")
  print(string.format("%s", LoliCore.Info:GetReposVersion()))
  print(string.format("%s", LoliCore.Info:GetVersion()))
  print(string.format("%s", LoliCore.Info:GetAuthor()))
  print(string.format("%s", LoliCore.Info:GetCopyright()))
  print(string.format("Corext:%s", LoliCore.Arg:Get("corext")))
  print(string.format("Avatar:%s", LoliCore.Arg:Get("avatar")))
  print(string.format("CorextPath:%s", LoliCore.Arg:Get("corextpath")))
  print(string.format("AvatarPath:%s", LoliCore.Arg:Get("avatarpath")))
  print("LoliCore.Avatar Attaching...")

  assert(Av.OnBorn)(Av)
  self.Alive = 1
  while self.Alive == 1 do
    LoliCore.Imagination:Active() -- May be dump LoliCore.Net
    LoliCore.Net:Active()
    LoliCore.Os:Active(1) --带有Sleep功能
  end
  assert(Av.OnDie)(Av)
end

function Avatar:Detach()
  LoliCore.Imagination:EndAll()
  self.Alive = 0
end

function Avatar:ImageClose(Im)
  self:Detach()
  print("LoliCore.Avatar Detached")
end

function Avatar:ImageMem(Im)
  print(string.format("Mem:%d/%d", LoliCore.Base.GetMem()))
  LoliCore.Imagination:Begin(16, self.ImageMem, self)
end

function Avatar:ImageTestIo(Im)
  local T1 = {Code = "Lolita", Age = 19,}
  local S1 = LoliCore.Io:Serialize(T1)
  local T2 = LoliCore.Io:Deserialize(S1)
  print(S1)
  print(T2)
  --Compare Table
  --Show Table
  for k, v in pairs(T2) do
    print(k, v)
  end
  LoliCore.Imagination:Begin(16, self.ImageTestIo, self)
end

function Avatar:ImageTestNet(Im)
  local Ip = "127.0.0.1"
  local Port = 7000
  for i = 1, 20 do
    assert(LoliCore.Net:Listen(Ip, Port), string.format("Listen Failed @ %s:%d", Ip, Port))
    Port = Port + 1
  end
  Port = 7000
  for i = 1, 20 do
    assert(LoliCore.Net:Connect(Ip, Port), string.format("Connect Failed 2 %s:%d", Ip, Port))
    Port = Port + 1
  end
end

function Avatar:OnSignal(Signal)
  if Signal == LoliCore.Os.SIG_INT then
    print("Avatar Recivied Interupt Signal")
    self:Detach()
  end
end

print("Avatar Compiled")
