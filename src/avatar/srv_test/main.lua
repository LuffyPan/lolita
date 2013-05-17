--
-- Server Test Main
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/04/13 01:12:40
--

LoliSrvTest = {}

function LoliSrvTest:Main()
  self:TestInit()
  self.Snap = LoliCore.Base:Snap({})
end

function LoliSrvTest:TestInit()
  self.TestListenEventFuncs = {Param = self, Accept = self.TestListenAccept, Package = self.TestListenPackage,
  Close = self.TestListenClose,}
  self.TestConnectEventFuncs = {Param = self, Connect = self.TestConnectConnect, Package = self.TestConnectPackage,
  Close = self.TestConnectClose,}
  self.TestListenNets = {}
  self.TestAttachNets = {}
  self.TestConnectNets = {}
  self.TestListenCount = 0
  self.TestAttachCount = 0
  self.TestConnectCount = 0
  self.TestConnectPushCount = 0
  self.TestAttachPushCount = 0
  self.TestCount = 0

  local Target = LoliCore.Arg:Get("target")
  print(Target)
  if Target == "login" then
    LoliCore.Imagination:Begin(16, self.TestLoginConnect, self)
  elseif Target == "sa" then
    LoliCore.Imagination:Begin(16, self.TestSAConnect, self)
  elseif Target == "gss" then
    LoliCore.Imagination:Begin(16, self.TestGSSConnect, self)
  elseif Target == "goverment" then
    --LoliCore.Imagination:Begin(16, self.TestGovermentRequestConnect, self)
  elseif Target == "god" then
    LoliCore.Imagination:Begin(16, self.TestGodRequestConnect, self)
  else
    LoliCore.Imagination:Begin(8, self.TestListen, self)
  end
end

function LoliSrvTest:TestListenAccept(Id)
  print("Listen Accept", Id)
  assert(not self.TestAttachNets[Id])
  self.TestAttachNets[Id] = 1
  self.TestAttachCount = self.TestAttachCount + 1
end

function LoliSrvTest:TestListenPackage(Id, Pack)
  print("Listen Package", Id)
  assert(self.TestAttachNets[Id])
end

function LoliSrvTest:TestListenClose(Id)
  print("Listen Close", Id)
  if self.TestAttachNets[Id] then
    self.TestAttachNets[Id] = nil
    self.TestAttachCount = self.TestAttachCount - 1
  elseif self.TestListenNets[Id] then
    self.TestListenNets[Id] = nil
    self.TestListenCount = self.TestListenCount - 1
  else
    assert()
  end
  if self.TestListenCount == 0 and self.TestAttachCount == 0 then
    print("All Listen Is Closed")
  end
end

function LoliSrvTest:TestConnectConnect(Id, Result)
  print("Connect Connect", Id, Result)
  assert(self.TestConnectNets[Id])
end

function LoliSrvTest:TestConnectPackage(Id, Pack)
  print("Connect Package", Id)
  assert(self.TestConnectNets[Id])
end

function LoliSrvTest:TestConnectClose(Id)
  assert(self.TestConnectNets[Id])
  print("Connect Close", Id)
  self.TestConnectNets[Id] = nil
  self.TestConnectCount = self.TestConnectCount - 1
end

function LoliSrvTest:TestListen()
  local Id = assert(LoliCore.Net:Listen("127.0.0.1", 8000 + self.TestListenCount, self.TestListenEventFuncs))
  self.TestListenNets[Id] = 1
  self.TestListenCount = self.TestListenCount + 1
  if self.TestListenCount >= 20 then
    LoliCore.Imagination:Begin(4, self.TestConnect, self)
  else
    LoliCore.Imagination:Begin(4, self.TestListen, self)
  end
end

function LoliSrvTest:TestConnect()
  local Id = assert(LoliCore.Net:Connect("127.0.0.1", 8000 + self.TestConnectCount, self.TestConnectEventFuncs))
  self.TestConnectNets[Id] = 1
  self.TestConnectCount = self.TestConnectCount + 1
  if self.TestConnectCount >= 20 then
    LoliCore.Imagination:Begin(4, self.TestPushPackage, self)
  else
    LoliCore.Imagination:Begin(4, self.TestConnect, self)
  end
end

