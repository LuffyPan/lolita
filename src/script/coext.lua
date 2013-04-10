--
-- LoliCore Base, Arg, Info Extend
-- Chamz Lau
-- 2013/03/03 00:01:59
--

LoliCore.Base = {}
LoliCore.Arg = {}
LoliCore.Info = {}

local core = core
local Base = LoliCore.Base
local Arg = LoliCore.Arg
local Info = LoliCore.Info

--Base
function Base:GetMem()
  return core.base.getmem()
end

function Base:SetMaxMem(mm)
  return core.base.setmaxmem(mm)
end

function Base:SetDebug(lv)
  return core.base.enabletraceback(lv)
end

--Remove later
function Base:Kill()
  return core.base.kill()
end

--Arg
function Arg:Get(key)
  return core.arg[key]
end

function Arg:Set(key, val)
  core.arg[key] = val
end

function Arg:All()
  return core.arg
end

--Info
function Info:GetAuthor()
  return core.info.author
end

function Info:GetCopyright()
  return core.info.copyright
end

function Info:GetVersion()
  return core.info.version
end

function Info:GetReposVersion()
  return core.info.reposversion
end

function Info:GetPlatform()
  return core.info.platform
end

print("LoliCore.Base Extended")
print("LoliCore.Arg Extended")
print("LoliCore.Info Extended")
