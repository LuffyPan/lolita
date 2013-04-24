--
-- Main Logic
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/04/25 00:18:50
--

LoliSrvGSS.Logic = {}

local Logic = LoliSrvGSS.Logic
local SrvNet = LoliSrvGSS.SrvNet

function Logic:Init()
  SrvNet:RegisterLogic(self:__GetLogic(), self)
end

function Logic:OnRequestLock(Srv)
  print("OnRequestLock")
end

function Logic:OnRequestGet(Srv)
  print("OnRequestGet")
end

function Logic:OnRequestSet(Srv)
  print("OnRequestSet")
end

function Logic:__GetLogic()
  if self.__Logic then return self.__Logic end
  self.__Logic =
  {
    RequestLock = self.OnRequestLock,
    RequestGet = self.OnRequestGet,
    RequestSet = self.OnRequestSet,
  }
  return self.__Logic
end