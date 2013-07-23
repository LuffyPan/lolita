--
-- God's Proc 
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/05/17 14:12:36
--

local Base = LoliSrvGod.Base
local Srv = LoliSrvGod.Srv
local Proc = LoliSrvGod.Proc
local Soul = LoliSrvGod.Soul
local PersonRepos = LoliSrvGod.PersonRepos

function Proc:Init()
  local D = Base:GetDefaultConfig()
  local U = Base:GetUserConfig()
  local Ip = U.Ip or D.Ip
  local Port = U.Port or D.Port
  local ListenExParam = {}
  ListenExParam.Procs = self:_GetProcs()
  self.NetId = LoliCore.Net:ListenEx(Ip, Port, ListenExParam)
end

function Proc:ReqQueryArea(NetId, Pack)
  Pack.ProcId = "ResQueryArea"
  local t = Srv:GetAllByType("srvarea")
  local AreaList = {}
  --TODO:这里的列表也可以预先计算好
  for _, s in ipairs(t) do
    table.insert(AreaList, {Id = s.Id, Available = s.NetId > 0 and 1 or 0})
  end
  Pack.AreaList = AreaList
  Pack.Result = 1
  LoliCore.Net:PushPackage(NetId, Pack)
end

function Proc:ReqQuerySouler(NetId, Pack)
  Pack.MindNetId = NetId
  local Soulers = PersonRepos:QuerySouler(Pack.PersonId)
  Pack.ProcId = "ResQuerySouler"
  Pack.Result = 1
  Pack.Soulers = Soulers
  self:ResQuerySouler(NetId, Pack)
end

function Proc:ReqCreateSouler(NetId, Pack)
  Pack.MindNetId = NetId
  local SoulerId, e = PersonRepos:CreateSouler(Pack.PersonId, Pack.SoulerInfo)
  Pack.ProcId = "ResCreateSouler"
  Pack.SoulerId = SoulerId
  Pack.Result = SoulerId and 1 or 0
  Pack.ErrorCode = e
  self:ResCreateSouler(NetId, Pack)
end

function Proc:ReqDestroySouler(NetId, Pack)
  Pack.MindNetId = NetId
  local SoulerId, e = PersonRepos:DestroySouler(Pack.PersonId, Pack.SoulerId)
  Pack.ProcId = "ResDestroySouler"
  Pack.SoulerId = SoulerId
  Pack.Result = SoulerId and 1 or 0
  Pack.ErrorCode = e
  self:ResDestroySouler(NetId, Pack)
end

function Proc:ReqSelectSouler(NetId, Pack)
  Pack.MindNetId = NetId
  local Souler, e = PersonRepos:SelectSouler(Pack.PersonId, Pack.SoulerId)
  Pack.ProcId = "ResSelectSouler"
  Pack.Souler = Souler
  Pack.Result = Souler and 1 or 0
  Pack.ErrorCode = e
  self:ResSelectSouler(NetId, Pack)
end

function Proc:ResQuerySouler(NetId, Pack)
  assert(LoliCore.Net:PushPackage(Pack.MindNetId, Pack))
end

function Proc:ResCreateSouler(NetId, Pack)
  assert(LoliCore.Net:PushPackage(Pack.MindNetId, Pack))
end

function Proc:ResDestroySouler(NetId, Pack)
  assert(LoliCore.Net:PushPackage(Pack.MindNetId, Pack))
end

function Proc:ResSelectSouler(NetId, Pack)
  local Souler = Pack.Souler
  Pack.Souler = nil
  Pack.SoulerId = Souler.Id
  if Pack.Result == 1 then
    local Person = PersonRepos:New(Pack.PersonId, Pack.SoulerId, Pack.MindNetId)
    Person.Souler = Souler
  else
  end
  assert(LoliCore.Net:PushPackage(Pack.MindNetId, Pack))
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
  local SrvMind = Srv:GetByNetId(Pack.MindNetId)
  if SrvMind and SrvMind.State == 1 then
    assert(LoliCore.Net:PushPackage(SrvMind.NetId, Pack))
  else
    print("Mind Server [%s] Is Not Connected!", Pack.MindNetId)
  end
end

