--
--LoliCore Imagination
--Chamz Lau, Copyright (C) 2013-2017
--2013/03/16 22:12:23
--

core.image = {}
local image = core.image

function image:gettime()
  return core.api.os.gettime()
end

function image:register(imagecnt, fn, fnparam)
  local id = self.nextid
  local ima = {}
  ima.id = id
  ima.ima = self.imagecnt + imagecnt
  ima.fn = fn
  ima.fnparam = fnparam
  ima.bclose = 0
  self.images[id] = ima
  self.nextid = self.nextid + 1
  return id
end

function image:unregister(id)
  local ima = self.images[id]
  assert(ima, "invalid image id" .. id)
  assert(ima.bclose == 0, "already closed image, id " .. id)
  ima.bclose = 1
  table.insert(self.closeimages, ima)
end

function image:born()
  self.lasttime = core.api.os.gettime()
  self.imagecnt = 0
  self.nextid = 1
  self.images = {}
  self.closeimages = {}
end

function image:active()
  local curtime = core.api.os.gettime()
  local elapse = curtime - self.lasttime
  if elapse > 1 / 16 then
    self.imagecnt = self.imagecnt + 1
    self.lasttime = curtime
  end

  if #self.closeimages > 0 then
    for _, v in ipairs(self.closeimages) do
      self.images[v.id] = nil
    end
    self.closeimages = {}
  end

  for k, v in pairs(self.images) do
    if self.imagecnt >= v.ima and v.bclose == 0 then
      --Todo:pcall ?
      v.fn(v.fnparam, v)
      v.bclose = 1
      table.insert(self.closeimages, v)
    end
  end
end

function image:die()
end