/*

LoliCore OS
Chamz Lau, Copyright (C) 2013-2017
2013/03/16 20:48:02

*/

#include "coos.h"
#include "co.h"
#include "cort.h"
#include "comm.h"
#include <sys/stat.h>

#if LOLICORE_PLAT == LOLICORE_PLAT_WIN32
  #include <Windows.h>
#else
  #include <unistd.h>
  #include <sys/types.h>
  #include <sys/resource.h>
  #include <sys/time.h>
  #include <signal.h>
#endif

#define COOS_SIG_INT 0
#define COOS_SIG_MAXCNT 32

struct coOs
{
  int sigs[COOS_SIG_MAXCNT];
  int sigcnt;
};

static int coOs_export_sleep(lua_State* L);
static int coOs_export_gettime(lua_State* L);
static int coOs_export_isdir(lua_State* L);
static int coOs_export_isfile(lua_State* L);
static int coOs_export_ispath(lua_State* L);
static int coOs_export_mkdir(lua_State* L);
static int coOs_export_getcwd(lua_State* L);
static int coOs_export_getpid(lua_State* L);
static int coOs_export_active(lua_State* L);
static int coOs_export_register(lua_State* L);

static void coOs_setsighandler(co* Co, coOs* Os);
static int coOs_getsighandler(co* Co, coOs* Os);

int coOs_pexportapi(co* Co, lua_State* L)
{
  static const luaL_Reg coOs_funcs[] =
  {
    {"sleep", coOs_export_sleep},
    {"gettime", coOs_export_gettime},
    {"isdir", coOs_export_isdir},
    {"isfile", coOs_export_isfile},
    {"ispath", coOs_export_ispath},
    {"mkdir", coOs_export_mkdir},
    {"getcwd", coOs_export_getcwd},
    {"getpid", coOs_export_getpid},
    {"active", coOs_export_active},
    {"register", coOs_export_register},
    {NULL, NULL},
  };
  co_assert(lua_gettop(L) == 0);
  co_pushcore(L, Co);
  lua_newtable(L);
  luaL_setfuncs(L, coOs_funcs, 0);
  /* push sig const */
  /* TODO More smart */
  lua_pushnumber(L, COOS_SIG_INT);
  lua_setfield(L, -2, "SIG_INT");
  /* --------- */
  lua_setfield(L, -2, "os");
  lua_pop(L, 1);
  co_assert(lua_gettop(L) == 0);
  return 0;
}

int coOs_pexport(lua_State* L)
{
  co* Co = co_C(L);
  coOs_pexportapi(Co, L);
  return 0;
}

void coOs_export(co* Co)
{
  int z, top;
  lua_State* L = co_L(Co);
  top = lua_gettop(L);
  if (!Co->battachL) {co_assert(top == 0);}
  lua_pushcfunction(L, coOs_pexport);
  z = lua_pcall(L, 0, 0, 0);
  if (z)
  {
    co_trace(Co, CO_MOD_CORE, CO_LVFATAL, lua_tostring(L, -1));
    lua_pop(L,1); co_assert(lua_gettop(L) == 0);
    coR_throw(Co, CO_ERRSCRIPTCALL);
  }
  co_assert(top == lua_gettop(L));
  if (!Co->battachL) {co_assert(lua_gettop(L) == 0);}
}

static coOs* _coOs = NULL;
#if LOLICORE_PLAT == LOLICORE_PLAT_WIN32
BOOL WINAPI coOs_signalhandler(DWORD t)
{
  if (!_coOs) return FALSE;
  if (_coOs->sigcnt >= COOS_SIG_MAXCNT) return FALSE;
  if (t != CTRL_C_EVENT){printf("signal:%u\n", t);return FALSE;}
  /* 我对Windows的其他信号处理失去信心了,打算放弃支持了,能支持到什么程度算什么吧 */
  _coOs->sigs[_coOs->sigcnt++] = (int)COOS_SIG_INT;
  return TRUE;
}
#else
void coOs_signalhandler(int t)
{
  if (!_coOs) return;
  if (_coOs->sigcnt >= COOS_SIG_MAXCNT) return;
  if (t != SIGINT) {printf("signal:%d\n", t); return;}
  _coOs->sigs[_coOs->sigcnt++] = (int)COOS_SIG_INT;
}
#endif

void coOs_initsig(co* Co)
{
#if LOLICORE_PLAT == LOLICORE_PLAT_WIN32
  BOOL b = FALSE;
  b = SetConsoleCtrlHandler(coOs_signalhandler, TRUE);
  co_assert(b);
#else
  signal(SIGINT, coOs_signalhandler);
#endif
  co_assert(!_coOs);
  _coOs = Co->Os;
}

