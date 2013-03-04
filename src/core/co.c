/*

LoliCore.
Chamz Lau, Copyright (C) 2013-2017
2013/02/26 21:11:26

*/

#include "co.h"

static void* _co_xlloc(void* p, size_t os, size_t ns);
static void co_new(co* Co, void* ud);
static void co_active(co* Co, void* ud);
static void co_free(co* Co);

lolicore* lolicore_born(int argc, const char** argv)
{
  co_xlloc fx = _co_xlloc;
  co* Co;
  printf("lolicore_born\n");
  Co = co_cast(co*, (*fx)(NULL, 0, sizeof(co)));
  if (NULL == Co) return NULL;
  Co->fxlloc = fx;
  Co->errjmp = NULL;
  Co->argc = argc;
  Co->argv = argv;
  Co->bactive = 0;
  Co->L = NULL;
  if (0 != coR_pcall(Co, co_new, NULL))
  {
    printf("co_new error!!\n");
    co_free(Co);
    return NULL;
  }
  return (lolicore*)Co;
}

void lolicore_active(lolicore* Co)
{
  if (0 != coR_pcall(Co, co_active, NULL))
  {
    printf("co_active error!!\n");
  }
}

void lolicore_die(lolicore* Co)
{
  printf("lolicore_die\n");
  co_free(Co);
}

static void co_new(co* Co, void* ud)
{
  coS_born(Co);
}

static void co_active(co* Co, void* ud)
{
  Co->bactive = 1;
  while(Co->bactive)
  {
    printf("lolicore_active\n");
    coS_active(Co);
  }
}

static void co_free(co* Co)
{
  coS_die(Co);
  (*Co->fxlloc)(Co, sizeof(co), 0);
}

static void* _co_xlloc(void* p, size_t os, size_t ns)
{
  if (ns == 0) {free(p);return NULL;}
  else{return realloc(p, ns);}
}

int co_kill(lua_State* L)
{
  co* Co = NULL;
  lua_getallocf(L, (void**)&Co);
  co_assert(Co);
  Co->bactive = 0;
  printf("co_kill\n");
  return 0;
}
