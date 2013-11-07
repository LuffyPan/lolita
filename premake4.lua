--Some Complicate, Need Rewrite This!


if not string.find(_PREMAKE_VERSION, "4.4") then
  printf("Current Premake version is %s, need %s", _PREMAKE_VERSION, "4.4")
  return
end

if not _ACTION then
  printf("_ACTION is nil!")
  return
end

printf("action:%s", _ACTION)
printf("os:%s", os.get())
printf("os:%s", tostring(os.is("linux")))
local v = os.getversion()
print(string.format("(%s) %d.%d.%d", v.description, v.majorversion, v.minorversion, v.revision))

solution "lolitall"
  configurations { "debug", "release" }
  location ("_build/" .. _ACTION)

  print(string.format("platforms:%s", tostring(platforms())))
  print(string.format("configurations:%s", tostring(configurations())))

  --IS this vs used only?
  debugdir ("_deploy")
  debugargs { "arg1key=arg1val", "arg2key=arg2val", "corext=../sample/echo.lua", "bsrv=1"}

  configuration "debug"
    targetdir ("_bin/" .. _ACTION .. "/debug")
    defines "_DEBUG"
    flags { "Symbols" }

  configuration "release"
    targetdir ("_bin/" .. _ACTION .. "/release")
    defines "NDEBUG"
    flags { "OptimizeSize" }

  --Platform macro configuration, much more thing to do..
  --macro is useful, simple, so keep this way, just rename to LOLITA_CORE_PLAT_XXX
  configuration "windows"
    defines {"LOLITA_CORE_PLAT=LOLITA_CORE_PLAT_WIN32"}
  configuration {"windows", "gmake"}
    --cygwin or mingw
    defines {"LOLITA_CORE_PLAT=LOLITA_CORE_PLAT_LINUX"}
    defines {"LUA_USE_LINUX"}
  configuration "linux"
    defines {"LOLITA_CORE_PLAT=LOLITA_CORE_PLAT_LINUX"}
    defines {"LOLITA_CORE_USE_EPOLL"}
    links { "dl" }
  configuration "bsd"
    defines {"LOLITA_CORE_PLAT=LOLITA_CORE_PLAT_UNIX"}
    defines {"LOLITA_CORE_USE_KQUEUE"}
  configuration "macosx"
    defines {"LOLITA_CORE_PLAT=LOLITA_CORE_PLAT_MACOSX"}
    defines {"LOLITA_CORE_USE_KQUEUE"}
    defines {"LUA_USE_MACOSX"}
    links {"CoreServices.framework"} -- is this need?

  configuration "linux or bsd"
    defines { "LUA_USE_POSIX", "LUA_USE_DLOPEN" }
    links { "m" }
    linkoptions { "-rdynamic" }

  configuration "gmake"
    buildoptions { "-g" }

  configuration "vs*"
    defines "_CRT_SECURE_NO_WARNINGS"
    links { "ole32" }

  configuration "vs2005"
    defines "_CRT_SECURE_NO_DEPRECATE"

  configuration { "macosx", "gmake" }
    buildoptions { "-mmacosx-version-min=10.4" }
    linkoptions { "-mmacosx-version-min=10.4" }

local extlua = _OPTIONS["luaver"] or "5.2.2"
print(string.format("lolitaext's Lua version is %s", extlua))
local extluapath = string.format("deps/lua-%s/src", extlua)
local lualibname = _OPTIONS["lualibname"]
local lualibpath = _OPTIONS["lualibpath"]

project "lua"
  targetname "lua"
  language "C"
  kind "SharedLib"
  files
  {
    extluapath .. "/**.h", extluapath .. "/**.c",
  }
  excludes
  {
    extluapath .. "/lua.c",
    extluapath .. "/luac.c",
    extluapath .. "/print.c",
  }
  configuration "vs*"
    defines {"LUA_BUILD_AS_DLL"}

project "lolitaext"
  targetname "lolitaext"
  language "C"
  kind "SharedLib"
  includedirs {extluapath,}

  files
  {
    extluapath .. "/**.h",
    "src/core/**.h", "src/core/**.c",
  }

  excludes
  {
    "src/core/comain.c",
  }

  if extlua == "5.2.2" then
    defines {"LOLITA_CORE_LUA_522"}
  elseif extlua == "5.2.1" then
    defines {"LOLITA_CORE_LUA_521"}
  elseif extlua == "5.1.4" then
    defines {"LOLITA_CORE_LUA_514"}
  end

  if lualibpath then
    print(string.format("specify lualibpath %s", lualibpath))
    libdirs {lualibpath}
  end
  if lualibname then
    print(string.format("specify lualibname %s", lualibname))
    links {lualibname}
  else
    links {"lua"}
  end


project "lolita"
  targetname "lolita"
  language "C"
  kind "ConsoleApp"
  includedirs {extluapath}

  files
  {
    extluapath .. "/**.h",
    "src/core/**.h", "src/core/**.c",
  }

  excludes
  {
    "src/core/coexport.c",
  }
  if extlua == "5.2.2" then
    defines {"LOLITA_CORE_LUA_522"}
  elseif extlua == "5.2.1" then
    defines {"LOLITA_CORE_LUA_521"}
  elseif extlua == "5.1.4" then
    defines {"LOLITA_CORE_LUA_514"}
  end
  links { "lua" }

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

