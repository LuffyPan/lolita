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

#if !defined(LOLITA_CORE_LUAJIT)
static void* co_lualloc(void* ud, void* p, size_t os, size_t ns);
#endif
static int co_panic(lua_State* L);
static void* co_xlloc(void* ud, void* p, size_t os, size_t ns);
static void co_newlua(co* Co);
static void co_deletelua(co* Co);
static void co_export(co* Co);
static void co_born(co* Co, void* ud);
static void co_load(co* Co);
static void co_execute(co* Co);
static void co_alive(co* Co, void* ud);
static void co_free(co* Co, void* ud);
static void co_die(co* Co);
static void co_fatalerror(co* Co, int e);
static const char* co_modname(co* Co, int mod);
static const char* co_lvname(co* Co, int lv);
static const char* co_errorstr(co* Co, int e);
static int co_attachfun(lua_State* L, const char* fun);

static int co_export_setmaxmem(lua_State* L);
static int co_export_getmem(lua_State* L);
static int co_export_settracelv(lua_State* L);
static int co_export_getregistry(lua_State* L);
static int co_export_attach(lua_State* L);
static int co_export_detach(lua_State* L);
static int co_export_rettach(lua_State* L);
static int co_export_isrettaching(lua_State* L);
static int co_export_addpath(lua_State* L);
static int co_export_active(lua_State* L);

static void co_buildintrace(co* Co, int mod, int lv, const char* msg, va_list msgva)
{
  if (lv > Co->tracelv) return;
  printf("[%s] [%s] ", co_modname(Co, mod), co_lvname(Co, lv));
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
  lua_getfield(L, -1, "all");
  lua_getfield(L, -1, "_confpathstack");
  lua_pushnumber(L, luaL_len(L, -1) + 1);

  path = file;
  while((path = strchr(path, '/'))) { pathlen = path - file + 1; path += 1; }
  lua_pushlstring(L, file, pathlen);
  lua_settable(L, -3);

  lua_pop(L, 4);
  co_assert(n == lua_gettop(L));
}

static void co_popconfpath(co* Co, lua_State* L)
{
  int n = lua_gettop(L);

  co_pushcore(L, Co);
  lua_getfield(L, -1, "conf");
  lua_getfield(L, -1, "all");
  lua_getfield(L, -1, "_confpathstack");
  lua_len(L, -1);
  lua_pushnil(L);
  lua_settable(L, -3);

  lua_pop(L, 4);
  co_assert(n == lua_gettop(L));
}

static void co_curconfpath(co* Co, lua_State* L)
{
  int n = lua_gettop(L);

  co_pushcore(L, Co);
  lua_getfield(L, -1, "conf");
  lua_getfield(L, -1, "all");
  lua_getfield(L, -1, "_confpathstack");
  lua_len(L, -1);
  lua_gettable(L, -2);

  lua_remove(L, -2);
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
  lua_getfield(L, -1, "all");
  lua_getfield(L, -1, "_confpathstack");
  lv = luaL_len(L, -1);

  lua_pop(L, 4);
  co_assert(n == lua_gettop(L));
  return lv;
}

