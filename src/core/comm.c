/*

Lolita Core memory
Chamz Lau, Copyright (C) 2013-2017
2013/03/03 12:59:23

*/

#include "comm.h"

void* coM_xllocmem(co* Co, void* p, size_t os, size_t ns, int bthrow)
{
  void* np;
  co_assert((os == 0) == (p == NULL));
  np = (*Co->xlloc)(Co->ud, p, os, ns);
  if (np == NULL && ns > 0)
  {
    co_assertex(ns > os, "failed when shrinking mem..");
    if (bthrow) coR_throw(Co, CO_ERRMEM); else return NULL;
  }
  co_assert((ns == 0) == (np == NULL));
  return np;
}
