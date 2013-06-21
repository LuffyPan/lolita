--
-- LoliCore OS Extend
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/04/08 18:11:12
--

LoliCore.Os = {}

local core = core
local Os = LoliCore.Os

function Os:Extend()
  self.SigRepos = {}
  self.SIG_INT = core.os.SIG_INT
  assert(core.os.register(Os.__OnSignal, self))
end

function Os:GetTime()
  return core.os.gettime()
end

function Os:Sleep(Msec)
  core.os.sleep(Msec)
end

function Os:IsDir(Dir)
  return core.os.isdir(Dir)
end

function Os:IsFile(File)
  return core.os.isfile(File)
end

function Os:IsPath(Path)
  return core.os.ispath(Path)
end

function Os:MkDir(Path)
  return core.os.mkdir(Path)
end

function Os:MkDirEx(Path)
  local i = 0
  local c
  while 1 do
    i = string.find(Path, "/", i + 1)
    if not i then
      return core.os.mkdir(Path)
    else
      c = string.sub(Path, 1, i)
      if not self:IsDir(c) then
        local r = core.os.mkdir(c)
        if not r then return r end
      end
    end
  end
  assert()
end

function Os:GetCwd()
  return core.os.getcwd()
end

function Os:Active(SleepMsec)
  return core.os.active(SleepMsec)
end

function Os:RegisterSignal(Signal, Func, FuncParam)
  assert(Func)
  if not self.SigRepos[Signal] then
    self.SigRepos[Signal] = {Func, FuncParam}
  else
    assert()
  end
end

function Os:__OnSignal(Signal)
  local H = self.SigRepos[Signal]
  if not H then return end
  H[1](H[2], Signal)
end

Os:Extend()
print("LoliCore.Os Extended")
