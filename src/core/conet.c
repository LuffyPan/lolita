/*

LoliCore net
Chamz Lau, Copyright (C) 2013-2017
2013/03/04 21:16:16

*/

#include "conet.h"
#include "cort.h"
#include "comm.h"
#include "cos.h"

#if LOLICORE_PLAT == LOLICORE_PLAT_WIN32
#ifndef WIN32_LEAN_AND_MEAN
    #define WIN32_LEAN_AND_MEAN
#endif
#include <windows.h>
#include <winsock2.h>
#include <winerror.h>
#pragma comment(lib, "ws2_32.lib")
typedef SOCKET cosockfd;
#define COSOCKFD_ERROR (SOCKET_ERROR)
#define COSOCKFD_NULL (INVALID_SOCKET)
#define COSOCKFD_EWOULDBLOCK WSAEWOULDBLOCK
#define COSOCKFD_EAGAIN COSOCKFD_EWOULDBLOCK
#define COSOCKFD_EINPROGRESS WSAEINPROGRESS
#define COSOCKFD_ENOTCONN WSAENOTCONN
#define cosockfd_close closesocket
#define cosockfd_ioctl ioctlsocket
#define cosockfd_errno WSAGetLastError()
#define cosockfd_errstr(ec) "not supported"
#define cosock_activeconn cosock_activeconn_win32
#define cosock_activeaccp cosock_activeaccp_common
#else
#include <unistd.h>
#include <sys/ioctl.h>
#include <sys/types.h>
#include <netinet/in.h>
#include <netinet/ip.h>
#include <errno.h>
typedef int cosockfd;
#define COSOCKFD_EWOULDBLOCK EWOULDBLOCK
#define COSOCKFD_EAGAIN EAGAIN
#define COSOCKFD_EINPROGRESS EINPROGRESS
#define COSOCKFD_ENOTCONN ENOTCONN
#define COSOCKFD_NULL (-1)
#define COSOCKFD_ERROR (-1)
#define cosockfd_close close
#define cosockfd_ioctl ioctl
#define cosockfd_errno errno
#define cosockfd_errstr(ec) strerror((ec))
#define cosock_activeconn cosock_activeconn_ux
#define cosock_activeaccp cosock_activeaccp_common /* hoho */
#endif

#define COSOCKFD_TNULL (0)
#define COSOCKFD_TCONN (1)
#define COSOCKFD_TACCP (2)
#define COSOCKFD_TATTA (3)

#define COSOCKFDEV_ACCEPT 0x00000001
#define COSOCKFDEV_READ 0x00000002
#define COSOCKFDEV_WRITE 0x00000004
#define COSOCKFDEV_CLOSE 0x00000008
#define COSOCKFDEV_ERROR 0x00000010
#define COSOCKFDEV_CONNSUC 0x00000020
#define COSOCKFDEV_CONNFAL 0x00000040

#define COSOCK_ATTA_INITCNT 64
#define COSOCK_ATTA_STEPCNT 128
#define COSOCK_ATTA_LIMITCNT 4096

#define COSOCKBUF_INITCNT 4096
#define COSOCKBUF_STEPCNT 4096
#define COSOCKBUF_LIMITCNT 4096 /* develop value for test and debug */
/* #define COSOCKBUF_LIMITCNT 40960 */
#define COSOCKBUF_ALLCNT COSOCKBUF_INITCNT, COSOCKBUF_STEPCNT, COSOCKBUF_LIMITCNT

#define CON_COSOCK_INITCNT 16
#define CON_COSOCK_STEPCNT 64
#define CON_COSOCK_LIMITCNT 4096

typedef struct cosockpack_hdr cosockpack_hdr;
typedef struct cosockpack_tail cosockpack_tail;
typedef struct cosockbuf cosockbuf;
typedef struct cosockpool cosockpool;
typedef struct cosockid2idx cosockid2idx;
typedef struct cosockevent cosockevent;
typedef struct cosock cosock;
typedef void (*cosockeventer)(co* Co, cosock* s, cosock* as, int extra);
/* typedef void (*cosock_activefunc)(void* p, cosock* s, cosock* sa); */

static void cosock_activeaccp_common(co* Co, cosock* s);
#if LOLICORE_PLAT == LOLICORE_PLAT_WIN32
static void cosock_activeconn_win32(co* Co, cosock* s);
#else
static void cosock_activeconn_ux(co* Co, cosock* s);
#endif

/* align & littleending ! */
#define COSOCKPACK_HDR_FLAG '|'
#define COSOCKPACK_TAIL_FLAG '^'
#define COSOCKPACK_VERSION 1990
struct cosockpack_hdr
{
  char flag;
  int ver;
  size_t dsize;
};

struct cosockpack_tail
{
  char flag;
};

struct cosockbuf
{
  char* b;
  size_t cursize;
  size_t stepsize;
  size_t maxsize;
  size_t limitsize;
};

struct cosockpool
{
  cosock** sp;
  int curcnt;
  int stepcnt;
  int maxcnt;
  int limitcnt;
};

struct cosockid2idx
{
  lua_State* id2idx;
  int nextid;
};

struct cosockevent
{
  cosockeventer connect;
  cosockeventer accept;
  cosockeventer processpack;
  cosockeventer close;
};

struct cosock
{
  int poolidx; /* internal use index! */
  int id; /* identify */
  cosockfd fd;
  int fdt; /* fd type, connector, acceptor, attacher */
  int bactive; /* is in active */
  int bconnected; /* is connected, TCONN used */
  int bclosed; /* delay delete flag */
  void* ud; /* user data */
  cosock* attaed2s; /* attached to s */
  cosockpool* closedpo; /* closed */
  cosockpool* attapo; /* cosocks, TATTA used */
  cosockbuf* revbuf; /* rev buf, TCONN, TATTA used */
  cosockbuf* sndbuf; /* send buf TCONN, ATTA used */
  cosockid2idx* id2idx; /* pointer 2 outside */
  cosockevent* eventer; /* pointer 2 outside */
  int ec; /* errorcode */
};

struct coN
{
  cosockpool* po;
  cosockpool* closedpo;
  cosockid2idx* id2idx;
  cosockevent eventer;
};

static cosockbuf* cosockbuf_new(co* Co, size_t initsize, size_t stepsize, size_t limitsize);
static void cosockbuf_use(co* Co, cosockbuf* buf, size_t usesize);
static int cosockbuf_isfull(co* Co, cosockbuf* buf, size_t usesize);
static void cosockbuf_delete(co* Co, cosockbuf* buf);
static void cosockbuf_lmove(cosockbuf* buf, size_t msize);
#define cosockbuf_clear(buf) (buf)->cursize = 0
#define cosockbuf_data(buf) ((buf)->b)
#define cosockbuf_datasize(buf) (buf)->cursize
#define cosockbuf_uudata(buf) ((buf)->b + (buf)->cursize)
#define cosockbuf_uusize(buf) ((buf)->maxsize - (buf)->cursize)

static cosockpool* cosockpool_new(co* Co, int initcnt, int stepcnt, int limitcnt);
static void cosockpool_add(co* Co, cosockpool* po, cosock* s);
static void cosockpool_addirect(co* Co, cosockpool* po, cosock* s);
static void cosockpool_del(co* Co, cosockpool* po, cosock* s);
static int cosockpool_isfull(co* Co, cosockpool* po, int cnt);
static void cosockpool_delete(co* Co, cosockpool* po);
static cosock* cosockpool_getsock(cosockpool* po, int idx);
#define cosockpool_cosocks(po) ((po)->sp)
#define cosockpool_cosockcnt(po) ((po)->curcnt)
#define cosockpool_clear(po) (po)->curcnt = 1

