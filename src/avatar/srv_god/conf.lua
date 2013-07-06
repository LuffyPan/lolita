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
}

God.Srv =
{
  --Login Servers
  {Id = 1991, Key = "19870805", Type="srvlogin"},

  --Sa Servers
  {Id = 2000, Key = "20000901", Type="srvsa"},

  --Gov Servers
  {Id = 2001, Key = "20010928", Type = "srvgov"},

  --Area Servers
  {Id = 2003, Key = "20030901", Type = "srvarea"},
  {Id = 2004, Key = "20030902", Type = "srvarea"},
  {Id = 2005, Key = "20030903", Type = "srvarea"},
  {Id = 2006, Key = "20030904", Type = "srvarea"},
}

if LoliCore then
  assert(LoliCore.Config:SetDefault(God))
else
  return God
end
