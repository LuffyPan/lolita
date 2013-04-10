--
-- LoliCore Net Extend
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/04/08 18:14:35
--

LoliCore.Net = {}

local core = core
local Io = LoliCore.Io
local Net = LoliCore.Net

function Net:Extend()
  --core Export This
  core.net.ids = {} --Only Compatible
  self.Ids = {} --core Should Export this
  self.States = {}
end

function Net:Connect(Addr, Port)
  local Id = core.net.connect(Addr, Port)
  if Id then
    self.States[Id] =
    {
      Id = Id,
      IsConnector = 1,
    }
  end
  return Id
end

function Net:Listen(Addr, Port)
  local Id = core.net.listen(Addr, Port)
  if Id then
    self.States[Id] =
    {
      IsConnector = 0,
    }
  end
  return Id
end

function Net:PushPackage(Id, Pack)
  --Modify core, only Id is enought, hide the attaid
  local S = Io.Serialize(Pack)
  return core.net.push(Id, 0, S)
end

function Net:Close(Id)
  self.States[Id] = nil
  return core.net.close(Id, 0)
end

function Net:Active()
  core.net.active()
end

Net:Extend()
print("LoliCore.Net Extended")
