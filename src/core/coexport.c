/*

Core Export
Chamz Lau, Copyright (C) 2013-2017
2013/07/28 13:07:59

*/

#include "codef.h"

LOLICORE_EXPORT int luaopen_lolitaext(lua_State* L)
{
  /* Lua�İ汾���ܼ���,������������ݼ��õ�������û���壬�����Ʋ����ݣ���ô��⣿ �ð汾�ַ����Ƚϸ����� */
#ifndef LOLICORE_LUA_514
  const lua_Number* v = lua_version(L);
  printf("version:%d\n", (int)(*v));
#endif
  return 0;
}
