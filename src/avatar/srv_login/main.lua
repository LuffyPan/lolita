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
  self:InitLogic()
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

function LoliSrvLogin:InitLogic()
  self.LogicFuncs =
  {
    Register = self.LogicRegister,
    Auth = self.LogicAuth,
  }
end

function LoliSrvLogin:LogicRegister(Id, Pack)
  assert(not self.Accounts[Pack.Account], "Account Exist")
  local Account = {Account = Pack.Account, Password = Pack.Password, SoulId = self.AccountMeta.SoulId, bNew = 1,}
  self.Accounts[Account.Account] = Account
  self.AccountMeta.Accounts[Pack.Account] = 1
  self.AccountMeta.AccountCount = self.AccountMeta.AccountCount + 1
  self.AccountMeta.SoulId = self.AccountMeta.SoulId + 1
  self.AccountMeta.bDirty = 1
  Pack.SoulId = Account.SoulId
  Pack.Result = 1
end

function LoliSrvLogin:LogicAuth(Id, Pack)
  local Account = assert(self.Accounts[Pack.Account], "Account NOT Exist")
  assert(Account.Password == Pack.Password, "Password Is NOT Correct")
  Pack.SoulId = Account.SoulId
  Pack.Result = 1
end

function LoliSrvLogin:LOGO()
  pf("               Lolita Login Server.")
  pf("               Based On %s %s", LoliCore.Info:GetName(), LoliCore.Info:GetReposVersion())
  pf("                             %s", "Works Of Chamz Lau's")
end

function LoliSrvLogin:InitNet()
  self.LoginNetEventFuncs =
  {
    Param = self,
    Accept = self.LoginNetEventAccept,
    Package = self.LoginNetEventPackage,
    Close = self.LoginNetEventClose,
  }
  self.LoginNetAttachIds = {}
  core.base.settracelv(4)
  self.LoginNetId = assert(LoliCore.Net:Listen("", 7000, self.LoginNetEventFuncs))
  core.base.settracelv(0)
end

function LoliSrvLogin:LoginNetEventAccept(Id)
  assert(not self.LoginNetAttachIds[Id])
  self.LoginNetAttachIds[Id] = 1
end

function LoliSrvLogin:LoginNetEventPackage(Id, Pack)
  assert(self.LoginNetAttachIds[Id])
  assert(self.LogicFuncs[Pack.ProcId])
  Pack.Result = 0
  Pack.ErrorCode = 0
  local r, e = pcall(self.LogicFuncs[Pack.ProcId], self, Id, Pack)
  if not r then
    print(e)
  end
  LoliCore.Net:PushPackage(Id, Pack)
end

function LoliSrvLogin:LoginNetEventClose(Id)
  if Id == self.LoginNetId then
    LoliCore.Avatar.Detach()
  else
    assert(self.LoginNetAttachIds[Id])
    self.LoginNetAttachIds[Id] = nil
  end
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

LoliCore.Avatar:Attach(LoliSrvLogin)
