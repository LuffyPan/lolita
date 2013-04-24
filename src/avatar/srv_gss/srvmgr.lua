--
-- Server Manager
-- Other Server's Connects Manager
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/04/24 21:56:34
--

LoliSrvGSS.SrvMgr = {}

local SrvMgr = LoliSrvGSS.SrvMgr

function SrvMgr:Init()
  self.Srvs = {}
end

function SrvMgr:New(Id)
  assert(not self.Srvs[Id])
  local Srv =
  {
    Id = Id,
  }
  self.Srvs[Id] = Srv  
  return Srv  
end

function SrvMgr:Delete(Id)
  assert(self.Srvs[Id])
  self.Srvs[Id] = nil
end

function SrvMgr:GetById(Id)
  return self.Srvs[Id]
end

