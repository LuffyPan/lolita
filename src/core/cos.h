/*

LoliCore script
Chamz Lau, Copyright (C) 2013-2017
2013/03/03 14:30:35

*/

#ifndef _COS_H_
#define _COS_H_

#include "codef.h"

void coS_born(co* Co);
void coS_die(co* Co);
void coS_active(co* Co);
lua_State* coS_lua(co* Co); /* Todo:more advanced function 2 other mod */

#endif
