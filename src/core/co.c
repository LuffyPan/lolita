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

static void* _co_xlloc(void* ud, void* p, size_t os, size_t ns);
static void co_new(co* Co, void* ud);
static void co_active(co* Co, void* ud);
static void co_free(co* Co);

lolicore* lolicore_born(int argc, const char** argv, co_xlloc x, void* ud)
{
  int z = 0;
  co* Co;
  x = x ? x : _co_xlloc;
  Co = co_cast(co*, (*x)(x == _co_xlloc ? NULL : ud, NULL, 0, sizeof(co)));
  if (NULL == Co) return NULL;
  Co->xlloc = x;
  Co->ud = ud;
  Co->umem = 0;
  Co->maxmem = 4096 * 20;
  if (Co->xlloc == _co_xlloc)
  {
    Co->ud = (void*)Co;
    Co->umem = sizeof(*Co);
    co_assertex(Co->umem <= Co->maxmem, "maxmem is set to small!");
  }
  Co->btrace = 1; /* process specially */
  Co->errjmp = NULL;
  Co->argc = argc;
  Co->argv = argv;
  Co->bactive = 0;
  Co->L = NULL;
  Co->N = NULL;
  z = coR_pcall(Co, co_new, NULL);
  if (z)
  {
    printf("mem:%u/%u\n", Co->umem, Co->maxmem);
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
    printf("mem:%u/%u\n", Co->umem, Co->maxmem);
    return;
  }
}

void lolicore_die(lolicore* Co)
{
  co_free(Co);
}

static void co_new(co* Co, void* ud)
{
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
  co_assert(Co->umem == sizeof(*Co));
  (*Co->xlloc)(NULL, Co, sizeof(co), 0);
}

static void* _co_xlloc(void* ud, void* p, size_t os, size_t ns)
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
  co_traceinfo(Co, "co be killed!\n");
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
  co_traceinfo(Co, "co enable trace!\n");
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

void co_trace(co* Co, int tracelv, const char* fmt, ...)
{
  va_list va;
  if (tracelv > Co->btrace) return;
  va_start(va, fmt);
  vprintf(fmt, va);
  va_end(va);
}