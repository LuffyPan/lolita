--
-- God's Proc 
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/05/17 14:12:36
--

local Base = LoliSrvGod.Base
local SrvNet = LoliSrvGod.SrvNet
local Proc = LoliSrvGod.Proc

local SoulerRepos = {}

function SoulerRepos:Init(RootPath, SoulerPath)
  self._SoulerRepos = {}
  self._RootPath = assert(RootPath)
  self._SoulerPath = assert(SoulerPath)

  if not LoliCore.Os:IsPath(self._RootPath) then
    print(string.format("%s Is Not Exist, Create It", self._RootPath))
    assert(LoliCore.Os:MkDirEx(self._RootPath))
    assert(LoliCore.Os:MkDirEx(self._SoulerPath))
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




function Proc:Init()
  local D = Base:GetDefaultConfig()
  local U = Base:GetUserConfig()
  SoulerRepos:Init(U.RootPath or D.RootPath, U.SoulerPath or D.SoulerPath)
  SrvNet:Init(U.Ip or D.Ip, U.Port or D.Port, self:GetProcs(), self)
end

function Proc:OnReqQuerySouler(NetId, Pack)
  print("OnRequestQuerySouler")
  local Souler = assert(SoulerRepos:Load(Pack.SoulId)) --Step 1
  Pack.Result = 1
  Pack.Souler = Souler.Fragments
end

function Proc:OnReqCreateSouler(NetId, Pack)
  print("OnRequestCreateSouler")
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
  assert(SoulerRepos:Save(Souler.SoulId))
  Pack.Result = 1
end

function Proc:OnReqSelectSouler(NetId, Pack)
  print("OnRequestSelectSouler")
  local Souler = assert(SoulerRepos:Load(Pack.SoulId))
  if not Souler.Fragments then
    Pack.Result = 0
    Pack.ErrorCode = 1
    print(string.format("Souler[%u]'s Fragments Has Not Create", Souler.SoulId))
    return
  end
  if Souler.Moments.Selected == 1 then
    Pack.Result = 0
    Pack.ErrorCode = 2
    print(string.format("Souler[%u] Already Selected", Souler.SoulId))
    return
  end
  Souler.Moments.Selected = 1
  Pack.GovId = Souler.Fragments.GovId
  Pack.Result = 1
end

function Proc:OnReqGetSouler(NetId, Pack)
  print("OnRequestGetSouler")
  local Souler = assert(SoulerRepos:Load(Pack.SoulId))
  if not Souler.Fragments then
    Pack.Result = 0
    Pack.ErrorCode = 2
    print(string.format("Souler[%u]'s Fragments Has Not Create", Souler.SoulId))
    return
  end
  if Souler.Moments.Selected ~= 1 then
    Pack.Result = 0
    Pack.ErrorCode = 3
    print(string.format("Souler[%u] Not Already Selected", Souler.SoulId))
    return
  end
  if Souler.Fragments.GovId ~= Pack.GovId then
    Pack.Result = 0
    Pack.ErrorCode = 4
    print(string.format("Souler[%u] GovId[%u] Is Not Match", Souler.Fragments.GovId))
    return
  end
  Pack.Souler = Souler.Fragments
  Pack.Result = 1
  print("RequestGetSouler Succeed")
end

function Proc:OnReqDestroySouler(NetId, Pack)
  print("OnRequestDestroySouler")
end

function Proc:OnReqClose(NetId)
  print("OnRequestClose")
  LoliCore.Avatar:Detach()
end

function Proc:OnReqSetEx(NetId, Pack)
  print(string.format("Souler[%u], RequestSetEx", Pack.SoulId))
  local Souler = assert(SoulerRepos:Load(Pack.SoulId))
  if Souler.LockKey ~= 0 then
    Pack.Result = 0
    Pack.ErrorCode = 1
    print(string.format("Souler[%u] Is Already Locked", Souler.SoulId))
    return
  end
  for k, v in pairs(Pack.Conds) do
    local n = Souler.Moments[k] or 0
    if n ~= v then
      Pack.Result = 0
      Pack.ErrorCode = 1
      print(string.format("Cond[%s] = [%s] != [%s]", tostring(k), tostring(n), tostring(v)))
      return
    end
  end
  for k, v in pairs(Pack.Values) do
    Souler.Moments[k] = v
  end
  Pack.Result = 1
  print("SetEx Succeed!!......")
end

function Proc:OnReqGetEx(NetId, Pack)
  print(string.format("Souler[%u], RequestGetEx", Pack.SoulId))
  local Souler = assert(SoulerRepos:Load(Pack.SoulId))
  if Souler.LockKey ~= 0 then
    Pack.Result = 0
    Pack.ErrorCode = 1
    print(string.format("Souler[%u] Is Already Locked", Souler.SoulId))
    return
  end
  local Values = {}
  for k, v in pairs(Pack.Conds) do
    local n = Souler.Moments[k] or 0
    Values[k] = n
  end
  Pack.Values = Values
  Pack.Result = 1
  print("GetEx Succeed!!.....")
end

function Proc:OnReqSrvLogin(NetId, Pack)
  print("RequestSrvLogin")
end

function Proc:GetProcs()
  local Proc =
  {
    RequestQuerySouler = self.OnReqQuerySouler,
    RequestCreateSouler = self.OnReqCreateSouler,
    RequestSelectSouler = self.OnReqSelectSouler,
    RequestDestroySouler = self.OnReqDestroySouler,
    RequestGetSouler = self.OnReqGetSouler,
    RequestClose = self.OnReqClose,

    RequestSetEx = self.OnReqSetEx,
    RequestGetEx = self.OnReqGetEx,

    --其他服务器都得连接到God,通过Key进行身份的匹配验证，汇报相关基本信息
    --God根据不同的服务器类型返回可能不同的数据
    RequestSrvLogin = self.OnReqSrvLogin,
  }
  return Proc
end