static cosockid2idx* cosockid2idx_new(co* Co);
static void cosockid2idx_delete(co* Co, cosockid2idx* id2idx);
static int cosockid2idx_newid(cosockid2idx* id2idx);
static void cosockid2idx_attachii(cosockid2idx* id2idx, int id, int idx);

static cosock* cosock_new(co* Co, cosockid2idx* i2i, cosockpool* closedpo, cosock* attached2s, cosockevent* eventer, int fdt);
static int cosock_listen(co* Co, cosock* s, const char* addr, unsigned short port);
static int cosock_connect(co* Co, cosock* s, const char* addr, unsigned short port);
static int cosock_accept(co* Co, cosock* s, cosock** psn);
static int cosock_recv(co* Co, cosock* s);
static int cosock_send(co* Co, cosock* s);
static int cosock_canpush(co* Co, cosock* s, size_t datasize);
static void cosock_push(co* Co, cosock* s, const char* data, size_t datasize);
static int cosock_pop(co* Co, cosock* s, const char** data, size_t* datasize);
static void cosock_active(co* Co, cosock* s);
static void cosock_close(co* Co, cosock* s);
static void cosock_delete(co* Co, cosock* s);
#define cosock_eventconnect(Co, s, as, extra) (s)->eventer->connect(Co, s, as, extra)
#define cosock_eventaccept(Co, s, as, extra) (s)->eventer->accept(Co, s, as, extra)
#define cosock_eventprocesspack(Co, s, as, extra) (s)->eventer->processpack(Co, s, as, extra)
#define cosock_eventclose(Co, s, as, extra) (s)->eventer->close(Co, s, as, extra)

static int cosock_newfd(co* Co, cosock* s);
static int cosock_attachfd(co* Co, cosock* s, cosockfd fd);
static void cosock_newfdt(co* Co, cosock* s);
static void cosock_deletefd(co* Co, cosock* s);
static void cosock_deletefdt(co* Co, cosock* s);
#define cosock_id(s) ((s)->id)
#define cosock_ec(s) ((s)->ec)
#define cosock_logec(s) cosock_ec(s) = cosockfd_errno
#define cosock_setev(s,e) ((s)->ev) |= (e)
#define cosock_afunc(s) ((s)->afunc)
#define cosock_fdt(s) ((s)->fdt)

static void coN_initenv(co* Co);
static void coN_uninitenv(co* Co);
static void coN_initeventer(co* Co);
static void coN_newid2idx(co* Co);
static void coN_deleteid2idx(co* Co);
static void coN_newcosocks(co* Co);
static void coN_deletecosocks(co* Co);
static int coN_listen(co* Co, const char* addr, unsigned short port);
static int coN_connect(co* Co, const char* addr, unsigned short port);
static int coN_push(co* Co, int id, int attaid, const char* data, size_t dsize);
static int coN_close(co* Co, int id, int attaid);
static void coN_realclose(co* Co);
static void coN_eventconnect(co* Co, cosock* s, cosock* as, int extra);
static void coN_eventaccept(co* Co, cosock* s, cosock* as, int extra);
static void coN_eventprocesspack(co* Co, cosock* s, cosock* as, int extra);
static void coN_eventclose(co* Co, cosock* s, cosock* as, int extra);

static cosockbuf* cosockbuf_new(co* Co, size_t initsize, size_t stepsize, size_t limitsize)
{
  cosockbuf* buf = NULL;
  co_assert(initsize > 0);
  co_assert(stepsize > 0);
  co_assert(initsize <= limitsize);
  buf = coM_newobj(Co, cosockbuf);
  buf->b = NULL;
  buf->cursize = 0;
  buf->stepsize = stepsize;
  buf->maxsize = 0;
  buf->limitsize = limitsize;
  buf->b = coM_newvector(Co, char, initsize);
  buf->maxsize = initsize;
  return buf;
}

static void cosockbuf_use(co* Co, cosockbuf* buf, size_t usesize)
{
  /* bug, cursize can be equl to maxsize */
  co_assertex(buf->cursize + usesize <= buf->maxsize, "use cosockbuf_isfull to check first!!");
  buf->cursize += usesize;
}

static int cosockbuf_isfull(co* Co, cosockbuf* buf, size_t usesize)
{
  if (buf->cursize + usesize > buf->maxsize)
  {
    size_t stepsize = 0;
    if (buf->maxsize >= buf->limitsize) return 1;
    stepsize = buf->limitsize - buf->maxsize;
    stepsize = stepsize > buf->stepsize ? buf->stepsize : stepsize;
    buf->b = coM_renewvector(Co, char, buf->b, buf->maxsize, buf->maxsize + stepsize);
    buf->maxsize += stepsize;
    return buf->cursize + usesize > buf->maxsize;
  }
  return 0;
}

static void cosockbuf_delete(co* Co, cosockbuf* buf)
{
  if (!buf) return;
  coM_deletevector(Co, buf->b, buf->maxsize);
  coM_deleteobj(Co, buf);
}

static void cosockbuf_lmove(cosockbuf* buf, size_t msize)
{
  co_assert(msize <= buf->cursize);
  memcpy(buf->b, buf->b + msize, buf->cursize - msize);
  buf->cursize -= msize;
}

static cosockpool* cosockpool_new(co* Co, int initcnt, int stepcnt, int limitcnt)
{
  cosockpool* po = NULL;
  co_assert(initcnt > 0);
  co_assert(stepcnt > 0);
  co_assert(initcnt <= limitcnt);
  po = coM_newobj(Co, cosockpool);
  po->sp = NULL;
  po->curcnt = 0;
  po->stepcnt = stepcnt;
  po->maxcnt = 0;
  po->limitcnt = limitcnt;
  po->sp = coM_newvector(Co, cosock*, initcnt);
  po->maxcnt = initcnt;
  po->sp[0] = NULL;
  po->curcnt = 1; /* reserved 0 to identify init state */
  return po;
}

static void cosockpool_add(co* Co, cosockpool* po, cosock* s)
{
  co_assert(s->poolidx == 0);
  co_assertex(po->curcnt < po->maxcnt, "use cosockpool_isfull to check first");
  s->poolidx = po->curcnt;
  po->sp[po->curcnt++] = s;
  cosockid2idx_attachii(s->id2idx, s->id, s->poolidx);
}

static void cosockpool_addirect(co* Co, cosockpool* po, cosock* s)
{
  co_assert(s);
  co_assertex(po->curcnt < po->maxcnt, "use cosockpool_isfull to check first");
  po->sp[po->curcnt++] = s;
}

static void cosockpool_del(co* Co, cosockpool* po, cosock* s)
{
  int idx = s->poolidx;
  cosock* lasts = NULL;
  co_assert(idx > 0);
  co_assert(idx < po->curcnt);
  co_assert(po->sp[idx] == s);
  lasts = po->sp[po->curcnt - 1];
  lasts->poolidx = idx;
  po->sp[idx] = lasts;
  s->poolidx = 0;
  cosockid2idx_attachii(lasts->id2idx, lasts->id, lasts->poolidx);
  cosockid2idx_attachii(s->id2idx, s->id, 0);
  --po->curcnt;
}

