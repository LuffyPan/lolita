/*

Lolita Core.
Chamz Lau, Copyright (C) 2013-2017
2013/02/26 21:11:26

*/

#include "co.h"
#include "cort.h"
#include "conet.h"
#include "coos.h"
#include "comm.h"

static int co_panic(lua_State* L);
static void* co_xlloc(void* ud, void* p, size_t os, size_t ns);
static void* co_lualloc(void* ud, void* p, size_t os, size_t ns);
static void co_newlua(co* Co);
static void co_deletelua(co* Co);
static void co_export(co* Co);
static void co_born(co* Co, void* ud);
static void co_alive(co* Co, void* ud);
static void co_free(co* Co);
static void co_fatalerror(co* Co, int e);
static const char* co_modname(co* Co, int mod);
static const char* co_lvname(co* Co, int lv);
static const char* co_errorstr(co* Co, int e);

static int co_export_setmaxmem(lua_State* L);
static int co_export_getmem(lua_State* L);
static int co_export_settracelv(lua_State* L);
static int co_export_getregistry(lua_State* L);
static int co_export_attach(lua_State* L);
static int co_export_detach(lua_State* L);
static int co_export_addpath(lua_State* L);

static void defaulttrace(co*Co, int mod, int lv, const char* msg, va_list msgva)
{
  if (lv > core_gettracelv(Co)) return;
  printf("[%s] [%s] ", core_getmodname(Co, mod), core_getlvname(Co, lv));
  vprintf(msg, msgva);
  printf("\n");
  fflush(stdout);fflush(stderr);
}

static void co_pushconfpath(co* Co, lua_State* L, const char* file)
{
  const char* path = NULL;
  size_t pathlen = 0;
  int n = lua_gettop(L);

  co_pushcore(L, Co);
  lua_getfield(L, -1, "conf");
  lua_getfield(L, -1, "_confpaths");
  lua_pushnumber(L, luaL_len(L, -1) + 1);

  path = file;
  while((path = strchr(path, '/'))) { pathlen = path - file + 1; path += 1; }
  lua_pushlstring(L, file, pathlen);
  lua_settable(L, -3);

  lua_pop(L, 3);
  co_assert(n == lua_gettop(L));
}

static void co_popconfpath(co* Co, lua_State* L)
{
  int n = lua_gettop(L);

  co_pushcore(L, Co);
  lua_getfield(L, -1, "conf");
  lua_getfield(L, -1, "_confpaths");
  lua_len(L, -1);
  lua_pushnil(L);
  lua_settable(L, -3);

  lua_pop(L, 3);
  co_assert(n == lua_gettop(L));
}

static void co_curconfpath(co* Co, lua_State* L)
{
  int n = lua_gettop(L);

  co_pushcore(L, Co);
  lua_getfield(L, -1, "conf");
  lua_getfield(L, -1, "_confpaths");
  lua_len(L, -1);
  lua_gettable(L, -2);

  lua_remove(L, -2);
  lua_remove(L, -2);
  lua_remove(L, -2);
  co_assert(n + 1 == lua_gettop(L));
}

static int co_getconfpathlevel(co* Co, lua_State* L)
{
  int n = lua_gettop(L);
  int lv = 0;

  co_pushcore(L, Co);
  lua_getfield(L, -1, "conf");
  lua_getfield(L, -1, "_confpaths");
  lv = luaL_len(L, -1);

  lua_pop(L, 3);
  co_assert(n == lua_gettop(L));
  return lv;
}

static void co_loadX(co* Co, lua_State* L, const char* file)
{
  int n = lua_gettop(L);
  int lv = co_getconfpathlevel(Co, L);
  if (lv >= 5)
  {
    co_trace(Co, CO_MOD_CORE, CO_LVFATAL, "config load level is too deep, %d", lv);
    return;
  }
  co_pushconfpath(Co, L, file);
  if (luaL_loadfile(L, file)) lua_error(L);
  lua_call(L, 0, 0);
  co_popconfpath(Co, L);
  co_assert(n == lua_gettop(L));
  co_trace(Co, CO_MOD_CORE, CO_LVDEBUG, "config %s loaded", file);
}

