/*

LoliCore memory
Chamz Lau
2013/03/03 12:59:23

*/

#include "comm.h"

void* coM_xllocmem(co* Co, void* p, size_t os, size_t ns)
{
  void* np;
  co_assert((os == 0) == (p == NULL));
  np = (*Co->fxlloc)(p, os, ns);
  if (np == NULL && ns > 0)
  {
    co_assertex(ns > os, "failed when shrinking mem..");
    coR_throw(Co, 1);
  }
  co_assert((ns == 0) == (np == NULL));
  return np;
}
