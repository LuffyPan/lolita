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
  self.EventFunc =
  {
    [110] = self.EventConnect,
    [111] = self.EventAccept,
    [112] = self.EventPackage,
    [113] = self.EventClose,
  } --Yes, It is Magic Num, So What ?
  core.net.register(Net.Event, self)
end

function Net:Connect(Addr, Port, EventFuncs)
  assert(EventFuncs)
  local Id = core.net.connect(Addr, Port)
  if Id then
    self.States[Id] =
    {
      Id = Id,
      IsConnector = 1,
      Attached2Id = 0,
      EventFuncs = EventFuncs,
    }
  end
  return Id
end

function Net:Listen(Addr, Port, EventFuncs)
  assert(EventFuncs)
  local Id = core.net.listen(Addr, Port)
  if Id then
    self.States[Id] =
    {
      Id = Id,
      IsConnector = 0,
      Attached2Id = 0,
      EventFuncs = EventFuncs,
    }
  end
  return Id
end

function Net:PushPackage(Id, Pack)
  --Modify core, only Id is enought, hide the attaid
  local State = assert(self.States[Id])
  local S = Io:Serialize(Pack)
  if State.Attached2Id > 0 then
    return core.net.push(State.Attached2Id, Id, S)
  else
    return core.net.push(Id, 0, S)
  end
end

function Net:GetInfo(Id)
  local State = assert(self.States[Id])
  if State.Attached2Id > 0 then
    return core.net.getinfo(State.Attached2Id, Id)
  else
    return core.net.getinfo(Id, 0)
  end
end

function Net:Close(Id)
  local State = assert(self.States[Id])
  if State.Attached2Id > 0 then
    return core.net.close(State.Attached2Id, Id)
  else
    return core.net.close(Id, 0)
  end
end

function Net:Active()
  core.net.active()
end

function Net:Event(EventType, Id, AttachId, Extra)
  print(string.format("Net Event[%d], Id[%d], AttachId[%d]", EventType, Id, AttachId))
  assert(self.EventFunc[EventType], "Wow, Fuck Invalid Event Type?")(self, Id, AttachId, Extra)
end

function Net:EventConnect(Id, AttachId, Extra)
  assert(0 == AttachId)
  assert(Extra)
  local State = assert(self.States[Id])
  --Call Logic
  assert(State.EventFuncs.Connect)(State.EventFuncs.Param, Id, Extra)
end

function Net:EventAccept(Id, AttachId, Extra)
  assert(AttachId > 0)
  assert(nil == Extra)
  local State = assert(self.States[Id])
  assert(not self.States[AttachId])
  local AttachState =
  {
    Id = AttachId,
    IsConnector = 0,
    Attached2Id = Id,
  }
  self.States[AttachId] = AttachState
  --Call Logic
  assert(State.EventFuncs.Accept)(State.EventFuncs.Param, AttachId)
end

function Net:EventPackage(Id, AttachId, Extra)
  local State = assert(self.States[Id])
  local Pack = assert(Io:Deserialize(Extra))
  if AttachId > 0 then
    local AttachState = assert(self.States[AttachId])
    --Call Logic
    assert(State.EventFuncs.Package)(State.EventFuncs.Param, AttachId, Pack)
  else
    --Call Logic
    assert(State.EventFuncs.Package)(State.EventFuncs.Param, Id, Pack)
  end
end

function Net:EventClose(Id, AttachId, Extra)
  local State = assert(self.States[Id])
  if AttachId > 0 then
    --Call Logic
    assert(State.EventFuncs.Close)(State.EventFuncs.Param, AttachId)
    self.States[AttachId] = nil
  else
    --Call Logic
    assert(State.EventFuncs.Close)(State.EventFuncs.Param, Id)
    self.States[Id] = nil
  end
end

Net:Extend()
print("LoliCore.Net Extended")
