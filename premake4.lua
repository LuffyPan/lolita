--
-- For VS, Xcode Project Generate Use, / Linux, Unix, Macosx with GCC can use Makefile directly.
-- Chamz Lau, Copyright (C) 2013-2017
-- 2014/03/22 16:46:03 (Make more clearly)
--

if not _ACTION then return end
local v = os.getversion()
printf("Premake: %s", _PREMAKE_VERSION)
printf("HostOs: (%s) %d.%d.%d", v.description, v.majorversion, v.minorversion, v.revision)
printf("TargetOs: %s", os.get())
printf("Action: %s", _ACTION or "nil")

solution "lolita"
  configurations { "Debug", "Release" }
  location ("_build/" .. _ACTION)
  targetdir "."

  configuration "Debug"
    defines {"_DEBUG"}
    flags {"Symbols"}

  configuration "Release"
    defines {"NDEBUG"}
    flags {"OptimizeSize"}

  configuration "vs*"
    debugdir "."
    debugargs {"tracelv=0", "x=test/config_server"}
    defines {"_CRT_SECURE_NO_WARNINGS"}
  configuration "vs2005"
    defines {"_CRT_SECURE_NO_DEPRECATE"}
  configuration {"linux","gmake"}
    defines {"LUA_USE_LINUX"}
  configuration {"macosx", "gmake"}
    defines {"LUA_USE_MACOSX"}
  configuration {"macosx", "xcode*"}
    defines {"LUA_USE_MACOSX"}

local extluapath = "deps/lua-5.2.3/src"

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
