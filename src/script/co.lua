--
-- LoliCore script
-- Chamz Lau
-- 2013/03/02 23:27:09
--

LoliCore = {}
LoliCore.ExtendManifest =
{
  "coext.lua",
  "coosext.lua",
  "coioext.lua",
  "coimext.lua",
  "conext.lua",
  "coavext.lua",
}

function LoliCore:Extend()
  local s = 0
  local e = nil
  local laste = nil
  local corepath
  local avatarpath
  while 1 do
    s, e = string.find(core.arg.core, "/", s + 1)
    if not s then break end
    laste = e - 1
  end
  if laste then
    corepath = string.sub(core.arg.core, 1, laste)
  else
    corepath = "."
  end
  core.arg.corepath = corepath

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

  for _, fn in ipairs(LoliCore.ExtendManifest) do
    dofile(corepath .. "/" .. fn)
  end
end

LoliCore:Extend()
LoliCore.Avatar:Attach()