static int co_export_conf_add(lua_State* L)
{
  co* Co = co_C(L);
  int n = lua_gettop(L);
  const char* k = NULL, *v = NULL;
  int srclen = 0, destlen = 0, i = 0;
  int bconf = 0, bmanif = 0, bsearcher = 0;

  luaL_checktype(L, 1, LUA_TTABLE);
  co_pushcore(L, Co); co_assert(n + 1 == lua_gettop(L));
  lua_getfield(L, -1, "conf"); co_assert(lua_istable(L, -1)); co_assert(n + 2 == lua_gettop(L));
  lua_getfield(L, -1, "_conf"); co_assert(lua_istable(L, -1)); co_assert(n + 3 == lua_gettop(L));

  /* k */
  lua_pushnumber(L, 1);
  lua_gettable(L, 1); co_assert(n + 4 == lua_gettop(L));
  if (lua_type(L, -1) != LUA_TSTRING) {co_trace(Co, CO_MOD_CORE, CO_LVFATAL, "invalid key type!"); return 0;}
  if (0 == strcmp("conf", lua_tostring(L, -1))) bconf = 1;
  if (0 == strcmp("manifest", lua_tostring(L, -1))) bmanif = 1;
  if (0 == strcmp("search", lua_tostring(L, -1))) bsearcher = 1;

  /* v */
  lua_pushnumber(L, 2);
  lua_gettable(L, 1); co_assert(n + 5 == lua_gettop(L));
  if (lua_type(L, -1) != LUA_TTABLE) {co_trace(Co, CO_MOD_CORE, CO_LVFATAL, "invalid value type"); return 0;}

  /* _conf[k] */
  lua_pushvalue(L, n + 4);
  lua_gettable(L, n + 3); co_assert(n + 6 == lua_gettop(L));
  if (lua_type(L, -1) != LUA_TTABLE)
  {
    co_assert(lua_type(L, -1) == LUA_TNIL);
    lua_pop(L, 1);

    /* init a empty table */
    lua_newtable(L);
    lua_pushvalue(L, n + 4);
    lua_pushvalue(L, -2);
    lua_settable(L, n + 3); co_assert(n + 6 == lua_gettop(L));
  }

  /* concat the v into _conf[k] */
  co_assert(n + 6 == lua_gettop(L));
  lua_len(L, n + 5); srclen = (int)lua_tonumber(L, -1); lua_pop(L, 1); /* len of src */
  lua_len(L, n + 6); destlen = (int)lua_tonumber(L, -1); lua_pop(L, 1); /* len of dest */
  for (i = 1; i <= srclen; ++i)
  {
    co_assert(n + 6 == lua_gettop(L));
    if (bmanif || bsearcher) {co_curconfpath(Co, L);}
    lua_pushnumber(L, i); lua_gettable(L, n + 5);
    if (bmanif || bsearcher) {lua_concat(L, 2);}
    co_assert(n + 7 == lua_gettop(L)); /* push the src v */
    lua_pushnumber(L, destlen + i); /* push the dest k */
    lua_pushvalue(L, n + 7); co_assert(n + 9 == lua_gettop(L)); /* copy of src v */
    lua_settable(L, n + 6);

    /* left src v */
    co_assert(n + 7 == lua_gettop(L));

    if (bconf)
    {
      co_curconfpath(Co, L); co_assert(lua_isstring(L, -1)); co_assert(n + 8 == lua_gettop(L));
      lua_insert(L, -2);
      if (lua_type(L, -1) != LUA_TSTRING)
      {
        co_trace(Co, CO_MOD_CORE, CO_LVFATAL, "conf with invalid value type[%s]", lua_typename(L, lua_type(L, -1)));
        lua_pop(L, 2);
        continue;
      }
      lua_concat(L, 2); co_assert(n + 7 == lua_gettop(L));
      co_loadX(Co, L, lua_tostring(L, -1));
    }

    lua_pop(L, 1);
  }
  co_assert(n + 6 == lua_gettop(L));

  k = luaL_tolstring(L, n + 4, NULL);
  v = luaL_tolstring(L, n + 5, NULL);
  co_trace(Co, CO_MOD_CORE, CO_LVDEBUG, "%s = %s is add", k ? k : "none", v ? v : "none");
  lua_pop(L, 2);

  lua_pop(L, 6);
  co_assert(n == lua_gettop(L));
  return 0;
}

static int co_export_conf_set(lua_State* L)
{
  co* Co = co_C(L);
  const char* k = NULL, *v = NULL;

  luaL_checktype(L, 1, LUA_TTABLE);
  co_pushcore(L, Co);
  lua_getfield(L, -1, "conf"); co_assert(lua_istable(L, -1));
  lua_getfield(L, -1, "_conf"); co_assert(lua_istable(L, -1));

  lua_pushnumber(L, 1);
  lua_gettable(L, 1);
  if (lua_type(L, -1) != LUA_TSTRING) {co_trace(Co, CO_MOD_CORE, CO_LVFATAL, "invalid key type!"); return 0;}

  lua_pushnumber(L, 2);
  lua_gettable(L, 1);

  k = luaL_tolstring(L, -2, NULL);
  v = luaL_tolstring(L, -2, NULL);
  co_trace(Co, CO_MOD_CORE, CO_LVDEBUG, "%s = %s is set", k ? k : "none", v ? v : "none"); /* compact with 5.1 */
  lua_pop(L, 2);

  lua_settable(L, -3);
  return 0;
}

