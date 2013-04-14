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

print("LoliCore.Io Extended")
