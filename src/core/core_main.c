/*

LoliCore program entry point.
Chamz Lau, Copyright (C) 2013-2017
2013/02/26 20:51:04

*/

#include "core.h"

int main(int argc, const char** argv)
{
  lua_State* L;
  int z = 0;
  
  L = luaL_newstate();
  luaL_openlibs(L);

  printf("Copyright:      %s\n", LOLICORE_COPYRIGHT);
  printf("Version:        %d\n", LOLICORE_VERSION);
  printf("ReposVersion:   %s\n", LOLICORE_VERSION_REPOS);
  printf("Platform:       %s\n", LOLICORE_PLATSTR);

  lua_close(L);
  return z;
}