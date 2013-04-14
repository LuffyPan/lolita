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
  self.TestListenNets = {}
  self.TestConnectNets = {}
  self.TestListenCount = 0
  self.TestConnectCount = 0
  self.TestConnectPushCount = 0
  self.TestCount = 0
  LoliCore.Imagination:Begin(8, self.TestListen, self)
end

function LoliSrvTest:TestListen()
  local Id = assert(LoliCore.Net:Listen("127.0.0.1", 8000 + self.TestListenCount))
  self.TestListenNets[Id] = 1
  if self.TestListenCount >= 20 then
    LoliCore.Imagination:Begin(4, self.TestConnect, self)
  else
    LoliCore.Imagination:Begin(4, self.TestListen, self)
    self.TestListenCount = self.TestListenCount + 1
  end
end

function LoliSrvTest:TestConnect()
  local Id = assert(LoliCore.Net:Connect("127.0.0.1", 8000 + self.TestConnectCount))
  self.TestConnectNets[Id] = 1
  if self.TestConnectCount >= 20 then
    LoliCore.Imagination:Begin(4, self.TestPushPackage, self)
  else
    LoliCore.Imagination:Begin(4, self.TestConnect, self)
    self.TestConnectCount = self.TestConnectCount + 1
  end
end

function LoliSrvTest:TestPushPackage()
  for k, v in pairs(self.TestConnectNets) do
    LoliCore.Net:PushPackage(k, {"hahahahahahaha"})
  end
  if self.TestConnectPushCount >= 20 then
    LoliCore.Imagination:Begin(4, self.TestClose, self)
  else
    LoliCore.Imagination:Begin(4, self.TestPushPackage, self)
    self.TestConnectPushCount = self.TestConnectPushCount + 1
  end
end

function LoliSrvTest:TestClose()
  for k, v in pairs(self.TestConnectNets) do
    LoliCore.Net:Close(k)
  end
  self.TestConnectNets = {}
  self.TestConnectCount = 0
  self.TestConnectPushCount = 0

  self.TestCount = self.TestCount + 1
  if self.TestCount >= 1000 then
    debug.debug()
    LoliCore.Avatar:Detach()
  else
    LoliCore.Imagination:Begin(4, self.TestConnect, self)
  end
  print(string.format("Mem:%u/%u", LoliCore.Base:GetMem()))
end

LoliSrvTest:Main()
