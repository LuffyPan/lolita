print("avatar_demo.lua")

avatar.activecnt = 0
avatar.idaccp = 0
function avatar.born()
  for i = 1, 1 do
    local idaccp = core.api.net.listen("127.0.0.1", 7000 + i)
    avatar.idaccp = idaccp
  end

  for i = 1, 1 do
    local idconn = core.api.net.connect("127.0.0.1", 7000 + i)
    for ii = 1, 2 do
      local tb = {a = 1, b = 2, c = 3, fuck = "shit", shit = "fuck"}
      if core.api.net.push(idconn, 0, "print('helloworld')") then
        --print("push data successed")
      else
        --print("push data failed")
      end
      core.api.net.push(idconn, 0, "local a = 1")
      core.api.net.pushtb(idconn, 0, tb)
    end
  end
  print("avatar.born")
end

function avatar.active()
  --print("avatar.active")
  if avatar.activecnt > 3 then
    if avatar.idaccp > 0 then
      core.api.net.close(avatar.idaccp, 0)
      avatar.idaccp = 0
    end
  end
  avatar.activecnt = avatar.activecnt + 1
end

function avatar.die()
  print("avatar.die")
end

function avatar.onconnect(id, extra)
  print("avatar onconnect", id, extra)
end

function avatar.onaccept(id, attaid, extra)
  print("avatar onaccept", id, attaid, extra)
  core.api.net.pushtb(id, attaid, {})
end

function avatar.onpack(id, attaid, tbdata, extra)
  print("avatar onpack", id, attaid, tbdata, extra)
end

function avatar.onclose(id, attaid, extra)
  print("avatar onclose", id, attaid, extra)
end
