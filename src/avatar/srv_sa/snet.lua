--
-- Souler Net
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/04/23 15:23:34
--

LoliSrvSA.SoulerNet = {}

local SoulerNet = LoliSrvSA.SoulerNet

function SoulerNet:Init()
  self.LogicFuncs = {}
  self.LogicFuncParam = nil
  self.Id = assert(LoliCore.Net:Listen("", 7100, self:__GetEventFuncs()))
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

function SoulerNet:EventAccept(Id)
  local Souler = assert(SoulerMgr:New(Id))
  local Fn = self.LogicFuncs.Accept
  if Fn then
    local r, e = pcall(Fn, self.LogicParam, Souler)
    if not r then
      print(e)
    end
  end
end

function SoulerNet:EventPackage(Id, Pack)
  local Souler = assert(SoulerMgr:GetById(Id))
  local Fn = self.LogicFuncs[Pack.ProcId]
  if Fn then
    Souler.Pack = Pack
    local r, e = pcall(Fn, self.LogicParam, Souler)
    if not r then
      print(e)
    end
    Souler.Pack = nil
  else
    --Log this
  end
end

function SoulerNet:EventClose(Id)
  if Id == self.Id then
    --ToDo
  else
    local Souler = assert(SoulerMgr:GetById(Id))
    local Fn = self.LogicFuncs.Close
    if Fn then
      local r, e = pcall(Fn, self.LogicParam, Souler)
      if not r then
        print(e)
      end
    end
    SoulerMgr:Delete(Id)
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