static int cosockpool_isfull(co* Co, cosockpool* po, int cnt)
{
  co_assert(cnt >= 0);
  if (po->curcnt + cnt > po->maxcnt)
  {
    int stepcnt = 0;
    /* expand */
    if (po->maxcnt >= po->limitcnt) return 0;
    stepcnt = po->limitcnt - po->maxcnt;
    stepcnt = stepcnt > po->stepcnt ? po->stepcnt : stepcnt;
    po->sp = coM_renewvector(Co, cosock*, po->sp, po->maxcnt, po->maxcnt + stepcnt);
    po->maxcnt += stepcnt;
    return po->curcnt + cnt <= po->maxcnt;
  }
  return 1;
}

static void cosockpool_delete(co* Co, cosockpool* po)
{
  if (!po) return;
  coM_deletevector(Co, po->sp, po->maxcnt);
  coM_deleteobj(Co, po);
}

static cosock* cosockpool_getsock(cosockpool* po, int idx)
{
  co_assert(idx > 0 && idx < po->curcnt);
  return po->sp[idx];
}

static void* _cosockid2idx_alloc(void* ud, void* p, size_t os, size_t ns)
{
  co* Co = co_cast(co*, ud);
  void* np = NULL;
  /* when p == NULL, the un32_osize indicate the type of object lua, so, reset it to 0 */
  os = (NULL == p && os > 0) ? 0 : os;
  np = coM_xllocmem(Co, p, os, ns);
  /* Lua assumes that the allocator never fails when osize >= nsize */
  if (NULL == np && ns > 0 && ns <= os) co_assert(0);
  return np;
}

static cosockid2idx* cosockid2idx_new(co* Co)
{
  cosockid2idx* i2i = NULL;
  i2i = coM_newobj(Co, cosockid2idx);
  i2i->nextid = 1;
  i2i->id2idx = NULL;
  i2i->id2idx = lua_newstate(_cosockid2idx_alloc, Co);
  return i2i;
}

static void cosockid2idx_delete(co* Co, cosockid2idx* id2idx)
{
  if (!id2idx) return;
  lua_close(id2idx->id2idx);
  coM_deleteobj(Co, id2idx);
}

static int cosockid2idx_newid(cosockid2idx* id2idx)
{
  return id2idx->nextid++;
}

static void cosockid2idx_attachii(cosockid2idx* id2idx, int id, int idx)
{
  lua_pushglobaltable(id2idx->id2idx);
  lua_pushnumber(id2idx->id2idx, id);
  lua_pushnumber(id2idx->id2idx, idx);
  lua_settable(id2idx->id2idx, -3);
  lua_pop(id2idx->id2idx, 1);
}

static int cosockid2idx_getidx(cosockid2idx* id2idx, int id)
{
  int idx = 0;
  lua_pushglobaltable(id2idx->id2idx);
  lua_pushnumber(id2idx->id2idx, id);
  lua_gettable(id2idx->id2idx, -2);
  idx = (int)lua_tonumber(id2idx->id2idx, -1);
  lua_pop(id2idx->id2idx, 2);
  co_assertex(idx, "invalid id 2 idx");
  return idx;
}

void coN_born(co* Co)
{
  coN* N = NULL;
  co_assert(!Co->N);
  N = co_cast(coN*, coM_newobj(Co, coN));
  N->po = NULL;
  N->id2idx = NULL;
  Co->N = N;
  coN_initeventer(Co);
  coN_newid2idx(Co);
  coN_initenv(Co);
  coN_newcosocks(Co);
  co_traceinfo(Co, "coNet borned..\n");
}

void coN_active(co* Co)
{
  int i = 0;
  coN* N = Co->N;
  cosock** ps = NULL;
  int cnt = 0;
  ps = cosockpool_cosocks(N->po);
  cnt = cosockpool_cosockcnt(N->po);
  for (i = 1; i < cnt; ++i) { cosock_active(Co, ps[i]); }
  coN_realclose(Co);
}

void coN_die(co* Co)
{
  if (!Co->N) return;
  coN_deletecosocks(Co);
  coN_uninitenv(Co);
  coN_deleteid2idx(Co);
  coM_deleteobj(Co, Co->N);
  co_traceinfo(Co, "coNet died..\n");
}

static void coN_initenv(co* Co)
{
#if LOLICORE_PLAT == LOLICORE_PLAT_WIN32
  WSADATA wsadata = { 0 };
  coR_runerror(Co, 0 == WSAStartup(MAKEWORD(2, 2), &wsadata));
#endif
}

static void coN_uninitenv(co* Co)
{
#if LOLICORE_PLAT == LOLICORE_PLAT_WIN32
  WSACleanup();
#endif
}

static void coN_initeventer(co* Co)
{
  coN* N = Co->N;
  N->eventer.connect = coN_eventconnect;
  N->eventer.accept = coN_eventaccept;
  N->eventer.processpack = coN_eventprocesspack;
  N->eventer.close = coN_eventclose;
}

static void coN_newid2idx(co* Co)
{
  coN* N = Co->N;
  N->id2idx = cosockid2idx_new(Co);
}

static void coN_deleteid2idx(co* Co)
{
  coN* N = Co->N;
  cosockid2idx_delete(Co, N->id2idx);
}

static void coN_newcosocks(co* Co)
{
  coN* N = Co->N;
  N->po = cosockpool_new(Co, CON_COSOCK_INITCNT, CON_COSOCK_STEPCNT, CON_COSOCK_LIMITCNT);
  N->closedpo = cosockpool_new(Co, CON_COSOCK_INITCNT, CON_COSOCK_STEPCNT, CON_COSOCK_LIMITCNT);
}

static void coN_deletecosocks(co* Co)
{
  coN* N = Co->N;
  cosock** ps = NULL;
  int cnt = 0;
  if (!N) return;
  if (!N->po) return;
  ps = cosockpool_cosocks(N->po);
  cnt = cosockpool_cosockcnt(N->po);
  while(cnt > 1)
  {
    cosock* s = ps[1];
    cosockpool_del(Co, N->po, s);
    cosock_delete(Co, s);
    --cnt;
  }
  cosockpool_delete(Co, N->po);
  cosockpool_delete(Co, N->closedpo);
  N->po = NULL;
}

static int coN_listen(co* Co, const char* addr, unsigned short port)
{
  cosock* s = NULL;
  coN* N = Co->N;
  if (!cosockpool_isfull(Co, N->po, 1))
  {
    return 0;
  }
  s = cosock_new(Co, N->id2idx, N->closedpo, NULL, &N->eventer, COSOCKFD_TACCP);
  if (!cosock_listen(Co, s, addr, port))
  {
    cosock_delete(Co, s);
    return 0;
  }
  cosockpool_add(Co, N->po, s);
  return cosock_id(s);
}

static int coN_connect(co* Co, const char* addr, unsigned short port)
{
  cosock* s = NULL;
  coN* N = Co->N;
  if (!cosockpool_isfull(Co, N->po, 1))
  {
    return 0;
  }
  s = cosock_new(Co, N->id2idx, N->closedpo, NULL, &N->eventer, COSOCKFD_TCONN);
  if (!cosock_connect(Co, s, addr, port))
  {
    cosock_delete(Co, s);
    return 0;
  }
  cosockpool_add(Co, N->po, s);
  return cosock_id(s);
}

