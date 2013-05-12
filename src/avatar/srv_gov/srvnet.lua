--
-- Goverment's SoulerAgency Server Net
-- SoulerAgency Connects
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/04/28 13:46:21
--

LoliSrvGoverment.SrvNet = {}

local SrvNet = LoliSrvGoverment.SrvNet
local SrvMgr = LoliSrvGoverment.SrvMgr

function SrvNet:Init()
  self.LogicFuncs = {}
  self.LogicFuncParam = nil
  self.Id = assert(LoliCore.Net:Listen("", 7300, self:__GetEventFuncs()))
end

function SrvNet:UnInit()
  -- Is Not Supported Very Good.. So ToDo
  assert()
end

function SrvNet:RegisterLogic(LogicFuncs, LogicParam)
  for k, v in pairs(LogicFuncs) do
    self.LogicFuncs[k] = v
  end
  self.LogicParam = LogicParam
end

function SrvNet:PushPackage(Srv, Pack)
  if not LoliCore.Net:PushPackage(Srv.Id, Pack) then
    -- May Be Full, Close It
    assert(LoliCore.Net:Close(Srv.Id))
  end
  return 1
end

function SrvNet:EventAccept(Id)
  local Srv = assert(SrvMgr:New(Id))
  local Fn = self.LogicFuncs.Accept
  if not Fn then return end
  local r, e = pcall(Fn, self.LogicParam, Srv)
  if not r then
    print(e)
  end
end

function SrvNet:EventPackage(Id, Pack)
  local Srv = assert(SrvMgr:GetById(Id))
  local Fn = self.LogicFuncs[Pack.ProcId]
  if not Fn then
    -- Log this
    return
  end
  Srv.Pack = Pack
  local r, e = pcall(Fn, self.LogicParam, Srv)
  if not r then
    print(e)
  end
  self:PushPackage(Srv, Srv.Pack)
  Srv.Pack = nil
end

function SrvNet:EventClose(Id)
  if Id == self.Id then
    -- ToDo
    return
  end
  local Srv = assert(SrvMgr:GetById(Id))
  local Fn = self.LogicFuncs.Close
  if not Fn then return end
  local r, e = pcall(Fn, self.LogicParam, Srv)
  if not r then
    print(e)
  end
  SrvMgr:Delete(Id)
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
