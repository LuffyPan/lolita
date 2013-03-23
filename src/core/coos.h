/*

LoliCore OS
Chamz Lau, Copyright (C) 2013-2017
2013/03/16 20:48:48

*/

#ifndef _COOS_H_
#define _COOS_H_

#include "codef.h"

void coOs_sleep(int msec);
int coOs_export_gettime(lua_State* L);
int coOs_export_isdir(lua_State* L);
int coOs_export_isfile(lua_State* L);
int coOs_export_ispath(lua_State* L);
int coOs_export_mkdir(lua_State* L);
int coOs_export_getcwd(lua_State* L);

#endif
