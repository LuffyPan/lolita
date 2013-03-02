/*

LoliCore.
Chamz Lau, Copyright (C) 2013-2017
2013/02/26 21:11:26

*/

#include "core.h"

static int _init(lua_State* L, int argc, const char** argv);
static int _uninit(lua_State* L);
static void _export_info(lua_State* L);
static void _export_arg(lua_State* L, int argc, const char** argv);
static int _init_script(lua_State* L);

lua_State* lolicore_born(int argc, const char** argv)
{
  lua_State* L;
  int z;

  L = luaL_newstate();
  if (!L)
  {
    return NULL;
  }

  z = _init(L, argc, argv);
  if (!z)
  {
    _uninit(L);
    return NULL;
  }
  return L;
}

void lolicore_active(lua_State* L)
{
  int z;
  int n = 10;
  while(n)
  {
    lua_getglobal(L, "core");
    lua_getfield(L, -1, "c");
    lua_getfield(L, -1, "active");
    z = lua_pcall(L, 0, 0, 0);
    if (z != LUA_OK)
    {
      break;
    }
    lua_pop(L, 2);
    --n;
  }
}

void lolicore_die(lua_State* L)
{
  int z;
  lua_getglobal(L, "core");
  lua_getfield(L, -1, "c");
  lua_getfield(L, -1, "die");
  z = lua_pcall(L, 0, 0, 0);
  if (z != LUA_OK)
  {
  }
  lua_pop(L, 2);
  _uninit(L);
}

static int _init(lua_State* L, int argc, const char** argv)
{
  int z = 0;
  luaL_openlibs(L);
  lua_newtable(L); /* core */
  lua_setglobal(L, "core");
  _export_info(L);
  _export_arg(L, argc, argv);
  z = _init_script(L);
  if (!z)
  {
    return 0;
  }
  z = 1;
  return z;
}

static int _uninit(lua_State* L)
{
  lua_close(L);
}

static int _init_script(lua_State* L)
{
  int z;
  const char* path = NULL;
  char corefile[256];
  lua_getglobal(L, "core");
  if (!lua_istable(L, -1)){ printf("core is not table\n"); return 0;}
  lua_getfield(L, -1, "arg");
  if (!lua_istable(L, -1)){ printf("arg is not table!\n"); return 0;}
  lua_getfield(L, -1, "scriptpath");
  if (lua_isstring(L, -1))
  {
    size_t len = 0;
    path = lua_tostring(L, -1);
    len = strlen(path);
    if ((len + strlen("core.lua") + 1) > 256)
    {
      return 0;
    }
    sprintf(corefile, "%s/%s", path, "core.lua");
  }
  else
  {
    strcpy(corefile, "core.lua");
  }
  printf("corefile:%s\n", corefile);
  z = luaL_dofile(L, corefile);
  if (z)
  {
    printf("dofile error:%s\n", lua_tostring(L, -1));
    return 0;
  }
  lua_pop(L, 2);
  lua_getfield(L, -1, "c");
  lua_getfield(L, -1, "born");
  if (!lua_isfunction(L, -1)){ printf("core.born is not function\n"); return 0;}
  z = lua_pcall(L, 0, 0, 0);
  if (z != LUA_OK)
  {
    printf("core.born call error:%s\n", lua_tostring(L, -1));
    return 0;
  }
  lua_pop(L, 2);
  return 1;
}

static void _export_info(lua_State* L)
{
  lua_getglobal(L, "core");
  lua_newtable(L);
  lua_pushvalue(L, -1);
  lua_setfield(L, -3, "info"); /* core.info */
  lua_pushstring(L, LOLICORE_COPYRIGHT);
  lua_setfield(L, -2, "copyright");
  lua_pushstring(L, LOLICORE_AUTHOR);
  lua_setfield(L, -2, "author");
  lua_pushnumber(L, LOLICORE_VERSION);
  lua_setfield(L, -2, "version");
  lua_pushstring(L, LOLICORE_VERSION_REPOS);
  lua_setfield(L, -2, "reposversion");
  lua_pushstring(L, LOLICORE_PLATSTR);
  lua_setfield(L, -2, "platform");
  lua_pop(L, 2);
}

static void _export_arg(lua_State* L, int argc, const char** argv)
{
  int i;
  lua_getglobal(L, "core");
  lua_newtable(L); /* core.arg */
  lua_pushvalue(L, -1);
  lua_setfield(L, -3, "arg");
  for (i = 1; i < argc; ++i)
  {
    const char* p = strchr(argv[i], '=');
    if (p)
    {
      size_t len = p - argv[i];
      if (!len) continue;
      lua_pushlstring(L, argv[i], (int)len);
      lua_pushstring(L, p + 1);
    }
    else
    {
      lua_pushstring(L, argv[i]);
      lua_pushstring(L, "");
    }
    lua_settable(L, -3);
  }
  lua_pop(L, 2);
}