function LoliSrvTest:TestPushPackage()
  for k, v in pairs(self.TestConnectNets) do
    assert(LoliCore.Net:PushPackage(k, {"hahahahahahaha"}))
  end
  self.TestConnectPushCount = self.TestConnectPushCount + 1
  if self.TestConnectPushCount >= 20 then
    self.TestConnectPushCount = 0
    LoliCore.Imagination:Begin(4, self.TestClose, self)
  else
    LoliCore.Imagination:Begin(4, self.TestPushPackage, self)
  end
end

function LoliSrvTest:TestClose()
  self.TestCount = self.TestCount + 1
  if self.TestCount >= 2 then
    for k, v in pairs(self.TestListenNets) do
      LoliCore.Net:Close(k)
    end
    for k, v in pairs(self.TestAttachNets) do -- May be dump, old version absolutely
      LoliCore.Net:Close(k)
    end
    -- The Net Event Maybe is not over, but the Imagination is larger than 1 frame, so, it's ok now!
    LoliCore.Imagination:Begin(5 * 16, self.TestStep2Listen, self)
  else
    LoliCore.Imagination:Begin(4, self.TestConnect, self)
  end

  --Close the Connector later than Acceptor
  for k, v in pairs(self.TestConnectNets) do
    LoliCore.Net:Close(k)
  end
  print(string.format("Mem:%u/%u", LoliCore.Base:GetMem()))
end

--Test Step 2, one Listen Net, And many Net Connect to this Net, Push Data, Close Net, For Loop
function LoliSrvTest:TestStep2Listen()
  local Id = assert(LoliCore.Net:Listen("127.0.0.1", 9110, self.TestListenEventFuncs))
  self.TestListenNets[Id] = 1
  self.TestListenCount = self.TestListenCount + 1
  LoliCore.Imagination:Begin(16, self.TestStep2Connect, self)
end

function LoliSrvTest:TestStep2Connect()
  local Id = assert(LoliCore.Net:Connect("127.0.0.1", 9110, self.TestConnectEventFuncs))
  self.TestConnectNets[Id] = 1
  self.TestConnectCount = self.TestConnectCount + 1
  if self.TestConnectCount >= 62 then
    LoliCore.Imagination:Begin(16, self.TestStep2ConnectPushPackage, self)
  else
    LoliCore.Imagination:Begin(16, self.TestStep2Connect, self)
  end
end

function LoliSrvTest:TestStep2ConnectPushPackage()
  local Pack = {Type="Hello, This is Connector"}
  for k, v in pairs(self.TestConnectNets) do
    LoliCore.Net:PushPackage(k, Pack)
  end
  self.TestConnectPushCount= self.TestConnectPushCount+ 1
  if self.TestConnectPushCount >= 10 then
    self.TestConnectPushCount = 0
    LoliCore.Imagination:Begin(16 * 5, self.TestStep2AttachPushPackage, self)
  else
    LoliCore.Imagination:Begin(16, self.TestStep2ConnectPushPackage, self)
  end
end

function LoliSrvTest:TestStep2AttachPushPackage()
  local Pack = {Type="Hello, This is Attacher"}
  for k, v in pairs(self.TestAttachNets) do
    LoliCore.Net:PushPackage(k, Pack)
  end
  self.TestAttachPushCount = self.TestAttachPushCount + 1
  if self.TestAttachPushCount >= 10 then
    self.TestAttachPushCount = 0
    LoliCore.Imagination:Begin(16 * 5, self.TestStep2Close, self)
  else
    LoliCore.Imagination:Begin(16, self.TestStep2AttachPushPackage, self)
  end
end

function LoliSrvTest:TestStep2Close()
  for k, v in pairs(self.TestAttachNets) do
    LoliCore.Net:Close(k)
  end
  for k, v in pairs(self.TestListenNets) do
    LoliCore.Net:Close(k)
  end
  LoliCore.Imagination:Begin(16 * 5, self.TestStep2Assert, self)
end

