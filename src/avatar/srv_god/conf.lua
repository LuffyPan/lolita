--
-- Lolita Server God's Configuration
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/06/14 13:03:02
--

local GodPre =
{
  RootPath = "data/god",
}

local God =
{

  SrvId = 1991,
  SrvName = "Godddddddd",
  SrvDesc = "GOD OF THE [Lolita] World",

  Ip = "",
  Port = 7700,

  RootPath = GodPre.RootPath,
  SoulerPath = GodPre.RootPath .. "/souler",

  -- All the [Server Login]'s Id
  Logins =
  {
    [2000] = {},
  },

  -- All the [Server Gov]'s Id
  Govs =
  {
    [1840] = {},
    [1841] = {},
  },

  -- All the [Server SoulerAgency]'s Id
  Sas =
  {
    [1949] = {},
  },

  -- All the [Server Areas]'s Id And Other Info
  Areas =
  {
    [1900] =
    {
      GovId = 1840,
    },

    [1901] =
    {
      GovId = 1840,
    },

    [1902] =
    {
      GovId = 1840,
    },

    [1903] =
    {
      GovId = 1841,
    },

    [1904] =
    {
      GovId = 1841,
    },
  },

}

if LoliCore then
  assert(LoliCore.Config:SetDefault(God))
else
  return God
end
