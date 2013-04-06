local avatar_demo = core.avatar

function avatar_demo:image()
  print(string.format("mem:%u/%u", core.api.base.getmem()))
  core.image:register(16, self.image, self)
end

function avatar_demo:imageclose()
  print("imagination close")
  debug.debug()
  core.api.base.kill()
end

function avatar_demo:born()
  self.activecnt = 0
  self.idaccp = 0
  local t1sec = core.image:gettime()
  print(t1sec)

  local umem, maxmem = core.api.base.getmem()
  core.api.base.setmaxmem(maxmem)
  print(string.format("%d/%d", umem, maxmem))
  self.memtb = {}

  local cwd = assert(core.api.os.getcwd())
  print(string.format("Current Working Dir:%s", cwd))
  if core.api.os.ispath("avatar") then
    print("avatar is a path")
  else
    print("avatar is not a path")
  end

  if core.api.os.mkdir("avatar") then
    print("mkdir avatar succeed")
  end

  if core.api.os.isfile("avatar") then
    print("avatar is a file!")
  else
    print("avatar is not a file!")
  end

  if core.api.os.isdir("avatar") then
    print("avatar is a dir")
  else
    print("avatar si not a dir")
  end

  core.image:register(16, self.image, self)
  core.image:register(3200, self.imageclose, self)
  local imaid = core.image:register(64, self.image, self)
  core.image:unregister(imaid)
  for i = 1, 1 do
    local idaccp = core.net:listen("127.0.0.1", 7000 + i)
    self.idaccp = idaccp
  end

  for i = 1, 1 do
    local idconn = core.net:connect("127.0.0.1", 7000 + i)
    for ii = 1, 2 do
      local tb = {a = 1, b = 2, c = 3, fuck = "shit", shit = "fuck"}
      if core.api.net.push(idconn, 0, "print('helloworld')") then
        --print("push data successed")
      else
        --print("push data failed")
      end
      core.api.net.push(idconn, 0, "local a = 1")
      core.net:pushtb(idconn, 0, tb)
    end
  end
  local t2sec = core.image:gettime()
  print(t2sec)
  local telapse = t2sec - t1sec
  print(telapse)
  print("avatar_demo born")
end

function avatar_demo:active()
  if self.activecnt > 3 then
    if self.idaccp > 0 then
      core.net:close(self.idaccp, 0)
      self.idaccp = 0
    end
  end
  self.activecnt = self.activecnt + 1
end

function avatar_demo:die()
  print("avatar_demo die")
end

function avatar_demo:onconnect(id, extra)
  print("avatar_demo onconnect", id, extra)
end

function avatar_demo:onaccept(id, attaid, extra)
  print("avatar_demo onaccept", id, attaid, extra)
  core.net:pushtb(id, attaid, {})
end

function avatar_demo:onpack(id, attaid, tbdata, extra)
  print("avatar_demo onpack", id, attaid, tbdata, extra)
end

function avatar_demo:onclose(id, attaid, extra)
  print("avatar_demo onclose", id, attaid, extra)
end
