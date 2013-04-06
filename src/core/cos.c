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

static void coS_exportbasic(co* Co);
static void coS_exportarg(co* Co);
static void coS_exportinfo(co* Co);
static void coS_exportapi(co* Co);
static void coS_loadandoscript(co* Co);

static const luaL_Reg co_funcs[] =
{
  {"kill", co_export_kill},
  {"enabletrace", co_export_enabletrace},
  {"getmem", co_export_getmem},
  {"setmaxmem", co_export_setmaxmem},
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
  {"sleep", coOs_export_sleep},
  {"gettime", coOs_export_gettime},
  {"isdir", coOs_export_isdir},
  {"isfile", coOs_export_isfile},
  {"ispath", coOs_export_ispath},
  {"mkdir", coOs_export_mkdir},
  {"getcwd", coOs_export_getcwd},
  {NULL, NULL},
};

static void* _coS_alloc(void* ud, void* p, size_t os, size_t ns)
{
  co* Co = co_cast(co*, ud);
  void* np = NULL;
  /* when p == NULL, the un32_osize indicate the type of object lua, so, reset it to 0 */
  os = (NULL == p && os > 0) ? 0 : os;
  np = coM_xllocmem(Co, p, os, ns, 0); /* give control to Lua, don't let co throw */
  /* Lua assumes that the allocator never fails when osize >= nsize */
  if (NULL == np && ns > 0 && ns <= os) co_assert(0);
  return np;
}

static int coS_panic(lua_State* L)
{
  co* Co = NULL;
  lua_getallocf(L, (void**)&Co); co_assert(Co);
  coS_tracedebug(Co, "atpanic\?!");
  coR_throw(Co, CO_ERRSCRIPTPANIC);
  return 0;
}

static int coS_pinit(lua_State* L)
{
  co* Co = NULL;
  lua_getallocf(L, (void**)&Co);
  co_assert(Co && Co->L == L);
  coS_exportbasic(Co);
  coS_exportinfo(Co);
  coS_exportarg(Co);
  coS_exportapi(Co);
  coS_loadandoscript(Co);
  return 0;
}

void coS_born(co* Co)
{
  int z = 0;
  co_assert(!Co->L);
  Co->L = lua_newstate(_coS_alloc, Co);
  if (!Co->L) coR_throw(Co, CO_ERRSCRIPTNEW);
  lua_atpanic(Co->L, coS_panic);
  co_assert(0 == lua_gettop(Co->L));
  lua_pushcfunction(Co->L, coS_pinit);
  z = lua_pcall(Co->L, 0, 0, 0);
  if (z)
  {
    coS_tracedebug(Co, lua_tostring(Co->L, -1));
    coR_throw(Co, CO_ERRSCRIPTCALL);
  }
  co_assert(0 == lua_gettop(Co->L));
}

void coS_die(co* Co)
{
  lua_State* L = Co->L;
  if (!L) return;
  lua_getglobal(L, "core");
  if (!lua_istable(L, -1)) {lua_pop(L, 1); goto _coS1;}
  lua_getfield(L, -1, "die");
  if (!lua_isfunction(L, -1)) {lua_pop(L, 2); goto _coS1;}
  lua_pushvalue(L, -2);
  if (LUA_OK != lua_pcall(L, 1, 0, 0)){}
  lua_pop(L, 1);
_coS1:
  lua_close(L);
  Co->L = NULL;
}

void coS_active(co* Co)
{
  lua_State* L = Co->L;
  int nstack = lua_gettop(L);
  lua_getglobal(L, "core");
  lua_getfield(L, -1, "active"); co_assert(lua_isfunction(L, -1));
  lua_pushvalue(L, -2);
  if (LUA_OK != lua_pcall(L, 1, 0, 0))
  {
    coS_tracedebug(Co, "active failed, %s", lua_tostring(L, -1));
    lua_pop(L, 2);
    co_assert(nstack == lua_gettop(L));
    coR_throw(Co, CO_ERRSCRIPTCALL);
  }
  lua_pop(L, 1);
  co_assert(nstack == lua_gettop(L));
}

lua_State* coS_lua(co* Co)
{
  return Co->L;
}

static void coS_exportbasic(co* Co)
{
  lua_State* L = Co->L;
  co_assert(lua_gettop(L) == 0);
  luaL_openlibs(L);
  lua_newtable(L); /* core */
  lua_setglobal(L, "core");
  co_assert(lua_gettop(L) == 0);
}

static void coS_exportinfo(co* Co)
{
  lua_State* L = Co->L;
  co_assert(lua_gettop(L) == 0);
  lua_getglobal(L, "core"); co_assert(lua_istable(L, -1));
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
  co_assert(lua_gettop(L) == 0);
}

static void coS_exportarg(co* Co)
{
  lua_State* L = Co->L;
  const char** argv = Co->argv;
  int argc = Co->argc, i;
  co_assert(lua_gettop(L) == 0);
  lua_getglobal(L, "core"); co_assert(lua_istable(L, -1));
  lua_newtable(L);
  lua_pushvalue(L, -1);
  lua_setfield(L, -3, "arg"); /* core.arg */
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
  co_assert(lua_gettop(L) == 0);
}

static void coS_exportapi(co* Co)
{
  lua_State* L = Co->L;
  co_assert(lua_gettop(L) == 0);
  lua_getglobal(L, "core"); co_assert(lua_istable(L, -1));
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
  co_assert(lua_gettop(L) == 0);
}

static void coS_loadandoscript(co* Co)
{
  int z;
  lua_State* L = Co->L;
  const char* path = NULL;
  char corefile[256];
  co_assert(lua_gettop(L) == 0);
  lua_getglobal(L, "core"); co_assert(lua_istable(L, -1));
  lua_getfield(L, -1, "arg"); co_assert(lua_istable(L, -1));
  lua_getfield(L, -1, "corepath");
  if (lua_isstring(L, -1))
  {
    size_t len = 0;
    path = lua_tostring(L, -1);
    len = strlen(path);
    co_assert((len + strlen("co.lua") + 1) <= 256);
    sprintf(corefile, "%s/%s", path, "co.lua");
  }
  else {strcpy(corefile, "co.lua");}
  z = luaL_dofile(L, corefile);
  if (z) {luaL_error(L, "load corefile error\? %s, %s", corefile, lua_tostring(L, -1));}
  lua_pop(L, 2); /* arg.corepath */

  lua_getfield(L, -1, "born"); co_assert(lua_isfunction(L, -1));
  lua_pushvalue(L, -2);
  z = lua_pcall(L, 1, 0, 0);
  if (z) {luaL_error(L, "do corefile error! %s, %s", corefile, lua_tostring(L, -1));}
  lua_pop(L, 1); /* core */
  co_assert(lua_gettop(L) == 0);
}