function Proc:ReqArrival(NetId, Pack)
  local Person = PersonRepos:GetBySoulerId(Pack.PersonSoulerId)
  if not Person then
    print(string.format("Person[%s] Is Invalid", Pack.PersonSoulerId))
    return
  end
  local AreaId = assert(Person.Souler.CurrentAreaId)
  local Area = Srv:GetById(AreaId)
  if not Area then
    print(string.format("Current Area Id[%s] Is Invalid!", AreaId))
    Pack.ProcId = "ResArrival"
    Pack.ErrorCode = 1
    LoliCore.Net:PushPackage(Person.MindNetId, Pack)
  else
    print(string.format("Current Area Id[%s], NetId[%s]!", AreaId, Area.NetId))
    if Area.NetId > 0 then
      Pack.Souler = Person.Souler --角色数据发送给Area
      LoliCore.Net:PushPackage(Area.NetId, Pack)
    else
      Pack.ProcId = "ResArrival"
      Pack.ErrorCode = 2
      LoliCore.Net:PushPackage(Person.MindNetId, Pack)
    end
  end
end

function Proc:ReqDeparture(NetId, Pack)
  local Person = PersonRepos:GetBySoulerId(Pack.PersonSoulerId)
  if not Person then
    print(string.format("Person[%s] Is Invalid", Pack.PersonSoulerId))
    return
  end
  if Person.AreaNetId > 0 then
    LoliCore.Net:PushPackage(Person.AreaNetId, Pack)
  end
end

function Proc:ResArrival(NetId, Pack)
  local Person = PersonRepos:GetBySoulerId(Pack.PersonSoulerId)
  if not Person then
    print(string.format("Person[%s] Is Invalid", Pack.PersonSoulerId))
    return
  end
  if Pack.Result == 1 then
    local Area = assert(Srv:GetByNetId(NetId))
    if Area.Id == Person.Souler.CurrentAreaId then
      print(string.format("Attach AreaNetId[%s] To Person", Area.NetId))
      Person.AreaNetId = Area.NetId
    else
      print("AreaId[%s] Is Not Match Person's CurrentAreaId[%s]", Area.Id, Person.Souler.CurrentAreaId)
    end
  end
  LoliCore.Net:PushPackage(Person.MindNetId, Pack)
end

function Proc:ResDeparture(NetId, Pack)
  local Person = PersonRepos:GetBySoulerId(Pack.PersonSoulerId)
  if not Person then
    print(string.format("Person[%s] Is Invalid", Pack.PersonSoulerId))
    return
  end
  if Pack.Result == 1 then
    print(string.format("Deatach AreaNetId[%s] From Person", Person.AreaNetId))
    Person.AreaNetId = 0
  end
  LoliCore.Net:PushPackage(Person.MindNetId, Pack)
end

function Proc:PreProc(NetId, Pack)
  print(string.format("Net[%s], %s", NetId, Pack.ProcId))
  return 1
end

function Proc:_GetProcs()
  local Proc =
  {
    Param = self,
    Pre = self.PreProc,
    --Login
    ReqRegister = self.ReqLoginTransmit,
    ReqAuth = self.ReqLoginTransmit,
    ResRegister = self.ResLoginTransmit,
    ResAuth = self.ResLoginTransmit,

    ReqQueryArea = self.ReqQueryArea,

    ReqQuerySouler = self.ReqQuerySouler,
    ReqCreateSouler = self.ReqCreateSouler,
    ReqSelectSouler = self.ReqSelectSouler,
    ReqDestroySouler = self.ReqDestroySouler,
    ReqGetSouler = self.OnReqGetSouler,
    ReqSetEx = self.OnReqSetEx,
    ReqGetEx = self.OnReqGetEx,

    --Area
    ReqArrival = self.ReqArrival,
    ReqDeparture = self.ReqDeparture,
    ResArrival = self.ResArrival,
    ResDeparture = self.ResDeparture,

    --其他服务器都得连接到God,通过Key进行身份的匹配验证，汇报相关基本信息
    --God根据不同的服务器类型返回可能不同的数据
    ReqSrvLogin = self.OnReqSrvLogin,
    ReqSrvLogout = self.OnReqSrvLogout,
    Close = self.OnClose,
  }
  return Proc
end
