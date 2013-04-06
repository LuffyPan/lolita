/*

LoliCore memory
Chamz Lau, Copyright (C) 2013-2017
2013/03/03 12:58:23

*/

#ifndef _COMM_H_
#define _COMM_H_

#include "codef.h"
#include "cort.h"

void* coM_xllocmem(co* Co, void* p, size_t os, size_t ns, int bthrow);

#define coM_newmem(Co, s) coM_xllocmem(Co, NULL, 0, (s), 1)
#define coM_deletemem(Co, p, s) coM_xllocmem(Co, (p), (s), 0, 1)
#define coM_newobj(Co, t) co_cast(t*, coM_xllocmem(Co, NULL, 0, sizeof(t), 1))
#define coM_deleteobj(Co, p) coM_xllocmem(Co, (p), sizeof(*(p)), 0, 1)
#define coM_newvector(Co, t, n) co_cast(t*, _coM_xllocvector(Co, NULL, 0, n, sizeof(t)))
#define coM_deletevector(Co, p, n) _coM_xllocvector(Co, (p), n, 0, sizeof((p)[0]))
#define coM_renewvector(Co, t, p, on, nn) co_cast(t*, _coM_xllocvector(Co, (p), (on), (nn), sizeof(t)))

#define _coM_maxsizet ((~((size_t)0)) - 2)
#define _coM_xllocvector(Co, p, on, nn, e) \
  ((co_cast(size_t, (nn)) > _coM_maxsizet/(e)) ? \
  (coR_throw(Co,1111), (void*)NULL) :\
  coM_xllocmem(Co, p, (on)*(e), (nn)*(e), 1))

#endif
