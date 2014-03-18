/*

Lolita Core Compat
Chamz Lau, Copyright (C) 2013-2017
2014/03/18 12:56:42

*/

#ifndef _COMPAT_H_
#define _COMPAT_H_

#include "lua.h"
#include "lauxlib.h"

#if LUA_VERSION_NUM == 501

/* Only compact the api or defines that used */
#define LUA_OK 0

#define LUA_UNSIGNED unsigned int
typedef LUA_UNSIGNED lua_Unsigned;

LUA_API int (lua_absindex)(lua_State *L, int idx);
LUA_API const lua_Number* lua_version(lua_State *L);
LUA_API void (lua_rawgetp)(lua_State* L, int idx, const void* p);
LUA_API void (lua_rawsetp)(lua_State* L, int idx, const void* p);
LUA_API lua_Number (lua_tonumberx)(lua_State *L, int index, int *isnum);
LUA_API lua_Integer (lua_tointegerx)(lua_State *L, int idx, int *isnum);
LUA_API lua_Unsigned (lua_tounsignedx)(lua_State *L, int idx, int *isnum);
#define lua_tounsigned(L,i) lua_tounsignedx(L,i,NULL)
LUALIB_API lua_Unsigned (luaL_checkunsigned)(lua_State* L, int numArg);
LUALIB_API void (luaL_setfuncs)(lua_State *L, const luaL_Reg *l, int nup);
LUA_API void (lua_len)(lua_State *L, int idx);
LUALIB_API int (luaL_len)(lua_State *L, int idx);
LUALIB_API const char *(luaL_tolstring)(lua_State *L, int idx, size_t *len);

LUALIB_API void (luaL_checkversion_)(lua_State *L, lua_Number ver);
#define luaL_checkversion(L) luaL_checkversion_(L, LUA_VERSION_NUM)

#endif

#endif
