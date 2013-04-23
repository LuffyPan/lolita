--
-- Souler Net
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/04/23 15:23:34
--

LoliSrvSA.SoulerNet = {}

local SoulerNet = LoliSrvSA.SoulerNet

function SoulerNet:Init()
  self.AttachIds = {}
  self.Id = assert(LoliCore.Net:Listen("", 7100, self:__GetEventFuncs()))
end

function SoulerNet:UnInit()
  -- Is not supported very good
  assert()
end

function SoulerNet:EventAccept(Id)
  assert(not self.AttachIds[Id])
  self.AttachIds[Id] = 1
end

function SoulerNet:EventPackage(Id, Pack)
  assert(self.AttachIds[Id])
end

function SoulerNet:EventClose(Id)
  if Id == self.Id then
    --ToDo
  else
    assert(self.AttachIds[Id])
    self.AttachIds[Id] = nil
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
