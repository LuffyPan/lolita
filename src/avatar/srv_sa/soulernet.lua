--
-- Client Net
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/04/23 15:23:34
--

LoliSrvSa.SoulerNet = {}

local SoulerNet = LoliSrvSa.SoulerNet

function SoulerNet:Init()
  self.LogicFuncs = {}
  self.LogicFuncParam = nil
  self.NetId = assert(LoliCore.Net:Listen("", 7100, self:__GetEventFuncs()))
end

function SoulerNet:UnInit()
  -- Is not supported very good
  assert()
end

function SoulerNet:RegisterLogic(LogicFuncs, LogicParam)
  for k, v in pairs(LogicFuncs) do
    self.LogicFuncs[k] = v
  end
  self.LogicParam = LogicParam
end

function SoulerNet:PushPackage(NetId, Pack)
  if not LoliCore.Net:PushPackage(NetId, Pack) then
    --May be full, Close it.
    assert(LoliCore.Net:Close(NetId))
    return
  end
  return 1
end

function SoulerNet:EventAccept(NetId)
  local Fn = self.LogicFuncs.Accept
  if Fn then
    local R, E = pcall(Fn, self.LogicParam, NetId)
    if not R then
      print(E)
    end
  end
end

function SoulerNet:EventPackage(NetId, Pack)
  local Fn = self.LogicFuncs[Pack.ProcId]
  if Fn then
    Pack.Result = 0
    Pack.ErrorCode = 0
    local R, E = pcall(Fn, self.LogicParam, NetId, Pack)
    if not R then
      print(E)
    end
  else
    --Log this
  end
end

function SoulerNet:EventClose(NetId)
  if NetId == self.NetId then
    --ToDo
  else
    local Fn = self.LogicFuncs.Close
    if Fn then
      local R, E = pcall(Fn, self.LogicParam, NetId)
      if not R then
        print(E)
      end
    end
  end
end

function SoulerNet:__GetEventFuncs()
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
