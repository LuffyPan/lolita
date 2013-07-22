--
-- Servers
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/07/03 19:12:58
--

local Base = LoliSrvGod.Base
local Srv = LoliSrvGod.Srv

function Srv:Init()
  self.SrvRepos = {}
  self.SrvIdIdx = {}
  self.SrvNetIdIdx = {}
  local D = Base:GetDefaultConfig()
  local U = Base:GetUserConfig()
  local Srv = U.Srv or D.Srv
  for i, v in ipairs(assert(Srv)) do
    assert(not self.SrvRepos[v.Key])
    local x = {Id = v.Id, Key = v.Key, Type = v.Type} -- Copy a table!!!
    x.State = 0
    x.NetId = 0
    x.Extra = {}
    self.SrvRepos[x.Key] = x -- Index by [Key]
    self.SrvIdIdx[x.Id] = x --Index by [Id]
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
  self.SrvNetIdIdx[NetId] = x
  x.State = 1
  x.NetId = NetId
  -- 目前只复制了一层，需要一个CopyTable的函数
  for k, v in pairs(Extra) do
    x.Extra[k] = v
  end
  return x
end

function Srv:Logout(NetId)
  local x = self.SrvNetIdIdx[NetId]
  if not x then
    return
  end
  assert(x.State == 1)
  x.State = 0
  x.NetId = 0
  x.Extra = {}
  self.SrvNetIdIdx[NetId] = nil
end

function Srv:GetById(Id)
  return self.SrvIdIdx[Id]
end

function Srv:GetByNetId(NetId)
  return self.SrvNetIdIdx[NetId]
end

function Srv:GetByType(Type)
  for k, v in pairs(self.SrvNetIdIdx) do
    if v.Type == Type then
      return v
    end
  end
end

--可以预先根据Type进行索引
function Srv:GetAllByType(Type)
  local t = {}
  for k, v in pairs(self.SrvRepos) do
    if v.Type == Type then
      table.insert(t, v)
    end
  end
  return t
end

function Srv:GetBasic(Id)
  local x = assert(self.SrvIdIdx[Id])
  return {Id = x.Id, Type = x.Type}
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