void coOs_activesig(co* Co)
{
  int top = 0;
  lua_State* L = co_L(Co);
  coOs* Os = Co->Os;
  co_assert(L);co_assert(Os);
  if (Os->sigcnt <= 0) return;
  top = lua_gettop(L);
  while(Os->sigcnt)
  {
    int sig = Os->sigs[--Os->sigcnt];
    int z = 0;
    z = coOs_getsighandler(Co, Os);
    if (!z) {Os->sigcnt = 0; return;}
    co_assert(z > 0);
    lua_pushnumber(L, sig);
    lua_call(L, 1 + z - 1, 0);
    co_assert(top == lua_gettop(L));
  }
}

void coOs_born(co* Co)
{
  coOs* Os = NULL;
  co_assert(!Co->Os);
  Os = co_cast(coOs*, coM_newobj(Co, coOs));
  Os->sigcnt = 0;
  Co->Os = Os;
  if (!Co->battachL) {coOs_initsig(Co);}
  coOs_export(Co);
}

void coOs_die(co* Co)
{
  if (!Co->Os) return;
  coM_deleteobj(Co, Co->Os);
}

void coOs_sleep(int msec)
{
  co_assertex(msec >= 0 && msec < 1000 * 60, "fuck, need so long..\?");
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

int coOs_getpid(co* Co)
{
#if LOLICORE_PLAT == LOLICORE_PLAT_WIN32
  return (int)GetCurrentProcessId();
#else
  pid_t pid = getpid();
  co_assert(pid);
  return (int)pid;
#endif
}

static int coOs_export_sleep(lua_State* L)
{
  int msec = 0;
  msec = luaL_checkint(L, 1);
  coOs_sleep(msec);
  return 0;
}

static int coOs_export_gettime(lua_State* L)
{
  lua_pushnumber(L, coOs_gettime());
  return 1;
}

static int coOs_export_isdir(lua_State* L)
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

static int coOs_export_isfile(lua_State* L)
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

static int coOs_export_ispath(lua_State* L)
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

static int coOs_export_mkdir(lua_State* L)
{
  co* Co = co_C(L);
  const char* path = NULL;
  path = luaL_checkstring(L, 1);
  if (coOs_mkdir(Co, path))
  {
    lua_pushstring(L, path);
    return 1;
  }
  return 0;
}

static int coOs_export_getcwd(lua_State* L)
{
  char buf[1024];
  size_t bufs = 1024;
  co* Co = co_C(L);
  if (coOs_getcwd(Co, buf, bufs))
  {
    lua_pushstring(L, buf);
    return 1;
  }
  return 0;
}

static int coOs_export_getpid(lua_State* L)
{
  co* Co = co_C(L);
  lua_pushnumber(L, coOs_getpid(Co));
  return 1;
}

static int coOs_export_active(lua_State* L)
{
  co* Co = co_C(L);
  int msec = 0;
  msec = luaL_optint(L, 1, 0);
  coOs_activesig(Co);
  if (msec > 0) coOs_sleep(msec);
  return 0;
}

static int coOs_export_register(lua_State* L)
{
  int t;
  co* Co = co_C(L);
  coOs* Os = NULL;
  Os = Co->Os;co_assert(Os);
  if (lua_gettop(L) != 2) luaL_error(L, "a function and a table or nil!");
  t = lua_type(L, 2);
  luaL_checktype(L, 1, LUA_TFUNCTION);
  luaL_argcheck(L, t == LUA_TNIL || t == LUA_TTABLE, 2, "nil or table expected");
  coOs_setsighandler(Co, Os);
  co_assert(lua_gettop(L) == 0);
  lua_pushnumber(L, 1);
  return 1;
}

/* TODO almost the same as coN's coN_seteventer, ABSTRACT it */
static void coOs_setsighandler(co* Co, coOs* Os)
{
  int top;
  lua_State* L = NULL;
  L = co_L(Co);
  top = lua_gettop(L);
  co_assert(top >= 2);
  lua_rawsetp(L, LUA_REGISTRYINDEX, &Os->sigcnt); /* push funcparam */
  lua_rawsetp(L, LUA_REGISTRYINDEX, Os->sigs); /* push func */
  co_assert(top - 2 == lua_gettop(L));
}

static int coOs_getsighandler(co* Co, coOs* Os)
{
  int top;
  lua_State* L = NULL;
  L = co_L(Co);
  top = lua_gettop(L);
  lua_rawgetp(L, LUA_REGISTRYINDEX, Os->sigs); /* push func */
  lua_rawgetp(L, LUA_REGISTRYINDEX, &Os->sigcnt); /* push funcparam */
  co_assert(top + 2 == lua_gettop(L));
  if (lua_isfunction(L, -2))
  {
    if (lua_istable(L, -1)) return 2;
    else if (lua_isnil(L, -1)) {lua_pop(L, 1);return 1;}
    else {co_assert(0);}
  }
  lua_pop(L, 2);
  co_assert(top == lua_gettop(L));
  return 0;
}
