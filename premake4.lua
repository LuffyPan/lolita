


if not string.find(_PREMAKE_VERSION, "4.4") then
  printf("Current Premake version is %s, need %s", _PREMAKE_VERSION, "4.4")
  return
end

if not _ACTION then
  printf("_ACTION is nil!")
  return
end

solution "lolicore"
  configurations { "debug", "release" }
  location ("_build/" .. _ACTION)

  --IS this vs used only?
  debugdir ("_deploy")
  debugargs { "arg1key=arg1val", "arg2key=arg2val", "corext=../src/corext/co.lua", "avatar=../src/avatar/srv_test/av.lua", "conf=conf/srv_god.conf", }

project "lolicore"
  targetname "lolicore"
  language "C"
  kind "ConsoleApp"
  includedirs { "src/3rd/lua-5.2.2/src" }

  files
  {
    "src/3rd/lua-5.2.2/src/**.h", "src/3rd/lua-5.2.2/**.c",
    "src/core/**.h", "src/core/**.c",
  }

  excludes
  {
    "src/3rd/lua-5.2.2/src/lua.c",
    "src/3rd/lua-5.2.2/src/luac.c",
    "src/core/coconf.h",
  }

  --Platform macro configuration, much more thing to do..
  configuration "vs*"
    defines { "LOLICORE_PLAT=LOLICORE_PLAT_WIN32" }

  configuration "gmake"
    defines { "LOLICORE_PLAT=LOLICORE_PLAT_LINUX" }
    buildoptions { "-g" }

  configuration "debug"
    targetdir ("_bin/" .. _ACTION .. "/debug")
    defines "_DEBUG"
    flags { "Symbols" }

  configuration "release"
    targetdir ("_bin/" .. _ACTION .. "/release")
    defines "NDEBUG"
    flags { "OptimizeSize" }

  configuration "vs*"
    defines "_CRT_SECURE_NO_WARNINGS"

  configuration "vs2005"
    defines "_CRT_SECURE_NO_DEPRECATE"

  configuration "windows"
    links { "ole32" }

  configuration "linux or bsd"
    defines { "LUA_USE_POSIX", "LUA_USE_DLOPEN" }
    links { "m" }
    linkoptions { "-rdynamic" }

  configuration "linux"
    links { "dl" }

  configuration "macosx"
    defines { "LUA_USE_MACOSX" }
    links { "CoreServices.framework" }

  configuration { "macosx", "gmake" }
    buildoptions { "-mmacosx-version-min=10.4" }
    linkoptions { "-mmacosx-version-min=10.4" }

  configuration "solaris"
    linkoptions { "-Wl,--export-dynamic" }

if _ACTION == "clean" then
  os.rmdir("_bin")
  os.rmdir("_build")
  os.rmdir("_deploy")
end

local function _version()
  print("Updating version number...")
  local z = os.execute("git describe --dirty >output.log 2>&1")
  if z ~= 0 then
    printf("Get repos version failed:%d", z)
    return
  end
  local fvi = io.open("output.log", "rb")
  local version = fvi:read("*a")
  fvi:close()
  os.remove("output.log")
  version = version:gsub("\n", "")
  version = version:gsub("\r", "")
  printf("Repos version is %s", version)
  local fni = "src/core/coconf.h.in"
  local fi = io.open(fni, "rb")
  if not fi then
    printf("Cannot open conf template file:%s", fni)
    return
  end
  local text = fi:read("*a")
  fi:close()
  text = text:gsub("@REPOS_VERSION@", version)
  local fno = "src/core/coconf.h"
  local fo = io.open(fno, "wb")
  if not fo then
    printf("Cannot open conf file:%s", fno)
    return
  end
  fo:write(text)
  fo:close()
end

local function _embecore()
  local embestr = ""
  local func = assert(loadfile("src/corext/co.lua"))
  local manifest = assert(func(1))
  for i, fn in ipairs(manifest) do
    fn = "src/corext/" .. fn
    printf(fn)
    local fi = io.open(fn, "rb") if not fi then printf("Cannot open embe file:%s", fn) end
    local text = fi:read("*a")
    embestr = embestr .. text
    fi:close()
  end
  return embestr
end

local _embeserveropt =
{
  god = 1, gov = 1, sa = 1, login = 1, area = 1,
}
local function _embeserver(t)
  if not _embeserveropt[t] then return end
  local embestr = ""
  local func = assert(loadfile(string.format("src/avatar/srv_%s/av.lua", t)))
  local manifest = assert(func(1))
  for i, fn in ipairs(manifest) do
    fn = string.format("src/avatar/srv_%s/%s", t, fn)
    printf(fn)
    local fi = io.open(fn, "rb") if not fi then printf("Cannot open embe file:%s", fn) end
    local text = fi:read("*a")
    embestr = embestr .. text
    fi:close()
  end
  return embestr
end

local function _embe()
  local embestr = ""
  local embe = _OPTIONS["embe"] or "none"
  printf("embe %s", embe)
  if embe ~= "none" then
    local corext = _embecore()
    embestr = embestr .. corext
    local server = _embeserver(embe)
    if server then
      embestr = embestr .. server
    end
  end
  embestr = embestr:gsub("\\", "\\\\")
  embestr = embestr:gsub("\n", "\\n")
  embestr = embestr:gsub("\"", "\\\"")

  local fni = "src/core/coembe.h.in"
  local fi = io.open(fni, "rb")
  if not fi then
    printf("Cannot open embe template file:%s", fni)
    return
  end
  local text = fi:read("*a")
  fi:close()
  text = text:gsub("@TOBEEMBE@", function(s) return embestr end)
  text = text:gsub("@TOBEEMBETYPE@", function(s) return embe end)
  local fno = "src/core/coembe.h"
  local fo = io.open(fno, "wb")
  if not fo then
    printf("Cannot open embe file:%s", fno)
    return
  end
  fo:write(text)
  fo:close()