function LoliSrvTest:TestStep2Assert()
  local idsCount = 0
  for k, v in pairs(core.net.ids) do
    print(k, v)
    idsCount = idsCount + 1
  end
  print(string.format("core.net.ids Count[%d]", idsCount))

  local NetStateCount = 0
  for k, v in pairs(LoliCore.Net.States) do
    print(k, v)
    NetStateCount = NetStateCount + 1
  end
  print(string.format("LoliCore.Net.States Count[%d]", NetStateCount))

  local ConnectNetsCount = 0
  for k, v in pairs(LoliSrvTest.TestConnectNets) do
    print(k, v)
    ConnectNetsCount = ConnectNetsCount + 1
  end
  print(string.format("LoliSrvTest.TestConnectNets Count[%d]", ConnectNetsCount))

  local ListenNetsCount = 0
  for k, v in pairs(LoliSrvTest.TestListenNets) do
    print(k, v)
    ListenNetsCount = ListenNetsCount + 1
  end
  print(string.format("LoliSrvTest.TestListenNets Count[%d]", ListenNetsCount))

  local AttachNetsCount = 0
  for k, v in pairs(LoliSrvTest.TestAttachNets) do
    print(k, v)
    AttachNetsCount = AttachNetsCount + 1
  end
  print(string.format("LoliSrvTest.TestAttachNets Count[%d]", AttachNetsCount))

  assert(idsCount == 0)
  assert(NetStateCount == 0)
  assert(ConnectNetsCount ==0)
  assert(ListenNetsCount == 0)
  assert(AttachNetsCount == 0)
  LoliCore.Imagination:Begin(16 * 5, self.TestLoginConnect, self)
end

function LoliSrvTest:TestLoginConnect()
  local Id = assert(LoliCore.Net:Connect("127.0.0.1", 7000, self.TestConnectEventFuncs))
  self.TestConnectNets[Id] = Id
  self.TestConnectCount = self.TestConnectCount + 1
  if self.TestConnectCount >= 1 then
    LoliCore.Imagination:Begin(16, self.TestLoginRegister, self)
  else
    LoliCore.Imagination:Begin(16, self.TestLoginConnect, self)
  end
end

function LoliSrvTest:TestLoginRegister()
  local PackRegister =
  {
    ProcId = "Register",
    Account = string.format("account_%s", self.TestConnectPushCount),
    Password = string.format("password_%s", self.TestConnectPushCount),
    Age = self.TestConnectPushCount,
  }
  for k, v in pairs(self.TestConnectNets) do
    LoliCore.Net:PushPackage(k, PackRegister)
  end
  self.TestConnectPushCount = self.TestConnectPushCount + 1
  if self.TestConnectPushCount >= 100 then
    debug.debug()
    LoliCore.Imagination:Begin(16 * 2, self.TestLoginAuth, self)
    self.TestConnectPushCount = 0
  else
    LoliCore.Imagination:Begin(16 * 2, self.TestLoginRegister, self)
  end
end

function LoliSrvTest:TestLoginAuth()
  local PackAuth =
  {
    ProcId = "Auth",
    Account = string.format("account_%s", self.TestConnectPushCount),
    Password = string.format("password_%s", self.TestConnectPushCount),
  }
  for k, v in pairs(self.TestConnectNets) do
    LoliCore.Net:PushPackage(k, PackAuth)
  end
  self.TestConnectPushCount = self.TestConnectPushCount + 1
  if self.TestConnectPushCount >= 100 then
    debug.debug()
    LoliCore.Avatar:Detach()
    self.TestConnectPushCount = 0
  else
    LoliCore.Imagination:Begin(16 * 2, self.TestLoginAuth, self)
  end
end

function LoliSrvTest:TestSAConnect()
  local Id = assert(LoliCore.Net:Connect("127.0.0.1", 7100, self.TestConnectEventFuncs))
  self.TestConnectNets[Id] = Id
  self.TestConnectCount = self.TestConnectCount + 1
  if self.TestConnectCount >= 1 then
    LoliCore.Imagination:Begin(16, self.TestSARegister, self)
  else
    LoliCore.Imagination:Begin(16, self.TestSAConnect, self)
  end
end

function LoliSrvTest:TestSARegister()
  local PackRegister =
  {
    ProcId = "Register",
    Account = string.format("account_%s", self.TestConnectPushCount),
    Password = string.format("password_%s", self.TestConnectPushCount),
    Age = self.TestConnectPushCount,
  }
  for k, v in pairs(self.TestConnectNets) do
    LoliCore.Net:PushPackage(k, PackRegister)
  end
  self.TestConnectPushCount = self.TestConnectPushCount + 1
  if self.TestConnectPushCount >= 1 then
    debug.debug()
    LoliCore.Imagination:Begin(16 * 2, self.TestSAAuth, self)
    self.TestConnectPushCount = 0
  else
    LoliCore.Imagination:Begin(16 * 2, self.TestSARegister, self)
  end
end

