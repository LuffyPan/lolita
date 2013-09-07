/*

Lolita Core.
Chamz Lau, Copyright (C) 2013-2017
2013/02/26 21:10:58

*/

#ifndef _CO_H_
#define _CO_H_

#include "codef.h"

co*core_born(int argc, const char** argv, co_xllocf x, void* ud, co_tracef tf, lua_State* L);
void core_alive(co* Co);
void core_die(co* Co);
void core_pushcore(co* Co);
int core_gettracelv(co* Co);
size_t core_getusedmem(co* Co);
size_t core_getmaxmem(co* Co);
const char* core_getmodname(co* Co, int mod);
const char* core_getlvname(co* Co, int lv);

co* co_C(lua_State* L);
int co_pcallmsg(lua_State* L);

#define co_L(Co) ((Co)->L)
/* #define co_C(L, Co) lua_getallocf((L), (void**)&Co); co_assert(Co && co_L(Co) == L) */
#if LOLITA_CORE_LUA_514
  /* 用宏模拟失败会导致数据不一致 */
  #define lua_rawgetp(L, t, p) lua_pushlightuserdata(L, p); lua_rawget(L, t)
  #define lua_rawsetp(L, t, p) lua_pushlightuserdata(L, p); lua_insert(L, -2); lua_rawset(L, t)
  #define luaL_checkunsigned(L, idx) (unsigned int)luaL_checknumber(L, idx)
  #define luaL_setfuncs(L, l, nups) co_assert(nups == 0); luaL_register(L, NULL, l)
#endif
#define co_pushcore(L, Co) lua_getfield(L, LUA_REGISTRYINDEX, "lolita.core"); co_assert(lua_istable(L, -1));

#endif