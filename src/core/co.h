/*

LoliCore.
Chamz Lau, Copyright (C) 2013-2017
2013/02/26 21:10:58

*/

#ifndef _CO_H_
#define _CO_H_

#include "codef.h"

lolicore* lolicore_born(int argc, const char** argv, co_xlloc x, void* ud, co_tracef tf);
void lolicore_active(lolicore* Co);
void lolicore_die(lolicore* Co);
size_t lolicore_getusedmem(lolicore* Co);
size_t lolicore_getmaxmem(lolicore* Co);
const char* lolicore_getmodname(lolicore* Co, int mod);
const char* lolicore_getlvname(lolicore* Co, int lv);

int co_export_setmaxmem(lua_State* L);
int co_export_getmem(lua_State* L);
int co_export_kill(lua_State* L);
int co_export_enabletrace(lua_State* L);

#endif