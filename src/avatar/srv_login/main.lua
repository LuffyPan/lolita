--
-- Lolita Server Login Main
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/04/18 21:25:37
--

LoliSrvLogin = {}
local p = print
local function pf(fmt, ...)
  print(string.format(fmt, ...))
end

function LoliSrvLogin:OnBorn()
  self:InitRoot()
  self:LoadAccounts()
  self:InitNet()
  self:InitImagination()
  self:LOGO()
end

function LoliSrvLogin:OnDie()
end

function LoliSrvLogin:InitRoot()
  self.RootPath = "srv_login"
  self.AccountPath = self.RootPath .. "/accout"
  pf("Current Work Directory:%s", LoliCore.Os:GetCwd())
  if LoliCore.Os:IsPath(self.RootPath) then
    pf("%s Is Exist, Checking....", self.RootPath)
    assert(LoliCore.Os:IsDir(self.RootPath), string.format("%s Is NOT Directory", self.RootPath))
  else
    pf("%s Is NOT Exist, Init....", self.RootPath)
    assert(LoliCore.Os:MkDir(self.RootPath), string.format("%s Init Error", self.RootPath))
    assert(LoliCore.Os:MkDir(self.AccountPath), string.format("%s Init Error", self.AccountPath))
    pf("%s Inited", self.RootPath)
  end
end

function LoliSrvLogin:LoadAccounts()
  self.Accounts = {}
  self.AccountMetaFile = self.AccountPath .. "/meta.lua"
  if not LoliCore.Os:IsFile(self.AccountMetaFile) then
    --Save AccountMeta to File
    self.AccountMeta = {bDirty = 0, SoulId = 1987, AccountCount = 0, Accounts = {},}
    assert(LoliCore.Io:SaveFile(self.AccountMeta, self.AccountMetaFile))
    pf("%s Is Not Exist, Create And Init It.", self.AccountMetaFile)
  else
    --Load AccountMeta from File
    self.AccountMeta = assert(LoliCore.Io:LoadFile(self.AccountMetaFile))
    pf("%s Is Exist, Load And Init It.", self.AccountMetaFile)
  end

  pf("Next SoulId: %u", self.AccountMeta.SoulId)
  pf("Account Count: %u", self.AccountMeta.AccountCount)
  for k, v in pairs(self.AccountMeta.Accounts) do
    pf("Loading Account[%s]", k)
    assert(self:LoadAccount(k), string.format("Load Account[%s] Failed", k))
  end
  pf("Load Accounts ----- ok")
end

function LoliSrvLogin:SaveAccounts()
  for k, v in pairs(self.Accounts) do
    if v.bNew ~= 1 then goto continue end
    -- Set bNew first, may cause fatal error, TODO
    v.bNew = 0
    -- If one Account Save Failed, All Account Last Will Not Do Save, TODO
    local AccountFile = self.AccountPath .. "/" .. k .. ".lua"
    pf("Saving Account[%s] To %s", k, AccountFile)
    assert(LoliCore.Io:SaveFile(v, AccountFile))
    ::continue::
  end

  if self.AccountMeta.bDirty == 1 then
    self.AccountMeta.bDirty = 0
    pf("Saving Accounts Meta To %s", self.AccountMetaFile)
    assert(LoliCore.Io:SaveFile(self.AccountMeta, self.AccountMetaFile))
  end
  pf("Save Accounts ----- ok")
end

function LoliSrvLogin:LoadAccount(Account)
  local AccountFile = self.AccountPath .. "/" .. Account .. ".lua"
  assert(not self.Accounts[Account])
  self.Accounts[Account] = LoliCore.Io:LoadFile(AccountFile)
  return self.Accounts[Account]
end

function LoliSrvLogin:SaveAccount(Account)
  local AccountFile = self.AccountPath .. "/" .. Account
  assert(self.Accounts[Account])
  return LoliCore.Io:SaveFile(self.Accounts[Account], AccountFile)
end

