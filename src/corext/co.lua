--
-- LoliCore
-- Chamz Lau
-- 2013/03/02 23:27:09
--

assert(_VERSION ~= "Lua 5.1", "lolita.corext Need Lua5.2+")
local bGetManifest = select(1, ...)

local Manifest =
{
  "cobasext.lua",
  "coioext.lua",
  "coosext.lua",
  "coimext.lua",
  "conext.lua",
  "coconfext.lua",
  "coavext.lua",
  "coext.lua",
}

local function LoliCore()
  local s = 0
  local e = nil
  local laste = nil
  local corextpath
  local avatarpath
  -- TODO 接口根据文件名获取路径名,或者能直接在C里面处理了直接export出来
  assert(core.arg.corext)
  while 1 do
    s, e = string.find(core.arg.corext, "/", s + 1)
    if not s then break end
    laste = e - 1
  end
  if laste then
    corextpath = string.sub(core.arg.corext, 1, laste)
  else
    corextpath = "."
  end
  core.arg.corextpath = corextpath

  --LoliCore.Avatar to process this
  if core.arg.avatar then
    s = 0
    while 1 do
      s, e = string.find(core.arg.avatar, "/", s + 1)
      if not s then break end
      laste = e - 1
    end
    if laste then
      avatarpath = string.sub(core.arg.avatar, 1, laste)
    else
      avatarpath = "."
    end
    core.arg.avatarpath = avatarpath
end

  for _, fn in ipairs(Manifest) do
    dofile(corextpath .. "/" .. fn)
  end

  if core.arg.avatar then
    local AvManifest = assert(dofile(core.arg.avatar))
    for _, fn in ipairs(AvManifest) do
      dofile(avatarpath .. "/" .. fn)
    end
  end
end

if bGetManifest then
  return Manifest
else
  LoliCore()
end

--LoliCore:Extend()
--LoliCore.Avatar:Attach()
