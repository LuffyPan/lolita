--
-- Servers
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/07/03 19:12:58
--

local Base = LoliSrvGod.Base
local Srv = LoliSrvGod.Srv

function Srv:Init()
  self.SrvRepos = {}
  self.SrvNetIdIdx = {}
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

function Srv:Login(NetId, Key, Extra)
  if self.SrvNetIdIdx[NetId] then
    return nil, 1, "Already Logined"
  end
  local x = self.SrvRepos[Key]
  if not x then
    return nil, 2, "Key Is Mismatch"
  end
  assert(Key == x.Key)
  assert(x.State == 0)
  self.SrvNetIdIdx[NetId] = Key
  x.State = 1
  -- 目前只复制了一层，需要一个CopyTable的函数
  for k, v in pairs(Extra) do
    x.Extra[k] = v
  end
  return 1
end

function Srv:Logout(NetId)
  local Key = self.SrvNetIdIdx[NetId]
  if not Key then
    return
  end
  local x = assert(self.SrvRepos[Key])
  assert(x.State == 1)
  x.State = 0
  x.Extra = {}
  self.SrvNetIdIdx[NetId] = nil
end

function Srv:Dump()
  print("Servers's State:")
  for k, v in pairs(self.SrvRepos) do
    print(string.format("%d--%s--%s--%d", v.Id, v.Key, v.Type, v.State))
    for k, v in pairs(v.Extra) do
      print(string.format("    %s = %s", k, v))
    end
  end
end
