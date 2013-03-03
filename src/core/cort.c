/*

LoliCore runtime
Chamz Lau
2013/03/03 13:54:37

*/

#include "cort.h"

void coR_throw(co* Co, int status)
{
  if (Co->errjmp) {Co->errjmp->status = status; longjmp(Co->errjmp->b, 1);}
  else {abort();}
}

int coR_pcall(co* Co, coR_pfunc f, void* ud)
{
  co_longjmp lj;
  lj.status = 0;
  lj.pre = Co->errjmp;
  Co->errjmp = &lj;
  if (0 == setjmp(Co->errjmp->b))
  {
    (*f)(Co, ud);
  }
  co_assert(Co->errjmp == &lj);
  Co->errjmp = Co->errjmp->pre;
  return lj.status;
}
