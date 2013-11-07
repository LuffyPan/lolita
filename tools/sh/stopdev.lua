#!/usr/bin/lua
--
-- Lolita Development Stop Script
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/11/07 18:59:24
--

print("Lolita For Developmenet Is Stoping.")

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

local function stopv(v)
  print(string.format("stoping v [ %s ] ......", v))
  execmd(string.format("kill -s INT $(cat pids/%s.pid)", v))

  -- todo: calc the time used.
  -- todo: deathday for detected the correct die time.
  -- todo: wait death
  print(string.format("v [ %s ] is stoped!", v))
end

stopv("vgate")
stopv("vauth")
stopv("varea")
stopv("vsoul")
stopv("vgod")

print("Lolita For Developmenet Is Stoped.")
