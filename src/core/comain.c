/*

Lolita Core program entry point.
Chamz Lau, Copyright (C) 2013-2017
2013/02/26 20:51:04

*/

#include "co.h"
#if LOLITA_CORE_PLAT == LOLITA_CORE_PLAT_WIN32 && !defined(__MINGW32__)
#include <crtdbg.h>
#elif LOLITA_CORE_PLAT == LOLITA_CORE_PLAT_LINUX
#include <sys/resource.h>
#include <sys/types.h>
#endif

static void prepare();
static void trace(co* Co, int mod, int lv, const char* moddesc, const char* lvdesc, const char* msg, va_list msgva);
static void exf(co* Co, lua_State* L, void* feature);

int main(int argc, const char** argv)
{
  co* Co;
  co_gene Coge = { 0 };

  prepare();

  Coge.exf = exf;
  Coge.tf = trace;
  Coge.ud = NULL;
  Co = core_born(argc, argv, NULL, &Coge, 0, NULL);if (!Co){return 1;}
  core_alive(Co);
  core_die(Co);
  return 0;
}

static void prepare()
{
#if LOLITA_CORE_PLAT == LOLITA_CORE_PLAT_WIN32 && !defined(__MINGW32__)
  _CrtSetDbgFlag(_CRTDBG_ALLOC_MEM_DF | _CRTDBG_LEAK_CHECK_DF);
#endif

#if LOLITA_CORE_PLAT == LOLITA_CORE_PLAT_LINUX
  /* enable coredump */
  struct rlimit rl = { -1, -1 };
  setrlimit(RLIMIT_CORE, &rl);
#endif
}

static void trace(co* Co, int mod, int lv, const char* moddesc, const char* lvdesc, const char* msg, va_list msgva)
{
  /* write to file? */
  /*
  printf("<%s> <%s> ", moddesc, lvdesc);
  vprintf(msg, msgva);
  printf("\n");
  */
}

static void exf(co* Co, lua_State* L, void* feature)
{
  /* promise the lua_gettop(L) is 0 when finished */
  /*
  co_assert(0 == lua_gettop(L));
  lua_newtable(L);
  lua_setglobal(L, "exf");
  co_assert(0 == lua_gettop(L));
  */
}
