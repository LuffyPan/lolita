--
-- LoliCore Net Extend
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/04/08 18:14:35
--

local Net = LoliCore:NewExtend("Net")

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
  print("Net Extended")
end

--仅仅是为了向前兼容，即将废弃
function Net:Connect(Addr, Port, EventFuncs)
  assert(EventFuncs)
  return self:ConnectEx(Addr, Port, {EventFuncs = EventFuncs})
end

--仅仅是为了向前兼容，即将废弃
function Net:Listen(Addr, Port, EventFuncs)
  assert(EventFuncs)
  return self:ListenEx(Addr, Port, {EventFuncs = EventFuncs})
end

function Net:ConnectEx(Addr, Port, Param)
  assert(Param)
  local Id = core.net.connect(Addr, Port)
  if not Id then return end
  assert(self:_New(Id, 1, 0, assert(Param)))
  return Id
end

function Net:ListenEx(Addr, Port, Param)
  assert(Param)
  local Id = core.net.listen(Addr, Port)
  if not Id then return end
  assert(self:_New(Id, 0, 0, assert(Param)))
  return Id
end

function Net:PushPackage(Id, Pack)
  --Modify core, only Id is enought, hide the attaid
  local State = self:_Get(Id)
  local S = LoliCore.Io:Serialize(Pack)
  if State.Attached2Id > 0 then
    return core.net.push(State.Attached2Id, Id, S)
  else
    return core.net.push(Id, 0, S)
  end
end

function Net:GetInfo(Id)
  local State = self:_Get(Id)
  if State.Attached2Id > 0 then
    return core.net.getinfo(State.Attached2Id, Id)
  else
    return core.net.getinfo(Id, 0)
  end
end

function Net:Close(Id)
  local State = self:_Get(Id)
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
  local fn = assert(self.EventFunc[EventType])
  local r, e = pcall(fn, self, Id, AttachId, Extra)
  if not r then
    print(e)
  end
end

function Net:EventConnect(Id, AttachId, Extra)
  assert(0 == AttachId)
  assert(Extra)
  local State = self:_Get(Id)
  if State.Procs then
    local fn = State.Procs.Connect
    if fn then
      fn(State.Procs.Param, State.Id, Extra)
    end
  else
    assert(State.EventFuncs.Connect)(State.EventFuncs.Param, State.Id, Extra)
  end
end

function Net:EventAccept(Id, AttachId, Extra)
  assert(AttachId > 0)
  assert(nil == Extra)
  local State = self:_Get(Id)
  local AttachState = self:_New(AttachId, 0, Id, {})
  if State.Procs then
    local fn = State.Procs.Accept
    if fn then
      fn(State.Procs.Param, AttachState.Id)
    else
      --TODO:没有注册AcceptProc，是否有必要Log一下
    end
  else
    assert(State.EventFuncs.Accept)(State.EventFuncs.Param, AttachState.Id)
  end
end

function Net:EventPackage(Id, AttachId, Extra)
  local State = self:_Get(Id)
  local AttachState = AttachId > 0 and self:_Get(AttachId) or nil
  local Pack = assert(LoliCore.Io:Deserialize(Extra))
  if State.Procs then
    --需要过滤一下关键字, Connect, Accept, Close, ProcParam
    local fn = State.Procs[Pack.ProcId]
    if not fn then
      --协议匹配是可以出现匹配不到的情况的，只需要纪录一下log并忽略处理则可。
      return
    end
    fn(State.Procs.Param, AttachState and AttachState.Id or State.Id)
  else
    assert(State.EventFuncs.Package)(State.EventFuncs.Param, AttachState and AttachState.Id or State.Id, Pack)
  end
  if State.SendBack then
    --自动回包
    self:PushPackage(AttachState and AttachState.Id or State.Id, Pack)
  end
end

function Net:EventClose(Id, AttachId, Extra)
  local State = self:_Get(Id)
  local AttachState = AttachId > 0 and self:_Get(AttachId) or nil
  if State.Procs then
    local fn = State.Procs.Close
    if fn then
      fn(State.Procs.Param, AttachState and AttachState.Id or State.Id)
    end
  else
    assert(State.EventFuncs.Close)(State.EventFuncs.Param, AttachState and AttachState.Id or State.Id)
  end
  self:_Delete(AttachState and AttachState.Id or State.Id)
end

function Net:_New(Id, IsConnector, Attached2Id, Param)
  assert(not self.States[Id])
  local x =
  {
    Id = assert(Id),
    IsConnector = assert(IsConnector),
    Attached2Id = assert(Attached2Id),
    EventFuncs = Param.EventFuncs,
    Procs = Param.Procs,
    SendBack = Param.SendBack,
  }
  self.States[Id] = x
  return x
end

function Net:_Get(Id)
  local x = assert(self.States[Id])
  assert(x.Id == Id)
  return x
end

function Net:_Delete(Id)
  local x = self:_Get(Id)
  self.States[x.Id] = nil
end

print("Net Compiled")