/*
  lua_State* can be non-force? and use void* instead
*/
co* core_born(int argc, const char** argv, co_xllocf x, void* ud, co_tracef tf, lua_State* L)
{
  int z = 0;
  co* Co;
  x = x ? x : co_xlloc;
  Co = co_cast(co*, (*x)(x == co_xlloc ? NULL : ud, NULL, 0, sizeof(co)));
  if (NULL == Co) return NULL;
  Co->xlloc = x;
  Co->ud = ud;
  Co->tf = tf ? tf : defaulttrace;
  Co->argc = argc;
  Co->argv = argv;
  Co->umem = 0;
  Co->maxmem =  4 * 1024 * 1024;
  if (Co->xlloc == co_xlloc)
  {
    Co->ud = (void*)Co;
    Co->umem = sizeof(*Co);
    co_assertex(Co->umem <= Co->maxmem, "maxmem is set to small!");
  }
  Co->bactive = 0;
  Co->tracelv = CO_LVFATAL;
  Co->errjmp = NULL;
  Co->L = L;
  Co->battachL = 0;
  Co->N = NULL;
  Co->Os = NULL;
  z = coR_pcall(Co, co_born, NULL);
  if (z)
  {
    co_fatalerror(Co, z);
    co_free(Co);
    return NULL;
  }
  return (co*)Co;
}

void core_alive(co* Co)
{
  int z = coR_pcall(Co, co_alive, NULL);
  if (z)
  {
    co_fatalerror(Co, z);
    return;
  }
}

void core_die(co* Co)
{
  co_free(Co);
}

void core_open(co* Co, int x)
{
  lua_State* L = co_L(Co);
  if (x) lua_newtable(L);
  co_pushcore(L, Co);
  if (x){lua_setfield(L, -2, "core"); lua_setglobal(L, "lolita");}
}

const char* core_getmodname(co* Co, int mod)
{
  return co_modname(Co, mod);
}

const char* core_getlvname(co* Co, int lv)
{
  return co_lvname(Co, lv);
}

int core_gettracelv(co* Co)
{
  return Co->tracelv;
}

static void co_born(co* Co, void* ud)
{
  co_newlua(Co);
  co_export(Co);
  coOs_born(Co);
  coN_born(Co);
}

static void co_addpath(co* Co, lua_State* L, const char* path)
{
  int top = lua_gettop(L);
  lua_getglobal(L, "package");
  co_assert(lua_istable(L, -1));

  lua_getfield(L, -1, "path");
  co_assert(lua_isstring(L, -1));
  lua_pushfstring(L, ";%s?.lua", path);
  lua_pushfstring(L, ";%s?/init.lua", path);
  lua_concat(L, 3);
  lua_setfield(L, -2, "path");

  co_assert(lua_gettop(L) == top + 1);
  lua_getfield(L, -1, "cpath");
  co_assert(lua_isstring(L, -1));
#if LOLITA_CORE_PLAT == LOLITA_CORE_PLAT_WIN32
  lua_pushfstring(L, ";%s?.dll", path);
#else
  lua_pushfstring(L, ";%s?.so", path);
#endif
  lua_concat(L, 2);
  lua_setfield(L, -2, "cpath");

  lua_pop(L, 1);
  co_assert(lua_gettop(L) == top);
  co_trace(Co, CO_MOD_CORE, CO_LVDEBUG, "add search path: %s", path);
}

static void co_ppath(co* Co, lua_State* L)
{
  /* arg.p to add all path */
  size_t len = 0;
  const char* paths = NULL, *p1 = NULL, *p2 = NULL;
  char path[256] = { 0 };

  co_assert(lua_gettop(L) == 0);
  co_pushcore(L, Co);
  lua_getfield(L, -1, "arg"); co_assert(lua_istable(L, -1));
  lua_getfield(L, -1, "p"); co_assert(lua_gettop(L) == 3);
  if (lua_isstring(L, -1)) {paths = lua_tostring(L, -1);}

  if (!paths)
  {
    co_trace(Co, CO_MOD_CORE, CO_LVDEBUG, "empty paths. didn't add anything!");
    lua_pop(L, 3);
    return;
  }

  p1 = paths;
  while(1)
  {
    p2 = strchr(p1, ',');
    len = p2 ? p2 - p1 : strlen(p1);
    if (len >= 256 || len == 0)
    {
      goto _continue;
    }

    strncpy(path, p1, len);path[len] = 0;
    co_addpath(Co, L, path);
    co_trace(Co, CO_MOD_CORE, CO_LVDEBUG, "add path[%s]", path);

    _continue:
    if (!p2) break;
    p1 = p2 + 1;
    p2 = NULL;
  }

  co_assert(3 == lua_gettop(L));
  lua_pop(L, 3);
  co_assert(lua_gettop(L) == 0);
  co_trace(Co, CO_MOD_CORE, CO_LVDEBUG, "add all paths x[%s]", paths);
}

