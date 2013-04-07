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
typedef co lolicore;
typedef void* (*co_xllocf)(void* ud, void* p, size_t olds, size_t news);
typedef void (*co_tracef)(lolicore* Co, int mod, int lv, const char* msg, va_list msgva);

struct co_longjmp
{
  volatile int status;
  co_longjmp* pre;
  jmp_buf b;
};

struct co
{
  int btrace;
  co_xllocf xlloc;
  co_tracef tf;
  void* ud;
  size_t umem;
  size_t maxmem;
  co_longjmp* errjmp;
  int argc;
  const char** argv;
  int bactive;
  lua_State* L;
  coN* N;
};

#define CO_OK 0
#define CO_ERRRUN 1
#define CO_ERRMEM 2
#define CO_ERRSCRIPTPANIC 3
#define CO_ERRSCRIPTNEW 4
#define CO_ERRSCRIPTCALL 5
#define CO_ERRX 6

#define CO_LVFATAL 0
#define CO_LVDEBUG 1
#define CO_LVINFO 2

#define CO_MOD_CORE 0
#define CO_MOD_NET 1
#define CO_MOD_SCRIPT 2

#define LOLICORE_LVFATAL CO_LVFATAL
#define LOLICORE_LVDEBUG CO_LVDEBUG
#define LOLICORE_LVINFO CO_LVINFO

#define LOLICORE_MOD_CORE CO_MOD_CORE
#define LOLICORE_MOD_NET CO_MOD_NET
#define LOLICORE_MOD_SCRIPT CO_MOD_SCRIPT

#define co_cast(t, exp) ((t)(exp))
#define co_assert(x) assert((x))
#define co_assertex(x,msg) co_assert((x) && msg)
void co_trace(co* Co, int mod, int lv, const char* msg, ...);
#endif
