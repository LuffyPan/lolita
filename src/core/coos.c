/*

LoliCore OS
Chamz Lau, Copyright (C) 2013-2017
2013/03/16 20:48:02

*/

#include "coos.h"

#if LOLICORE_PLAT == LOLICORE_PLAT_WIN32
  #include <Windows.h>
#endif

double coOs_gettime()
{
#if LOLICORE_PLAT == LOLICORE_PLAT_WIN32
  LARGE_INTEGER frequency;
  LARGE_INTEGER counter;
  double dfre, dc, sec;
  QueryPerformanceFrequency(&frequency); dfre = co_cast(double, frequency.QuadPart);
  QueryPerformanceCounter(&counter); dc = co_cast(double, counter.QuadPart);
  sec = dc / dfre;
  return sec;
#else
  return 0.0f;
#endif
}

int coOs_export_gettime(lua_State* L)
{
  lua_pushnumber(L, coOs_gettime());
  return 1;
}