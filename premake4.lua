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
  debugargs { "tracelv=0", "X=../test/config_server" }
  --defines { "LUA_COMPAT_ALL" }

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
    --defines {"LOLITA_CORE_PLAT=LOLITA_CORE_PLAT_WIN32"}
  configuration {"windows", "gmake"}
    --cygwin or mingw
    --defines {"LOLITA_CORE_PLAT=LOLITA_CORE_PLAT_LINUX"}
    defines {"LUA_USE_LINUX"}
  configuration "linux"
    --defines {"LOLITA_CORE_PLAT=LOLITA_CORE_PLAT_LINUX"}
    --defines {"LOLITA_CORE_USE_EPOLL"}
    links { "dl" }
  configuration "bsd"
    --defines {"LOLITA_CORE_PLAT=LOLITA_CORE_PLAT_UNIX"}
    --defines {"LOLITA_CORE_USE_KQUEUE"}
  configuration "macosx"
    --defines {"LOLITA_CORE_PLAT=LOLITA_CORE_PLAT_MACOSX"}
    --defines {"LOLITA_CORE_USE_KQUEUE"}
    defines {"LUA_USE_MACOSX"}
    buildoptions { "-Wno-deprecated" }
    --links {"CoreServices.framework"} -- is this need?

  configuration "linux or bsd"
    defines {"LUA_USE_LINUX"}
    --defines { "LUA_USE_POSIX", "LUA_USE_DLOPEN" }
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

local extlua = _OPTIONS["luaver"] or "5.2.3"
print(string.format("lolitaext's Lua version is %s", extlua))
local extluapath = string.format("deps/lua-%s/src", extlua)

if os.is("linux") then
  if not os.pathsearch("uuid/uuid.h", "/usr/include") then
    print("can not find lib[uuid], please install uuid-dev first")
    return
  end
end

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

  configuration "macosx"
    --linkoptions { "-rdynamic" }
    linkoptions { "-fPIC -dynamiclib -Wl,-undefined,dynamic_lookup" }
  configuration "linux"
    links { "uuid" }
    linkoptions { "-fPIC --shared" }
  configuration "windows"
    links {"lua"}

  defines {"LOLITA_CORE_PREMAKE"}

project "lolita"
  targetname "lolita"
  language "C"
  kind "ConsoleApp"
  includedirs {extluapath}

  files
  {
    extluapath .. "/**.h",
    extluapath .. "/**.c",
    "src/core/**.h", "src/core/**.c",
  }

  excludes
  {
    "src/core/coexport.c",
    extluapath .. "/lua.c",
    extluapath .. "/luac.c",
    extluapath .. "/print.c",
  }
  defines {"LOLITA_CORE_PREMAKE"}

  configuration "linux"
    links { "uuid" }

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
  local luaver = _OPTIONS["luaver"] or "5.2.3"
  local lualib = ""
  lualib = lualib:gsub("\\", "\\\\")
  printf("Premaking %s...", action)
  os.mkdir("_deploy")
  _version()
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
    {string.format("%s/liblolitaext.dylib", bin), "_deploy/lolitaext.so"},
  }

  for _, v in ipairs(_deployexe) do
    if os.isfile(v[1]) then
      print(string.format("copy %s to %s", v[1], v[2]))
      os.copyfile(v[1], v[2])
      os.execute(string.format("chmod 755 %s", v[2]))
    end
  end
end

local function _doclean()
  printf("Clean....")
  os.rmdir("_bin")
  os.rmdir("_build")
  os.rmdir("_deploy")
  --has on this api..
  --os.rmfile("/src/core/coconf.h")
  --os.rmfile("/src/core/coembe.h")
  printf("Cleaned!")
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
  trigger = "clean",
  description = "Clean",
  execute = _doclean,
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
  trigger = "luaver",
  value = "luaversion",
  description = "lua version",
  allowed =
  {
    {"5.2.3", "version 5.2.3"},
  },
}