static int coN_push(co* Co, int id, int attaid, const char* data, size_t dsize)
{
  coN* N = Co->N;
  cosock* s = NULL, *attas = NULL, *ps = NULL;
  int idx = 0, attaidx = 0;
  cosockpack_hdr hdr;
  cosockpack_tail tail;
  co_assert(id > 0 && attaid >= 0);
  co_assert(!(id == 0 && attaid == 0));
  idx = cosockid2idx_getidx(N->id2idx, id); co_assert(idx);
  s = cosockpool_getsock(N->po, idx); co_assert(s);
  co_assert(s->id == id); co_assert(s->poolidx == idx);
  if (attaid == 0)
  {
    co_assertex(COSOCKFD_TCONN == s->fdt, "only connector or attachor can push data");
    ps = s;
  }
  else
  {
    co_assertex(COSOCKFD_TACCP == s->fdt, "only acceptor's attachor can push data");
    attaidx = cosockid2idx_getidx(s->id2idx, attaid); co_assert(attaidx);
    attas = cosockpool_getsock(s->attapo, attaidx); co_assert(attas);
    co_assert(attas->id == attaid); co_assert(attas->poolidx == attaidx);
    co_assertex(COSOCKFD_TATTA == attas->fdt, "only attachor can push data");
    ps = attas;
  }
  if (!cosock_canpush(Co, ps, dsize + sizeof(cosockpack_hdr) + sizeof(cosockpack_tail)))
  {
    co_traceerror(Co, "coNet, id[%d], attaid[%d]'s send buffer is full!!!!!\n", s->id, attas ? attas->id : 0);
    return 0;
  }
  hdr.flag = COSOCKPACK_HDR_FLAG;
  hdr.ver = COSOCKPACK_VERSION;
  hdr.dsize = dsize;
  tail.flag = COSOCKPACK_TAIL_FLAG;
  cosock_push(Co, ps, (const char*)&hdr, sizeof(hdr));
  cosock_push(Co, ps, data, dsize);
  cosock_push(Co, ps, (const char*)&tail, sizeof(tail));
  co_traceinfo(Co, "coNet, id[%d], attaid[%d] push data, size[%u]\n", s->id, attas ? attas->id : 0, dsize);
  return 1;
}

static int coN_close(co* Co, int id, int attaid)
{
  coN* N = Co->N;
  cosock* s = NULL, *attas = NULL;
  int idx = 0, attaidx = 0;
  co_assert(id > 0 && attaid >= 0);
  co_assert(!(id == 0 && attaid == 0));
  idx = cosockid2idx_getidx(N->id2idx, id); co_assert(idx);
  s = cosockpool_getsock(N->po, idx); co_assert(s);
  co_assert(s->id == id); co_assert(s->poolidx == idx);
  if (attaid == 0)
  {
    co_assert(COSOCKFD_TCONN == s->fdt || COSOCKFD_TACCP == s->fdt);
    cosock_close(Co, s);
  }
  else
  {
    co_assert(COSOCKFD_TACCP == s->fdt);
    attaidx = cosockid2idx_getidx(s->id2idx, attaid); co_assert(attaidx);
    attas = cosockpool_getsock(s->attapo, attaidx); co_assert(attas);
    co_assert(attas->id == attaid); co_assert(attas->poolidx == attaidx);
    co_assert(COSOCKFD_TATTA == attas->fdt);
    cosock_close(Co, attas);
  }
  co_traceinfo(Co, "coNet, id[%d], attaid[%d] close!!\n", s->id, attas ? attas->id : 0);
  return 1;
}

static void coN_realclose(co* Co)
{
  int i = 0;
  coN* N = Co->N;
  cosock** ps = cosockpool_cosocks(N->closedpo);
  int cnt = cosockpool_cosockcnt(N->closedpo);
  for (i = 1; i < cnt; ++i)
  {
    cosock* s = ps[i];
    cosock* attaed2s = s->attaed2s;
    if (attaed2s)
    {
      co_assert(COSOCKFD_TATTA == s->fdt);
      co_traceinfo(Co, "coNet, attacher id[%d], attaid[%d] realclosed!!\n", attaed2s->id, s->id);
      cosockpool_del(Co, attaed2s->attapo, s);
      cosock_delete(Co, s);
    }
    else
    {
      co_assert(COSOCKFD_TACCP == s->fdt || COSOCKFD_TCONN == s->fdt);
      co_traceinfo(Co, "coNet, connector id[%d], attaid[%d] realclosed!!\n", s->id, 0);
      cosockpool_del(Co, N->po, s);
      cosock_delete(Co, s);
    }
  }
  cosockpool_clear(N->closedpo);
}

static void coN_eventconnect(co* Co, cosock* s, cosock* as, int extra)
{
  lua_State* L = coS_lua(Co);
  co_assert(!as);
  co_traceinfo(Co, "coNet, id[%d], connect event result[%d]\n", s->id, extra);
  lua_getglobal(L, "core");
  lua_getfield(L, -1, "onconnect");
  lua_pushvalue(L, -2);
  lua_pushnumber(L, s->id);
  lua_pushnumber(L, extra);
  if (LUA_OK != lua_pcall(L, 3, 0, 0))
  {
    co_traceerror(Co, "coNet id[%d] failed call onconnect, detail, %s\n", s->id, lua_tostring(L, -1));
    lua_pop(L, 2);
    return;
  }
  lua_pop(L, 1);
}

static void coN_eventaccept(co* Co, cosock* s, cosock* as, int extra)
{
  lua_State* L = coS_lua(Co);
  co_assert(as);
  co_traceinfo(Co, "coNet, id[%d], attaid[%d] accept event\n", s->id, as->id);
  co_traceerror(Co, "coScript, current stack count[%d]\n", lua_gettop(L));
  lua_getglobal(L, "core");
  lua_getfield(L, -1, "onaccept");
  lua_pushvalue(L, -2);
  lua_pushnumber(L, s->id);
  lua_pushnumber(L, as->id);
  lua_pushnumber(L, extra);
  if (LUA_OK != lua_pcall(L, 4, 0, 0))
  {
    co_traceerror(Co, "coNet id[%d], attaid[%d] failed call onaccept, detail, %s\n", s->id, as->id, lua_tostring(L, -1));
    lua_pop(L, 2);
    co_traceerror(Co, "coScript, current stack count[%d]\n", lua_gettop(L));
    return;
  }
  /* SHIT, why pop 3 ..... */
  lua_pop(L, 1);
  co_traceerror(Co, "coScript, current stack count[%d]\n", lua_gettop(L));
}