function LoliSrvTest:TestSAAuth()
  local PackAuth =
  {
    ProcId = "Auth",
    Account = string.format("account_%s", self.TestConnectPushCount),
    Password = string.format("password_%s", self.TestConnectPushCount),
  }
  for k, v in pairs(self.TestConnectNets) do
    LoliCore.Net:PushPackage(k, PackAuth)
  end
  self.TestConnectPushCount = self.TestConnectPushCount + 1
  if self.TestConnectPushCount >= 1 then
    --LoliCore.Avatar:Detach()
    --debug.debug()
    self.TestConnectPushCount = 0
  else
    LoliCore.Imagination:Begin(16 * 2, self.TestSAAuth, self)
  end
end

function LoliSrvTest:TestGSSConnect()
  local Id = assert(LoliCore.Net:Connect("127.0.0.1", 7200, self.TestConnectEventFuncs))
  self.TestConnectNets[Id] = Id
  self.TestConnectCount = self.TestConnectCount + 1
  if self.TestConnectCount >= 1 then
    LoliCore.Imagination:Begin(16, self.TestGSSRequestSetEx, self)
  else
    LoliCore.Imagination:Begin(16, self.TestGSSConnect, self)
  end
end

function LoliSrvTest:TestGSSRequestSetEx()
  local RequestSetExPack =
  {
    ProcId = "RequestSetEx",
    SoulId = 1,
    Conds =
    {
      xixi = 0,
      haha = 0,
      hehe = 0,
    },
    Values =
    {
      xixi = 1,
      haha = 2,
      hehe = 3,
    },
  }
  for k, v in pairs(self.TestConnectNets) do
    LoliCore.Net:PushPackage(k, RequestSetExPack)
  end
  self.TestConnectPushCount = self.TestConnectPushCount + 1
  if self.TestConnectPushCount >= 1 then
    LoliCore.Imagination:Begin(16 * 2, self.TestGSSRequestGetEx, self)
    self.TestConnectPushCount = 0
  else
    LoliCore.Imagination:Begin(16 * 2, self.TestGSSRequestSetEx, self)
  end
end

function LoliSrvTest:TestGSSRequestGetEx()
  local RequestGetExPack =
  {
    ProcId = "RequestGetEx",
    SoulId = 1,
    Conds =
    {
      xixi = 0,
      haha = 0,
      hehe = 0,
    },
  }
  for k, v in pairs(self.TestConnectNets) do
    LoliCore.Net:PushPackage(k, RequestGetExPack)
  end
  self.TestConnectPushCount = self.TestConnectPushCount + 1
  if self.TestConnectPushCount >= 1 then
    LoliCore.Imagination:Begin(16 * 2, self.TestGSSRequestLock, self)
    self.TestConnectPushCount = 0
  else
    LoliCore.Imagination:Begin(16 * 2, self.TestGSSRequestGetEx, self)
  end
end
function LoliSrvTest:TestGSSRequestLock()
  local RequestLockPack =
  {
    ProcId = "RequestLock",
    SoulId = 1,
  }
  for k, v in pairs(self.TestConnectNets) do
    LoliCore.Net:PushPackage(k, RequestLockPack)
  end
  self.TestConnectPushCount = self.TestConnectPushCount + 1
  if self.TestConnectPushCount >= 1 then
    LoliCore.Imagination:Begin(16 * 2, self.TestGSSRequestGet, self)
    self.TestConnectPushCount = 0
  else
    LoliCore.Imagination:Begin(16 * 2, self.TestGSSRequestLock, self)
  end
end

function LoliSrvTest:TestGSSRequestGet()
  local RequestGetPack =
  {
    ProcId = "RequestGet",
    SoulId = 1,
    LockKey = 1991,
  }
  for k, v in pairs(self.TestConnectNets) do
    LoliCore.Net:PushPackage(k, RequestGetPack)
  end
  self.TestConnectPushCount = self.TestConnectPushCount + 1
  if self.TestConnectPushCount >= 1 then
    LoliCore.Imagination:Begin(16 * 2, self.TestGSSRequestSet, self)
    self.TestConnectPushCount = 0
  else
    LoliCore.Imagination:Begin(16 * 2, self.TestGSSRequestGet, self)
  end
end

