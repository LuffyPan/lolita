--
-- LoliCore IO Extend
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/04/10 23:33:07
--

local Io = LoliCore:NewExtend("Io")

function Io:Extend()
  self.LogId = 1
  self.Logs = {}
  print("Io Extended")
end

local function Serialize(Obj)
  local S = ""
  if type(Obj) == "number" then
    S = S .. tostring(Obj)
  elseif type(Obj) == "string" then
    S = S .. string.format("%q", Obj)
  elseif type(Obj) == "table" then
    S = S .. "{\n"
    for k, v in pairs(Obj) do
      S = S .. string.format("[%s] = %s,\n", Serialize(k), Serialize(v))
    end
    S = S .. "}"
  else
    assert(0, string.format("Can not Serialize a Obj %s", type(Obj)))
  end
  return S
end

function Io:Serialize(ObjTable)
  assert(type(ObjTable) == "table", string.format("Must be a Table, But Give a %s", type(ObjTable)))
  return "return \n" .. Serialize(ObjTable)
end

function Io:Deserialize(ObjStr)
  local Fn = assert(load(ObjStr, nil, "t", {}))
  local ObjTable = Fn()
  assert(type(ObjTable) == "table", "Must be a String Represent Table. Please Check")
  return ObjTable
end

function Io:LoadFile(Path)
  local Fn, E = loadfile(Path, "t", {})
  return Fn and Fn() or nil, E
end

function Io:SaveFile(Table, Path)
  local Seria = LoliCore.Io:Serialize(Table)
  if not Seria then return nil, "Serialize Failed" end
  local Fh, e = LoliCore.Io:OpenFile(Path, "wb")
  if not Fh then return Fh, e end
  local r
  r, e = LoliCore.Io:WriteFile(Fh, Seria)
  if not r then LoliCore.Io:CloseFile(Fh) return r, e end
  LoliCore.Io:CloseFile(Fh)
  return 1
end

function Io:OpenFile(Path, Mode)
  return io.open(Path, Mode)
end

function Io:CloseFile(Fh)
  Fh:close()
end

function Io:ReadFile(Fh, ...)
  return Fh:read(...)
end

function Io:WriteFile(Fh, ...)
  return Fh:write(...)
end

-- Log
function Io:OpenLog(Path)
  local Fh, e = self:OpenFile(Path, "wb")
  if not Fh then return Fh, e end
  local Logh = {}
  Logh.Id = self.LogId
  Logh.Fh = Fh
  self.Logs[self.LogId] = Logh
  self.LogId = self.LogId + 1
  return Logh
end

function Io:CloseLog(Logh)
  local Logh2 = assert(self.Logs[Logh.Id])
  assert(Logh == Logh2)
  self:CloseFile(Logh.Fh)
  self.Logs[Logh.Id] = nil
end

function Io:Log(Logh, fmt, ...)
  local l = string.format(fmt, ...)
  print(l)
  Io:WriteFile(Logh.Fh, os.date(), " ", l, "\n")
end

print("Io Compile")
