--
-- Servers
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/07/03 19:12:58
--

function LoliSrvGod:Srv_Init()
  self.SrvRepos = {}
  local Srv = self.Uconf.Srv or self.Dconf.Srv
  for i, v in ipairs(assert(Srv)) do
    local x = {Id = v.Id, Key = v.Key, Type = v.Type,} -- Copy a table!!!
    x.State = 0
    x.Extra = {}
    self.SrvRepos[x.Key] = x -- Index by [Key]
  end
end

function LoliSrvGod:Srv_Dump()
  print("Servers's State:")
  for k, v in pairs(self.SrvRepos) do
    print(string.format("%d--%s--%s--%d", v.Id, v.Key, v.Type, v.State))
  end
end
