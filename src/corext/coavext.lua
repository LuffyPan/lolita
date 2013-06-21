--
-- LoliCore Avatar Extend
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/04/08 18:15:58
--

LoliCore.Avatar = {}

local Base = LoliCore.Base
local Info = LoliCore.Info
local Arg = LoliCore.Arg
local Io = LoliCore.Io
local Os = LoliCore.Os
local Imagination = LoliCore.Imagination
local Net = LoliCore.Net
local Avatar = LoliCore.Avatar

function Avatar:Extend()
  self.Alive = 0
  --Load Avatar Script
  local AvatarFile = Arg:Get("avatar")
  local AvatarPath = Arg:Get("avatarpath")
  local AvatarManifest = dofile(AvatarFile)
  assert(type(AvatarManifest) == "table")
  for _, FN in ipairs(AvatarManifest) do
    dofile(AvatarPath .. "/" .. FN)
  end
  --Imagination:Begin(16, self.ImageTestIo, self)
  --Imagination:Begin(16, self.ImageTestNet, self)
  --Imagination:Begin(16 * 5, self.ImageMem, self)
  Imagination:Begin(16 * 3600 * 2, self.ImageClose, self)
  Os:RegisterSignal(Os.SIG_INT, Avatar.OnSignal, self)
end

function Avatar:Attach()
  print("LoliCore")
  print(string.format("%s", Info:GetReposVersion()))
  print(string.format("%s", Info:GetVersion()))
  print(string.format("%s", Info:GetAuthor()))
  print(string.format("%s", Info:GetCopyright()))
  print(string.format("Corext:%s", Arg:Get("corext")))
  print(string.format("Avatar:%s", Arg:Get("avatar")))
  print(string.format("CorextPath:%s", Arg:Get("corextpath")))
  print(string.format("AvatarPath:%s", Arg:Get("avatarpath")))
  print("LoliCore.Avatar Attaching...")

  self:Extend()

  self.Alive = 1
  while self.Alive == 1 do
    Imagination:Active() -- May be dump Net
    Net:Active()
    Os:Active(1) --带有Sleep功能
  end
end

function Avatar:Detach()
  Imagination:EndAll()
  self.Alive = 0
end

function Avatar:ImageClose(Im)
  self:Detach()
  print("LoliCore.Avatar Detached")
end

function Avatar:ImageMem(Im)
  print(string.format("Mem:%d/%d", Base.GetMem()))
  Imagination:Begin(16, self.ImageMem, self)
end

function Avatar:ImageTestIo(Im)
  local T1 = {Code = "Lolita", Age = 19,}
  local S1 = Io:Serialize(T1)
  local T2 = Io:Deserialize(S1)
  print(S1)
  print(T2)
  --Compare Table
  --Show Table
  for k, v in pairs(T2) do
    print(k, v)
  end
  Imagination:Begin(16, self.ImageTestIo, self)
end

function Avatar:ImageTestNet(Im)
  local Ip = "127.0.0.1"
  local Port = 7000
  for i = 1, 20 do
    assert(Net:Listen(Ip, Port), string.format("Listen Failed @ %s:%d", Ip, Port))
    Port = Port + 1
  end
  Port = 7000
  for i = 1, 20 do
    assert(Net:Connect(Ip, Port), string.format("Connect Failed 2 %s:%d", Ip, Port))
    Port = Port + 1
  end
end

function Avatar:OnSignal(Signal)
  if Signal == Os.SIG_INT then
    print("Avatar Recivied Interupt Signal")
    debug.debug()
    self:Detach()
  end
end
