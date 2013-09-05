/*

Lolita Core net
Chamz Lau, Copyright (C) 2013-2017
2013/03/04 21:15:41

*/

#ifndef _CONET_H_
#define _CONET_H_

#include "codef.h"

void coN_born(co* Co);
void coN_die(co* Co);

#define coN_traceinfo(Co, msg, ...) co_trace((Co), CO_MOD_NET, CO_LVINFO, msg, ##__VA_ARGS__)
#define coN_tracedebug(Co, msg, ...) co_trace((Co), CO_MOD_NET, CO_LVDEBUG, msg, ##__VA_ARGS__)
#define coN_tracefatal(Co, msg, ...) co_trace((Co), CO_MOD_NET, CO_LVFATAL, msg, ##__VA_ARGS__)

#endif