static void co_loadx(co* Co, lua_State* L, const char* file)
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
  lua_getfield(L, -1, "all"); co_assert(lua_istable(L, -1)); co_assert(n + 3 == lua_gettop(L));

  /* k */
  lua_pushnumber(L, 1);
  lua_gettable(L, 1); co_assert(n + 4 == lua_gettop(L));
  if (lua_type(L, n + 4) != LUA_TSTRING) {co_trace(Co, CO_MOD_CORE, CO_LVFATAL, "invalid key type!"); return 0;}
  if (0 == strcmp("conf", lua_tostring(L, n + 4))) bconf = 1;
  else if (0 == strcmp("manifest", lua_tostring(L, n + 4))) bmanif = 1;
  else if (0 == strcmp("search", lua_tostring(L, n + 4))) bsearcher = 1;

  /* check conf.arg */
  lua_getfield(L, n + 2, "arg"); co_assert(n + 5 == lua_gettop(L));
  lua_pushvalue(L, n + 4); co_assert(n + 6 == lua_gettop(L));
  lua_gettable(L, n + 5); co_assert(n + 6 == lua_gettop(L));
  if (lua_type(L, n + 6) != LUA_TNIL){co_trace(Co, CO_MOD_CORE, CO_LVDEBUG, "conf.arg[%s] first, ignore this", lua_tostring(L, n + 4)); return 0;}
  lua_pop(L, 2);

  /* v */
  lua_pushnumber(L, 2);
  lua_gettable(L, 1); co_assert(n + 5 == lua_gettop(L));
  if (lua_type(L, -1) != LUA_TTABLE) {co_trace(Co, CO_MOD_CORE, CO_LVFATAL, "invalid value type"); return 0;}

  /* all[k] */
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

  /* concat the v into all[k] */
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
      co_loadx(Co, L, lua_tostring(L, -1));
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
  int n = 0;

  n = lua_gettop(L);
  luaL_checktype(L, 1, LUA_TTABLE);
  co_pushcore(L, Co); co_assert(n + 1 == lua_gettop(L));
  lua_getfield(L, n + 1, "conf"); co_assert(n + 2 == lua_gettop(L)); co_assert(lua_istable(L, n + 2));
  lua_getfield(L, n + 2, "all"); co_assert(n + 3 == lua_gettop(L)); co_assert(lua_istable(L, n + 3));
  lua_getfield(L, n + 2, "arg"); co_assert(n + 4 == lua_gettop(L)); co_assert(lua_istable(L, n + 4));

  lua_pushnumber(L, 1);
  lua_gettable(L, 1); co_assert(n + 5 == lua_gettop(L)); /* the key */
  if (lua_type(L, n + 5) != LUA_TSTRING) {co_trace(Co, CO_MOD_CORE, CO_LVFATAL, "invalid key type!"); return 0;}
  lua_pushvalue(L, n + 5); co_assert(n + 6 == lua_gettop(L));
  lua_gettable(L, n + 4); co_assert(n + 6 == lua_gettop(L)); /* the key in conf.arg */
  if (lua_type(L, n + 6) != LUA_TNIL){co_trace(Co, CO_MOD_CORE, CO_LVDEBUG, "conf.arg[%s] is first, ignore this", lua_tostring(L, n + 5)); return 0;}
  lua_pop(L, 1); co_assert(n + 5 == lua_gettop(L));

  lua_pushnumber(L, 2);
  lua_gettable(L, 1); co_assert(n + 6 == lua_gettop(L)); /* the value */
  k = luaL_tolstring(L, n + 5, NULL);
  v = luaL_tolstring(L, n + 6, NULL);
  co_trace(Co, CO_MOD_CORE, CO_LVDEBUG, "%s = %s is set", k ? k : "none", v ? v : "none"); /* compact with 5.1 */
  lua_pop(L, 2);

  lua_settable(L, n + 3);
  return 0;
}

/*

the next version will move the [co_xllocf] and [L] and [noexport] to the co_gene

*/
co* core_born(int argc, const char** argv, co_xllocf x, co_gene* Coge, int noexport, lua_State* L)
{
  int z = 0;
  co* Co;
  x = x ? x : co_xlloc;
  Co = co_cast(co*, (*x)(x == co_xlloc ? NULL : (Coge ? Coge->ud : NULL), NULL, 0, sizeof(co)));
  if (NULL == Co) return NULL;
  Co->xlloc = x;
  Co->ud = Coge ? Coge->ud : NULL;
  Co->tf = Coge ? Coge->tf : NULL;
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
  Co->inneractive = 0;
  Co->bactive = 0;
  Co->brettach = 0;
  Co->noexport = noexport;
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
    co_die(Co); Co = NULL;
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
  co_die(Co);
}

void core_steal(co* Co)
{
  lua_State* L = co_L(Co);
  co_pushcore(L, Co);
}

static void co_doborn(co* Co)
{
  int z = 0;
  lua_State* L = co_L(Co);
  co_assert(0 == lua_gettop(L));
  if (!co_attachfun(L, "born")) {co_assert(0 == lua_gettop(L)); return;}
  co_assert(lua_isfunction(L, 1));
  co_assert(lua_istable(L, 2));
  lua_call(L, 1, 1); co_assert(lua_gettop(L) == 1);
  z = co_cast(int, lua_tonumber(L, 1));
  lua_pop(L, 1);
  co_trace(Co, CO_MOD_CORE, CO_LVINFO, "attach's born is called with return %d", z);
  /* set born's return value */
  Co->bactive = z;
  co_assert(0 == lua_gettop(L));
}

