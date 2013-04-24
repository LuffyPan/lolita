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

LoliSrvTest:Main()
