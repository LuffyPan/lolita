/*

Lolita Core program entry point.
Chamz Lau, Copyright (C) 2013-2017
2013/02/26 20:51:04

*/

#include "co.h"
#if LOLITA_CORE_PLAT == LOLITA_CORE_PLAT_WIN32
#include <crtdbg.h>
#endif

void* externalxlloc(void* ud, void* p, size_t os, size_t ns)
{
  void* x = NULL;
  if (ns == 0){free(p);}
  else{x = realloc(p, ns);}
  return x;
}

/* is this need controled by outside ?? */
void externaltracef(co*Co, int mod, int lv, const char* msg, va_list msgva)
{
  if (lv > core_gettracelv(Co)) return;
  printf("<%s><%s> ", core_getmodname(Co, mod), core_getlvname(Co, lv));
  vprintf(msg, msgva);
  printf("\n");
  fflush(stdout);fflush(stderr);
}

int main(int argc, const char** argv)
{
  co*Co;
  co_xllocf x = NULL;
  /* Todo: hide plat */
#if LOLITA_CORE_PLAT == LOLITA_CORE_PLAT_WIN32
  _CrtSetDbgFlag(_CRTDBG_ALLOC_MEM_DF | _CRTDBG_LEAK_CHECK_DF);
#endif

#ifdef LOLITA_CORE_USE_EXTERNALXLLOC
  x = externalxlloc;
#endif
  Co = core_born(argc, argv, x, NULL, externaltracef, NULL);if (!Co){return 1;}
  core_alive(Co);
  core_die(Co);
  return 0;
}
