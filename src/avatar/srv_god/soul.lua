--
-- God Soul
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/07/03 20:51:39
--

local Base = LoliSrvGod.Base
local Soul = LoliSrvGod.Soul

function Soul:Init()
end

function Soul:Init()
  local D = Base:GetDefaultConfig()
  local U = Base:GetUserConfig()
  local RootPath = U.RootPath or D.RootPath
  local SoulerPath = U.SoulerPath or D.SoulerPath
  self._SoulerRepos = {}
  self._RootPath = assert(RootPath)
  self._SoulerPath = assert(SoulerPath)
  if not LoliCore.Os:IsPath(self._RootPath) then
    print(string.format("%s Is Not Exist, Create It", self._RootPath))
    assert(LoliCore.Os:MkDirEx(self._RootPath))
    assert(LoliCore.Os:MkDirEx(self._SoulerPath))
  end
end

function Soul:Get(SoulId)
  return self._SoulerRepos[SoulId]
end

function Soul:Load(SoulId)
  local Souler = self._SoulerRepos[SoulId]
  if Souler then return Souler end
  Souler =
  {
    SoulId = SoulId,
    LockKey = 0,
    Moments = {},
    Fragments = nil,
  }
  assert(self:_LoadFragments(Souler))
  self._SoulerRepos[SoulId] = Souler
  return Souler
end

function Soul:Save(SoulId)
  local Souler = assert(self._SoulerRepos[SoulId])
  if Souler.Fragments then assert(self:_SaveFragments(Souler)) end
  return 1
end

function Soul:_LoadFragments(Souler)
  local Fi = self._SoulerPath .. "/" .. "souler_" .. tostring(Souler.SoulId) .. ".lua"
  Souler.Fragments = LoliCore.Io:LoadFile(Fi)
  return 1
end

function Soul:_SaveFragments(Souler)
  assert(Souler.Fragments)
  local Fi = self._SoulerPath .. "/" .. "souler_" .. tostring(Souler.SoulId) .. ".lua"
  return LoliCore.Io:SaveFile(Souler.Fragments, Fi)
end