/* TODO:Simple the implelemt, suck as dir operation */
static void co_ploadx(co* Co, lua_State* L)
{
  int z = 0;
  const char* exts = NULL;
  const char* p3 = NULL, *p4 = NULL, *p5 = NULL;
  size_t len = 0;
  char extspath[256] = { 0 };

  co_assert(lua_gettop(L) == 0);
  co_pushcore(L, Co);
  lua_getfield(L, -1, "arg"); co_assert(lua_istable(L, -1));
  lua_getfield(L, -1, "x"); co_assert(lua_gettop(L) == 3);
  if (lua_isstring(L, -1)) {exts = lua_tostring(L, -1);}

  if (!exts)
  {
    co_trace(Co, CO_MOD_CORE, CO_LVDEBUG, "empty x script. didn't load and execute anything!");
    lua_pop(L, 3); /* pop the core.arg.x */
    return;
  }
  len = strlen(exts);
  if (len >= 256)
  {
    co_trace(Co, CO_MOD_CORE, CO_LVDEBUG, "exts is too long, len[%d]", (int)len);
    lua_pop(L, 3);
    return;
  }

  /* parse the path */
  p3 = exts; p5 = NULL;
  while((p4 = strchr(p3, '/'))){p5 = p4; p3 = p4 + 1;}
  len = p5 ? p5 - exts + 1 : 0; co_assert(len < 256);
  strncpy(extspath, exts, len); extspath[len] = 0;

  /* add path */
  co_addpath(Co, L, extspath);

  co_trace(Co, CO_MOD_CORE, CO_LVDEBUG, "exts path is [%s]", extspath);
  co_trace(Co, CO_MOD_CORE, CO_LVDEBUG, "loading and executing x[%s]", exts);
  z = luaL_loadfile(L, exts); if (z) lua_error(L);
  lua_call(L, 0, 0);

  co_assert(3 == lua_gettop(L)); lua_pop(L, 3);
  co_assert(0 == lua_gettop(L));
  co_trace(Co, CO_MOD_CORE, CO_LVDEBUG, "load and executed x[%s]", exts);
}

static void co_pexeX(co* Co, lua_State* L)
{
  co_assert(0 == lua_gettop(L)); co_pushcore(L, Co);
  lua_getfield(L, -1, "conf"); co_assert(2 == lua_gettop(L));
  lua_getfield(L, 2, "_conf"); co_assert(3 == lua_gettop(L));

  /* set all arg to _conf */
  /* exeX args */
  lua_getfield(L, 1, "arg"); co_assert(4 == lua_gettop(L));
  lua_pushnil(L);
  while(lua_next(L, 4))
  {
    co_assert(6 == lua_gettop(L));
    lua_pushvalue(L, -2);
    lua_insert(L, -2);
    lua_settable(L, 3);
    co_assert(5 == lua_gettop(L));
  }
  lua_pop(L, 1);

  /* exeX tracelv */
  lua_getfield(L, 3, "tracelv"); co_assert(4 == lua_gettop(L));
  if (lua_isnumber(L, -1))
  {
    int lv = (int)lua_tonumber(L, -1);
    co_trace(Co, CO_MOD_CORE, CO_LVDEBUG, "exeX tracelv %d -> %d", Co->tracelv, lv);
    Co->tracelv = lv;
  }
  lua_pop(L, 1);

  /* exeX search */
  lua_getfield(L, 3, "search"); co_assert(4 == lua_gettop(L));
  if (lua_istable(L, -1))
  {
    int len = 0, i = 0;
    lua_len(L, -1); len = (int)lua_tonumber(L, -1); lua_pop(L, 1);
    for (i = 1; i <= len; ++i)
    {
      lua_pushnumber(L, i);
      lua_gettable(L, 4);
      co_assert(5 == lua_gettop(L));
      co_addpath(Co, L, lua_tostring(L, -1));
      lua_pop(L, 1); co_assert(4 == lua_gettop(L));
    }
    co_trace(Co, CO_MOD_CORE, CO_LVDEBUG, "exeX search");
  }
  lua_pop(L, 1);

  /* exeX manifest */
  lua_getfield(L, 3, "manifest"); co_assert(4 == lua_gettop(L));
  if (lua_istable(L, -1))
  {
    int len = 0, i = 0, len2 = 0, i2 = 0;
    lua_len(L, -1); len = (int)lua_tonumber(L, -1); lua_pop(L, 1);
    for (i = 1; i <= len; ++i)
    {
      lua_pushnumber(L, i); lua_gettable(L, 4); co_assert(5 == lua_gettop(L));
      co_addpath(Co, L, lua_tostring(L, 5));
      lua_pushvalue(L, 5); co_assert(6 == lua_gettop(L));
      lua_pushstring(L, "manifest.lua");
      lua_concat(L, 2); co_assert(6 == lua_gettop(L));
      if (luaL_loadfile(L, lua_tostring(L, -1))) lua_error(L);
      lua_call(L, 0, 1); co_assert(7 == lua_gettop(L));

      lua_len(L, 7); len2 = (int)lua_tonumber(L, -1); lua_pop(L, 1);
      for (i2 = 1; i2 <= len2; ++i2)
      {
        co_assert(7 == lua_gettop(L));
        lua_pushvalue(L, 5); /* manifest path */
        lua_pushnumber(L, i2); lua_gettable(L, 7); co_assert(9 == lua_gettop(L));
        lua_concat(L, 2); co_assert(8 == lua_gettop(L));
        if (luaL_loadfile(L, lua_tostring(L, 8))) lua_error(L);
        lua_call(L, 0, 0); co_assert(8 == lua_gettop(L));
        lua_pop(L, 1);
      }

      lua_pop(L, 3);
      co_assert(4 == lua_gettop(L));
    }
    co_trace(Co, CO_MOD_CORE, CO_LVDEBUG, "exeX manifest");
  }
  lua_pop(L, 1);

  co_assert(3 == lua_gettop(L)); lua_pop(L, 3);
  co_assert(0 == lua_gettop(L));
}

