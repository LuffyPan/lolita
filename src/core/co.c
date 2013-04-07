/*

LoliCore.
Chamz Lau, Copyright (C) 2013-2017
2013/02/26 21:11:26

*/

#include "co.h"
#include "cort.h"
#include "cos.h"
#include "conet.h"
#include "coos.h"
#include "comm.h"

static int co_panic(lua_State* L);
static void* co_xlloc(void* ud, void* p, size_t os, size_t ns);
static void* co_lualloc(void* ud, void* p, size_t os, size_t ns);
static void co_newlua(co* Co);
static void co_deletelua(co* Co);
static void co_born(co* Co, void* ud);
static void co_active(co* Co, void* ud);
static void co_free(co* Co);
static void co_fatalerror(co* Co, int e);
static const char* co_modname(co* Co, int mod);
static const char* co_lvname(co* Co, int lv);
static const char* co_errorstr(co* Co, int e);

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
  Co->maxmem = 4096 * 25;
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
  z = coR_pcall(Co, co_born, NULL);
  if (z)
  {
    co_fatalerror(Co, z);
    co_free(Co);
    return NULL;
  }
  return (lolicore*)Co;
}

void lolicore_active(lolicore* Co)
{
  int z = coR_pcall(Co, co_active, NULL);
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
  coN_born(Co);
  coS_born(Co);
}

static void co_active(co* Co, void* ud)
{
  Co->bactive = 1;
  while(Co->bactive)
  {
    coN_active(Co);
    coS_active(Co);
    coOs_sleep(1);
  }
}

static void co_free(co* Co)
{
  coS_die(Co);
  coN_die(Co);
  co_deletelua(Co);
  co_assert((Co->xlloc == co_xlloc) == (Co->umem == sizeof(*Co)));
  (*Co->xlloc)(NULL, Co, sizeof(co), 0);
}

static void co_newlua(co* Co)
{
  co_assert(!Co->L);
  Co->L = lua_newstate(co_lualloc, Co);
  if (!Co->L) coR_throw(Co, CO_ERRSCRIPTNEW);
  lua_atpanic(Co->L, co_panic);
}

static void co_deletelua(co* Co)
{
  if (Co->L) lua_close(Co->L);
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
  lua_getallocf(L, (void**)&Co); co_assert(Co);
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

int co_export_kill(lua_State* L)
{
  co* Co = NULL;
  lua_getallocf(L, (void**)&Co);
  co_assert(Co);
  Co->bactive = 0;
  return 0;
}

int co_export_enabletrace(lua_State* L)
{
  co* Co = NULL;
  int benable = 0;
  lua_getallocf(L, (void**)&Co);
  co_assert(Co);
  benable = luaL_checkint(L, 1);
  Co->btrace = benable;
  return 0;
}

int co_export_setmaxmem(lua_State* L)
{
  co* Co = NULL;
  size_t maxmem;
  lua_getallocf(L, (void**)&Co); co_assert(Co);
  maxmem = co_cast(size_t, luaL_checkunsigned(L, 1));
  Co->maxmem = maxmem > Co->maxmem ? maxmem : Co->maxmem;
  return 0;
}

int co_export_getmem(lua_State* L)
{
  co* Co = NULL;
  lua_getallocf(L, (void**)&Co); co_assert(Co);
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