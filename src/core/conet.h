/*

LoliCore net
Chamz Lau, Copyright (C) 2013-2017
2013/03/04 21:15:41

*/

#ifndef _CONET_H_
#define _CONET_H_

#include "codef.h"

void coN_born(co* Co);
void coN_active(co* Co);
void coN_die(co* Co);

int coN_export_register(lua_State* L);
int coN_export_connect(lua_State* L);
int coN_export_listen(lua_State* L);
int coN_export_push(lua_State* L);
int coN_export_close(lua_State* L);

#endif