function LoliSrvTest:TestGSSRequestSet()
  local RequestSetPack =
  {
    ProcId = "RequestSet",
    SoulId = 1,
    LockKey = 1991,
    Field = "State",
    Value = 1,
  }
  for k, v in pairs(self.TestConnectNets) do
    LoliCore.Net:PushPackage(k, RequestSetPack)
  end
  self.TestConnectPushCount = self.TestConnectPushCount + 1
  if self.TestConnectPushCount >= 1 then
    LoliCore.Imagination:Begin(16 * 2, self.TestGSSRequestUnlock, self)
    self.TestConnectPushCount = 0
  else
    LoliCore.Imagination:Begin(16 * 2, self.TestGSSRequestSet, self)
  end
end

function LoliSrvTest:TestGSSRequestUnlock()
  local RequestUnlockPack =
  {
    ProcId = "RequestUnlock",
    SoulId = 1,
    LockKey = 1991,
  }
  for k, v in pairs(self.TestConnectNets) do
    LoliCore.Net:PushPackage(k, RequestUnlockPack)
  end
  self.TestConnectPushCount = self.TestConnectPushCount + 1
  if self.TestConnectPushCount >= 1 then
    LoliCore.Imagination:Begin(16 * 2, self.TestGSSRequestLockAndGet, self)
    self.TestConnectPushCount = 0
  else
    LoliCore.Imagination:Begin(16 * 2, self.TestGSSRequestUnlock, self)
  end
end

function LoliSrvTest:TestGSSRequestLockAndGet()
  local RequestLockAndGetPack =
  {
    ProcId = "RequestLockAndGet",
    SoulId = 1,
    Field = "State",
  }
  for k, v in pairs(self.TestConnectNets) do
    LoliCore.Net:PushPackage(k, RequestLockAndGetPack)
  end
  self.TestConnectPushCount = self.TestConnectPushCount + 1
  if self.TestConnectPushCount >= 1 then
    LoliCore.Imagination:Begin(16 * 2, self.TestGSSRequestSetAndUnlock, self)
    self.TestConnectPushCount = 0
  else
    LoliCore.Imagination:Begin(16 * 2, self.TestGSSRequestLockAndGet, self)
  end
end

function LoliSrvTest:TestGSSRequestSetAndUnlock()
  local RequestSetAndUnlockPack =
  {
    ProcId = "RequestSetAndUnlock",
    SoulId = 1,
    LockKey = 1992, --I Planned About This
    Field = "Name",
    Value = "Chamz Lau",
  }
  for k, v in pairs(self.TestConnectNets) do
    LoliCore.Net:PushPackage(k, RequestSetAndUnlockPack)
  end
  self.TestConnectPushCount = self.TestConnectPushCount + 1
  if self.TestConnectPushCount >= 1 then
    LoliCore.Imagination:Begin(16 * 2, self.TestGSSRequestClose, self)
    self.TestConnectPushCount = 0
  else
    LoliCore.Imagination:Begin(16 * 2, self.TestGSSRequestSetAndUnlock, self)
  end
end

function LoliSrvTest:TestGSSRequestClose()
  local RequestClosePack =
  {
    ProcId = "RequestClose",
  }
  for k, v in pairs(self.TestConnectNets) do
    LoliCore.Net:PushPackage(k, RequestClosePack)
  end
  self.TestConnectPushCount = self.TestConnectPushCount + 1
  if self.TestConnectPushCount >= 1 then
    debug.debug()
    self.TestConnectPushCount = 0
  else
    debug.debug()
  end
end

function LoliSrvTest:TestGodRequestConnect()
  local Id = assert(LoliCore.Net:Connect("127.0.0.1", 7700, self.TestConnectEventFuncs))
  self.TestConnectNets[Id] = Id
  self.TestConnectCount = self.TestConnectCount + 1
  if self.TestConnectCount >= 1 then
    LoliCore.Imagination:Begin(16, self.TestGodRequestQuerySouler, self)
  else
    LoliCore.Imagination:Begin(16, self.TestGodRequestConnect, self)
  end
end

function LoliSrvTest:TestGodRequestQuerySouler()
  local RequestQuerySoulerPack =
  {
    ProcId = "RequestQuerySouler",
    SoulId = 1,
  }
  for k, v in pairs(self.TestConnectNets) do
    LoliCore.Net:PushPackage(k, RequestQuerySoulerPack)
  end
  self.TestConnectPushCount = self.TestConnectPushCount + 1
  if self.TestConnectPushCount >= 1 then
    LoliCore.Imagination:Begin(16 * 2, self.TestGodRequestCreateSouler, self)
    self.TestConnectPushCount = 0
  else
    LoliCore.Imagination:Begin(16 * 2, self.TestGodRequestQuerySouler, self)
  end
end

