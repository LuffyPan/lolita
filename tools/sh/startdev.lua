#!/usr/bin/lua
--
-- Lolita Developmenet Startup Script
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/11/07 17:43:56
--

print("Lolita For Developmenet Is Starting.")

local path = arg[0]
print(string.format("script: [ %s ]", path))

local i = 0
local e = 0

while 1 do
  i = string.find(path, "/", i + 1)
  if not i then
    break
  end
  e = i
end

local pwd = string.sub(path, 1, e)
if not pwd or pwd == "" then
  pwd = "./"
end
print(string.format("pwd: [%s]", pwd))


local function execmd(cmd)
  local finalcmd = string.format("cd %s;%s", pwd, cmd)
  --print(string.format("execute cmd : %s", finalcmd))
  os.execute(finalcmd)
end

local function initenv()
  print("init enviroment.....")
  execmd("rm -rf pids")
  execmd("rm -rf logs")
  execmd("mkdir pids")
  execmd("mkdir logs")
end

local function startv(v)
  print(string.format("starting v [ %s ] ......", v))
  local cmd = "./lolita x=../../lolitax/src/x.lua,../../lolita%s/src/x.lua xlvs=[x=4] pid=pids/%s.pid birthday=pids/%s.birth >logs/%s.log 2>&1 &"
  execmd(string.format(cmd, v, v, v, v))

  -- todo: calc the time used.
  -- wait birthday
  local f = string.format("%s/pids/%s.birth", pwd, v)

  while 1 do

    local fh = io.open(f, "rb")
    if fh then
      fh:close()
      break
    end

    execmd("sleep 0.01")

  end

  print(string.format("v [ %s ] is started!", v))
end

initenv()
startv("vgod")
startv("vauth")
startv("vsoul")
startv("varea")
startv("vgate")

--execmd("./lolita x=../../lolitax/src/x.lua,../../lolitavgod/src/x.lua xlvs=[x=4] pid=pids/vgod.pid birthday=pids/vgod.birth >logs/vgod.log 2>&1 &")
--execmd("date")
--execmd("git status")

print("Lolita For Developmenet Is Started.")
