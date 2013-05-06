--
-- Goverment's Souler Manager
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/05/06 21:14:50
-- ToDo: A Common Souler Manager For All Server
--

LoliSrvGoverment.SoulerMgr = {}

local SoulerMgr = LoliSrvGoverment.SoulerMgr

function SoulerMgr:Init()
  self.Soulers = {}
end

function SoulerMgr:New(Id)
  assert(not self.Soulers[Id])
  local Souler =
  {
    Id = Id,
  }
  self.Soulers[Id] = Souler
  return Souler
end

function SoulerMgr:Delete(Id)
  self.Soulers[Id] = nil
end

function SoulerMgr:GetById(Id)
  return self.Soulers[Id]
end