function LoliSrvTest:TestGodRequestCreateSouler()
  local RequestCreateSoulerPack =
  {
    ProcId = "RequestCreateSouler",
    SoulId = 1,
    SoulInfo = 
    {
      Sex = 1,
      Job = 110,
      Name = "Chamz",
      GovId = 1,
    },
  }
  for k, v in pairs(self.TestConnectNets) do
    LoliCore.Net:PushPackage(k, RequestCreateSoulerPack)
  end
  self.TestConnectPushCount = self.TestConnectPushCount + 1
  if self.TestConnectPushCount >= 1 then
    LoliCore.Imagination:Begin(16 * 2, self.TestGodRequestDestroySouler, self)
    self.TestConnectPushCount = 0
  else
    LoliCore.Imagination:Begin(16 * 2, self.TestGodRequestCreateSouler, self)
  end
end

function LoliSrvTest:TestGodRequestDestroySouler()
  local RequestDestroySoulerPack =
  {
    ProcId = "RequestDestroySouler",
    SoulId = 1,
  }
  for k, v in pairs(self.TestConnectNets) do
    LoliCore.Net:PushPackage(k, RequestDestroySoulerPack)
  end
  self.TestConnectPushCount = self.TestConnectPushCount + 1
  if self.TestConnectPushCount >= 1 then
    LoliCore.Imagination:Begin(16 * 2, self.TestGodRequestSelectSouler, self)
    self.TestConnectPushCount = 0
  else
    LoliCore.Imagination:Begin(16 * 2, self.TestGodRequestDestroySouler, self)
  end
end

function LoliSrvTest:TestGodRequestSelectSouler()
  local RequestSelectSoulerPack =
  {
    ProcId = "RequestSelectSouler",
    SoulId = 1,
  }
  for k, v in pairs(self.TestConnectNets) do
    LoliCore.Net:PushPackage(k, RequestSelectSoulerPack)
  end
  self.TestConnectPushCount = self.TestConnectPushCount + 1
  if self.TestConnectPushCount >= 1 then
    LoliCore.Imagination:Begin(16 * 2, self.TestGodRequestSetEx, self)
    self.TestConnectPushCount = 0
  else
    LoliCore.Imagination:Begin(16 * 2, self.TestGodRequestSelectSouler, self)
  end
end

function LoliSrvTest:TestGodRequestSetEx()
  local RequestSetExPack =
  {
    ProcId = "RequestSetEx",
    SoulId = 1,
    Conds =
    {
      xixi = 0,
      haha = 0,
      hehe = 0,
    },
    Values =
    {
      xixi = 1,
      haha = 2,
      hehe = 3,
    },
  }
  for k, v in pairs(self.TestConnectNets) do
    LoliCore.Net:PushPackage(k, RequestSetExPack)
  end
  self.TestConnectPushCount = self.TestConnectPushCount + 1
  if self.TestConnectPushCount >= 1 then
    LoliCore.Imagination:Begin(16 * 2, self.TestGodRequestGetEx, self)
    self.TestConnectPushCount = 0
  else
    LoliCore.Imagination:Begin(16 * 2, self.TestGodRequestSetEx, self)
  end
end

function LoliSrvTest:TestGodRequestGetEx()
  local RequestGetExPack =
  {
    ProcId = "RequestGetEx",
    SoulId = 1,
    Conds =
    {
      xixi = 0,
      haha = 0,
      hehe = 0,
    },
  }
  for k, v in pairs(self.TestConnectNets) do
    LoliCore.Net:PushPackage(k, RequestGetExPack)
  end
  self.TestConnectPushCount = self.TestConnectPushCount + 1
  if self.TestConnectPushCount >= 1 then
    LoliCore.Imagination:Begin(16 * 2, self.TestGodRequestClose, self)
    self.TestConnectPushCount = 0
  else
    LoliCore.Imagination:Begin(16 * 2, self.TestGodRequestGetEx, self)
  end
end

function LoliSrvTest:TestGodRequestClose()
  local RequestClosePack =
  {
    ProcId = "RequestClose",
  }
  for k, v in pairs(self.TestConnectNets) do
    LoliCore.Net:PushPackage(k, RequestClosePack)
  end
  self.TestConnectPushCount = self.TestConnectPushCount + 1
  if self.TestConnectPushCount >= 1 then
    debug.debug()
    self.TestConnectPushCount = 0
  else
    debug.debug()
  end
end

LoliSrvTest:Main()
