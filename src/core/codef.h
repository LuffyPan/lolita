/*

LoliCore definitions
Chamz Lau
2013/03/03 10:37:35

*/

#ifndef _CODEF_H_
#define _CODEF_H_

#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include <errno.h>
#include <setjmp.h>
#include <assert.h>
#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

typedef struct co_longjmp co_longjmp;
typedef struct co co;
typedef void* (*co_xlloc)(void* p, size_t olds, size_t news);

struct co_longjmp
{
  volatile int status;
  co_longjmp* pre;
  jmp_buf b;
};

struct co
{
  co_xlloc fxlloc;
  co_longjmp* errjmp;
  int argc;
  const char** argv;
  int bactive;
  lua_State* L;
};

#define co_cast(t, exp) ((t)(exp))
#define co_assert(x) assert((x))
#define co_assertex(x,msg) co_assert((x) && msg)

#endif
