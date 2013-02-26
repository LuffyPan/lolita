/*

file    core_main.c
desc    LoliCore program entry point.
author  Chamz Lau Copyrigh (c) 2013-2017
date    2013/02/26 20:51:04

*/

#include "core.h"

int main(int argc, const char** argv)
{
  lua_State* L;
  int z = 0;
  
  L = luaL_newstate();
  luaL_openlibs(L);

  printf("LolitaCore\n");

  lua_close(L);
  return z;
}