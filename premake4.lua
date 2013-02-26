

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
    targetdir "_bin/debug"
    defines "_DEBUG"
    flags { "Symbols" }

  configuration "release"
    targetdir "_bin/release"
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