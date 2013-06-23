--
-- LoliCore
-- Chamz Lau
-- 2013/03/02 23:27:09
--

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

  for _, fn in ipairs(Manifest) do
    dofile(corextpath .. "/" .. fn)
  end

  local AvManifest = assert(dofile(core.arg.avatar))
  for _, fn in ipairs(AvManifest) do
    dofile(avatarpath .. "/" .. fn)
  end
end

if bGetManifest then
  return Manifest
else
  LoliCore()
end

--LoliCore:Extend()
--LoliCore.Avatar:Attach()
