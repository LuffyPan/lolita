--
-- Global Souler State Manager
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/04/25 22:07:36

LoliSrvGSS.GMgr = {}

local GMgr = LoliSrvGSS.GMgr

function GMgr:Init()
  self.GSoulerStates = {}
  self.LockKey = 1991
end

function GMgr:Lock(SoulerId)
  assert(SoulerId)
  local g = assert(self:__GetGSoulerState(SoulerId))
  if g.LockKey > 0 then
    return nil, 1, "Locked By Other"
  end
  g.LockKey = self.LockKey
  self.LockKey = self.LockKey + 1
  return g.LockKey
end

function GMgr:Unlock(SoulerId, LockKey)
  assert(SoulerId)
  local g = assert(self:__GetGSoulerState(SoulerId))
  if g.LockKey ~= LockKey then
    return nil, 1, "LockKey Not Match"
  end
  g.LockKey = 0
  return 1
end

function GMgr:Get(SoulerId, LockKey, Field)
  assert(SoulerId)
  local g = assert(self:__GetGSoulerState(SoulerId))
  if g.LockKey ~= LockKey then
    return nil, 1, "LockKey Not Match"
  end
  -- 5.2 can index with nil!!
  local Value = g.Fields[Field] or 0
  return Value
end

function GMgr:Set(SoulerId, LockKey, Field, Value)
  assert(SoulerId)
  local g = assert(self:__GetGSoulerState(SoulerId))
  if g.LockKey ~= LockKey then
    return nil, 1, "LockKey Not Match"
  end
  g.Fields[Field] = Value
  return 1
end

function GMgr:__GetGSoulerState(SoulerId)
  local GSoulerState = self.GSoulerStates[SoulerId]
  GSoulerState = GSoulerState and GSoulerState or self:__NewGSoulerState(SoulerId)
  return GSoulerState
end

function GMgr:__NewGSoulerState(SoulerId)
  assert(not self.GSoulerStates[SoulerId])
  local GSoulerState = 
  {
    SoulerId = SoulerId,
    LockKey = 0,
    Fields = {},
  }
  self.GSoulerStates[SoulerId] = GSoulerState
  return GSoulerState
end
