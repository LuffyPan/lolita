--
-- God's Proc 
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/05/17 14:12:36
--

local Base = LoliSrvGod.Base
local Srv = LoliSrvGod.Srv
local Proc = LoliSrvGod.Proc
local Soul = LoliSrvGod.Soul

function Proc:Init()
  local D = Base:GetDefaultConfig()
  local U = Base:GetUserConfig()
  local Ip = U.Ip or D.Ip
  local Port = U.Port or D.Port
  local ListenExParam = {}
  ListenExParam.Procs = self:_GetProcs()
  self.NetId = LoliCore.Net:ListenEx(Ip, Port, ListenExParam)
end

function Proc:OnReqQuerySouler(NetId, Pack)
  print("OnRequestQuerySouler")
  local Souler = assert(Soul:Load(Pack.SoulId)) --Step 1
  Pack.Result = 1
  Pack.Souler = Souler.Fragments
end

function Proc:OnReqCreateSouler(NetId, Pack)
  print("OnRequestCreateSouler")
  local Souler = assert(Soul:Load(Pack.SoulId))
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
  assert(Soul:Save(Souler.SoulId))
  Pack.Result = 1
end

function Proc:OnReqSelectSouler(NetId, Pack)
  print("OnRequestSelectSouler")
  local Souler = assert(Soul:Load(Pack.SoulId))
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
  local Souler = assert(Soul:Load(Pack.SoulId))
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
  local Souler = assert(Soul:Load(Pack.SoulId))
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
  local Souler = assert(Soul:Load(Pack.SoulId))
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
  Pack.ProcId = "ResSrvLogin"
  local r, e, es = Srv:Login(NetId, Pack.Key, Pack.Extra)
  if not r then
    Pack.ErrorCode = e
    print(string.format("NetId[%s], Key[%s] Login Failed, Detail[%s]", NetId, Pack.Key, es))
    return
  end
  Pack.Result = 1
  Pack.Basic = Srv:GetBasic(r.Id)
  Srv:Dump() -- Just debug
  print("Login Succeed!!")
end

function Proc:OnReqSrvLogout(NetId, Pack)
  Pack.ProcId = "ResSrvLogout"
  Srv:Logout(NetId)
  Pack.Result = 1
  Srv:Dump()
  print("Logout Succeed!!")
end

function Proc:OnClose(NetId)
  print("Close")
  Srv:Logout(NetId)
  Srv:Dump()
  print("Logout By Close Succeed!!")
end

function Proc:ReqLoginTransmit(NetId, Pack)
  local SrvMind = Srv:GetByNetId(NetId)
  local SrvLogin = Srv:GetByType("srvlogin")
  Pack.MindNetId = NetId
  if SrvLogin and SrvLogin.State == 1 then
    assert(LoliCore.Net:PushPackage(SrvLogin.NetId, Pack))
  else
    print("Login Server Is Not Connected!")
  end
end

function Proc:ResLoginTransmit(NetId, Pack)
  print(string.format("ResLoginTransmit, ProcId[%s]", Pack.ProcId))
  local SrvMind = Srv:GetByNetId(Pack.MindNetId)
  if SrvMind and SrvMind.State == 1 then
    assert(LoliCore.Net:PushPackage(SrvMind.NetId, Pack))
  else
    print("Mind Server [%s] Is Not Connected!", Pack.MindNetId)
  end
end

function Proc:_GetProcs()
  local Proc =
  {
    --Login
    ReqRegister = self.ReqLoginTransmit,
    ReqAuth = self.ReqLoginTransmit,
    ResRegister = self.ResLoginTransmit,
    ResAuth = self.ResLoginTransmit,

    ReqQuerySouler = self.OnReqQuerySouler,
    ReqCreateSouler = self.OnReqCreateSouler,
    ReqSelectSouler = self.OnReqSelectSouler,
    ReqDestroySouler = self.OnReqDestroySouler,
    ReqGetSouler = self.OnReqGetSouler,
    ReqSetEx = self.OnReqSetEx,
    ReqGetEx = self.OnReqGetEx,

    --其他服务器都得连接到God,通过Key进行身份的匹配验证，汇报相关基本信息
    --God根据不同的服务器类型返回可能不同的数据
    ReqSrvLogin = self.OnReqSrvLogin,
    ReqSrvLogout = self.OnReqSrvLogout,
    Close = self.OnClose,
  }
  return Proc
end
