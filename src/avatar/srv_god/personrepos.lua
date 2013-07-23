--
-- God PersonRepos
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/07/21 11:52:14
--


local PersonRepos = LoliSrvGod.PersonRepos
local SrvRepos = LoliSrvGod.Srv

function PersonRepos:Init()
  self.Root = "data/god"
  self.BasePath = self.Root .. "/base.lua"
  self.PersonRoot = "data/god/person"
  self.SoulerRoot = "data/god/souler"
  self.Id2Person = {}
  self.SoulerId2Person = {}
  LoliCore.Os:MkDirEx(self.PersonRoot)
  LoliCore.Os:MkDirEx(self.SoulerRoot)

  --下一个SoulerId需要存档,后续和服务器有关的存档数据都可以存到这里
  local BaseFile = LoliCore.Io:LoadFile(self.BasePath)
  if not BaseFile then
    local NewBaseFile =
    {
      SoulerId = 1987,
    }
    LoliCore.Io:SaveFile(NewBaseFile, self.BasePath)
    BaseFile = NewBaseFile
  end
  self.BaseFile = BaseFile
end

--QuerySouler,CreateSouler,DestroySouler,SelectSouler使用同步模拟异步
function PersonRepos:QuerySouler(PersonId)
  local Path = string.format("%s/%s.lua", self.PersonRoot, PersonId)
  local PersonFile = LoliCore.Io:LoadFile(Path)
  if not PersonFile then
    local NewPersonFile =
    {
      Soulers = {},
      SoulerCount = 0,
      SoulerMax = 3,
    }
    PersonFile = NewPersonFile
    LoliCore.Io:SaveFile(PersonFile, Path)
  end
  return PersonFile.Soulers
end

function PersonRepos:CreateSouler(PersonId, SoulerInfo)
  local Path = string.format("%s/%s.lua", self.PersonRoot, PersonId)
  local PathEx = string.format("%s/%s.lua", self.SoulerRoot, self.BaseFile.SoulerId)
  local PersonFile = LoliCore.Io:LoadFile(Path)
  if not PersonFile then
    return nil, 0
  end

  if PersonFile.SoulerCount >= PersonFile.SoulerMax then
    return nil, 1
  end

  if not SrvRepos:GetById(SoulerInfo.AreaId) then
    --非法的一個Area
    return nil, 2
  end

  local NewSouler =
  {
    Id = self.BaseFile.SoulerId,
    Name = SoulerInfo.Name,
    Sex = SoulerInfo.Sex,
    Job = SoulerInfo.Job,
    AreaId = SoulerInfo.AreaId,
    CurrentAreaId = SoulerInfo.AreaId,
    Level = 0,
  }
  self.BaseFile.SoulerId = self.BaseFile.SoulerId + 1
  LoliCore.Io:SaveFile(NewSouler, PathEx)

  PersonFile.Soulers[NewSouler.Id] = 1
  PersonFile.SoulerCount = PersonFile.SoulerCount + 1
  LoliCore.Io:SaveFile(PersonFile, Path)

  LoliCore.Io:SaveFile(self.BaseFile, self.BasePath)

  return NewSouler.Id
end

function PersonRepos:DestroySouler(PersonId, SoulerId)
  local Path = string.format("%s/%s.lua", self.PersonRoot, PersonId)
  local PersonFile = LoliCore.Io:LoadFile(Path)
  if not PersonFile then
    print(Path)
    return nil, 0
  end
  if not PersonFile.Soulers[SoulerId] then
    return nil, 1
  end
  PersonFile.Soulers[SoulerId] = nil
  PersonFile.SoulerCount = PersonFile.SoulerCount - 1
  LoliCore.Io:SaveFile(PersonFile, Path)
  return SoulerId
end

function PersonRepos:SelectSouler(PersonId, SoulerId)
  local Path = string.format("%s/%s.lua", self.PersonRoot, PersonId)
  local PersonFile = LoliCore.Io:LoadFile(Path)
  if not PersonFile then
    return nil, 0
  end
  if not PersonFile.Soulers[SoulerId] then
    return nil, 1
  end

  local PathEx = string.format("%s/%s.lua", self.SoulerRoot, SoulerId)
  local SoulerFile = LoliCore.Io:LoadFile(PathEx)
  if not SoulerFile then
    return nil, 2
  end
  return SoulerFile
end



-------------------------PersonRepos----------------------------
function PersonRepos:New(Id, SoulerId, MindNetId)
  assert(not self.Id2Person[Id])
  local Person =
  {
    Id = Id,
    SoulerId = SoulerId,
    MindNetId = MindNetId,
    AreaNetId = 0,
  }
  self.Id2Person[Id] = Person
  self.SoulerId2Person[SoulerId] = Person
  return Person
end

function PersonRepos:Delete(Id)
  local Person = assert(self.Id2Person[Id])
  self.Id2Person[Id] = nil
  self.SoulerId2Person[Person.SoulerId] = nil
  return Person
end

function PersonRepos:GetById(Id)
  return self.Id2Person[Id]
end

function PersonRepos:GetBySoulerId(SoulerId)
  return self.SoulerId2Person[SoulerId]
end
