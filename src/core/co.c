/*

LoliCore.
Chamz Lau, Copyright (C) 2013-2017
2013/02/26 21:11:26

*/

#include "co.h"
#include "cort.h"
#include "cos.h"
#include "conet.h"

static void* _co_xlloc(void* p, size_t os, size_t ns);
static void co_new(co* Co, void* ud);
static void co_active(co* Co, void* ud);
static void co_free(co* Co);

lolicore* lolicore_born(int argc, const char** argv)
{
  co* Co;
  co_xlloc fx = _co_xlloc;
  Co = co_cast(co*, (*fx)(NULL, 0, sizeof(co)));
  if (NULL == Co) return NULL;
  Co->btrace = 1; /* process specially */
  Co->fxlloc = fx;
  Co->errjmp = NULL;
  Co->argc = argc;
  Co->argv = argv;
  Co->bactive = 0;
  Co->L = NULL;
  Co->N = NULL;
  if (0 != coR_pcall(Co, co_new, NULL))
  {
    co_free(Co);
    co_traceerror(Co, "co failed while born\n");
    return NULL;
  }
  co_traceinfo(Co, "co borned..\n");
  return (lolicore*)Co;
}

void lolicore_active(lolicore* Co)
{
  coR_runerror(Co, 0 == coR_pcall(Co, co_active, NULL));
}

void lolicore_die(lolicore* Co)
{
  co_free(Co);
  co_traceinfo(Co, "co died..\n");
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
  }
}

static void co_free(co* Co)
{
  coS_die(Co);
  coN_die(Co);
  (*Co->fxlloc)(Co, sizeof(co), 0);
}

static void* _co_xlloc(void* p, size_t os, size_t ns)
{
  if (ns == 0) {free(p);return NULL;}
  else{return realloc(p, ns);}
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

void co_trace(co* Co, int tracelv, const char* fmt, ...)
{
  va_list va;
  if (tracelv < Co->btrace) return;
  va_start(va, fmt);
  vprintf(fmt, va);
  va_end(va);
}