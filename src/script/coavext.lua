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
  Imagination:Begin(16, self.ImageTestIo, self)
  Imagination:Begin(16, self.ImageMem, self)
  Imagination:Begin(16 * 30, self.ImageClose, self)
end

function Avatar:Attach()
  print("LoliCore")
  print(string.format("%s", Info:GetReposVersion()))
  print(string.format("%s", Info:GetVersion()))
  print(string.format("%s", Info:GetAuthor()))
  print(string.format("%s", Info:GetCopyright()))
  print("LoliCore.Avatar Attaching...")

  self:Extend()

  self.Alive = 1
  while self.Alive == 1 do
    Net:Active()
    Imagination:Active()
    Os:Sleep(1)
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