static void co_dodie(co* Co)
{
  int n = 0;
  lua_State* L = co_L(Co);
  n = lua_gettop(L);
  co_assert(n == lua_gettop(L));
  if (!co_attachfun(L, "die")) {co_assert(n == lua_gettop(L)); return;}
  co_assert(lua_isfunction(L, n + 1));
  co_assert(lua_istable(L, n + 2));
  lua_call(L, 1, 0);
  co_trace(Co, CO_MOD_CORE, CO_LVINFO, "attach's die is called");
  co_assert(n == lua_gettop(L));
}

static int co_doactive(co* Co)
{
  int n = 0, z = 0, i = 0;
  lua_State* L = co_L(Co);
  if (!Co->bactive) {co_trace(Co, CO_MOD_CORE, CO_LVDEBUG, "attach's bactive flag is %d, stop!", Co->bactive); return Co->bactive;}
  n = lua_gettop(L);
  co_assert(n == lua_gettop(L));
  if (!co_attachfun(L, "active")) {co_assert(n == lua_gettop(L)); Co->bactive = 0; return Co->bactive;}
  co_assert(lua_isfunction(L, n + 1));
  co_assert(lua_istable(L, n + 2));
  if (n > 0 ) {for(i = 1; i <= n; ++i) lua_pushvalue(L, i);}
  lua_call(L, n + 1, 1);co_assert(n + 1 == lua_gettop(L));
  z = co_cast(int, lua_tonumber(L, n + 1)); lua_pop(L, 1);
  if (!z) co_trace(Co, CO_MOD_CORE, CO_LVINFO, "attach's active is called with return %d", z);
  co_assert(n == lua_gettop(L));
  if (Co->bactive) Co->bactive = z;
  else co_trace(Co, CO_MOD_CORE, CO_LVINFO, "is detached!");
  if (Co->bactive)
  {
    coOs_active(Co, 1);
    coN_active(Co);
  }
  return Co->bactive;
}

static int co_pborn(lua_State* L)
{
  co* Co = co_C(L);
  co_export(Co);
  coOs_born(Co);
  coN_born(Co);
  co_load(Co);
  co_execute(Co);
  co_doborn(Co);
  return 0;
}

static void co_born(co* Co, void* ud)
{
  int n = 0;
  lua_State* L = NULL;

  co_newlua(Co);

  /* pborn */
  L = co_L(Co); n = lua_gettop(L);
  lua_pushcfunction(L, co_pcallmsg);
  lua_pushcfunction(L, co_pborn);
  if (lua_pcall(L, 0, 0, 1)) {co_tracecallstack(Co, CO_MOD_CORE, CO_LVFATAL, L); coR_throw(Co, CO_ERRSCRIPTCALL);}
  co_assert(lua_gettop(L) == n + 1);
  lua_pop(L, 1);
  co_assert(n == lua_gettop(L));
}

