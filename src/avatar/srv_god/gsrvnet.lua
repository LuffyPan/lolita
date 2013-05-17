--
-- God's Server Nets
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/05/17 13:43:20
--

LoliSrvGod.SrvNet = {}

local SrvNet = LoliSrvGod.SrvNet

-- Add Session to extend logic process
function SrvNet:Init()
  self.Srvs = {}
  self.LogicFuncs = {}
  self.LogicFuncParam = nil
  self.Id = assert(LoliCore.Net:Listen("", 7700, self:__GetEventFuncs()))
end

function SrvNet:UnInit()
  -- Is not supported very good.. ToDo
  assert()
end

function SrvNet:RegisterLogic(LogicFuncs, LogicParam)
  for k, v in pairs(LogicFuncs) do
    self.LogicFuncs[k] = v
  end
  self.LogicParam = LogicParam
end

function SrvNet:PushPackage(Srv, Pack)
  if not LoliCore.Net:PushPackage(Srv.SrvId, Pack) then
    -- May be full, Close it.
    assert(LoliCore.Net:Close(Srv.SrvId))
  end
  return 1
end

function SrvNet:EventAccept(SrvId)
  assert(not self.Srvs[SrvId])
  local Srv =
  {
    SrvId = SrvId,
  }
  self.Srvs[SrvId] = Srv
  local Fn = self.LogicFuncs.Accept
  if not Fn then return end
  local R, E = pcall(Fn, self.LogicParam, Srv)
  if not R then
    print(E)
  end
end

function SrvNet:EventPackage(SrvId, Pack)
  local Srv = assert(self.Srvs[SrvId])
  local Fn = self.LogicFuncs[Pack.ProcId]
  if not Fn then
    --Log this
    assert()
    return
  end
  Pack.Result = 0
  Pack.ErrorCode = 0
  Srv.Pack = Pack
  local R, E = pcall(Fn, self.LogicParam, Srv)
  if not R then
    print(E)
  end
  self:PushPackage(Srv, Srv.Pack)
  Srv.Pack = nil
end

function SrvNet:EventClose(SrvId)
  if SrvId == self.Id then
    --ToDo
    return
  end
  local Srv = assert(self.Srvs[SrvId])
  self.Srvs[SrvId] = nil
  local Fn = self.LogicFuncs.Close
  if not Fn then return end
  local R, E = pcall(Fn, self.LogicParam, Srv)
  if not R then
    print(E)
  end
end

function SrvNet:__GetEventFuncs()
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
