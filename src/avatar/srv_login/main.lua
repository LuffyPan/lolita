--
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/04/18 21:25:37
--

LoliSrvLogin = {}

function LoliSrvLogin:Init()
  self:InitNet()
  self:InitImagination()
  self:InitLogic()
  self:LOGO()
end

function LoliSrvLogin:InitLogic()
  self.LogicFuncs =
  {
    Register = self.LogicRegister,
    Auth = self.LogicAuth,
  }
  self.Accounts = {}
end

function LoliSrvLogin:LogicRegister(Id, Pack)
  assert(not self.Accounts[Pack.Account], "Account Exist")
  self.Accounts[Pack.Account] = {Password = Pack.Password,}
  Pack.Result = 1
end

function LoliSrvLogin:LogicAuth(Id, Pack)
  local Account = assert(self.Accounts[Pack.Account], "Account NOT Exist")
  assert(Account.Password == Pack.Password, "Password Is NOT Correct")
  Pack.Result = 1
end

function LoliSrvLogin:LOGO()
  print(string.format("                         Lolita Login Server."))
  print(string.format("                             %s", "Chamz Lau's Production"))
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
  self.LoginNetId = assert(LoliCore.Net:Listen("127.0.0.1", 7000, self.LoginNetEventFuncs))
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
  LoliCore.Imagination:Begin(16 * 20, self.ImageSaveAccount, self)
end

function LoliSrvLogin:ImageMem(Im)
  print(string.format("Memory:%u/%u", LoliCore.Base:GetMem()))
  LoliCore.Imagination:Begin(16 * 10, self.ImageMem, self)
end

function LoliSrvLogin:ImageSaveAccount(Im)
  LoliCore.Imagination:Begin(16 * 20, self.ImageSaveAccount, self)
  for k, v in pairs(self.Accounts) do
    print(string.format("Saved Account[%s]", k))
  end
  print("Save Account Done")
end

LoliSrvLogin:Init()
