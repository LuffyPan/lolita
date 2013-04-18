/*

LoliCore.
Chamz Lau, Copyright (C) 2013-2017
2013/02/26 21:10:58

*/

#ifndef _CO_H_
#define _CO_H_

#include "codef.h"

lolicore* lolicore_born(int argc, const char** argv, co_xllocf x, void* ud, co_tracef tf);
void lolicore_alive(lolicore* Co);
void lolicore_die(lolicore* Co);
int lolicore_gettracelv(lolicore* Co);
size_t lolicore_getusedmem(lolicore* Co);
size_t lolicore_getmaxmem(lolicore* Co);
const char* lolicore_getmodname(lolicore* Co, int mod);
const char* lolicore_getlvname(lolicore* Co, int lv);

#define co_L(Co) ((Co)->L)
#define co_C(L, Co) lua_getallocf((L), (void**)&Co); co_assert(Co && co_L(Co) == L)
#define co_pushcore(L, Co) lua_rawgetp(L, LUA_REGISTRYINDEX, Co); co_assert(lua_istable(L, -1));

#endif