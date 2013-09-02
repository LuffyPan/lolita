/*

Core Export
Chamz Lau, Copyright (C) 2013-2017
2013/07/28 13:07:59

*/

#include "co.h"

LOLICORE_EXPORT int luaopen_lolitaext(lua_State* L)
{
  lolicore* Co = NULL;
  void* ud = NULL;
  lua_Alloc acfn = NULL;
  /* Lua的版本检测好鸡肋,二进制如果不兼容，怎么检测，版本字符串更靠谱吧? */
#ifndef LOLICORE_LUA_514
  const lua_Number* v = lua_version(L);
  printf("version:%d\n", (int)(*v));
#endif

  acfn = lua_getallocf(L, (void**)&ud);
  printf("AllocFunc:%p, UserData:%p\n", acfn, ud);
  Co = lolicore_born(0, NULL, NULL, NULL, NULL, L);
  if (!Co)
  {
    printf("core born failed\n");
    return 0;
  }
  lolicore_pushcore(Co);
  return 1;
}
