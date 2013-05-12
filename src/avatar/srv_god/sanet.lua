--
-- God's SoulerAgency Server Net
-- SoulerAgency Connects
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/05/06 21:46:45
--

LoliSrvGod.SANet = {}

local SANet = LoliSrvGod.SANet

function SANet:Init()
  self.SAStates = {}
  self.LogicFuncs = {}
  self.LogicFuncParam = nil
  self.Id = assert(LoliCore.Net:Listen("", 7700, self:__GetEventFuncs()))
end

function SANet:UnInit()
  -- Is Not Supported Very Good.. So ToDo
  assert()
end

function SANet:RegisterLogic(LogicFuncs, LogicParam)
  for k, v in pairs(LogicFuncs) do
    self.LogicFuncs[k] = v
  end
  self.LogicParam = LogicParam
end

function SANet:PushPackage(SAState, Pack)
  if not LoliCore.Net:PushPackage(SAState.Id, Pack) then
    -- May Be Full, Close It
    assert(LoliCore.Net:Close(SAState.Id))
  end
  return 1
end

function SANet:EventAccept(Id)
  assert(not self.SAStates[Id])
  self.SAStates[Id] = {Id = Id,}
  local SAState = self.SAStates[Id]
  local Fn = self.LogicFuncs.Accept
  if not Fn then return end
  local r, e = pcall(Fn, self.LogicParam, SAState)
  if not r then
    print(e)
  end
end

function SANet:EventPackage(Id, Pack)
  local SAState = assert(self.SAStates[Id])
  local Fn = self.LogicFuncs[Pack.ProcId]
  if not Fn then
    -- Log this
    return
  end
  SAState.Pack = Pack
  local r, e = pcall(Fn, self.LogicParam, SAState)
  if not r then
    print(e)
  end
  self:PushPackage(SAState, SAState.Pack)
  SAState.Pack = nil
end

function SANet:EventClose(Id)
  if Id == self.Id then
    -- ToDo
    return
  end
  local SAState = assert(self.SAStates[Id])
  local Fn = self.LogicFuncs.Close
  if not Fn then return end
  local r, e = pcall(Fn, self.LogicParam, SAState)
  if not r then
    print(e)
  end
  self.SAStates[Id] = nil
end

function SANet:__GetEventFuncs()
  if self.__EventFuncs then return self.__EventFuncs end
  self.__EventFuncs =
  {
    Param = self,
    Accept = self.EventAccept,
    Package = self.EventPackage,
    Close = self.EventClose,
  }
  return self.__EventFuncs
end
