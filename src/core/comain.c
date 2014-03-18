/*

Lolita Core program entry point.
Chamz Lau, Copyright (C) 2013-2017
2013/02/26 20:51:04

*/

#include "co.h"
#if LOLITA_CORE_PLAT == LOLITA_CORE_PLAT_WIN32
#include <crtdbg.h>
#endif

void prepare();

int main(int argc, const char** argv)
{
  co*Co;

  prepare();

  Co = core_born(argc, argv, NULL, NULL, 0, NULL);if (!Co){return 1;}
  core_alive(Co);
  core_die(Co);
  return 0;
}

void prepare()
{
#if LOLITA_CORE_PLAT == LOLITA_CORE_PLAT_WIN32
  _CrtSetDbgFlag(_CRTDBG_ALLOC_MEM_DF | _CRTDBG_LEAK_CHECK_DF);
#endif

#if LOLITA_CORE_PLAT == LOLITA_CORE_PLAT_LINUX
  /* enable coredump */
#endif
}