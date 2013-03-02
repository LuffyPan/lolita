/*

LoliCore program entry point.
Chamz Lau, Copyright (C) 2013-2017
2013/02/26 20:51:04

*/

#include "core.h"

int main(int argc, const char** argv)
{
  lua_State* L = NULL;
  
  L = lolicore_born(argc, argv);
  if (!L)
  {
    return 1;
  }
  lolicore_active(L);
  lolicore_die(L);

  return 0;
}