local function _getpath(file)
  local n = 1
  local e = 0
  while 1 do
    n = string.find(file, "/", n)
    if not n then break end
    e = n
    n = n + 1
  end
  return string.sub(file, 1, e)
end

local function _embecore(mfile)
  local embestr = ""
  local func = assert(loadfile(mfile))
  local mfilepath = _getpath(mfile)
  local _, manifest = assert(func())
  for i, tfn in ipairs(manifest) do
    fn = mfilepath .. tfn[1]
    printf(fn)
    local fi = io.open(fn, "rb")
    if fi then
      local text = fi:read("*a")

      text = text:gsub("\\", "\\\\")
      text = text:gsub("\n", "\\n")
      text = text:gsub("\"", "\\\"")

      embestr = embestr .. "\"" .. text .. "\",\n"
      fi:close()
    else
      if tfn[2] == 1 then
        printf("file:%s is optional, so ignore it", fn)
      else
        printf("Cannot open embe file:%s", fn)
      end
    end
  end
  return embestr
end

local _embeserveropt =
{
  god = 1, mind = 1, login = 1, area = 1,
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
  local embe = _OPTIONS["embe"]
  printf("embe %s", embe or "none")
  if embe then
    local corext = _embecore(embe)
    embestr = embestr .. corext
  end
  --embestr = embestr:gsub("\\", "\\\\")
  --embestr = embestr:gsub("\n", "\\n")
  --embestr = embestr:gsub("\"", "\\\"")

  local fni = "src/core/coembe.h.in"
  local fi = io.open(fni, "rb")
  if not fi then
    printf("Cannot open embe template file:%s", fni)
    return
  end
  local text = fi:read("*a")
  fi:close()
  text = text:gsub("@TOBEEMBEX@", function(s) return embestr end)
  text = text:gsub("@TOBEEMBEMODE@", function(s) return embe end)
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
  --local z = os.execute(cmd .. " > output.log 2> error.log")
  local z = os.execute(cmd)
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
  local luaver = _OPTIONS["luaver"] or "5.2.2"
  local lualibname = _OPTIONS["lualibname"]
  local lualibpath = _OPTIONS["lualibpath"]
  local lualib = ""
  if lualibname then lualib = lualib .. " --lualibname=" .. lualibname end
  if lualibpath then lualib = lualib .. " --lualibpath=" .. lualibpath end
  lualib = lualib:gsub("\\", "\\\\")
  printf("Premaking %s...", action)
  os.mkdir("_deploy")
  _version()
  _embe()
  _exec("premake4 --%s=%s %s %s", "luaver", luaver, lualib, action)
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
  --{"src/avatar/srv_god/conf.lua", "_deploy/conf/srv_god.conf"},
}

local _deploysh =
{
  {"tools/sh/startdev.sh", "_deploy/startdev.sh"},
  {"tools/sh/stopdev.sh", "_deploy/stopdev.sh"},
  {"tools/sh/startdev.lua", "_deploy/startdev.lua"},
  {"tools/sh/stopdev.lua", "_deploy/stopdev.lua"},
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

  local _deployexe =
  {
    {string.format("%s/lolita.exe", bin), "_deploy/lolita.exe"},
    {string.format("%s/lolita", bin), "_deploy/lolita"},
    {string.format("%s/lolitaext.dll", bin), "_deploy/lolitaext.dll"},
    {string.format("%s/lolitaext.dll", bin), "_deploy/lolitaext.so"},
    {string.format("%s/lolitaext.so", bin), "_deploy/lolitaext.so"},
    {string.format("%s/lua.dll", bin), "_deploy/lua.dll"},
    {string.format("%s/liblua.so", bin), "_deploy/liblua.so"},
    {string.format("%s/liblolitaext.so", bin), "_deploy/liblolitaext.so"},
    {string.format("%s/liblolitaext.dylib", bin), "_deploy/liblolitaext.dylib"},
    {string.format("%s/liblua.dylib", bin), "_deploy/liblua.dylib"},
  }

  for _, v in ipairs(_deployexe) do
    if os.isfile(v[1]) then
      print(string.format("copy %s to %s", v[1], v[2]))
      os.copyfile(v[1], v[2])
      os.execute(string.format("chmod 755 %s", v[2]))
    end
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
  local samplefiles = os.matchfiles("sample/**.lua")
  local mdfiles = os.matchfiles("README.md")
  table.insert(sfiles, "premake4.lua")
  local files = {cfiles, chdrfiles, cinfiles, sfiles, afiles, confiles, docfiles, shfiles, samplefiles, mdfiles}
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
  description = "embe file",
}

newoption
{
  trigger = "luaver",
  value = "luaversion",
  description = "lua version",
  allowed =
  {
    {"5.2.2", "version 5.2.2"},
    {"5.2.1", "version 5.2.1"},
    {"5.1.4", "version 5.1.4"},
  },
}

newoption
{
  trigger = "lualibname",
  value = "lua lib's name",
  description = "specify lua lib's name for lolitaext",
}

newoption
{
  trigger = "lualibpath",
  value = "lua lib's path",
  description = "specify lua lib's path for lolitaext",
}
