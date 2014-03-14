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

char* coM_newstr(co* Co, const char* str, size_t len, size_t* newlen)
{
    char* ns = NULL;
    len = str ? strlen(str) + 1 : len ? len : 1;
    ns = co_cast(char*, coM_xllocmem(Co, NULL, 0, len + sizeof(size_t), 1));
    *((size_t*)ns) = len + sizeof(size_t);
    ns = (char*)(((size_t*)ns) + 1);
    if (str) strcpy(ns, str);
    else memset(ns, 0, len);
    if (newlen) *newlen = len;
    return ns;
}

void coM_deletestr(co* Co, char* str)
{
    size_t* p = NULL;
    if (!str) return;
    p = ((size_t*)str) - 1;
    coM_xllocmem(Co, (void*)p, *p, 0, 1);
}