static void co_ploadX(co* Co, lua_State* L)
{
  co_assert(0 == lua_gettop(L)); co_pushcore(L, Co);

  lua_getfield(L, -1, "arg"); co_assert(lua_istable(L, -1));
  lua_getfield(L, -1, "X"); co_assert(3 == lua_gettop(L));
  if (!lua_isstring(L, -1)) {co_trace(Co, CO_MOD_CORE, CO_LVDEBUG, "no X file ignored!"); lua_pop(L, 3); return;}

  co_loadX(Co, L, lua_tostring(L, -1));

  co_assert(3 == lua_gettop(L)); lua_pop(L, 3);
  co_assert(0 == lua_gettop(L));
}

/* core is on the top of stack */
static void co_pload(co* Co, lua_State* L)
{
  co_ppath(Co, L);
  co_ploadx(Co, L);
  co_ploadX(Co, L);
  co_pexeX(Co, L);
}

static void co_pactive(co* Co, lua_State* L)
{
  int z = 0;

  co_assert(0 == lua_gettop(L)); co_pushcore(L, Co);
  lua_getfield(L, LUA_REGISTRYINDEX, "lolita.attach"); /* idx = 2 */
  if (!lua_istable(L, -1))
  {
    co_assert(lua_isnil(L, -1));
    co_trace(Co, CO_MOD_CORE, CO_LVINFO, "have not register active func");
    lua_pop(L, 2);
    return;
  }

  /* born */
  lua_getfield(L, -1, "born");
  co_assert(lua_isfunction(L, -1));
  lua_pushvalue(L, 2); /* param */
  lua_call(L, 1, 1);
  co_assert(lua_gettop(L) == 3);
  z = co_cast(int, lua_tonumber(L, -1));
  lua_pop(L, 1);
  if ( z != 1 )
  {
    co_trace(Co, CO_MOD_CORE, CO_LVINFO, "born's return value is %d, stop active, direct to die", z);
    goto die;
  }

  /* active */
  lua_getfield(L, -1, "active"); /* idx = 3 */
  co_assert(lua_isfunction(L, -1));
  Co->bactive = 1;
  while(Co->bactive)
  {
    co_assert(3 == lua_gettop(L));
    lua_pushvalue(L, -1); /* function top = 4 */
    lua_pushvalue(L, 2); /* param top = 5 */
    lua_call(L, 1, 1);
    co_assert(lua_gettop(L) == 4);
    if (lua_tointeger(L, -1) != 1)
    {
      Co->bactive = 0;
      co_trace(Co, CO_MOD_CORE, CO_LVDEBUG, "active is stoped!");
    }
    lua_pop(L, 1);
  }
  co_assert(3 == lua_gettop(L));
  lua_pop(L, 1);

die:
  /* die */
  lua_getfield(L, -1, "die");
  co_assert(lua_isfunction(L, -1));
  lua_pushvalue(L, 2);
  lua_call(L, 1, 0);
  co_assert(lua_gettop(L) == 2); lua_pop(L, 2);
}

static int co_palive(lua_State* L)
{
  co* Co = co_C(L);
  co_assert(lua_gettop(L) == 0);
  co_pload(Co, L);
  co_pactive(Co, L);
  co_assert(lua_gettop(L) == 0);
  return 0;
}

static void co_alive(co* Co, void* ud)
{
  int z;
  lua_State* L = NULL;
  L = co_L(Co);
  co_assert(lua_gettop(L) == 0);
  lua_pushcfunction(L, co_pcallmsg);
  lua_pushcfunction(L, co_palive);
  z = lua_pcall(L, 0, 0, 1);
  if (z)
  {
    co_tracecallstack(Co, CO_MOD_CORE, CO_LVFATAL, L);
    coR_throw(Co, CO_ERRSCRIPTCALL);
  }
  co_assert(lua_gettop(L) == 1);
  lua_pop(L, 1);
  co_assert(lua_gettop(L) == 0);
}