/* the ignore parameter is to control should be really add the path, reborn is useful on this */
static void co_addpath(co* Co, lua_State* L, const char* path, int ignore)
{
  int top = 0;

  if (ignore)
  {
    co_trace(Co, CO_MOD_CORE, CO_LVDEBUG, "ignore add search path: %s, caz rettaching", path);
    return;
  }
  top = lua_gettop(L);
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

static void co_execute(co* Co)
{
  lua_State* L = co_L(Co);
  co_assert(0 == lua_gettop(L)); co_pushcore(L, Co);
  lua_getfield(L, -1, "conf"); co_assert(2 == lua_gettop(L));
  lua_getfield(L, 2, "all"); co_assert(3 == lua_gettop(L));

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
      co_addpath(Co, L, lua_tostring(L, -1), Co->brettach);
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
      co_addpath(Co, L, lua_tostring(L, 5), Co->brettach);
      lua_pushvalue(L, 5); co_assert(6 == lua_gettop(L));
      lua_pushstring(L, "manifest.lua");
      lua_concat(L, 2); co_assert(6 == lua_gettop(L));
      if (luaL_loadfile(L, lua_tostring(L, -1))) lua_error(L);
      lua_call(L, 0, 1); co_assert(7 == lua_gettop(L));

      lua_len(L, 7); len2 = (int)lua_tonumber(L, -1); lua_pop(L, 1);
      for (i2 = 1; i2 <= len2; ++i2)
      {
        int boption = 0, r = 0;
        co_assert(7 == lua_gettop(L));
        lua_pushvalue(L, 5); /* manifest path */
        lua_pushnumber(L, i2); lua_gettable(L, 7); co_assert(9 == lua_gettop(L));
        if (lua_istable(L, 9)) /* check optional flag */
        {
            lua_pushnumber(L, 2); lua_gettable(L, 9); co_assert(10 == lua_gettop(L));
            boption = (int)lua_tonumber(L, 10); lua_pop(L, 1);
            lua_pushnumber(L, 1); lua_gettable(L, 9); co_assert(10 == lua_gettop(L));
            if (!lua_isstring(L, 10)) luaL_error(L, "invalid manifest value");
            lua_remove(L, 9); co_assert(9 == lua_gettop(L));
        }
        lua_concat(L, 2); co_assert(8 == lua_gettop(L));
        r = luaL_loadfile(L, lua_tostring(L, 8)); co_assert(9 == lua_gettop(L));
        if (r)
        {
            if (!boption) lua_error(L);
            else {lua_pop(L, 1); co_assert(8 == lua_gettop(L));}
        }
        else
        {
            lua_call(L, 0, 0); co_assert(8 == lua_gettop(L));
        }
        lua_pop(L, 1); co_assert(7 == lua_gettop(L));
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

static void co_load(co* Co)
{
  lua_State* L = co_L(Co);
  co_assert(0 == lua_gettop(L)); co_pushcore(L, Co);

  lua_getfield(L, 1, "conf"); co_assert(2 == lua_gettop(L));
  lua_getfield(L, 2, "arg"); co_assert(lua_istable(L, 3)); co_assert(3 == lua_gettop(L));
  lua_getfield(L, 3, "x"); co_assert(4 == lua_gettop(L));
  if (!lua_isstring(L, 4)) {co_trace(Co, CO_MOD_CORE, CO_LVDEBUG, "no x file, ignored!"); lua_pop(L, 4); return;}

  co_loadx(Co, L, lua_tostring(L, 4));

  co_assert(4 == lua_gettop(L)); lua_pop(L, 4);
  co_assert(0 == lua_gettop(L));
}

static int co_palive(lua_State* L)
{
  co* Co = co_C(L);
  co_assert(0 == lua_gettop(L));
  Co->inneractive = 1; /* inner drive active */
  while(co_doactive(Co)){}
  co_assert(0 == lua_gettop(L));
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

static int co_pfree(lua_State* L)
{
  co* Co = co_C(L);
  co_assert(0 == lua_gettop(L));
  co_dodie(Co);
  co_assert(0 == lua_gettop(L));
  return 0;
}

static void co_free(co* Co, void* ud)
{
  int n = 0;
  lua_State* L = co_L(Co);
  if (L)
  {
    n = lua_gettop(L);
    lua_pushcfunction(L, co_pcallmsg);
    lua_pushcfunction(L, co_pfree);
    if (lua_pcall(L, 0, 0, 1)) {co_tracecallstack(Co, CO_MOD_CORE, CO_LVFATAL, L); coR_throw(Co, CO_ERRSCRIPTCALL);}
    co_assert(lua_gettop(L) == n + 1);
    lua_pop(L, 1);
    co_assert(n == lua_gettop(L));
  }

  coN_die(Co);
  coOs_die(Co);
  co_deletelua(Co);
  co_assert((Co->xlloc == co_xlloc) == (Co->umem == sizeof(*Co)));
  /* (*Co->xlloc)(NULL, Co, sizeof(co), 0); */
}

static void co_die(co* Co)
{
  int z = coR_pcall(Co, co_free, NULL);
  if (z)
  {
      co_fatalerror(Co, z);
      /* the memory leak is not important at this time.. */
      /* will delete force */
  }
  (*Co->xlloc)(NULL, Co, sizeof(co), 0);
}

static void co_newlua(co* Co)
{
  int n = 0;
  lua_State* L = co_L(Co);
  if (L)
  {
    Co->battachL = 1; /* set first so that co know don't close this L */
    n = lua_gettop(L);
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
    /* Luajit under 64bit, must use luaL_newstate, caz must use the build-in memory alloc? */
#if defined(LOLITA_CORE_LUAJIT)
    L = luaL_newstate();
#else
    L = lua_newstate(co_lualloc, Co);
#endif
    if (!L) coR_throw(Co, CO_ERRSCRIPTNEW);
    n = lua_gettop(L); co_assert(n == 0);
    co_L(Co) = L;
    lua_atpanic(L, co_panic);
  }
  lua_pushlightuserdata(L, Co);
  lua_setfield(L, LUA_REGISTRYINDEX, "lolita");
  co_assert(n == lua_gettop(L));
}

static void co_deletelua(co* Co)
{
  lua_State* L = co_L(Co);
  if (L)
  {
    lua_pushnil(L);
    lua_setfield(L, LUA_REGISTRYINDEX, "lolita");
    if (!Co->noexport)
    {
      /* there has no double check */
      lua_pushnil(L);
      lua_setglobal(L, "lolita");
    }
    if (!Co->battachL)
    {
      lua_close(L);
    }
  }
  co_L(Co) = NULL;
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

  /* TODO: need a flag to control should export the lolita, caz attach mode should need export at this time */
  if (Co->noexport) lua_pop(L, 1);
  else lua_setglobal(L, "lolita");
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
  lua_pushstring(L, LOLITA_CORE_GITVER); lua_setfield(L, -2, "reposversion");
  lua_pushstring(L, LOLITA_CORE_PLATSTR); lua_setfield(L, -2, "platform");
  lua_pop(L, 2); /* core.info */
  co_assert(lua_gettop(L) == 0);
}

static void co_pexportonearg2conf(co* Co, lua_State* L, const char* k, const char* v)
{
    co_assert(7 == lua_gettop(L));
    if (strncmp(v, "t::", 3) == 0)
    {
        /* table */
        size_t len = 0, i;
        char* t = coM_newstr(Co, NULL, strlen(v + 3) + 12, &len);
        strcat(strcat(t, "return "), v + 3);
        for (i = 0; i < len; ++i)
        {
            if (t[i] == '[') t[i] = '{';
            else if (t[i] == ']') t[i] = '}';
        }
        
        lua_pushstring(L, k); co_assert(8 == lua_gettop(L));
        if (LUA_OK != luaL_loadstring(L, t)) {coM_deletestr(Co, t);lua_error(L);}
        coM_deletestr(Co, t); t = NULL;
        co_assert(9 == lua_gettop(L));
        if (LUA_OK != lua_pcall(L, 0, 1, 0)) lua_error(L);
        co_assert(9 == lua_gettop(L));
        if (!lua_istable(L, 9)) luaL_error(L, "%s is not table!! fucker?", k);
        lua_pushvalue(L, 8);
        lua_pushvalue(L, 9);
        lua_settable(L, 4); /* conf.arg[k] = v */
        lua_settable(L, 3); /* conf.all[k] = v */
    }
    else if (strncmp(v, "n::", 3) == 0)
    {
        /* number */
        double dv = atof(v + 3);
        lua_pushstring(L, k);
        lua_pushnumber(L, (lua_Number)dv);
        lua_pushvalue(L, 8);
        lua_pushvalue(L, 9);
        lua_settable(L, 4); /* conf.arg[k] = v */
        lua_settable(L, 3); /* conf.all[k] = v */
    }
    else
    {
        /* set string conf.arg[k] = v and conf.all[k] = v */
        lua_pushstring(L, k);
        lua_pushstring(L, v);
        lua_pushvalue(L, 8);
        lua_pushvalue(L, 9);
        lua_settable(L, 4); /* conf.arg[k] = v */
        lua_settable(L, 3); /* conf.all[k] = v */
    }

    co_assert(7 == lua_gettop(L));
}

static void co_pexportarg2conf(co* Co, lua_State* L)
{
  const char** argv = NULL;
  const char* p = NULL;
  int argc = 0, i = 0;
  size_t len = 0;
  argv = Co->argv;
  argc = Co->argc;
  co_assert(lua_gettop(L) == 0);
  co_pushcore(L, Co);
  lua_getfield(L, 1, "conf"); co_assert(2 == lua_gettop(L));
  lua_getfield(L, 2, "all"); co_assert(3 == lua_gettop(L));
  lua_getfield(L, 2, "arg"); co_assert(4 == lua_gettop(L));
  lua_newtable(L); lua_pushvalue(L, -1); lua_setfield(L, 4, "_original"); co_assert(5 == lua_gettop(L)); /* conf.arg._original */
  lua_pushvalue(L, 5); lua_setfield(L, 3, "_original"); co_assert(5 == lua_gettop(L)); /* copy to conf.all._orginal */
  lua_pushstring(L, argc > 0 ? argv[0] : ""); lua_pushvalue(L, 6); lua_setfield(L, 4, "_path"); co_assert(6 == lua_gettop(L)); /* conf.arg._path */
  lua_setfield(L, 3, "_path"); co_assert(5 == lua_gettop(L)); /* copy to conf.all._path */

  for (i = 1; i < argc; ++i)
  {
    lua_pushnumber(L, i); lua_pushstring(L, argv[i]); lua_settable(L, 5); /* set to conf.arg._original */
    p = strchr(argv[i], '=');
    if (!p) {lua_pushstring(L, argv[i]); lua_pushstring(L, ""); lua_settable(L, 4); continue; } /* have no =, just empty string */
    len = p - argv[i]; if (!len) continue; /* = at first, have no key, so ignore this */

    lua_pushlstring(L, argv[i], (int)len); co_assert(6 == lua_gettop(L));
    lua_pushstring(L, p + 1); co_assert(7 == lua_gettop(L));
    co_pexportonearg2conf(Co, L, lua_tostring(L, 6), lua_tostring(L, 7));
    lua_pop(L, 2);
  }

  lua_getfield(L, 4, "tracelv");
  Co->tracelv = (int)lua_tonumber(L, -1);
  lua_pop(L, 1);

  lua_pop(L, 5);
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
  co_pushcore(L, Co); co_assert(1 == lua_gettop(L));
  lua_newtable(L); co_assert(2 == lua_gettop(L));
  lua_pushvalue(L, 2); lua_setfield(L, 1, "conf"); co_assert(2 == lua_gettop(L)); /* set core.conf */
  luaL_setfuncs(L, co_funcs, 0); co_assert(2 == lua_gettop(L)); /* set function to core.conf */
  lua_pushvalue(L, 2); lua_setmetatable(L, 2); co_assert(2 == lua_gettop(L)); /* set core.conf as metatable as itself */

  lua_newtable(L); lua_setfield(L, 2, "arg"); co_assert(2 == lua_gettop(L)); /* set core.conf.arg */
  lua_newtable(L); lua_pushvalue(L, 3); lua_setfield(L, 2, "all"); co_assert(3 == lua_gettop(L)); /* set core.conf.all */
  /*
    core.conf.all
    core.conf
    core
  */

  lua_newtable(L); lua_setfield(L, 3, "_confpathstack"); co_assert(3 == lua_gettop(L)); /* set core.conf._confpath */
  lua_pushvalue(L, 3); lua_setfield(L, 2, "__index"); co_assert(3 == lua_gettop(L)); /* set core.conf.all as core.conf's __index */
  lua_pushvalue(L, 3); lua_setfield(L, 2, "__newindex"); co_assert(3 == lua_gettop(L)); /* set core.conf.all as core.conf's __newindex */

  lua_pop(L, 3);
  co_assert(lua_gettop(L) == 0);

  co_pexportarg2conf(Co, L);
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
    {"rettach", co_export_rettach},
    {"isrettaching", co_export_isrettaching},
    {"addpath", co_export_addpath},
    {"active", co_export_active},
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

static void co_export(co* Co)
{
  lua_State* L = co_L(Co);
  co_assert(lua_gettop(L) == 0);
  co_pexportcore(Co, L);
  co_pexportconf(Co, L);
  co_pexportinfo(Co, L);
  co_pexportbase(Co, L);
  co_assert(lua_gettop(L) == 0);
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
    "NONE","FATAL","DEBUG", "INFO",
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

#if !defined(LOLITA_CORE_LUAJIT)
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
#endif

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
  co* Co = co_C(L);
  if (Co->brettach)
  {
    co_trace(Co, CO_MOD_CORE, CO_LVDEBUG, "attach while rettaching, just return the attach!");
    lua_getfield(L, LUA_REGISTRYINDEX, "lolita.attach");
    return 1;
  }


  /* if table is different? replace it ?? let me think about it!! */
  lua_getfield(L, LUA_REGISTRYINDEX, "lolita.attach");
  if (!lua_isnil(L, -1)) { luaL_error(L, "duplicate attach"); }
  lua_pop(L, 1);


  /* if attach is not pass in, create a new for it */
  /* ensure that the -1 is this table */
  if (!lua_istable(L, 1))
  {
    lua_newtable(L);
    lua_pushvalue(L, -1);
    co_trace(Co, CO_MOD_CORE, CO_LVDEBUG, "create a new attach for it");
  }
  else
  {
    lua_pushvalue(L, 1);
    co_trace(Co, CO_MOD_CORE, CO_LVDEBUG, "pass in attach for it");
  }

  lua_getfield(L, -1, "born");
  if (!(lua_isnil(L, -1) || lua_isfunction(L, -1))) luaL_error(L, "[born] should be nil or function");
  lua_pop(L, 1);
  lua_getfield(L, -1, "active");
  if (!(lua_isnil(L, -1) || lua_isfunction(L, -1))) luaL_error(L, "[active] should be nil or function");
  lua_pop(L, 1);
  lua_getfield(L, -1, "die");
  if (!(lua_isnil(L, -1) || lua_isfunction(L, -1))) luaL_error(L, "[die] should be nil or function");
  lua_pop(L, 1);
  lua_getfield(L, -1, "reborn");
  if (!(lua_isnil(L, -1) || lua_isfunction(L, -1))) luaL_error(L, "[reborn] should be nil or function");
  lua_pop(L, 1);
  lua_setfield(L, LUA_REGISTRYINDEX, "lolita.attach");
  return 1;
}

static int co_export_detach(lua_State* L)
{
  co* Co = co_C(L);
  Co->bactive = 0;
  /* don't erase the old, erase it while attach
  lua_pushnil(L);
  lua_setfield(L, LUA_REGISTRYINDEX, "lolita.attach");
  */

  /*
    return 1 directly caz luajit coredump
  */
  lua_pushnil(L);
  return 1;
}

static int co_export_isrettaching(lua_State* L)
{
  co* Co = co_C(L);
  lua_pushboolean(L, Co->brettach);
  return 1;
}

static int co_prettach(lua_State* L)
{
  co* Co = co_C(L);
  int n = lua_gettop(L);

  /* reexecute */
  /* TODO::should clear some status, such as package.cpath, package.path, */
  /* TODO::rettach include the x=path config files */
  co_assert(0 == n);
  co_execute(Co);
  co_assert(lua_gettop(L) == n);

  if (!co_attachfun(L, "reborn"))
  {
    co_assert(lua_gettop(L) == n);
    return 0;
  }

  co_trace(Co, CO_MOD_CORE, CO_LVDEBUG, "reborning........");
  co_assert(lua_isfunction(L, n + 1));
  co_assert(lua_istable(L, n + 2));
  lua_call(L, 1, 0);
  co_trace(Co, CO_MOD_CORE, CO_LVDEBUG, "reborned!!!!!!!!!!");
  co_assert(0 == lua_gettop(L));

  return 0;
}

static int co_export_rettach(lua_State* L)
{
  co* Co = co_C(L);
  int n = lua_gettop(L);
  if (Co->brettach) { luaL_error(L, "rettach in rettaching?? fucker?"); }
  if (!Co->bactive) { luaL_error(L, "can't rettach while not in active"); }
  Co->brettach = 1;
  co_trace(Co, CO_MOD_CORE, CO_LVDEBUG, "rettaching........");

  lua_pushcfunction(L, co_pcallmsg); co_assert(n + 1 == lua_gettop(L));
  lua_pushcfunction(L, co_prettach); co_assert(n + 2 == lua_gettop(L));
  if (lua_pcall(L, 0, 0, n + 1)) {co_tracecallstack(Co, CO_MOD_CORE, CO_LVFATAL, L); lua_pop(L, 1);} /* pop the error string */
  co_assert(n + 1 == lua_gettop(L));
  lua_pop(L, 1); /* pop the pcallmsg function */

  co_trace(Co, CO_MOD_CORE, CO_LVDEBUG, "rettached!!!!!!!!!");
  Co->brettach = 0;

  co_assert(lua_gettop(L) == n);
  lua_pushnumber(L, 1);
  return 1;
}

static int co_export_addpath(lua_State* L)
{
  co* Co = co_C(L);
  co_addpath(Co, L, luaL_checkstring(L, 1), 0);
  return 0;
}

static int co_export_active(lua_State* L)
{
  int z = 0;
  co* Co = co_C(L);
  if (Co->inneractive) {co_trace(Co, CO_MOD_CORE, CO_LVFATAL, "active is drived by inner!"); lua_error(L); return 0;}
  z = co_doactive(Co);
  if (z) lua_pushnumber(L, 1);
  return z;
}

void co_trace(co* Co, int mod, int lv, const char* msg, ...)
{
  va_list msgva;

  va_start(msgva, msg);
  co_buildintrace(Co, mod, lv, msg, msgva);
  va_end(msgva);

  if (Co->tf)
  {
    va_start(msgva, msg);
    Co->tf(Co, mod, lv, co_modname(Co, mod), co_lvname(Co, lv), msg, msgva);
    va_end(msgva);
  }
}

void co_tracecallstack(co* Co, int mod, int lv, lua_State* L)
{
    co_trace(Co, CO_MOD_CORE, CO_LVFATAL, "=================================== |\n%s", lua_tostring(L, -1));
    co_trace(Co, CO_MOD_CORE, CO_LVFATAL, "=================================== |");
}

int co_pcallmsg(lua_State* L)
{
#if LUA_VERSION_NUM == 501
  /* what if lua 5.1.4 or lower ? */
  /* TODO: check stack space is enough to do this? */
  lua_getglobal(L, "debug");
  if (!lua_istable(L, -1))
  {
    lua_pop(L, 1);
    lua_pushstring(L, "\n");
    lua_pushstring(L, "WTF, the [debug] is overwrited? give up traceback");
    goto co_exit_flag;
  }
  lua_getfield(L, -1, "traceback");
  if (!lua_isfunction(L, -1))
  {
    lua_pop(L, 2);
    lua_pushstring(L, "\n");
    lua_pushstring(L, "WTF, the [debug.traceback] is overwrited? give up traceback");
    goto co_exit_flag;
  }
  lua_call(L, 0, 1);
  if (!lua_isstring(L, -1))
  {
    lua_pop(L, 2); /* pop [wrong return value], [debug] */
    lua_pushstring(L, "\n");
    lua_pushstring(L, "WTF, the [debug.traceback] return is overwrited? give up traceback");
  }
  else
  {
    lua_remove(L, -2); /* pop debug */
    lua_pushstring(L, "\n");
    lua_insert(L, -2);
  }
  co_exit_flag:
  lua_concat(L, 3);
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

int co_attachfun(lua_State* L, const char* fun)
{
  int n = 0;
  co* Co = co_C(L);
  n = lua_gettop(L);
  lua_getfield(L, LUA_REGISTRYINDEX, "lolita.attach");
  if (!lua_istable(L, n + 1)) {lua_pop(L, 1); co_assert(n == lua_gettop(L)); return 0;}
  co_assert(n + 1 == lua_gettop(L));

  lua_getfield(L, n + 1, fun); co_assert(n + 2 == lua_gettop(L)); co_assert(lua_isfunction(L, n + 2) || lua_isnil(L, n + 2));
  if (lua_isnil(L, n + 2))
  {
    co_trace(Co, CO_MOD_CORE, CO_LVDEBUG, "attach's [%s] is nil!", fun);
    lua_pop(L, 2);
    return 0;
  }
  lua_insert(L, n + 1);
  co_assert(n + 2 == lua_gettop(L));
  return 1;
}
