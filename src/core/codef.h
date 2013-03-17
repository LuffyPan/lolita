/*

LoliCore definitions
Chamz Lau, Copyright (C) 2013-2017
2013/03/03 10:37:35

*/

#ifndef _CODEF_H_
#define _CODEF_H_

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include <errno.h>
#include <setjmp.h>
#include <assert.h>
#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"
#include "coconf.h"

#define LOLICORE_PLAT_WIN32 (1)
#define LOLICORE_PLAT_UNIX (2)
#define LOLICORE_PLAT_LINUX (3)
#define LOLICORE_PLAT_MACOSX (4)

#ifndef LOLICORE_PLAT
  #error No definition of LOLICORE_PLAT!
#endif

#if LOLICORE_PLAT == LOLICORE_PLAT_WIN32
  #define LOLICORE_PLATSTR "win32"
#elif LOLICORE_PLAT == LOLICORE_PLAT_UNIX
  #define LOLICORE_PLATSTR "unix"
#elif LOLICORE_PLAT == LOLICORE_PLAT_LINUX
  #define LOLICORE_PLATSTR "linux"
#elif LOLICORE_PLAT == LOLICORE_PLAT_MACOSX
  #define LOLICORE_PLATSTR "macosx"
#else
  #error Unknown LOLICORE_PLAT!
#endif

#define LOLICORE_VERSION 1990
#define LOLICORE_AUTHOR "Chamz Lau"
#define LOLICORE_COPYRIGHT "LolitaCore Copyright (C) 2013-2017, " LOLICORE_AUTHOR

typedef struct coN coN;

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
  int btrace;
  co_xlloc fxlloc;
  co_longjmp* errjmp;
  int argc;
  const char** argv;
  int bactive;
  lua_State* L;
  coN* N;
};

typedef co lolicore;

#define co_cast(t, exp) ((t)(exp))
#define co_assert(x) assert((x))
#define co_assertex(x,msg) co_assert((x) && msg)
void co_trace(co* Co, int tracelv, const char* fmt, ...);
#define co_traceinfo(Co, fmt, ...) co_trace((Co), 1, fmt, ##__VA_ARGS__)
#define co_traceinfolv2(Co, fmt, ...) co_trace((Co), 2, fmt, ##__VA_ARGS__)
#define co_traceinfolv3(Co, fmt, ...) co_trace((Co), 3, fmt, ##__VA_ARGS__)
#define co_traceerror(Co, fmt, ...) co_trace((Co), 0, fmt, ##__VA_ARGS__)
#endif