static void co_free(co* Co)
{
  coN_die(Co);
  coOs_die(Co);
  co_deletelua(Co);
  co_assert((Co->xlloc == co_xlloc) == (Co->umem == sizeof(*Co)));
  (*Co->xlloc)(NULL, Co, sizeof(co), 0);
}

static void co_newlua(co* Co)
{
  int top = 0;
  lua_State* L = co_L(Co);
  if (L)
  {
    Co->battachL = 1; /* set first so that co know don't close this L */
    top = lua_gettop(L);
    lua_getfield(L, LUA_REGISTRYINDEX, "lolita");
    if (!lua_isnil(L, -1))
    {
      co_trace(Co, CO_MOD_CORE, CO_LVFATAL, "lolita is loaded!");
      coR_throw(Co, 1);
    }
    lua_pop(L, 1);
    /* if Host is [lolita], and require [lolitaext], then, below's call will rewrite the registry[L]!!!, so aband this ocurrs */
    /* Check registry["lolita"], if not nil, then break it */
  }
  else
  {
    L = lua_newstate(co_lualloc, Co);
    top = lua_gettop(L); co_assert(top == 0);
    co_L(Co) = L;
    if (!L) coR_throw(Co, CO_ERRSCRIPTNEW);
    lua_atpanic(L, co_panic);
  }
  lua_pushlightuserdata(L, Co);
  lua_setfield(L, LUA_REGISTRYINDEX, "lolita");
  co_assert(top == lua_gettop(L));
}

static void co_deletelua(co* Co)
{
  lua_State* L = co_L(Co);
  if ((!Co->battachL) && L) lua_close(L);
}

static void co_pexportcore(co* Co, lua_State* L)
{
  co_assert(lua_gettop(L) == 0);
  if (!Co->battachL) {luaL_openlibs(L);}
  /* check lolita.core and assert */
  lua_newtable(L); /* lolita? the name is not important */
  lua_newtable(L); /* lolita.core */
  lua_pushvalue(L, -1);
  lua_setfield(L, -3, "core");
  lua_setfield(L, LUA_REGISTRYINDEX, "lolita.core");

  if (!Co->battachL) {lua_setglobal(L, "lolita");}
  else {lua_pop(L, 1);}
  co_assert(lua_gettop(L) == 0);
}

static void co_pexportinfo(co* Co, lua_State* L)
{
  co_assert(lua_gettop(L) == 0);
  co_pushcore(L, Co);
  lua_newtable(L);
  lua_pushvalue(L, -1); lua_setfield(L, -3, "info"); /* core.info */
  lua_pushstring(L, LUA_COPYRIGHT); lua_setfield(L, -2, "lcopyright");
  lua_pushstring(L, LUA_AUTHORS); lua_setfield(L, -2, "lauthors");
  lua_pushstring(L, LOLITA_CORE_COPYRIGHT); lua_setfield(L, -2, "copyright");
  lua_pushstring(L, LOLITA_CORE_AUTHOR); lua_setfield(L, -2, "author");
  lua_pushnumber(L, LOLITA_CORE_VERSION); lua_setfield(L, -2, "version");
  lua_pushstring(L, LOLITA_CORE_VERSION_REPOS); lua_setfield(L, -2, "reposversion");
  lua_pushstring(L, LOLITA_CORE_PLATSTR); lua_setfield(L, -2, "platform");
  lua_pop(L, 2); /* core.info */
  co_assert(lua_gettop(L) == 0);
}

static void co_pexportarg(co* Co, lua_State* L)
{
  const char** argv = NULL;
  int argc = 0, i = 0;
  argv = Co->argv;
  argc = Co->argc;
  co_assert(lua_gettop(L) == 0);
  co_pushcore(L, Co);
  lua_newtable(L);
  lua_pushvalue(L, -1); lua_setfield(L, -3, "arg"); /* core.arg */

  lua_newtable(L);
  lua_pushvalue(L, -1); lua_setfield(L, -3, "_original"); /* core.arg._original */
  lua_pushstring(L, argc > 0 ? argv[0] : ""); lua_setfield(L, -3, "_path"); /* core.arg._path */
  for (i = 1; i < argc; ++i)
  {
    const char* p = strchr(argv[i], '=');
    if (p)
    {
      size_t len = p - argv[i];
      if (!len) continue;
      lua_pushlstring(L, argv[i], (int)len);
      lua_pushstring(L, p + 1);
    }
    else
    {
      lua_pushstring(L, argv[i]);
      lua_pushstring(L, "");
    }
    lua_settable(L, -4);

    lua_pushnumber(L, i);
    lua_pushstring(L, argv[i]);
    lua_settable(L, -3);
  }
  lua_pop(L, 1); /* _original */

  lua_getfield(L, -1, "tracelv");
  Co->tracelv = (int)lua_tonumber(L, -1);
  lua_pop(L, 1);

  lua_pop(L, 2); /* core.arg */
  co_assert(lua_gettop(L) == 0);
}

