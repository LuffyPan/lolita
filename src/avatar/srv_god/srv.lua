--
-- Servers
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/07/03 19:12:58
--

local Base = LoliSrvGod.Base
local Srv = LoliSrvGod.Srv

function Srv:Init()
  self.SrvRepos = {}
  local D = Base:GetDefaultConfig()
  local U = Base:GetUserConfig()
  local Srv = U.Srv or D.Srv
  for i, v in ipairs(assert(Srv)) do
    local x = {Id = v.Id, Key = v.Key, Type = v.Type,} -- Copy a table!!!
    x.State = 0
    x.Extra = {}
    self.SrvRepos[x.Key] = x -- Index by [Key]
  end
end

function Srv:Dump()
  print("Servers's State:")
  for k, v in pairs(self.SrvRepos) do
    print(string.format("%d--%s--%s--%d", v.Id, v.Key, v.Type, v.State))
  end
end
