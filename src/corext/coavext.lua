--
-- LoliCore Avatar Extend
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/04/08 18:15:58
--

local Avatar = LoliCore:NewExtend("Avatar")

function Avatar:Extend()
  self.Alive = 0
  self:ExecuteArgs()
  LoliCore.Imagination:Begin(16 * 60, self.ImageMem, self)
  LoliCore.Imagination:Begin(16 * 3600 * 2, self.ImageClose, self)
  LoliCore.Os:RegisterSignal(LoliCore.Os.SIG_INT, Avatar.OnSignal, self)
  print("Avatar Extended")
end

function Avatar:ExecuteArgs()
  -- TODO ExecuteArgs can be a low level basic machnism
  local PidFile = LoliCore.Arg:Get("pid")
  if PidFile then
    print("ExecuteArgPid", PidFile)
    self:ExecuteArgPid("pid", PidFile)
  end
end

function Avatar:ExecuteArgPid(Arg, ArgValue)
  local Pid = LoliCore.Os:GetPid()
  local Fh, Err = LoliCore.Io:OpenFile(ArgValue, "wb")
  if not Fh then return 0 end
  LoliCore.Io:WriteFile(Fh, tostring(Pid))
  LoliCore.Io:CloseFile(Fh)
  return 1
end

function Avatar:Attach(Av)
  print("LoliCore.Avatar Attaching...")
  print("\n-----------------------------------------------------------\n")
  print(LoliCore.Info:GetLCopyright())
  print(LoliCore.Info:GetLAuthors())
  print("\n-----------------------------------------------------------\n")
  print(string.format("%s", LoliCore.Info:GetReposVersion()))
  print(string.format("%s", LoliCore.Info:GetVersion()))
  print(string.format("%s", LoliCore.Info:GetAuthor()))
  print(string.format("%s", LoliCore.Info:GetCopyright()))
  print("\n-----------------------------------------------------------\n")
  print(string.format("Corext:%s", LoliCore.Arg:Get("corext")))
  print(string.format("Avatar:%s", LoliCore.Arg:Get("avatar")))
  print(string.format("CorextPath:%s", LoliCore.Arg:Get("corextpath")))
  print(string.format("AvatarPath:%s", LoliCore.Arg:Get("avatarpath")))

  assert(Av.OnBorn)(Av)
  self.Alive = 1
  while self.Alive == 1 do
    LoliCore.Imagination:Active() -- May be dump LoliCore.Net
    LoliCore.Net:Active()
    LoliCore.Os:Active(1) --带有Sleep功能
  end
  assert(Av.OnDie)(Av)
end

function Avatar:Detach()
  LoliCore.Imagination:EndAll()
  self.Alive = 0
end

function Avatar:ImageClose(Im)
  self:Detach()
  print("LoliCore.Avatar Detached")
end

function Avatar:ImageMem(Im)
  print(string.format("Mem:%d/%d", LoliCore.Base.GetMem()))
  LoliCore.Imagination:Begin(16 * 60, self.ImageMem, self)
end

function Avatar:OnSignal(Signal)
  if Signal == LoliCore.Os.SIG_INT then
    print("Avatar Recivied Interupt Signal")
    self:Detach()
  end
end

print("Avatar Compiled")
