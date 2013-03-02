/*

LoliCore.
Chamz Lau, Copyright (C) 2013-2017
2013/02/26 21:11:26

*/

#include "core.h"

static void _process_arg(lua_State* L, int argc, const char** argv);

lua_State* lolicore_born(int argc, const char** argv)
{
  lua_State* L;
  int i;

  printf("Copyright:%s\n", LOLICORE_COPYRIGHT);
  printf("Version:%d\n", LOLICORE_VERSION);
  printf("ReposVersion:%s\n", LOLICORE_VERSION_REPOS);
  printf("Platform:%s\n", LOLICORE_PLATSTR);
  for (i = 0; i < argc; ++i)
  {
    printf("Arg[%d] = %s\n", i, argv[i]);
  }

  L = luaL_newstate();
  luaL_openlibs(L);
  lua_newtable(L); /* core */
  lua_setglobal(L, "core");
  _process_arg(L, argc, argv);

  return L;
}

void lolicore_active(lua_State* L)
{
}

void lolicore_die(lua_State* L)
{
  lua_close(L);
}

static void _process_arg(lua_State* L, int argc, const char** argv)
{
  int i;
  lua_getglobal(L, "core");
  lua_newtable(L); /* core.arg */
  lua_pushvalue(L, -1);
  lua_setfield(L, -3, "arg");
  for (i = 0; i < argc; ++i)
  {
    const char* p = strchr(argv[i], '=');
    if (p)
    {
      size_t len = p - argv[i];
      if (!len) continue;
      lua_pushlstring(L, p, (int)len);
      lua_pushstring(L, p + 1);
    }
    else
    {
      lua_pushstring(L, argv[i]);
      lua_pushstring(L, "");
    }
    lua_settable(L, -3);
  }
}