static void co_pexportconf(co* Co, lua_State* L)
{
  const luaL_Reg co_funcs[] =
  {
    {"add", co_export_conf_add},
    {"set", co_export_conf_set},
    {NULL, NULL},
  };

  co_assert(lua_gettop(L) == 0);
  co_pushcore(L, Co);
  lua_newtable(L);
  luaL_setfuncs(L, co_funcs, 0);
  lua_pushvalue(L, -1); /* a copy to setfield */
  lua_setfield(L, -3, "conf"); /* set core.conf */
  lua_pushvalue(L, -1);
  lua_setmetatable(L, -2); /* set self as metatable */
  co_assert(lua_gettop(L) == 2); /* left core.conf */

  lua_newtable(L);
  lua_pushvalue(L, -1);
  lua_setfield(L, -3, "__index"); /* set core.conf._conf as __index */
  lua_setfield(L, -2, "_conf"); /* set core.conf._conf */
  lua_newtable(L);
  lua_setfield(L, -2, "_confpaths");
  lua_pop(L, 2);
  co_assert(lua_gettop(L) == 0);
}

static void co_pexportbase(co* Co, lua_State* L)
{
  static const luaL_Reg co_funcs[] =
  {
    {"getmem", co_export_getmem},
    {"setmaxmem", co_export_setmaxmem},
    {"settracelv", co_export_settracelv},
    {"getregistry", co_export_getregistry},
    {"attach", co_export_attach},
    {"detach", co_export_detach},
    {"addpath", co_export_addpath},
    {NULL, NULL},
  };
  co_assert(lua_gettop(L) == 0);
  co_pushcore(L, Co);
  lua_newtable(L);
  luaL_setfuncs(L, co_funcs, 0);
  lua_setfield(L, -2, "base"); /* core.base */
  lua_pop(L, 1); /* core */
  co_assert(lua_gettop(L) == 0);
}

static int co_pexport(lua_State* L)
{
  co* Co = co_C(L);
  co_assert(lua_gettop(L) == 0);
  co_pexportcore(Co, L);
  co_pexportinfo(Co, L);
  co_pexportarg(Co, L);
  co_pexportconf(Co, L);
  co_pexportbase(Co, L);
  co_assert(lua_gettop(L) == 0);
  return 0;
}

static void co_export(co* Co)
{
  int z, top;
  lua_State* L = co_L(Co);
  top = lua_gettop(L);
  if (!Co->battachL) {co_assert(top == 0);}
  lua_pushcfunction(L, co_pcallmsg);
  lua_pushcfunction(L, co_pexport);
  z = lua_pcall(L, 0, 0, top + 1);
  if (z)
  {
    co_tracecallstack(Co, CO_MOD_CORE, CO_LVFATAL, L);
    /* when the failed, you never know the stack would be, so, cancel this assert */
    /* lua_pop(L,1); co_assert(lua_gettop(L) == 0); */
    coR_throw(Co, CO_ERRSCRIPTCALL);
  }
  co_assert(top + 1 == lua_gettop(L)); /* caz co_pcallmsg is not poped */
  lua_pop(L, 1); co_assert(top == lua_gettop(L));
  if (!Co->battachL) {co_assert(top == 0);}
}

static void co_fatalerror(co* Co, int e)
{
  switch(e)
  {
  case CO_ERRMEM:
    co_trace(Co, CO_MOD_CORE, CO_LVFATAL, "memory:%u/%u", Co->umem, Co->maxmem);
  case CO_ERRSCRIPTNEW:
  case CO_ERRSCRIPTCALL:
  default:
    co_trace(Co, CO_MOD_CORE, CO_LVFATAL, "%s", co_errorstr(Co, e));
  }
}

static const char* co_modname(co* Co, int mod)
{
  static const char* _mn[CO_MOD_SCRIPT+1] =
  {
    "co","coN", "coS",
  };
  co_assert(mod >= CO_MOD_CORE && mod <= CO_MOD_SCRIPT);
  return _mn[mod];
}

static const char* co_lvname(co* Co, int lv)
{
  static const char* _ln[CO_LVINFO+1] =
  {
    "FATAL","DEBUG", "INFO",
  };
  co_assert(lv >= CO_LVFATAL && lv <= CO_LVINFO);
  return _ln[lv];
}

#define CO_OK 0
#define CO_ERRRUN 1
#define CO_ERRMEM 2
#define CO_ERRSCRIPTPANIC 3
#define CO_ERRSCRIPTNEW 4
#define CO_ERRSCRIPTCALL 5
#define CO_ERRX 6
static const char* co_errorstr(co* Co, int e)
{
  static const char* _es[CO_ERRX+1] =
  {
    "ok!","runtime error", "memory is not enough\?", "script paniced!", "memory is not enough to new script", "failed to call script",
    "xxxxx error\?",
  };
  co_assert(e >= CO_OK && e <= CO_ERRX);
  return _es[e];
}

