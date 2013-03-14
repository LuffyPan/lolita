/*

LoliCore.
Chamz Lau, Copyright (C) 2013-2017
2013/02/26 21:10:58

*/

#ifndef _CO_H_
#define _CO_H_

#include "codef.h"

lolicore* lolicore_born(int argc, const char** argv);
void lolicore_active(lolicore* L);
void lolicore_die(lolicore* L);

int co_export_kill(lua_State* L);
int co_export_enabletrace(lua_State* L);

#endif