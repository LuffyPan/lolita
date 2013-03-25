/*

LoliCore OS
Chamz Lau, Copyright (C) 2013-2017
2013/03/16 20:48:02

*/

#include "coos.h"
#include <sys/stat.h>

#if LOLICORE_PLAT == LOLICORE_PLAT_WIN32
  #include <Windows.h>
#else
  #include <unistd.h>
  #include <sys/types.h>
  #include <sys/resource.h>
  #include <sys/time.h>
#endif

void coOs_sleep(int msec)
{
  co_assertex(msec >= 0 && msec < 1000 * 60, "fuck, need so long..");
#if LOLICORE_PLAT == LOLICORE_PLAT_WIN32
  Sleep((DWORD)msec);
#else
  struct timeval delay;
  delay.tv_sec = 0;
  delay.tv_usec = msec * 1000; // 20 ms
  select(0, NULL, NULL, NULL, &delay);
#endif
}

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
  int z = 0;
  struct timeval _tv;
  double sec;
  z = gettimeofday(&_tv, NULL);
  co_assertex(0 == z, "gettimeofday failed!");
  sec = (double)_tv.tv_sec + (double)((double)_tv.tv_usec / (double)1000000.0f);
  return sec;
#endif
}

/* reference premake4, th3x */
int coOs_isfile(const char* path)
{
  struct stat st;
  co_assert(path);
  if (0 == stat(path, &st))
  {
    return !(st.st_mode & S_IFDIR);
  }
  return 0;
}

int coOs_isdir(const char* path)
{
  struct stat st;
  co_assert(path);
  if (0 == stat(path, &st))
  {
    return st.st_mode & S_IFDIR;
  }
  return 0;
}

int coOs_ispath(const char* path)
{
  struct stat st;
  co_assert(path);
  if (0 == stat(path, &st))
  {
    return 1;
  }
  return 0;
}

int coOs_mkdir(co* Co, const char* path)
{
  int z = 0;
#if LOLICORE_PLAT == LOLICORE_PLAT_WIN32
  z = CreateDirectoryA(path, NULL);
#else
  z = (mkdir(path, S_IRWXU | S_IRWXG | S_IROTH | S_IXOTH) == 0);
#endif
  return z > 0 ? 1:0;
}

int coOs_getcwd(co* Co, char* buf, size_t bufs)
{
  int z = 0;
#if LOLICORE_PLAT == LOLICORE_PLAT_WIN32
  DWORD r = 0;
  r = GetCurrentDirectoryA(bufs, buf);
  z = (r > 0 && r < (DWORD)bufs);
  if (z)
  {
    buf[r] = 0;
  }
#else
  z = (getcwd(buf, bufs) != 0);
#endif
  return z;
}

int coOs_export_sleep(lua_State* L)
{
  int msec = 0;
  msec = luaL_checkint(L, 1);
  coOs_sleep(msec);
  return 0;
}

int coOs_export_gettime(lua_State* L)
{
  lua_pushnumber(L, coOs_gettime());
  return 1;
}

int coOs_export_isdir(lua_State* L)
{
  const char* path = NULL;
  path = luaL_checkstring(L, 1);
  if (coOs_isdir(path))
  {
    lua_pushnumber(L, 1);
    return 1;
  }
  return 0;
}

int coOs_export_isfile(lua_State* L)
{
  const char* path = NULL;
  path = luaL_checkstring(L, 1);
  if (coOs_isfile(path))
  {
    lua_pushnumber(L, 1);
    return 1;
  }
  return 0;
}

int coOs_export_ispath(lua_State* L)
{
  const char* path = NULL;
  path = luaL_checkstring(L, 1);
  if (coOs_ispath(path))
  {
    lua_pushnumber(L, 1);
    return 1;
  }
  return 0;
}

int coOs_export_mkdir(lua_State* L)
{
  co* Co = NULL;
  const char* path = NULL;
  lua_getallocf(L, (void**)&Co); co_assert(Co);
  path = luaL_checkstring(L, 1);
  if (coOs_mkdir(Co, path))
  {
    lua_pushstring(L, path);
    return 1;
  }
  return 0;
}

int coOs_export_getcwd(lua_State* L)
{
  char buf[1024];
  size_t bufs = 1024;
  co* Co = NULL;
  lua_getallocf(L, (void**)&Co); co_assert(Co);
  if (coOs_getcwd(Co, buf, bufs))
  {
    lua_pushstring(L, buf);
    return 1;
  }
  return 0;
}