static int co_panic(lua_State* L)
{
  co* Co = co_C(L);
  co_trace(Co, CO_MOD_CORE, CO_LVFATAL, "atpanic\?!");
  coR_throw(Co, CO_ERRSCRIPTPANIC);
  return 0;
}

static void* co_lualloc(void* ud, void* p, size_t os, size_t ns)
{
  co* Co = co_cast(co*, ud);
  void* np = NULL;
  /* when p == NULL, the un32_osize indicate the type of object lua, so, reset it to 0 */
  os = (NULL == p && os > 0) ? 0 : os;
  np = coM_xllocmem(Co, p, os, ns, 0); /* give control to Lua, don't let co throw */
  /* Lua assumes that the allocator never fails when osize >= nsize */
  if (NULL == np && ns > 0 && ns <= os) co_assert(0);
  return np;
}

static void* co_xlloc(void* ud, void* p, size_t os, size_t ns)
{
  void* x = NULL;
  co* Co = (co*)ud;
  size_t m = 0;
  if (Co)
  {
    m = Co->umem;
    co_assert(m >= os);
    m -= os;
    m += ns;
    if (m > Co->maxmem)
    {
      /* co_assertex(0, "used mem is larger than max mem!"); */
      return NULL;
    }
  }
  if (ns == 0){free(p);}
  else{x = realloc(p, ns);}
  if (Co){Co->umem = m;}
  return x;
}

static int co_export_setmaxmem(lua_State* L)
{
  co* Co = NULL;
  size_t maxmem;
  Co = co_C(L);
  maxmem = co_cast(size_t, luaL_checkunsigned(L, 1));
  Co->maxmem = maxmem > Co->maxmem ? maxmem : Co->maxmem;
  return 0;
}

static int co_export_getmem(lua_State* L)
{
  co* Co = co_C(L);
  lua_pushnumber(L, Co->umem);
  lua_pushnumber(L, Co->maxmem);
  return 2;
}

static int co_export_settracelv(lua_State* L)
{
  co* Co = co_C(L);
  Co->tracelv = luaL_checkint(L, 1);
  return 0;
}

static int co_export_getregistry(lua_State* L)
{
  lua_pushvalue(L, LUA_REGISTRYINDEX);
  return 1;
}

static int co_export_attach(lua_State* L)
{
  lua_getfield(L, LUA_REGISTRYINDEX, "lolita.attach");
  if (!lua_isnil(L, -1)) { luaL_error(L, "duplicate attach"); }
  lua_pop(L, 1);
  luaL_checktype(L, 1, LUA_TTABLE);
  lua_pushvalue(L, 1); /* ensure that the -1 is this table */
  lua_getfield(L, -1, "born"); luaL_checktype(L, -1, LUA_TFUNCTION); lua_pop(L, 1);
  lua_getfield(L, -1, "active"); luaL_checktype(L, -1, LUA_TFUNCTION); lua_pop(L, 1);
  lua_getfield(L, -1, "die"); luaL_checktype(L, -1, LUA_TFUNCTION); lua_pop(L, 1);
  lua_setfield(L, LUA_REGISTRYINDEX, "lolita.attach");
  return 1;
}

static int co_export_detach(lua_State* L)
{
  co* Co = co_C(L);
  Co->bactive = 0;
  lua_pushnil(L);
  lua_setfield(L, LUA_REGISTRYINDEX, "lolita.attach");
  return 1;
}

static int co_export_addpath(lua_State* L)
{
  co* Co = co_C(L);
  co_addpath(Co, L, luaL_checkstring(L, 1));
  return 0;
}

void co_trace(co* Co, int mod, int lv, const char* msg, ...)
{
  va_list msgva;
  if (!Co->tf) return;
  va_start(msgva, msg);
  Co->tf(Co, mod, lv, msg, msgva);
  va_end(msgva);
}

void co_tracecallstack(co* Co, int mod, int lv, lua_State* L)
{
    co_trace(Co, CO_MOD_CORE, CO_LVFATAL, "=================================== |\n%s", lua_tostring(L, -1));
    co_trace(Co, CO_MOD_CORE, CO_LVFATAL, "=================================== |");
}

int co_pcallmsg(lua_State* L)
{
#if defined(LOLITA_CORE_LUA_514)
  /* what if lua 5.1.4 or lower ? */
#else
  luaL_traceback(L, L, lua_tostring(L, 1), 0);
#endif
  return 1;
}

co* co_C(lua_State* L)
{
  int top = 0;
  co* Co = NULL;
  top = lua_gettop(L);
  lua_getfield(L, LUA_REGISTRYINDEX, "lolita");
  Co = (co*)lua_touserdata(L, -1);
  co_assert(co_L(Co) == L);
  lua_pop(L, 1);
  co_assert(top == lua_gettop(L));
  return Co;
}
