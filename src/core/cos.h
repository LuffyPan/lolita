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

#define coS_tracefatal(Co, msg, ...) co_trace((Co), CO_MOD_SCRIPT, CO_LVFATAL, msg, ##__VA_ARGS__)
#define coS_tracedebug(Co, msg, ...) co_trace((Co), CO_MOD_SCRIPT, CO_LVDEBUG, msg, ##__VA_ARGS__)
#define coS_traceinfo(Co, msg, ...) co_trace((Co), CO_MOD_SCRIPT, CO_LVINFO, msg, ##__VA_ARGS__)

#endif
