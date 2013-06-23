--
-- LoliCore Imagination Extend
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/04/08 17:57:58
--

local Imagination = LoliCore:NewExtend("Imagination")

function Imagination:Extend()
  self.NextId = 1
  self.Ims = {}
  self.ClosedIms = {}
  self.LastTime = Imagination.GetTime()
  self.ImCount = 0
  print("Imagination Extended")
end

function Imagination:GetTime()
  return LoliCore.Os.GetTime()
end

function Imagination:Begin(ImCount, Fn, FnParam)
  local Id = self.NextId
  local Im =
  {
    Id = Id,
    ImCount = self.ImCount + ImCount,
    Fn = Fn,
    FnParam = FnParam,
    IsClosed = 0,
  }
  self.Ims[Id] = Im
  self.NextId = self.NextId + 1
  return Id
end

function Imagination:End(Id)
  local Im = self.Ims[Id]
  assert(Im, string.format("Invalid Imagination Id[%d]", Id))
  Im.IsClosed = 1
  table.insert(self.ClosedIms, Im)
end

function Imagination:EndAll()
  for k, v in pairs(self.Ims) do
    self:End(k)
  end
end

function Imagination:Active()
  local Cur = self.GetTime()
  local Elapse = Cur - self.LastTime
  if Elapse > 1 / 16 then
    self.ImCount = Imagination.ImCount + 1
    self.LastTime = Cur
  end

  if #self.ClosedIms > 0 then
    for _, v in ipairs(self.ClosedIms) do
      --self.Ims's Timer is not be cleared!! memleak
      self.Ims[v.Id] = nil
    end
    self.ClosedIms = {}
  end

  for k, v in pairs(self.Ims) do
    if self.ImCount >= v.ImCount and v.IsClosed == 0 then
      --Todo:pcall ?
      v.Fn(v.FnParam, v)
      v.IsClosed = 1
      table.insert(self.ClosedIms, v)
    end
  end
end

print("Imagination Compile")
