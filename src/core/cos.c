/*

LoliCore script
Chamz Lau, Copyright (C) 2013-2017
2013/03/03 14:31:15

*/

#include "cos.h"
#include "co.h"
#include "cort.h"
#include "comm.h"
#include "conet.h"
#include "coos.h"

static void _coS_exportbasic(co* Co);
static void _coS_exportarg(co* Co);
static void _coS_exportinfo(co* Co);
static void _coS_exportapi(co* Co);
static void _coS_initscript(co* Co);

static const luaL_Reg co_funcs[] =
{
  {"kill", co_export_kill},
  {"enabletrace", co_export_enabletrace},
  {NULL, NULL},
};

static const luaL_Reg coN_funcs[] =
{
  {"register", coN_export_register},
  {"connect", coN_export_connect},
  {"listen", coN_export_listen},
  {"push", coN_export_push},
  {"close", coN_export_close},
  {NULL, NULL},
};

static const luaL_Reg coOs_funcs[] =
{
  {"gettime", coOs_export_gettime},
  {NULL, NULL},
};

static void* _coS_alloc(void* ud, void* p, size_t os, size_t ns)
{
  co* Co = co_cast(co*, ud);
  void* np = NULL;
  /* when p == NULL, the un32_osize indicate the type of object lua, so, reset it to 0 */
  os = (NULL == p && os > 0) ? 0 : os;
  np = coM_xllocmem(Co, p, os, ns);
  /* Lua assumes that the allocator never fails when osize >= nsize */
  if (NULL == np && ns > 0 && ns <= os) co_assert(0);
  return np;
}

void coS_born(co* Co)
{
  co_assert(!Co->L);
  Co->L = lua_newstate(_coS_alloc, Co);
  co_traceinfo(Co, "coScript, current stack count[%d]\n", lua_gettop(Co->L));
  _coS_exportbasic(Co);
  _coS_exportinfo(Co);
  _coS_exportarg(Co);
  _coS_exportapi(Co);
  _coS_initscript(Co);
  co_traceinfo(Co, "coScript, current stack count[%d]\n", lua_gettop(Co->L));
  co_traceinfo(Co, "coScript borned..\n");
}

void coS_die(co* Co)
{
  lua_State* L = Co->L;
  lua_getglobal(L, "core");
  if (!lua_istable(L, -1)) {lua_pop(L, 1); goto _coS1;}
  lua_getfield(L, -1, "die");
  if (!lua_isfunction(L, -1)) {lua_pop(L, 2); goto _coS1;}
  lua_pushvalue(L, -2);
  if (LUA_OK != lua_pcall(L, 1, 0, 0)){}
  lua_pop(L, 1);
_coS1:
  lua_close(Co->L);
  Co->L = NULL;
  co_traceinfo(Co, "coScript died..\n");
}

void coS_active(co* Co)
{
  lua_State* L = Co->L;
  int nstack = lua_gettop(L);
  lua_getglobal(L, "core");
  lua_getfield(L, -1, "active");
  coR_runerror(Co, lua_isfunction(L, -1));
  lua_pushvalue(L, -2);
  if (LUA_OK != lua_pcall(L, 1, 0, 0))
  {
    co_traceerror(Co, "coScript failed call active, detail, %s\n", lua_tostring(L, -1));
    lua_pop(L, 2);
    co_assert(nstack == lua_gettop(L));
    return;
  }
  lua_pop(L, 1);
  co_assert(nstack == lua_gettop(L));
}

lua_State* coS_lua(co* Co)
{
  return Co->L;
}

static void _coS_exportbasic(co* Co)
{
  lua_State* L = Co->L;
  luaL_openlibs(L);
  lua_newtable(L); /* core */
  lua_setglobal(L, "core");
}

static void _coS_exportinfo(co* Co)
{
  lua_State* L = Co->L;
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

static void _coS_exportarg(co* Co)
{
  int i;
  lua_State* L = Co->L;
  int argc = Co->argc;
  const char** argv = Co->argv;
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

static void _coS_exportapi(co* Co)
{
  lua_State* L = Co->L;
  lua_getglobal(L, "core");
  coR_runerror(Co, lua_istable(L, -1));
  lua_newtable(L);
  lua_pushvalue(L, -1);
  lua_setfield(L, -3, "api"); /* core.api */

  lua_newtable(L);
  luaL_setfuncs(L, co_funcs, 0);
  lua_setfield(L, -2, "base");

  lua_newtable(L);
  luaL_setfuncs(L, coN_funcs, 0);
  lua_setfield(L, -2, "net");

  lua_newtable(L);
  luaL_setfuncs(L, coOs_funcs, 0);
  lua_setfield(L, -2, "os");

  /* SHIT, Forget to pop, deley the fatal error occurs later!! */
  lua_pop(L, 2);
}

static void _coS_initscript(co* Co)
{
  int z;
  lua_State* L = Co->L;
  const char* path = NULL;
  char corefile[256];
  lua_getglobal(L, "core");
  coR_runerror(Co, lua_istable(L, -1));
  lua_getfield(L, -1, "arg");
  coR_runerror(Co, lua_istable(L, -1));
  lua_getfield(L, -1, "corepath");
  if (lua_isstring(L, -1))
  {
    size_t len = 0;
    path = lua_tostring(L, -1);
    len = strlen(path);
    coR_runerror(Co, (len + strlen("co.lua") + 1) <= 256);
    sprintf(corefile, "%s/%s", path, "co.lua");
  }
  else
  {
    strcpy(corefile, "co.lua");
  }
  z = luaL_dofile(L, corefile);
  if (z)
  {
    co_traceinfo(Co, "coScript load %s failed, detail, %s\n", corefile, lua_tostring(L, -1));
    coR_runerror(Co, 0);
  }
  co_traceinfo(Co, "coScript load %s succeed\n", corefile);
  lua_pop(L, 2);
  lua_getfield(L, -1, "born");
  coR_runerror(Co, lua_isfunction(L, -1));
  lua_pushvalue(L, -2);
  z = lua_pcall(L, 1, 0, 0);
  if (z != LUA_OK)
  {
    co_traceinfo(Co, "coScript initializing failed, detail, %s\n", lua_tostring(L, -1));
    coR_runerror(Co, 0);
  }
  co_traceinfo(Co, "coScript initializing succeed\n");
  lua_pop(L, 1);
}
