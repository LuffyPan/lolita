/*

LoliCore.
Chamz Lau, Copyright (C) 2013-2017
2013/02/26 21:10:58

*/

#ifndef _CO_H_
#define _CO_H_

#include "codef.h"

lolicore* lolicore_born(int argc, const char** argv, co_xllocf x, void* ud, co_tracef tf, lua_State* L);
void lolicore_alive(lolicore* Co);
void lolicore_die(lolicore* Co);
void lolicore_pushcore(lolicore* Co);
int lolicore_gettracelv(lolicore* Co);
size_t lolicore_getusedmem(lolicore* Co);
size_t lolicore_getmaxmem(lolicore* Co);
const char* lolicore_getmodname(lolicore* Co, int mod);
const char* lolicore_getlvname(lolicore* Co, int lv);

co* co_C(lua_State* L);

#define co_L(Co) ((Co)->L)
/* #define co_C(L, Co) lua_getallocf((L), (void**)&Co); co_assert(Co && co_L(Co) == L) */
#if LOLICORE_LUA_514
  /* �ú�ģ��ʧ�ܻᵼ�����ݲ�һ�� */
  #define lua_rawgetp(L, t, p) lua_pushlightuserdata(L, p); lua_rawget(L, t)
  #define lua_rawsetp(L, t, p) lua_pushlightuserdata(L, p); lua_insert(L, -2); lua_rawset(L, t)
  #define luaL_checkunsigned(L, idx) (unsigned int)luaL_checknumber(L, idx)
  #define luaL_setfuncs(L, l, nups) co_assert(nups == 0); luaL_register(L, NULL, l)
#endif
#define co_pushcore(L, Co) lua_getfield(L, LUA_REGISTRYINDEX, "lolita.core"); co_assert(lua_istable(L, -1));

#endif