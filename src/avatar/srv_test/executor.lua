--
-- Test Executor, do special target test through the steps
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/07/04 11:54:02
--

local Executor = assert(LoliSrvTest.Executor)

function Executor:Init()
  assert(not self.TargetRepos)
  self.TargetRepos = {}
end

function Executor:AttachTarget(Name, Target)
  assert(not self.TargetRepos[Name])
  assert(Target.Execute)
  self.TargetRepos[Name] = Target
end

function Executor:Execute(Name)
  local Target = self.TargetRepos[Name]
  if not Target then
    print(string.format("The Target Name[%s] Is Not Register", Name))
    return
  end
  assert(Target.Execute)(Target)
end
