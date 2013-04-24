--
-- LoliCore IO Extend
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/04/10 23:33:07
--

LoliCore.Io = {}

local Io = LoliCore.Io

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
  assert(type(ObjTable) == "table", "Must be a Table, But Give a %s" .. type(ObjTable))
  return "return \n" .. Serialize(ObjTable)
end

function Io:Deserialize(ObjStr)
  local Fn = assert(load(ObjStr, nil, "t", {}))
  local ObjTable = Fn()
  assert(type(ObjTable) == "table", "Must be a String Represent Table. Please Check")
  return ObjTable
end

function Io:LoadFile(Path)
  local Fn = loadfile(Path, "t", {})
  return Fn and Fn() or nil
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

print("LoliCore.Io Extended")