static void coN_eventprocesspack(co* Co, cosock* s, cosock* as, int extra)
{
  cosock* ps = NULL;
  lua_State* L = coS_lua(Co);
  const char* data = NULL;
  size_t datasize = 0, leftsize = 0, usesize = 0;
  cosockpack_hdr* hdr = NULL;
  cosockpack_tail* tail = NULL;
  int bclose = 0;
  co_traceinfo(Co, "coNet, id[%d], attaid[%d] try process pack\n", s->id, as ? as->id : 0);
  co_traceinfo(Co, "coScript, current stack count[%d]\n", lua_gettop(L));
  lua_getglobal(L, "core");
  if (as == NULL) { co_assert(s->fdt == COSOCKFD_TCONN); ps = s; }
  else { co_assert(s->fdt == COSOCKFD_TACCP && as->fdt == COSOCKFD_TATTA); ps = as; }
  /* Todo:hide low level data */
  data = cosockbuf_data(ps->revbuf);
  datasize = cosockbuf_datasize(ps->revbuf);
  leftsize = datasize;
  while (1)
  {
    if (leftsize < sizeof(cosockpack_hdr) + sizeof(cosockpack_tail)) break;
    hdr = (cosockpack_hdr*)data;
    if (hdr->flag != COSOCKPACK_HDR_FLAG || hdr->ver != COSOCKPACK_VERSION) { bclose = 1; break; }
    if (leftsize < sizeof(cosockpack_hdr) + sizeof(cosockpack_tail) + hdr->dsize) break;
    tail = (cosockpack_tail*)(data + sizeof(cosockpack_hdr) + hdr->dsize);
    if (tail->flag != COSOCKPACK_TAIL_FLAG) { bclose = 1; break; }
    co_traceinfo(Co, "coNet, id[%d], attaid[%d] processpack event, packsize[%u]\n", s->id, as ? as->id : 0, hdr->dsize);
    lua_getfield(L, -1, "onpack");
    lua_pushvalue(L, -2);
    lua_pushnumber(L, s->id);
    lua_pushnumber(L, as ? as->id : 0);
    lua_pushlstring(L, data + sizeof(cosockpack_hdr), hdr->dsize);
    lua_pushnumber(L, extra);
    if (LUA_OK != lua_pcall(L, 5, 0, 0))
    {
      co_traceerror(Co, "coNet id[%d], attaid[%d] failed call onpack, detail, %s\n", s->id, as ? as->id : 0, lua_tostring(L, -1));
      lua_pop(L, 1);
      co_traceinfo(Co, "coScript, current stack count[%d]\n", lua_gettop(L));
    }
    usesize += sizeof(cosockpack_hdr) + sizeof(cosockpack_tail) + hdr->dsize;
    data += sizeof(cosockpack_hdr) + sizeof(cosockpack_tail) + hdr->dsize;
    leftsize -= sizeof(cosockpack_hdr) + sizeof(cosockpack_tail) + hdr->dsize;
  }
  lua_pop(L, 1);
  if (usesize == datasize) { cosockbuf_clear(ps->revbuf); }
  else { co_assert(usesize < datasize); cosockbuf_lmove(ps->revbuf, usesize); }
  co_traceinfo(Co, "coNet, id[%d], attaid[%d] finish processpack, leftsize[%u]\n", s->id, as ? as->id : 0, co_cast(size_t, cosockbuf_datasize(ps->revbuf)));
  if (bclose)
  {
    cosock_close(Co, ps);
    cosock_eventclose(Co, s, as, extra);
    co_traceinfo(Co, "coNet, id[%d], attaid[%d] close while exception when processpack\n", s->id, as ? as->id : 0);
  }
  co_traceinfo(Co, "coScript, current stack count[%d]\n", lua_gettop(L));
}

static void coN_eventclose(co* Co, cosock* s, cosock* as, int extra)
{
  cosock* ps = NULL;
  lua_State* L = coS_lua(Co);
  co_traceinfo(Co, "coNet, id[%d], attaid[%d] close event\n", s->id, as ? as->id : 0);
  lua_getglobal(L, "core");
  lua_getfield(L, -1, "onclose");
  lua_pushvalue(L, -2);
  if (as == NULL) { co_assert(s->fdt == COSOCKFD_TCONN); ps = s; }
  else { co_assert(s->fdt == COSOCKFD_TACCP && as->fdt == COSOCKFD_TATTA); ps = as; }
  lua_pushnumber(L, s->id);
  lua_pushnumber(L, as ? as->id : 0);
  lua_pushnumber(L, extra);
  if (LUA_OK != lua_pcall(L, 4, 0, 0))
  {
    co_traceerror(Co, "coNet id[%d], attaid[%d] failed call onclose, detail, %s\n", s->id, as ? as->id : 0, lua_tostring(L, -1));
    lua_pop(L, 2);
    return;
  }
  lua_pop(L, 1);
}

static cosock* cosock_new(co* Co, cosockid2idx* i2i, cosockpool* closedpo, cosock* attached2s, cosockevent* eventer, int fdt)
{
  cosock* s = co_cast(cosock*, coM_newobj(Co, cosock));
  s->poolidx = 0;
  s->id = cosockid2idx_newid(i2i);
  s->fd = COSOCKFD_NULL;
  s->fdt = fdt;
  s->bactive = 0;
  s->bconnected = 0;
  s->bclosed = 0;
  s->attapo = NULL;
  s->revbuf = NULL;
  s->sndbuf = NULL;
  s->id2idx = i2i;
  s->closedpo = closedpo;
  s->attaed2s = attached2s;
  s->eventer = eventer;
  s->ec = 0;
  cosock_newfdt(Co, s);
  return s;
}

static int cosock_listen(co* Co, cosock* s, const char* addr, unsigned short port)
{
  struct sockaddr_in sin = { 0 };
  co_assert(COSOCKFD_TACCP == cosock_fdt(s));
  co_assert(addr);
  co_traceinfo(Co, "coNet id[%d], try listen at addr[%s], port[%d]\n", s->id, addr, (int)port);
  if (!cosock_newfd(Co, s))
  {
    co_traceerror(Co, "coNet id[%d], listen failed when newfd, ec[%d], ecs[%s]\n", s->id, cosock_ec(s), cosockfd_errstr(cosock_ec(s)));
    return 0;
  }
  sin.sin_family = PF_INET;
  sin.sin_addr.s_addr = addr ? inet_addr(addr) : htonl(INADDR_ANY);
  sin.sin_port = htons(port);
  if (bind(s->fd, (const struct sockaddr*)&sin, sizeof(sin)))
  {
    cosock_logec(s);
    co_traceerror(Co, "coNet id[%d], listen failed when bind, ec[%d], ecs[%s]\n", s->id, cosock_ec(s), cosockfd_errstr(cosock_ec(s)));
    return 0;
  }
  if (listen(s->fd, 5))
  {
    cosock_logec(s);
    co_traceerror(Co, "coNet id[%d] listen failed, ec[%d], ecs[%s]\n", s->id, cosock_ec(s), cosockfd_errstr(cosock_ec(s)));
    return 0;
  }
  co_traceinfo(Co, "coNet id[%d] listen succeed\n", s->id);
  return 1;
}

static int cosock_connect(co* Co, cosock* s, const char* addr, unsigned short port)
{
  struct sockaddr_in sin = { 0 };
  co_assert(addr);
  co_assert(COSOCKFD_TCONN == cosock_fdt(s));
  co_traceinfo(Co, "coNet id[%d], try connect to addr[%s], port[%d]\n", s->id, addr, (int)port);
  if (!cosock_newfd(Co, s))
  {
    co_traceerror(Co, "coNet id[%d], connect failed when newfd, ec[%d], ecs[%s]\n", s->id, cosock_ec(s), cosockfd_errstr(cosock_ec(s)));
    return 0;
  }
  sin.sin_family = PF_INET;
  sin.sin_addr.s_addr = inet_addr(addr);
  sin.sin_port = htons(port);
  if (connect(s->fd, (const struct sockaddr*)&sin, sizeof(sin)))
  {
    cosock_logec(s);
    if (COSOCKFD_EWOULDBLOCK == cosock_ec(s) ||
      COSOCKFD_EAGAIN == cosock_ec(s) ||
      COSOCKFD_EINPROGRESS == cosock_ec(s))
    {
      co_traceinfo(Co, "coNet id[%d], conneting in progress....\n", s->id);
      return 1;
    }
    else
    {
      co_traceinfo(Co, "coNet id[%d], connect failed, ec[%d], ecs[%s]\n", s->id, cosock_ec(s), cosockfd_errstr(cosock_ec(s)));
      return 0;
    }
  }
  else
  {
    /* success directly ? may be this true? */
    co_assert(0);
  }
  return 1;
}

