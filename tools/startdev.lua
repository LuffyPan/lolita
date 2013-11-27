--
-- Lolita Developmenet Startup Script
-- Chamz Lau, Copyright (C) 2013-2017
-- 2013/11/07 17:43:56
--

print("Lolita For Developmenet Is Starting.")

--local path = arg[0]
local path = assert(lolita.core.arg.x)
print(string.format("script: [ %s ]", path))

for k, v in pairs(lolita.core.arg) do print(k, v) end

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
  --execmd("rm -rf pids")
  --execmd("rm -rf logs")
  local ppids = string.format("%s/pids", pwd)
  if not lolita.core.os.isdir(ppids) then
    print(string.format("init %s", ppids))
    execmd("mkdir pids")
  end
  local plogs = string.format("%s/logs", pwd)
  if not lolita.core.os.isdir(plogs) then
    print(string.format("init %s", plogs))
    execmd("mkdir logs")
  end
end

local function startv(v, lv)
  lv = lv and lv or 3 -- default Errr and Warn and Important Info
  print(string.format("starting v [ %s ] ......", v))

  local f = string.format("%s/pids/%s.pid", pwd, v)
  local fh = io.open(f, "rb")
  if fh then
    local pid = tonumber(fh:read("*a"))
    fh:close()
    if lolita.core.os.getpinfo(pid) then
      print(string.format("v [%s] is already running", v))
      return
    end
  end

  --lolita.core.os.rmfile
  f = string.format("%s/pids/%s.birth", pwd, v)
  if lolita.core.os.ispath(f) then
    print(string.format("remove the old birth %s", f))
    execmd(string.format("rm %s", f))
  end

  local cmd = "./lolita x=../../lolitax/src/x.lua,../../lolita%s/src/x.lua xlvs=[x=%s] pid=pids/%s.pid birthday=pids/%s.birth deathday=pids/%s.death >logs/%s.log 2>&1 &"
  execmd(string.format(cmd, v, lv, v, v, v, v))

  print(string.format("v [ %s ] is started!", v))
end

local tlv = lolita.core.arg.lv
initenv()
startv("vgod", tlv)
startv("vauth", tlv)
startv("vsoul", tlv)
startv("varea", tlv)
startv("vgate", tlv)

--execmd("./lolita x=../../lolitax/src/x.lua,../../lolitavgod/src/x.lua xlvs=[x=4] pid=pids/vgod.pid birthday=pids/vgod.birth >logs/vgod.log 2>&1 &")
--execmd("date")
--execmd("git status")

print("Lolita For Developmenet Is Started.")
