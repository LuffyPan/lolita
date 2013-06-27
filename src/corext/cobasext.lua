--
-- LoliCore Base, Arg, Info Extend
-- Chamz Lau
-- 2013/03/03 00:01:59
--

LoliCore = {}
LoliCore.ExtendRepos = {}

function LoliCore:NewExtend(Name)
  assert(not self[Name])
  local Ext = {}
  self[Name] = Ext
  table.insert(self.ExtendRepos, Ext)
  return Ext
end

function LoliCore:Extend()
  assert(not self.IsExtended)
  for i, Ext in ipairs(self.ExtendRepos) do
    assert(Ext.Extend)(Ext)
  end
  self.IsExtended = 1
end

local Base = LoliCore:NewExtend("Base")
local Arg = LoliCore:NewExtend("Arg")
local Info = LoliCore:NewExtend("Info")

--Base
function Base:Extend()
  print("Base Extended")
end

function Base:GetMem()
  return core.base.getmem()
end

function Base:SetMaxMem(mm)
  return core.base.setmaxmem(mm)
end

function Base:_SnapNew(Snap)
  local NewField = {}
  local NewFieldCount = 0
  while 1 do
    for k, v in pairs(Snap.__NewField) do
      Snap[k] = v
      if Snap.__Ignore[v] then goto continue end
      Snap.__Ignore[v] = 1
      if type(v) == "table" then
        for sk, sv in pairs(v) do
          local sk = k .. "." .. tostring(sk)
          Snap[sk] = sv
          if not Snap.__Ignore[sv] then
            NewField[sk] = sv
            NewFieldCount = NewFieldCount + 1
          end
        end
      end
      ::continue::
    end
    Snap.__NewField = NewField
    if NewFieldCount <= 0 then return end
    NewField = {}
    NewFieldCount = 0
  end
end

function Base:Snap(Ignore)
  local Snap = {}
  Snap.__NewField = {Global = _G,}
  Snap.__Ignore = {}
  Snap.__Ignore[package] = 1
  Snap.__Ignore[Snap] = 1
  Snap.__Ignore[Ignore] = 1
  for _, v in ipairs(Ignore) do
    Snap.__Ignore[v] = 1
  end
  self:_SnapNew(Snap)
  return Snap
end

function Base:ParseSnap(Old, New)
  local Parse = {}
  for k, v in pairs(New) do
    if not Old[k] then
      Parse[k] = v
    end
  end
  return Parse
end

--Arg
function Arg:Extend()
  print("Arg Extended")
end

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
function Info:Extend()
  print("Info Extended")
end

function Info:GetName()
  return "LoliCore"
end

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

function Info:GetLCopyright()
  return core.info.lcopyright
end

function Info:GetLAuthors()
  return core.info.lauthors
end

print("Base Compile")
