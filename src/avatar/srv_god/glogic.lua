--
-- God's Logic
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/05/17 14:12:36
--

LoliSrvGod.Logic = {}

local Logic = LoliSrvGod.Logic
local SrvNet = LoliSrvGod.SrvNet

local SoulerRepos = {}

function SoulerRepos:Init()
  self._SoulerRepos = {}
  self._RootPath = "srv_god"
  self._SoulerPath = self._RootPath .. "/souler"

  if not LoliCore.Os:IsPath(self._RootPath) then
    print(string.format("%s Is Not Exist, Create It", self._RootPath))
    assert(LoliCore.Os:MkDir(self._RootPath))
    assert(LoliCore.Os:MkDir(self._SoulerPath))
  end
end

function SoulerRepos:Get(SoulId)
  return self._SoulerRepos[SoulId]
end

function SoulerRepos:Load(SoulId)
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

function SoulerRepos:Save(SoulId)
  local Souler = assert(self._SoulerRepos[SoulId])
  if Souler.Fragments then assert(self:_SaveFragments(Souler)) end
  return 1
end

function SoulerRepos:_LoadFragments(Souler)
  local Fi = self._SoulerPath .. "/" .. "souler_" .. tostring(Souler.SoulId) .. ".lua"
  Souler.Fragments = LoliCore.Io:LoadFile(Fi)
  return 1
end

function SoulerRepos:_SaveFragments(Souler)
  assert(Souler.Fragments)
  local Fi = self._SoulerPath .. "/" .. "souler_" .. tostring(Souler.SoulId) .. ".lua"
  return LoliCore.Io:SaveFile(Souler.Fragments, Fi)
end




function Logic:Init()
  SoulerRepos:Init()
  SrvNet:RegisterLogic(self:__GetLogic(), self)
end

function Logic:OnRequestQuerySouler(Srv)
  print("OnRequestQuerySouler")
  local Pack = Srv.Pack
  local Souler = assert(SoulerRepos:Load(Pack.SoulId)) --Step 1
  Pack.Result = 1
  Pack.Souler = Souler.Fragments
end

function Logic:OnRequestCreateSouler(Srv)
  print("OnRequestCreateSouler")
  local Pack = Srv.Pack
  local Souler = assert(SoulerRepos:Load(Pack.SoulId))
  if Souler.Fragments then
    Pack.Result = 0
    Pack.ErrorCode = 1
    print(string.format("Souler[%u]'s Fragments Already Created", Pack.SoulId))
    return
  end
  --Step 2. CHeck Name.
  --Step 3. Create.
  local SoulInfo = Pack.SoulInfo
  local Fragments =
  {
    SoulId= Pack.SoulId,
    Name = SoulInfo.Name,
    Sex = SoulInfo.Sex,
    Job = SoulInfo.Job,
    GovId = SoulInfo.GovId,
    SoulLv = 1,
    Soul = 0,
    MaxSoul = 1000,
  }
  Souler.Fragments = Fragments
  --Step 4. Save, Should use timer to save, and log failed
  assert(SoulerRepos:Save(Pack.SoulId))
end

function Logic:OnRequestSelectSouler(Srv)
  print("OnRequestSelectSouler")
  local Pack = Srv.Pack
  local Souler = assert(SoulerRepos:Load(Pack.SoulId))
  if not Souler.Fragments then
    Pack.Result = 0
    Pack.ErrorCode = 1
    print(string.format("Souler[%u]'s Fragments Has Not Create", Pack.SoulId))
    return
  end
  if Souler.Moments.Selected == 1 then
    Pack.Result = 0
    Pack.ErrorCode = 2
    print(string.format("Souler[%u] Already Selected", Pack.SoulId))
    return
  end
  Souler.Moments.Selected = 1
  Pack.GovId = Souler.Fragments.GovId
  Pack.Result = 1
end

function Logic:OnRequestDestroySouler(Srv)
  print("OnRequestDestroySouler")
end

function Logic:OnRequestClose(Srv)
  print("OnRequestClose")
  LoliCore.Avatar:Detach()
end

function Logic:__GetLogic()
  if self.__Logic then return self.__Logic end
  self.__Logic =
  {
    RequestQuerySouler = self.OnRequestQuerySouler,
    RequestCreateSouler = self.OnRequestCreateSouler,
    RequestSelectSouler = self.OnRequestSelectSouler,
    RequestDestroySouler = self.OnRequestDestroySouler,
    RequestClose = self.OnRequestClose,
  }
  return self.__Logic
end
