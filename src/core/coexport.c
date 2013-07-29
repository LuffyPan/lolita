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
  /* Lua�İ汾���ܼ���,������������ݼ��õ�������û���壬�����Ʋ����ݣ���ô��⣿ �ð汾�ַ����Ƚϸ����� */
#ifndef LOLICORE_LUA_514
  const lua_Number* v = lua_version(L);
  printf("version:%d\n", (int)(*v));
#endif

  acfn = lua_getallocf(L, (void**)&ud);
  printf("AllocFunc:%0x, UserData:%0x\n", acfn, ud);
  Co = lolicore_born(0, NULL, NULL, NULL, NULL, L);
  if (!Co)
  {
    printf("core born failed\n");
    return 0;
  }
  lolicore_pushcore(Co);
  return 1;
}
