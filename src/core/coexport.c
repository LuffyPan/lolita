/*

Core Export
Chamz Lau, Copyright (C) 2013-2017
2013/07/28 13:07:59

*/

#include "co.h"

LOLITA_CORE_EXPORT int luaopen_lolitaext(lua_State* L)
{
  co*Co = NULL;
  void* ud = NULL;
  lua_Alloc acfn = NULL;
  /* the detect version of Lua is just a kid while in this solution, string is more kaopu. */
#ifndef LOLITA_CORE_LUA_514
  const lua_Number* v = lua_version(L);
  printf("version:%d\n", (int)(*v));
#endif

  acfn = lua_getallocf(L, (void**)&ud);
  printf("AllocFunc:%p, UserData:%p\n", acfn, ud);
  Co = core_born(0, NULL, NULL, NULL, NULL, L);
  if (!Co)
  {
    printf("core born failed\n");
    return 0;
  }
  core_open(Co, 0);

  /* didn't not process die, what the fuck */
  return 1;
}
