/*

Lolita Core.
Chamz Lau, Copyright (C) 2013-2017
2013/02/26 21:10:58

*/

#ifndef _CO_H_
#define _CO_H_

#include "codef.h"

co* core_born(int argc, const char** argv, co_xllocf x, void* ud, int noexport, lua_State* L);
void core_alive(co* Co);
void core_die(co* Co);
void core_open(co* Co, int x);

#endif
