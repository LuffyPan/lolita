/*

LoliCore.
Chamz Lau, Copyright (C) 2013-2017
2013/02/26 21:11:26

*/

#include "co.h"
#include "cort.h"
#include "conet.h"
#include "coos.h"
#include "comm.h"

static int co_panic(lua_State* L);
static void* co_xlloc(void* ud, void* p, size_t os, size_t ns);
static void* co_lualloc(void* ud, void* p, size_t os, size_t ns);
static void co_newlua(co* Co);
static void co_deletelua(co* Co);
static void co_export(co* Co);
static void co_born(co* Co, void* ud);
static void co_alive(co* Co, void* ud);
static void co_free(co* Co);
static void co_fatalerror(co* Co, int e);
static const char* co_modname(co* Co, int mod);
static const char* co_lvname(co* Co, int lv);
static const char* co_errorstr(co* Co, int e);

static int co_export_setmaxmem(lua_State* L);
static int co_export_getmem(lua_State* L);
static int co_export_kill(lua_State* L);
static int co_export_enabletrace(lua_State* L);

lolicore* lolicore_born(int argc, const char** argv, co_xllocf x, void* ud, co_tracef tf)
{
  int z = 0;
  co* Co;
  x = x ? x : co_xlloc;
  Co = co_cast(co*, (*x)(x == co_xlloc ? NULL : ud, NULL, 0, sizeof(co)));
  if (NULL == Co) return NULL;
  Co->xlloc = x;
  Co->ud = ud;
  Co->tf = tf;
  Co->argc = argc;
  Co->argv = argv;
  Co->umem = 0;
  Co->maxmem = 4096 * 10;
  if (Co->xlloc == co_xlloc)
  {
    Co->ud = (void*)Co;
    Co->umem = sizeof(*Co);
    co_assertex(Co->umem <= Co->maxmem, "maxmem is set to small!");
  }
  Co->btrace = 1; /* process specially */
  Co->errjmp = NULL;
  Co->bactive = 0;
  Co->L = NULL;
  Co->N = NULL;
  Co->core[0] = 0;
  z = coR_pcall(Co, co_born, NULL);
  if (z)
  {
    co_fatalerror(Co, z);
    co_free(Co);
    return NULL;
  }
  return (lolicore*)Co;
}

void lolicore_alive(lolicore* Co)
{
  int z = coR_pcall(Co, co_alive, NULL);
  if (z)
  {
    co_fatalerror(Co, z);
    return;
  }
}

void lolicore_die(lolicore* Co)
{
  co_free(Co);
}

size_t lolicore_getusedmem(lolicore* Co)
{
  return Co->umem;
}

size_t lolicore_getmaxmem(lolicore* Co)
{
  return Co->maxmem;
}

const char* lolicore_getmodname(lolicore* Co, int mod)
{
  return co_modname(Co, mod);
}

const char* lolicore_getlvname(lolicore* Co, int lv)
{
  return co_lvname(Co, lv);
}

static void co_born(co* Co, void* ud)
{
  co_newlua(Co);
  co_export(Co);
  coOs_born(Co);
  coN_born(Co);
}

static int co_palive(lua_State* L)
{
  int z;
  co* Co = NULL;
  co_C(L, Co);
  strncpy(Co->core, "./co.lua", sizeof(Co->core));
  co_assert(lua_gettop(L) == 0);
  co_pushcore(L, Co);
  lua_pushvalue(L, -1);lua_setglobal(L, "core");
  lua_getfield(L, -1, "arg"); co_assert(lua_istable(L, -1));
  lua_getfield(L, -1, "core");
  if (lua_isstring(L, -1))
  {
    const char* core = NULL;
    size_t len = 0;
    core = lua_tolstring(L, -1, &len);
    if (len >= sizeof(Co->core))
    {
      co_trace(Co, CO_MOD_CORE, CO_LVDEBUG, "arg.core is larger than %u, use default %s", sizeof(Co->core), Co->core);
    }
    else
    {
      strncpy(Co->core, core, sizeof(Co->core));
    }
    lua_pop(L, 3); co_assert(lua_gettop(L) == 0);
  }
  else
  {
    co_trace(Co, CO_MOD_CORE, CO_LVDEBUG, "arg.core is NIL, use default %s", Co->core);
  }
  z = luaL_loadfile(L, Co->core); if (z) lua_error(L);
  z = lua_pcall(L, 0, 0, 0); if (z) lua_error(L);
  co_assert(lua_gettop(L) == 0);
  return 0;
}

