/*

LoliCore program entry point.
Chamz Lau, Copyright (C) 2013-2017
2013/02/26 20:51:04

*/

#include "co.h"
#if LOLICORE_PLAT == LOLICORE_PLAT_WIN32
#include <crtdbg.h>
#endif

int main(int argc, const char** argv)
{
  lolicore* Co;
  /* Todo: hide plat */
#if LOLICORE_PLAT == LOLICORE_PLAT_WIN32
  _CrtSetDbgFlag( _CRTDBG_ALLOC_MEM_DF | _CRTDBG_LEAK_CHECK_DF );
#endif
  Co = lolicore_born(argc, argv, NULL, NULL);if (!Co){return 1;}
  lolicore_active(Co);
  lolicore_die(Co);
  return 0;
}
