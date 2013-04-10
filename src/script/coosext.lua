--
-- LoliCore OS Extend
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/04/08 18:11:12
--

LoliCore.Os = {}

local core = core
local Os = LoliCore.Os

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

function Os:GetCwd()
  return core.os.getcwd()
end

print("LoliCore.Os Extended")