static void co_alive(co* Co, void* ud)
{
  int z;
  lua_State* L = NULL;
  L = co_L(Co);
  co_assert(lua_gettop(L) == 0);
  lua_pushcfunction(L, co_palive);
  z = lua_pcall(L, 0, 0, 0);
  if (z)
  {
    co_trace(Co, CO_MOD_CORE, CO_LVFATAL, lua_tostring(L, -1));
    lua_pop(L, 1);
    co_assert(lua_gettop(L) == 0);
    coR_throw(Co, CO_ERRSCRIPTCALL);
  }
  co_assert(lua_gettop(L) == 0);
}

static void co_free(co* Co)
{
  coOs_die(Co);
  coN_die(Co);
  co_deletelua(Co);
  co_assert((Co->xlloc == co_xlloc) == (Co->umem == sizeof(*Co)));
  (*Co->xlloc)(NULL, Co, sizeof(co), 0);
}

static void co_newlua(co* Co)
{
  lua_State* L = co_L(Co);
  co_assert(!L);
  L = lua_newstate(co_lualloc, Co);
  co_L(Co) = L;
  if (!L) coR_throw(Co, CO_ERRSCRIPTNEW);
  lua_atpanic(L, co_panic);
}

static void co_deletelua(co* Co)
{
  lua_State* L = co_L(Co);
  if (L) lua_close(L);
}

static void co_pexportcore(co* Co, lua_State* L)
{
  co_assert(lua_gettop(L) == 0);
  luaL_openlibs(L);
  lua_newtable(L); /* core? the name is not important */
  lua_rawsetp(L, LUA_REGISTRYINDEX, Co);
  co_assert(lua_gettop(L) == 0);
}

static void co_pexportinfo(co* Co, lua_State* L)
{
  co_assert(lua_gettop(L) == 0);
  co_pushcore(L, Co);
  lua_newtable(L);
  lua_pushvalue(L, -1); lua_setfield(L, -3, "info"); /* core.info */
  lua_pushstring(L, LOLICORE_COPYRIGHT); lua_setfield(L, -2, "copyright");
  lua_pushstring(L, LOLICORE_AUTHOR); lua_setfield(L, -2, "author");
  lua_pushnumber(L, LOLICORE_VERSION); lua_setfield(L, -2, "version");
  lua_pushstring(L, LOLICORE_VERSION_REPOS); lua_setfield(L, -2, "reposversion");
  lua_pushstring(L, LOLICORE_PLATSTR); lua_setfield(L, -2, "platform");
  lua_pop(L, 2); /* core.info */
  co_assert(lua_gettop(L) == 0);
}

static void co_pexportarg(co* Co, lua_State* L)
{
  const char** argv = NULL;
  int argc = 0, i = 0;
  argv = Co->argv;
  argc = Co->argc;
  co_assert(lua_gettop(L) == 0);
  co_pushcore(L, Co);
  lua_newtable(L);
  lua_pushvalue(L, -1); lua_setfield(L, -3, "arg"); /* core.arg */
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
  lua_pop(L, 2); /* core.arg */
  co_assert(lua_gettop(L) == 0);
}

static void co_pexportapi(co* Co, lua_State* L)
{
  static const luaL_Reg co_funcs[] =
  {
    {"kill", co_export_kill},
    {"enabletrace", co_export_enabletrace},
    {"getmem", co_export_getmem},
    {"setmaxmem", co_export_setmaxmem},
    {NULL, NULL},
  };
  co_assert(lua_gettop(L) == 0);
  co_pushcore(L, Co);
  lua_newtable(L);
  luaL_setfuncs(L, co_funcs, 0);
  lua_setfield(L, -2, "base"); /* core.base */
  lua_pop(L, 1); /* core */
  co_assert(lua_gettop(L) == 0);
}

static int co_pexport(lua_State* L)
{
  co* Co = NULL;
  co_C(L, Co);
  co_assert(lua_gettop(L) == 0);
  co_pexportcore(Co, L);
  co_pexportinfo(Co, L);
  co_pexportarg(Co, L);
  co_pexportapi(Co, L);
  co_assert(lua_gettop(L) == 0);
  return 0;
}

