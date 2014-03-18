/*

Lolita Core Compat
Chamz Lau, Copyright (C) 2013-2017
2014/03/18 12:56:42

*/

#if LUA_VERSION_NUM == 501

#include "compat.h"

LUA_API const lua_Number* lua_version(lua_State *L)
{
    static const lua_Number version = LUA_VERSION_NUM;
    return &version;
}

LUA_API int lua_absindex(lua_State *L, int idx)
{
    if (idx > 0 || idx <= LUA_REGISTRYINDEX)
        return idx;
    else
    {
        return lua_gettop(L) + idx + 1;
    }
}

LUA_API void lua_rawgetp(lua_State* L, int idx, const void* p)
{
    idx = lua_absindex(L, idx);
    lua_pushlightuserdata(L, (void *)p);
    lua_rawget(L, idx); 
}

LUA_API void lua_rawsetp(lua_State* L, int idx, const void* p)
{
    idx = lua_absindex(L, idx);
    lua_pushlightuserdata(L, (void *)p);
    lua_insert(L, -2);
    lua_rawset(L, idx);
}

LUA_API lua_Number lua_tonumberx(lua_State *L, int index, int *isnum)
{
    lua_Number n = lua_tonumber(L, index);
    if (isnum) {
        if (n != 0) {
            *isnum = 1;
        } else {
            switch (lua_type(L, index)) {
            case LUA_TNUMBER:
                *isnum = 1;
                break;
            case LUA_TSTRING: {
                size_t sz = 0;
                const char * number = lua_tolstring(L, index, &sz);
                if ((sz == 1 && number[0] == '0') || 
                    (sz == 3 && number[0] == '0' && (number[1] == 'x' || number[1] == 'X') && number[2] == '0')) {
                    *isnum = 1;
                } else {
                    *isnum = 0;
                }
                break;
            }
            default:
                *isnum = 0;
                break;
            }
        }
    } 
    return n;
}

LUA_API lua_Unsigned lua_tounsignedx(lua_State *L, int idx, int *isnum)
{
    lua_Number n = lua_tonumberx(L, idx, isnum);
    return (lua_Unsigned)(int)n;
}

LUA_API lua_Integer lua_tointegerx(lua_State *L, int idx, int *isnum)
{
    lua_Number n = lua_tonumberx(L, idx, isnum);
    return (lua_Integer)n;
}

LUALIB_API lua_Unsigned luaL_checkunsigned(lua_State* L, int numArg)
{
    int isnum;
    lua_Unsigned d = lua_tounsignedx(L, narg, &isnum);
    if (!isnum)
    {
        return luaL_error(L, "arg %d is not a unsigned", narg);
    }
    return d;
}

LUALIB_API void luaL_setfuncs(lua_State *L, const luaL_Reg *l, int nup)
{
    luaL_checkversion(L);
    luaL_checkstack(L, nup, "too many upvalues");
    for (; l->name != NULL; l++)
    {  /* fill the table with given functions */
        int i;
        for (i = 0; i < nup; i++){lua_pushvalue(L, -nup);}
        lua_pushcclosure(L, l->func, nup);  /* closure with those upvalues */
        lua_setfield(L, -(nup + 2), l->name);
    }
    lua_pop(L, nup);  /* remove upvalues */
}

LUA_API void lua_len(lua_State *L, int idx)
{
    int hasmeta = luaL_callmeta(L, idx, "__len");
    if (hasmeta == 0)
    {
        size_t sz = lua_objlen(L, idx);
        lua_pushnumber(L, sz);
    }
}

LUALIB_API int luaL_len(lua_State *L, int idx)
{
    int l;
    int isnum;
    lua_len(L, idx);
    l = (int)lua_tointegerx(L, -1, &isnum);
    if (!isnum)
    luaL_error(L, "object length is not a number");
    lua_pop(L, 1);  /* remove object */
    return l;
}

LUALIB_API const char *luaL_tolstring(lua_State *L, int idx, size_t *len)
{
  if (!luaL_callmeta(L, idx, "__tostring"))
  {
    /* no metafield? */
    switch (lua_type(L, idx))
    {
      case LUA_TNUMBER:
      case LUA_TSTRING:
        lua_pushvalue(L, idx);
        break;
      case LUA_TBOOLEAN:
        lua_pushstring(L, (lua_toboolean(L, idx) ? "true" : "false"));
        break;
      case LUA_TNIL:
        lua_pushliteral(L, "nil");
        break;
      default:
        lua_pushfstring(L, "%s: %p", luaL_typename(L, idx),lua_topointer(L, idx));
        break;
    }
  }
  return lua_tolstring(L, -1, len);
}

LUALIB_API void luaL_checkversion_(lua_State *L, lua_Number ver)
{
    const lua_Number *v = lua_version(L);
    if (*v != ver) luaL_error(L, "version mismatch: app. needs %f, Lua core provides %f", ver, *v);
    /* check conversions number -> integer types */
    lua_pushnumber(L, -(lua_Number)0x1234);
    if (lua_tointeger(L, -1) != -0x1234 ||
      lua_tounsigned(L, -1) != (lua_Unsigned)-0x1234)
    luaL_error(L, "bad conversion number->int;"
                  " must recompile Lua with proper settings");
    lua_pop(L, 1);
}

#endif