end

local function _exec(cmd, ...)
  cmd = string.format(cmd, unpack(arg))
  local z = os.execute(cmd .. " > output.log 2> error.log")
  --local z = os.execute(cmd)
  os.remove("output.log")
  os.remove("error.log")
  return z
end

local function _execex(cmd, ch2dir)
  local cwd = os.getcwd()
  local z = os.execute(string.format("cd %s;%s", ch2dir, cmd))
  os.chdir(cwd)
  return z
end

local function _dopremake()
  local action = _OPTIONS["action"] or "gmake"
  printf("Premaking %s...", action)
  os.mkdir("_deploy")
  _version()
  _embe()
  _exec("premake4 %s", action)
end

local function _domake()
  local action = _OPTIONS["action"] or "gmake"
  local config = _OPTIONS["config"] or "debug"
  printf("Making %s %s...", action, config)
  if action == "gmake" then
    printf("Current working directory:%s", os.getcwd())
    _execex(string.format("make config=%s", config), string.format("_build/%s", action))
    printf("After Make, Current working directory:%s", os.getcwd())
  else
    printf("Unsupported action %s now!", action)
  end
end

local _deployconf =
{
  {"src/avatar/srv_god/conf.lua", "_deploy/conf/srv_god.conf"},
}

local _deploysh =
{
  {"src/sh/startdev.sh", "_deploy/startdev.sh"},
  {"src/sh/stopdev.sh", "_deploy/stopdev.sh"},
}

local function _dodeploy()
  local action = _OPTIONS["action"] or "gmake"
  local config = _OPTIONS["config"] or "debug"

  printf("Deploy %s %s...", action, config)
  local bin = string.format("_bin/%s/%s", action, config)
  if not os.isdir(bin) then
    printf("%s is not a dir", bin)
    return
  end

  os.rmdir("_deploy")
  os.mkdir("_deploy")
  os.mkdir("_deploy/conf")

  for _, v in ipairs(_deployconf) do
    os.copyfile(v[1], v[2])
  end

  for _, v in ipairs(_deploysh) do
    os.copyfile(v[1], v[2])
    os.execute(string.format("chmod 755 %s", v[2]))
  end

  local src = string.format("%s/lolicore.exe", bin)
  local dest = string.format("_deploy/lolicore.exe")
  if not os.isfile(src) then
    printf("%s is not a file", src)
  else
    os.copyfile(src, dest)
  end
  src = string.format("%s/lolicore", bin)
  dest = string.format("_deploy/lolicore")
  if not os.isfile(src) then
    printf("%s is not a file", src)
  else
    os.copyfile(src, dest)
  end
end

local function _docheck()
  printf("Check code style....")
  local cfiles = os.matchfiles("src/core/**.c")
  local chdrfiles = os.matchfiles("src/core/**.h")
  local cinfiles = os.matchfiles("src/core/**.h.in")
  local sfiles = os.matchfiles("src/corext/**.lua")
  local afiles = os.matchfiles("src/avatar/**.lua")
  local confiles = os.matchfiles("src/conf/**.in")
  local docfiles = os.matchfiles("doc/**.md")
  local shfiles = os.matchfiles("src/sh/**.sh")
  table.insert(sfiles, "premake4.lua")
  local files = {cfiles, chdrfiles, cinfiles, sfiles, afiles, confiles, docfiles, shfiles}
  for _, v in ipairs(files) do
    for _, file in ipairs(v) do
      printf("Checking file %s....", file)
      local f = io.open(file, "rb")
      if f then
        local text = f:read("*a")
        if string.find(text, "\r") then
          printf("Checked \\r in file!!")
          f:close()
          return
        end
        if string.find(text, "\t") then
          printf("Checked \\t in file!!")
          f:close()
          return
        end
        f:close()
      end
    end
  end
  printf("Check passed!")
end

newaction
{
  trigger = "premake",
  description = "Premake, Generate native make",
  execute = _dopremake,
}

newaction
{
  trigger = "make",
  description = "Make",
  execute = _domake,
}


newaction
{
  trigger = "deploy",
  description = "Deploy",
  execute = _dodeploy,
}

newaction
{
  trigger = "check",
  description = "Check code style",
  execute = _docheck,
}

newoption
{
  trigger = "config",
  value = "configvalue",
  description = "configuration",
  allowed =
  {
    { "debug", "Debug" },
    { "release", "Release" }
  }
}

newoption
{
  trigger = "action",
  value = "actionvalue",
  description = "Same as _ACTION",
  allowed =
  {
    { "gmake", "gmake" },
    { "vs2002", "Visual Studio 2002" },
    { "vs2003", "Visual Studio 2003" },
    { "vs2005", "Visual Studio 2005" },
    { "vs2008", "Visual Studio 2008" },
    { "vs2010", "Visual Studio 2010" },
  }
}

newoption
{
  trigger = "embe",
  value = "embevalue",
  description = "embe type",
  allowed =
  {
    { "none", "don't embe script, use external" },
    { "core", "only embe core script" },
    { "god", "embe core and god" },
    { "gov", "embe core and gov" },
    { "sa", "embe core and sa" },
    { "login", "embe core and login" },
    { "area", "embe core and area" },
  }
}
