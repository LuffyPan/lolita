/*

LoliCore runtime
Chamz Lau, Copyright (C) 2013-2017
2013/03/03 13:53:52

*/

#ifndef _CORT_H_
#define _CORT_H_

#include "codef.h"

typedef void (*coR_pfunc)(co* Co, void* ud);

void coR_throw(co* Co, int status);
int coR_pcall(co* Co, coR_pfunc f, void* ud);
#define coR_runerror(Co, e) if (!(e)) {printf("runerror:%s\n", #e); coR_throw((Co), 1);}

#endif