static void co_export(co* Co)
{
  int z;
  lua_State* L = co_L(Co);
  co_assert(lua_gettop(L) == 0);
  lua_pushcfunction(L, co_pexport);
  z = lua_pcall(L, 0, 0, 0);
  if (z)
  {
    co_trace(Co, CO_MOD_CORE, CO_LVFATAL, lua_tostring(L, -1));
    lua_pop(L,1); co_assert(lua_gettop(L) == 0);
    coR_throw(Co, CO_ERRSCRIPTCALL);
  }
  co_assert(lua_gettop(L) == 0);
}

static void co_fatalerror(co* Co, int e)
{
  switch(e)
  {
  case CO_ERRMEM:
  case CO_ERRSCRIPTNEW:
  case CO_ERRSCRIPTCALL:
  default:
    co_trace(Co, CO_MOD_CORE, CO_LVFATAL, "%s", co_errorstr(Co, e));
  }
}

static const char* co_modname(co* Co, int mod)
{
  static const char* _mn[CO_MOD_SCRIPT+1] =
  {
    "co","coN", "coS",
  };
  co_assert(mod >= CO_MOD_CORE && mod <= CO_MOD_SCRIPT);
  return _mn[mod];
}

static const char* co_lvname(co* Co, int lv)
{
  static const char* _ln[CO_LVINFO+1] =
  {
    "FATAL","DEBUG", "INFO",
  };
  co_assert(lv >= CO_LVFATAL && lv <= CO_LVINFO);
  return _ln[lv];
}

#define CO_OK 0
#define CO_ERRRUN 1
#define CO_ERRMEM 2
#define CO_ERRSCRIPTPANIC 3
#define CO_ERRSCRIPTNEW 4
#define CO_ERRSCRIPTCALL 5
#define CO_ERRX 6
static const char* co_errorstr(co* Co, int e)
{
  static const char* _es[CO_ERRX+1] =
  {
    "ok!","runtime error", "memory is not enough\?", "script paniced!", "memory is not enough to new script", "failed to call script",
    "xxxxx error\?",
  };
  co_assert(e >= CO_OK && e <= CO_ERRX);
  return _es[e];
}

static int co_panic(lua_State* L)
{
  co* Co = NULL;
  co_C(L, Co);
  co_trace(Co, CO_MOD_CORE, CO_LVFATAL, "atpanic\?!");
  coR_throw(Co, CO_ERRSCRIPTPANIC);
  return 0;
}

static void* co_lualloc(void* ud, void* p, size_t os, size_t ns)
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

static void* co_xlloc(void* ud, void* p, size_t os, size_t ns)
{
  void* x = NULL;
  co* Co = (co*)ud;
  size_t m = 0;
  if (Co)
  {
    m = Co->umem;
    co_assert(m >= os);
    m -= os;
    m += ns;
    if (m > Co->maxmem)
    {
      /* co_assertex(0, "used mem is larger than max mem!"); */
      return NULL;
    }
  }
  if (ns == 0){free(p);}
  else{x = realloc(p, ns);}
  if (Co){Co->umem = m;}
  return x;
}

static int co_export_kill(lua_State* L)
{
  co* Co = NULL;
  co_C(L, Co);
  Co->bactive = 0;
  return 0;
}

static int co_export_enabletrace(lua_State* L)
{
  co* Co = NULL;
  int benable = 0;
  co_C(L, Co);
  benable = luaL_checkint(L, 1);
  Co->btrace = benable;
  return 0;
}

static int co_export_setmaxmem(lua_State* L)
{
  co* Co = NULL;
  size_t maxmem;
  co_C(L, Co);
  maxmem = co_cast(size_t, luaL_checkunsigned(L, 1));
  Co->maxmem = maxmem > Co->maxmem ? maxmem : Co->maxmem;
  return 0;
}

static int co_export_getmem(lua_State* L)
{
  co* Co = NULL;
  co_C(L, Co);
  lua_pushnumber(L, Co->umem);
  lua_pushnumber(L, Co->maxmem);
  return 2;
}

void co_trace(co* Co, int mod, int lv, const char* msg, ...)
{
  va_list msgva;
  if (!Co->tf) return;
  va_start(msgva, msg);
  Co->tf(Co, mod, lv, msg, msgva);
  va_end(msgva);
}