function LoliSrvLogin:LogicRegister(Id, Pack)
  Pack.ProcId = "ResRegister"
  Pack.Result = 0
  if self.Accounts[Pack.Account] then
    print(string.format("Account[%s] Is Exist", Pack.Account))
    Pack.ErrorCode = 0
    assert(LoliCore.Net:PushPackage(self.GodNetId, Pack))
    return
  end
  local Account = {Account = Pack.Account, Password = Pack.Password, SoulId = self.AccountMeta.SoulId, bNew = 1,}
  self.Accounts[Account.Account] = Account
  self.AccountMeta.Accounts[Pack.Account] = 1
  self.AccountMeta.AccountCount = self.AccountMeta.AccountCount + 1
  self.AccountMeta.SoulId = self.AccountMeta.SoulId + 1
  self.AccountMeta.bDirty = 1
  Pack.PersonId = Account.SoulId
  Pack.Result = 1
  assert(LoliCore.Net:PushPackage(self.GodNetId, Pack))
end

function LoliSrvLogin:LogicAuth(Id, Pack)
  Pack.ProcId = "ResAuth"
  Pack.Result = 0
  local Account = self.Accounts[Pack.Account]
  if not Account then
    print(string.format("Account[%s] Is Not Exist", Pack.Account))
    Pack.ErrorCode = 0
    assert(LoliCore.Net:PushPackage(self.GodNetId, Pack))
    return
  end
  if Account.Password ~= Pack.Password then
    print(string.format("Account[%s]'s Password[%s] Is Not Correct", Pack.Account, Pack.Password))
    Pack.ErrorCode = 1
    assert(LoliCore.Net:PushPackage(self.GodNetId, Pack))
    return
  end
  Pack.PersonId = Account.SoulId
  Pack.Result = 1
  assert(LoliCore.Net:PushPackage(self.GodNetId, Pack))
end

function LoliSrvLogin:LOGO()
  pf("               Lolita Login Server.")
  pf("               Based On %s %s", LoliCore.Info:GetName(), LoliCore.Info:GetReposVersion())
  pf("                             %s", "Works Of Chamz Lau's")
end

function LoliSrvLogin:InitNet()
  core.base.settracelv(4)
  --取消监听7000端口,直接通过God转发
  --TODO配置表读取相关的信息
  local ConnectParam = {}
  ConnectParam.Procs = self:_GetGodProcs()
  self.GodNetId = assert(LoliCore.Net:ConnectEx("127.0.0.1", 7700, ConnectParam))
  core.base.settracelv(0)
end

function LoliSrvLogin:InitImagination()
  LoliCore.Imagination:Begin(16 * 10, self.ImageMem, self)
  LoliCore.Imagination:Begin(16 * 20, self.ImageSaveAccounts, self)
end

function LoliSrvLogin:ImageMem(Im)
  print(string.format("Memory:%u/%u", LoliCore.Base:GetMem()))
  LoliCore.Imagination:Begin(16 * 10, self.ImageMem, self)
end

local function msgh(x)
  pf("%s", x)
  pf("%s", debug.traceback())
end

function LoliSrvLogin:ImageSaveAccounts(Im)
  LoliCore.Imagination:Begin(16 * 20, self.ImageSaveAccounts, self)
  local r, e = xpcall(self.SaveAccounts, msgh, self)
  if not r then
    pf("Save Accounts ----- failed, %s", e)
  end
end

function LoliSrvLogin:OnGodConnect(NetId, Result)
  if Result == 0 then
    print("Connect To God Is Failed, Don't Request SrvLogin")
    return
  end
  local Pack = LoliCore.Net:GenPackage("ReqSrvLogin", {Key = "19870805", Extra = {}})
  LoliCore.Net:PushPackage(self.GodNetId, Pack)
end

function LoliSrvLogin:OnGodClose(NetId)
  print("Connection To God Is Disconnect")
end

function LoliSrvLogin:GodResSrvLogin(NetId, Pack)
  print(string.format("Login To God, Result : %s", Pack.Result))
  if Pack.Result == 1 then
    print(string.format("SrvId[%s], Type[%s]", Pack.Basic.Id, Pack.Basic.Type))
  end
end

function LoliSrvLogin:GodResSrvLogout(NetId, Pack)
  --暂时没有触发
  print(string.format("Logout From God, Result : %s", Pack.Result))
end

--在这里细分到每个协议是否需要自动回包
function LoliSrvLogin:_GetGodProcs()
  return
  {
    Param = self,
    Connect = self.OnGodConnect,
    Close = self.OnGodClose,
    ResSrvLogin = self.GodResSrvLogin,
    ResSrvLogout = self.GodResSrvLogout,

    ReqRegister = self.LogicRegister,
    ReqAuth = self.LogicAuth,
  }
end

LoliCore.Avatar:Attach(LoliSrvLogin)
