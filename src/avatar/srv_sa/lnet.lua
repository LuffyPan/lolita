--
-- Login Net
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/04/23 15:58:29
--

LoliSrvSA.LoginNet = {}

local LoginNet = LoliSrvSA.LoginNet

function LoginNet:Init()
  self.Connected = 0
  self.Id = assert(LoliCore.Net:Connect("127.0.0.1", 7000, self:__GetEventFuncs()))
end

function LoginNet:UnInit()
  if self.Id > 0 then LoliCore.Net:Close(self.Id) end
end

function LoginNet:EventConnect(Id, Result)
  assert(Id == self.Id)
  self.Connected = Result
end

function LoginNet:EventPackage(Id, Pack)
  assert(Id == self.Id)
end

function LoginNet:EventClose(Id)
  assert(Id == self.Id)
  self.Id = 0
  self.Connected = 0
end

function LoginNet:__GetEventFuncs()
  if self.__EventFuncs then return self.__EventFuncs end
  self.__EventFuncs =
  {
    Param = self,
    Connect = self.EventConnect,
    Package = self.EventPackage,
    Close = self.EventClose,
  }
  return self.__EventFuncs
end
