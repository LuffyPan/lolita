--
-- God Logic Souler
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/05/14 19:37:32
--

LoliSrvGod.LogicSouler = {}

local LogicSouler = LoliSrvGod.LogicSouler
local function pf(fmt, ...)
  print(string.format(fmt, ...))
end

function LogicSouler:Init()
  self.RootPath = "srv_god"
  self.SoulerPath = self.RootPath .. "/souler"
  self.Soulers = {} --Why s

  if not LoliCore.Os:IsPath(self.RootPath) then
    pf("%s Is Not Exist, Create It", self.RootPath)
    assert(LoliCore.Os:MkDir(self.RootPath))
    assert(LoliCore.Os:MkDir(self.SoulerPath))
  end
end

function LogicSouler:_LoadSouler(SoulId)
  if self.Soulers[SoulId] then return end
  local F = self.SoulerPath .. "/" .. "souler_" .. tostring(SoulId) .. ".lua"
  self.Soulers[SoulId] = LoliCore.Io:LoadFile(F)
end

function LogicSouler:_SaveSouler(SoulId, Souler)
  local F = self.SoulerPath .. "/" .. "souler_" .. tostring(SoulId) .. ".lua"
  return LoliCore.Io:SaveFile(Souler, F)
end

function LogicSouler:Query(SoulId)
  self:_LoadSouler(SoulId)
  --Return it directly now! ToDo
  return self.Soulers[SoulId]
end

function LogicSouler:Create(SoulId, SoulInfo)
  self:_LoadSouler(SoulId)
  if self.Soulers[SoulId] then return end
  local Souler =
  {
    SoulId= SoulId,
    Name = SoulInfo.Name,
    Sex = SoulInfo.Sex,
    Job = SoulInfo.Job,
    GovId = SoulInfo.GovId,
    SoulLv = 1,
    Soul = 0,
    MaxSoul = 1000,
  }
  if not self:_SaveSouler(SoulId, Souler) then return end
  self.Soulers[SoulId] = Souler
  return 1
end
