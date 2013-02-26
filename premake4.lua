



if not _ACTION then
  printf("_ACTION is nil!")
  return
end

solution "lolicore"
  configurations { "debug", "release" }
  location ("_build/" .. _ACTION)

project "lolicore"
  targetname "lolicore"
  language "C"
  kind "ConsoleApp"
  includedirs { "src/3rd/lua-5.2.1/src" }

  files
  {
    "src/3rd/lua-5.2.1/src/**.h", "src/3rd/lua-5.2.1/**.c",
    "src/core/**.h", "src/core/**.c",
  }

  excludes
  {
    "src/3rd/lua-5.2.1/src/lua.c",
    "src/3rd/lua-5.2.1/src/luac.c",
  }

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

local function exec(cmd, ...)
  cmd = string.format(cmd, unpack(arg))
  local z = os.execute(cmd .. " > output.log 2> error.log")
  --local z = os.execute(cmd)
  os.remove("output.log")
  os.remove("error.log")
  return z
end

local function _dopremake()
  local action = _OPTIONS["action"] or "gmake"
  printf("Premaking %s...", action)
  exec("premake4 %s", action)
end

local function _domake()
  local action = _OPTIONS["action"] or "gmake"
  local config = _OPTIONS["config"] or "debug"
  printf("Making %s %s...", action, config)
  if action == "gmake" then
    local cwd = os.getcwd()
    printf("Current working directory:%s", cwd)
    os.chdir(string.format("_build/%s", action))
    exec("make config=%s", config)
    os.chdir(cwd)
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
    printf("%s is not a dir")
    return
  end

  os.rmdir("_deploy")
  os.mkdir("_deploy")
  local src = string.format("%s/lolicore.exe", bin)
  local dest = string.format("_deploy/lolicore.exe")
  if not os.isfile(src) then
    printf("%s is not a file")
    return
  end
  os.copyfile(src, dest)
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
  }
}
