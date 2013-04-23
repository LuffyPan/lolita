--
-- Souler Manager
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/04/23 18:49:16
--

LoliSrvSA.SoulerMgr = {}

local SoulerMgr = LoliSrvSA.SoulerMgr

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
