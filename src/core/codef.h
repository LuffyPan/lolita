/*

Lolita Core definitions
Chamz Lau, Copyright (C) 2013-2017
2013/03/03 10:37:35

*/

#ifndef _CODEF_H_
#define _CODEF_H_

#include <stdint.h>
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
#include "compat.h"

#ifndef LOLITA_CORE_GITVER
  #define LOLITA_CORE_GITVER "none-gitver"
#endif

#define LOLITA_CORE_PLAT_WIN32 (1)
#define LOLITA_CORE_PLAT_UNIX (2)
#define LOLITA_CORE_PLAT_LINUX (3)
#define LOLITA_CORE_PLAT_MACOSX (4)

#if defined(__APPLE__)
  #define LOLITA_CORE_PLAT LOLITA_CORE_PLAT_MACOSX
#elif defined(__linux__) || defined(__linux)
  #define LOLITA_CORE_PLAT LOLITA_CORE_PLAT_LINUX
#elif defined(__unix__)
  #define LOLITA_CORE_PLAT LOLITA_CORE_PLAT_UNIX
#elif defined(_WIN32)
  #define LOLITA_CORE_PLAT LOLITA_CORE_PLAT_WIN32
#endif

#ifndef LOLITA_CORE_PLAT
  #error No definition of LOLITA_CORE_PLAT!
#endif

#if LOLITA_CORE_PLAT == LOLITA_CORE_PLAT_WIN32
  #define LOLITA_CORE_PLATSTR "win32"
  #define LOLITA_CORE_EXPORT __declspec(dllexport)
#elif LOLITA_CORE_PLAT == LOLITA_CORE_PLAT_UNIX
  #define LOLITA_CORE_PLATSTR "unix"
  #define LOLITA_CORE_EXPORT
  #define LOLITA_CORE_USE_KQUEUE
#elif LOLITA_CORE_PLAT == LOLITA_CORE_PLAT_LINUX
  #define LOLITA_CORE_PLATSTR "linux"
  #define LOLITA_CORE_EXPORT
  #define LOLITA_CORE_USE_EPOLL
#elif LOLITA_CORE_PLAT == LOLITA_CORE_PLAT_MACOSX
  #define LOLITA_CORE_PLATSTR "macosx"
  #define LOLITA_CORE_EXPORT
  #define LOLITA_CORE_USE_KQUEUE
#else
  #error Unknown LOLITA_CORE_PLAT!
#endif

#define LOLITA_CORE_VERSION 1993
#define LOLITA_CORE_AUTHOR "Chamz Lau"
#define LOLITA_CORE_COPYRIGHT "Lolita Copyright (C) 2013-2017, " LOLITA_CORE_AUTHOR

#ifndef LOLITA_CORE_LUA
  #define LOLITA_CORE_LUA LUA_VERSION
#endif

typedef struct coN coN;
typedef struct coOs coOs;

typedef struct co_longjmp co_longjmp;
typedef struct co co;
typedef void* (*co_xllocf)(void* ud, void* p, size_t olds, size_t news);
typedef void (*co_tracef)(co*Co, int mod, int lv, const char* msg, va_list msgva);

struct co_longjmp
{
  volatile int status;
  co_longjmp* pre;
  jmp_buf b;
};

struct co
{
  int noexport;
  int inneractive;
  int bactive;
  int tracelv;
  co_xllocf xlloc;
  co_tracef tf;
  void* ud;
  size_t umem;
  size_t maxmem;
  co_longjmp* errjmp;
  int argc;
  const char** argv;
  lua_State* L;
  int battachL;
  coN* N;
  coOs* Os;
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

#define LOLITA_CORE_LVFATAL CO_LVFATAL
#define LOLITA_CORE_LVDEBUG CO_LVDEBUG
#define LOLITA_CORE_LVINFO CO_LVINFO

#define LOLITA_CORE_MOD_CORE CO_MOD_CORE
#define LOLITA_CORE_MOD_NET CO_MOD_NET
#define LOLITA_CORE_MOD_SCRIPT CO_MOD_SCRIPT

#define co_cast(t, exp) ((t)(exp))
#define co_assert(x) assert((x))
#define co_assertex(x,msg) co_assert((x) && msg)
void co_trace(co* Co, int mod, int lv, const char* msg, ...);
void co_tracecallstack(co* Co, int mod, int lv, lua_State* L);

co* co_C(lua_State* L);
int co_pcallmsg(lua_State* L);

#define co_L(Co) ((Co)->L)
#define co_pushcore(L, Co) lua_getfield(L, LUA_REGISTRYINDEX, "lolita.core"); co_assert(lua_istable(L, -1)); (void)Co

#endif