static int cosock_accept(co* Co, cosock* s, cosock** psn)
{
  cosock* sn = NULL;
  cosockfd nfd;
  nfd = accept(s->fd, NULL, NULL);
  if (nfd == COSOCKFD_NULL)
  {
    cosock_logec(s);
    co_traceerror(Co, "coNet, id[%d] accept failed, ec[%d], ecs[%s]\n", s->id, s->ec, cosockfd_errstr(s->ec));
    return 0;
  }
  sn = cosock_new(Co, s->id2idx, s->closedpo, s, s->eventer, COSOCKFD_TATTA);
  if (!cosock_attachfd(Co, sn, nfd))
  {
    co_traceerror(Co, "coNet, id[%d], attaid[%d], accept failed while attachfd, ec[%d], ecs[%s]\n", s->id, sn->id, s->ec, cosockfd_errstr(s->ec));
    cosock_delete(Co, sn);
    return 0;
  }
  cosockpool_add(Co, s->attapo, sn);
  if (psn) { *psn = sn; }
  co_traceerror(Co, "coNet, id[%d], attaid[%d], accept success\n", s->id, sn->id);
  return 1;
}

/* 1: recved data,    0: closed gracely,   -1: closed exceptly */
static int cosock_recv(co* Co, cosock* s)
{
  int r = 0;
  char* buf = NULL;
  int buflen = 0;
  while (1)
  {
    if (cosockbuf_isfull(Co, s->revbuf, 1024))
    {
      co_traceerror(Co, "coNet, id[%d] buf is full while recv\n", s->id);
      return -1;
    }
    buf = cosockbuf_uudata(s->revbuf);
    buflen = (int)cosockbuf_uusize(s->revbuf);
    co_assert(buflen > 0);
    r = recv(s->fd, buf, buflen, 0);
    if (0 == r)
    {
      co_traceinfo(Co, "coNet, id[%d] closed while recv..\n", s->id);
      return 0;
    }
    if (COSOCKFD_ERROR == r)
    {
      cosock_logec(s);
      if (cosock_ec(s) == COSOCKFD_EWOULDBLOCK)
      {
        return 1;
      }
      co_traceerror(Co, "coNet, id[%d] ocurrs error while recv, ec[%d], ecs[%s]\n", s->id, s->ec, cosockfd_errstr(s->ec));
      return -1;
    }
    co_assert(r > 0);
    co_assert(r <= buflen);
    cosockbuf_use(Co, s->revbuf, (size_t)r);
    co_traceinfo(Co, "coNet, id[%d] recved data, dsize[%u]\n", s->id, co_cast(size_t, r));
  }
  return 1;
}

/* 1:sended data,    0:closed gracely,    -1:closed exceptly */
static int cosock_send(co* Co, cosock* s)
{
  int r = 0;
  const char* data = NULL;
  int datalen = 0;
  data = cosockbuf_data(s->sndbuf);
  datalen = co_cast(int, cosockbuf_datasize(s->sndbuf));
  if (datalen == 0) return 1;
  r = send(s->fd, data, datalen, 0);
  if (COSOCKFD_ERROR == r)
  {
    cosock_logec(s);
    if (cosock_ec(s) == COSOCKFD_EWOULDBLOCK)
    {
      co_traceinfo(Co, "coNet, id[%d] blocked while send\n", s->id);
    }
    else
    {
      co_traceerror(Co, "coNet, id[%d] ocurrs error while send, ec[%d], ecs[%s]\n", s->id, s->ec, cosockfd_errstr(s->ec));
      return -1;
    }
  }
  co_assert(r > 0);
  if (r == datalen)
  {
    cosockbuf_clear(s->sndbuf);
    co_traceinfo(Co, "coNet, id[%d] send succeed, leftsize[%u]\n", s->id, 0);
  }
  else
  {
    /* blocked! */
    co_assert(r > 0);
    co_assert(r < datalen);
    cosockbuf_lmove(s->sndbuf, (size_t)r);
    co_traceinfo(Co, "coNet, id[%d] blocked while send, leftsize[%u]\n", s->id, co_cast(size_t, cosockbuf_datasize(s->sndbuf)));
  }
  return 1;
}

static int cosock_canpush(co* Co, cosock* s, size_t datasize)
{
  if (cosockbuf_isfull(Co, s->sndbuf, datasize)) return 0;
  return 1;
}

static void cosock_push(co* Co, cosock* s, const char* data, size_t datasize)
{
  char* uudata = NULL;
  size_t uusize = 0;
  if (cosockbuf_isfull(Co, s->sndbuf, datasize)) { co_assertex(0, "cosockbuf is full, use canpush to check first"); }
  uudata = cosockbuf_uudata(s->sndbuf);
  uusize = cosockbuf_uusize(s->sndbuf);
  co_assert(uusize >= datasize);
  memcpy(uudata, data, datasize);
  cosockbuf_use(Co, s->sndbuf, datasize);
}

static int cosock_pop(co* Co, cosock* s, const char** pdata, size_t* pdatasize)
{
  const char* data;
  size_t datasize;
  cosockpack_hdr* hdr = NULL;
  cosockpack_tail* tail = NULL;
  size_t extrasize = sizeof(cosockpack_hdr) + sizeof(cosockpack_tail);
  data = cosockbuf_data(s->revbuf);
  datasize = cosockbuf_datasize(s->revbuf);
  if (datasize < extrasize) return 1;
  return 1;
}

static void cosock_active(co* Co, cosock* s)
{
  /*
  if (s->bclosed)
  {
    printf("cosock id=%d, already in close, don't active any more\n", s->id);
    return;
  }
  */
  co_assert(s->fdt == COSOCKFD_TCONN || s->fdt == COSOCKFD_TACCP);
  s->bactive = 1;
  if (COSOCKFD_TCONN == s->fdt)
  {cosock_activeconn(Co, s);}
  else if (COSOCKFD_TACCP == s->fdt)
  {cosock_activeaccp(Co, s);}
  else {co_assertex(0, "invalid cosock fdt");}
  s->bactive = 0;
}

static void cosock_close(co* Co, cosock* s)
{
  if (s->bclosed) return;
  cosockpool_addirect(Co, s->closedpo, s);
  s->bclosed = 1;
}

static void cosock_delete(co* Co, cosock* s)
{
  if (!s) return;
  co_assertex(!s->bactive, "delete in active is not allowed");
  cosock_deletefdt(Co, s);
  cosock_deletefd(Co, s);
  coM_deleteobj(Co, s);
}

