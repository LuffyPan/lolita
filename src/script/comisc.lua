--
--LoliCore script misc
--Chamz Lau, Copyright (C) 2013-2017
--2013/03/15 00:12:21
--

core.misc = {}
local misc = core.misc
local serialize
function serialize(o)
  local s = ""
  if type(o) == "number" then
    s = s .. tostring(o)
  elseif type(o) == "string" then
    s = s .. string.format("%q", o)
  elseif type(o) == "table" then
    s = s .. "{\n"
    for k, v in pairs(o) do
      s = s .. string.format("[%s] = %s,\n", serialize(k), serialize(v))
    end
    s = s .. "}"
  else
    assert(0, "cannot serialize a" .. type(o))
  end
  return s
end

function misc:serialize(tbdata)
  assert(type(tbdata) == "table", "cannot serialize a " .. type(tbdata))
  return "return \n" .. serialize(tbdata)
end

function misc:deserialize(sdata)
  local f = assert(load(sdata, nil, "t", {["print"] = print})) --just a joke!
  local tbdata = f()
  assert(type(tbdata) == "table", "sdata is not a table")
  return tbdata
end