/*

LoliCore program entry point.
Chamz Lau, Copyright (C) 2013-2017
2013/02/26 20:51:04

*/

#include "co.h"
#if LOLICORE_PLAT == LOLICORE_PLAT_WIN32
#include <crtdbg.h>
#endif

void* externalxlloc(void* ud, void* p, size_t os, size_t ns)
{
  void* x = NULL;
  if (ns == 0){free(p);}
  else{x = realloc(p, ns);}
  return x;
}

void externaltracef(lolicore* Co, int mod, int lv, const char* msg, va_list msgva)
{
  printf("<%s><%s> ", lolicore_getmodname(Co, mod), lolicore_getlvname(Co, lv));
  vprintf(msg, msgva);
  printf("\n");
}

int main(int argc, const char** argv)
{
  lolicore* Co;
  co_xllocf x = NULL;
  /* Todo: hide plat */
#if LOLICORE_PLAT == LOLICORE_PLAT_WIN32
  _CrtSetDbgFlag( _CRTDBG_ALLOC_MEM_DF | _CRTDBG_LEAK_CHECK_DF );
#endif

#if LOLICORE_USE_EXTERNALXLLOC
  x = externalxlloc;
#endif
  Co = lolicore_born(argc, argv, x, NULL, externaltracef);if (!Co){return 1;}
  lolicore_alive(Co);
  lolicore_die(Co);
  return 0;
}