static int cosock_newfd(co* Co, cosock* s)
{
  unsigned long v = 1;
  co_assert(s->fd == COSOCKFD_NULL);
  s->fd = socket(PF_INET, SOCK_STREAM, IPPROTO_TCP);
  if (s->fd == COSOCKFD_NULL) { cosock_logec(s); return 0; }
  if (cosockfd_ioctl(s->fd, FIONBIO, &v)) { cosock_logec(s); return 0; }
  return 1;
}

static int cosock_attachfd(co* Co, cosock* s, cosockfd fd)
{
  unsigned long v = 1;
  co_assert(s->fd == COSOCKFD_NULL);
  s->fd = fd;
  if (cosockfd_ioctl(s->fd, FIONBIO, &v)) { cosock_logec(s); return 0; }
  return 1;
}

static void cosock_newfdt(co* Co, cosock* s)
{
  co_assert(NULL == s->attapo);
  if (s->fdt == COSOCKFD_TACCP)
  {
    s->attapo = cosockpool_new(Co, COSOCK_ATTA_INITCNT, COSOCK_ATTA_STEPCNT, COSOCK_ATTA_LIMITCNT);
  }
  else
  {
    s->revbuf = cosockbuf_new(Co, COSOCKBUF_ALLCNT);
    s->sndbuf = cosockbuf_new(Co, COSOCKBUF_ALLCNT);
  }
}

static void cosock_deletefd(co* Co, cosock* s)
{
  if (COSOCKFD_NULL == s->fd) return;
  if (cosockfd_close(s->fd)){ cosock_logec(s); /* error ? */ }
}

static void cosock_deletefdt(co* Co, cosock* s)
{
  if (COSOCKFD_TACCP == s->fdt)
  {
    cosock** ps = NULL;
    int cnt = 0, i = 1;
    co_assert(!s->revbuf);
    co_assert(!s->sndbuf);
    co_assert(s->attapo);
    ps = cosockpool_cosocks(s->attapo);
    cnt = cosockpool_cosockcnt(s->attapo);
    while(cnt > 1)
    {
      cosock* ds = ps[1];
      cosockpool_del(Co, s->attapo, ds);
      cosock_delete(Co, ds);
      --cnt;
    }
    cosockpool_delete(Co, s->attapo);
    s->attapo = NULL;
  }
  else
  {
    co_assert(!s->attapo);
    co_assert(s->revbuf);
    co_assert(s->sndbuf);
    cosockbuf_delete(Co, s->revbuf);
    cosockbuf_delete(Co, s->sndbuf);
  }
}

static void cosock_activeaccp_common(co* Co, cosock* s)
{
  int r = 0;
  fd_set rfds, wfds, efds;
  struct timeval tv = { 0 };
  int cnt = 0, i = 0;
  cosock** ps = NULL;
  cosockfd maxfd;
  co_assert(COSOCKFD_TACCP == s->fdt);
  FD_ZERO(&rfds); FD_ZERO(&wfds); FD_ZERO(&efds);
  FD_SET(s->fd, &rfds); FD_SET(s->fd, &wfds); FD_SET(s->fd, &efds);
  maxfd = s->fd;
  ps = cosockpool_cosocks(s->attapo);
  cnt = cosockpool_cosockcnt(s->attapo);
  for (i = 1; i < cnt; ++i)
  {
    FD_SET(ps[i]->fd, &rfds); FD_SET(ps[i]->fd, &wfds); FD_SET(ps[i]->fd, &efds);
    maxfd = ps[i]->fd > maxfd ? ps[i]->fd : maxfd;
  }
  r = select(maxfd + 1, &rfds, &wfds, &efds, &tv);
  if (0 == r){cosock_logec(s); return;}
  if (COSOCKFD_ERROR == r)
  {
    cosock_logec(s);
    co_traceerror(Co, "coNet, id[%d] activeaccp failed while select, ec[%d], ecs[%s]\n", s->id, s->ec, cosockfd_errstr(s->ec));
    cosock_close(Co, s);
    cosock_eventclose(Co, s, NULL, 0);
    return;
  }
  co_assert(r >= 1);
  if (FD_ISSET(s->fd, &rfds))
  {
    cosock* ns = NULL;
    co_traceinfolv3(Co, "coNet, id[%d] is in readfds\n", s->id);
    if (!cosock_accept(Co, s, &ns)) { co_assert(!ns); }
    else { cosock_eventaccept(Co, s, ns, 1); }
  }
  if (FD_ISSET(s->fd, &wfds)){co_assertex(0, "acceptor has write event!!!!"); return;}
  if (FD_ISSET(s->fd, &efds)){co_assertex(0, "acceptor has except event!!!"); return;}

  for (i = 1; i < cnt; ++i)
  {
    cosock* as = ps[i];
    if (FD_ISSET(as->fd, &rfds))
    {
      co_traceinfolv3(Co, "coNet, id[%d] attaid[%d] is in readfds\n", s->id, as->id);
      r = cosock_recv(Co, as);
      if (0 == r)
      {
        /* close gracely, need process package first */
        cosock_close(Co, as);
        cosock_eventprocesspack(Co, s, as, 0);
        cosock_eventclose(Co, s, as, 0);
      }
      else if (-1 == r)
      {
        /* close exceptly */
        cosock_close(Co, as);
        cosock_eventprocesspack(Co, s, as, 0);
        cosock_eventclose(Co, s, as, 0);
      }
      else
      {
        /* recved data */
        co_assert(r == 1);
        cosock_eventprocesspack(Co, s, as, 0);
      }
    }
    if (FD_ISSET(as->fd, &wfds))
    {
      co_traceinfolv3(Co, "coNet, id[%d] attaid[%d] is in writefds\n", s->id, as->id);
      r = cosock_send(Co, as);
      if (0 == r)
      {
        cosock_close(Co, as);
        cosock_eventclose(Co, s, as, 0);
      }
      else if (-1 == r)
      {
        cosock_close(Co, as);
        cosock_eventclose(Co, s, as, 0);
      }
      else { co_assert(1 == r); }
    }
    if (FD_ISSET(as->fd, &efds))
    {
      co_traceinfolv3(Co, "coNet, id[%d] attaid[%d] is in exceptfds\n", s->id, as->id);
      cosock_close(Co, as);
      cosock_eventclose(Co, s, as, 0);
    }
  }
}

#if LOLICORE_PLAT == LOLICORE_PLAT_WIN32

