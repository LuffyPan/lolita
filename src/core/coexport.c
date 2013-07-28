/*

Core Export
Chamz Lau, Copyright (C) 2013-2017
2013/07/28 13:07:59

*/

#include "codef.h"

LOLICORE_EXPORT int luaopen_lolitaext(lua_State* L)
{
  /* Lua的版本检测很鸡肋,二进制如果兼容检测得到，但是没意义，二进制不兼容，怎么检测？ 用版本字符串比较更靠谱 */
#ifndef LOLICORE_LUA_514
  const lua_Number* v = lua_version(L);
  printf("version:%d\n", (int)(*v));
#endif
  return 0;
}
