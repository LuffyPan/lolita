/*

LoliCore.
Chamz Lau Copyright (C) 2013-2017
2013/02/26 21:10:58

*/

#ifndef _CO_H_
#define _CO_H_

#include "coconf.h"
#include "codef.h"
#include "cort.h"
#include "cos.h"

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
#define LOLICORE_COPYRIGHT "LolitaCore Copyright (C) 2006-2013, " LOLICORE_AUTHOR

typedef co lolicore;

lolicore* lolicore_born(int argc, const char** argv);
void lolicore_active(lolicore* L);
void lolicore_die(lolicore* L);

int co_kill(lua_State* L);

#endif