static void cosock_activeconn_win32(co* Co, cosock* s)
{
  int r = 0;
  fd_set rfds, wfds, efds;
  struct timeval tv = { 0 };
  co_assert(COSOCKFD_TCONN == s->fdt);
  FD_ZERO(&rfds); FD_ZERO(&wfds); FD_ZERO(&efds);
  FD_SET(s->fd, &rfds); FD_SET(s->fd, &wfds); FD_SET(s->fd, &efds);
  r = select(0, &rfds, &wfds, &efds, &tv);
  if (0 == r){cosock_logec(s); return;}
  if (COSOCKFD_ERROR == r)
  {
    cosock_logec(s);
    cosock_close(Co, s);
    co_traceerror(Co, "coNet, id[%d] activeconnector failed while select, ec[%d], ecs[%s]\n", s->id, s->ec, cosockfd_errstr(s->ec));
    cosock_eventclose(Co, s, NULL, 0);
    return;
  }
  co_assert(r >= 1);
  if (FD_ISSET(s->fd, &rfds))
  {
    co_traceinfolv3(Co, "coNet, id[%d] is in readfds\n", s->id);
    r = cosock_recv(Co, s);
    if (0 == r)
    {
      /* closed gracely, process package first */
      cosock_close(Co, s);
      cosock_eventprocesspack(Co, s, NULL, 0);
      cosock_eventclose(Co, s, NULL, 0);
    }
    else if (-1 == r)
    {
      cosock_close(Co, s);
      cosock_eventprocesspack(Co, s, NULL, 0);
      cosock_eventclose(Co, s, NULL, 0);
    }
    else
    {
      co_assert(1 == r);
      cosock_eventprocesspack(Co, s, NULL, 0);
    }
    return;
  }
  if (FD_ISSET(s->fd, &wfds))
  {
    co_traceinfolv3(Co, "coNet, id[%d] is in writefds\n", s->id);
    if (s->bconnected)
    {
      r = cosock_send(Co, s);
      if (0 == r)
      {
        cosock_close(Co, s);
        cosock_eventclose(Co, s, NULL, 0);
      }
      else if (-1 == r)
      {
        cosock_close(Co, s);
        cosock_eventclose(Co, s, NULL, 0);
      }
      else
      {
        co_assert(1 == r);
      }
      return;
    }
    else
    {
      s->bconnected = 1;
      cosock_eventconnect(Co, s, NULL, 1);
      return;
    }
  }
  if (FD_ISSET(s->fd, &efds))
  {
    co_traceerror(Co, "coNet, id[%d] is in exceptfds\n", s->id);
    cosock_close(Co, s);
    if (s->bconnected)
    {
      /* just close it as an exception */
      cosock_eventclose(Co, s, NULL, 0);
      return;
    }
    else
    {
      cosock_eventconnect(Co, s, NULL, 0);
      return;
    }
  }
}

#else

static void cosock_activeconn_ux(co* Co, cosock* s)
{
  int r = 0;
  fd_set rfds, wfds, efds;
  struct timeval tv = { 0 };
  co_assert(COSOCKFD_TCONN == s->fdt);
  FD_ZERO(&rfds); FD_ZERO(&wfds); FD_ZERO(&efds);
  FD_SET(s->fd, &rfds); FD_SET(s->fd, &wfds); FD_SET(s->fd, &efds);
  r = select(s->fd + 1, &rfds, &wfds, &efds, &tv);
  if (0 == r){cosock_logec(s); return;}
  if (COSOCKFD_ERROR == r)
  {
    cosock_logec(s);
    cosock_close(Co, s);
    co_traceerror(Co, "coNet, id[%d] activeconnector failed while select, ec[%d], ecs[%s]\n", s->id, s->ec, cosockfd_errstr(s->ec));
    cosock_eventclose(Co, s, NULL, 0);
    return;
  }
  co_assert(r >= 1);
  if (FD_ISSET(s->fd, &rfds))
  {
    co_traceinfolv2(Co, "coNet, id[%d] is in readfds\n", s->id);
    if (FD_ISSET(s->fd, &wfds))
    {
      struct sockaddr_in sin;
      int sinsize = sizeof(sin);
      co_traceinfolv2(Co, "coNet, id[%d] is also in writefds\n", s->id);
      if (0 != getpeername(s->fd, (struct sockaddr*)&sin, &sinsize))
      {
        /* connect failed */
        cosock_logec(s);
        cosock_close(Co, s);
        if (s->ec == COSOCKFD_ENOTCONN)
        {
          co_traceinfolv2(Co, "coNet, id[%d] is connect failed\n", s->id);
          cosock_eventconnect(Co, s, NULL, 0);
        }
        else
        {
          co_traceinfolv2(Co, "coNet, id[%d] is detected fatal error while getpeername, ec[%d], ecs[%s]\n", s->id, s->ec, cosockfd_errstr(s->ec));
          cosock_eventclose(Co, s, NULL, 0);
        }
        return;
      }
    }
    r = cosock_recv(Co, s);
    if (0 == r)
    {
      /* closed gracely, process package first */
      cosock_close(Co, s);
      cosock_eventprocesspack(Co, s, NULL, 0);
      cosock_eventclose(Co, s, NULL, 0);
    }
    else if (-1 == r)
    {
      cosock_close(Co, s);
      cosock_eventprocesspack(Co, s, NULL, 0);
      cosock_eventclose(Co, s, NULL, 0);
    }
    else
    {
      co_assert(1 == r);
      cosock_eventprocesspack(Co, s, NULL, 0);
    }
    return;
  }
  if (FD_ISSET(s->fd, &wfds))
  {
    co_traceinfolv3(Co, "coNet, id[%d] is in writefds\n", s->id);
    if (s->bconnected)
    {
      r = cosock_send(Co, s);
      if (0 == r)
      {
        cosock_close(Co, s);
        cosock_eventclose(Co, s, NULL, 0);
      }
      else if (-1 == r)
      {
        cosock_close(Co, s);
        cosock_eventclose(Co, s, NULL, 0);
      }
      else
      {
        co_assert(1 == r);
      }
      return;
    }
    else
    {
      co_traceinfolv2(Co, "coNet, id[%d], connect succeed\n", s->id);
      s->bconnected = 1;
      cosock_eventconnect(Co, s, NULL, 1);
    }
  }
  if (FD_ISSET(s->fd, &efds))
  {
    co_traceerror(Co, "coNet, id[%d] is in exceptfds\n", s->id);
    cosock_close(Co, s);
    cosock_eventclose(Co, s, NULL, 0);
  }
}

#endif

int coN_export_register(lua_State* L)
{
  return 0;
}

int coN_export_connect(lua_State* L)
{
  int id = 0;
  co* Co = NULL;
  const char* addr = NULL;
  unsigned short port = 0;
  lua_getallocf(L, (void**)&Co);
  co_assert(Co);
  addr = luaL_checkstring(L, 1);
  port = (unsigned short)luaL_checkint(L, 2);
  id = coN_connect(Co, addr, port);
  if (!id)
  {
    return 0;
  }
  lua_pushnumber(L, id);
  return 1;
}

int coN_export_listen(lua_State* L)
{
  int id = 0;
  co* Co = NULL;
  const char* addr = NULL;
  unsigned short port = 0;
  lua_getallocf(L, (void**)&Co);
  co_assert(Co);
  addr = luaL_checkstring(L, 1);
  port = (unsigned short)luaL_checkint(L, 2);
  id = coN_listen(Co, addr, port);
  if (!id)
  {
    return 0;
  }
  lua_pushnumber(L, id);
  return 1;
}

int coN_export_push(lua_State* L)
{
  co* Co = NULL;
  int id = 0, attaid = 0;
  const char* data = NULL;
  size_t datasize = 0;
  lua_getallocf(L, (void**)&Co); co_assert(Co);
  id = luaL_checkint(L, 1);
  attaid = luaL_checkint(L, 2);
  data = luaL_checklstring(L, 3, &datasize);
  co_assert(data);
  if (!coN_push(Co, id, attaid, data, datasize))
  {
    return 0;
  }
  lua_pushnumber(L, 1);
  return 1;
}

int coN_export_close(lua_State* L)
{
  co* Co = NULL;
  int id = 0, attaid = 0;
  lua_getallocf(L, (void**)&Co); co_assert(Co);
  id = luaL_checkint(L, 1);
  attaid = luaL_checkint(L, 2);
  if (!coN_close(Co, id, attaid))
  {
    return 0;
  }
  lua_pushnumber(L, 1);
  return 1;
}
