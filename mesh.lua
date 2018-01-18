local utils = require "utils"
local cpml = require "cpml"

local major, minor, revision, codename = love.getVersion()

local depth_shader = love.graphics.newShader("mesh_lib/shaders/depth_shader.glsl")
local depth_tex = love.graphics.newCanvas(love.graphics.getWidth(), love.graphics.getHeight())

local lib = {camera_position = cpml.vec3(0,0,0), camera_direction = cpml.vec3(0,0,1), mode="normal", outline=true, show_normals=false, render_canvas=nil, post_shader=nil, font=love.graphics.newFont(12)}

local l_dir = cpml.vec3(-1,-1,1):normalize()

local faces = {}
local lights = {}

local mesh = {}
mesh.__index = mesh

function lib.setColor(r,g,b,a)
  if minor >= 11 then
    love.graphics.setColor(r,g,b, a or 1)
  else
    love.graphics.setColor(r*255, g*255, b*255, (a or 1) * 255)
  end
end

function lib.polygon(mode, points, z_points)
  --Depth Check
  love.graphics.setShader(depth_shader)
  depth_shader:send("depth_tex",depth_tex)
  for i=1, #z_points do
    depth_shader:send("z_points["..tostring(i-1).."]", z_points[i])
  end
  depth_shader:send("z_point_length", #z_points-1)
  love.graphics.polygon(mode, points)
  love.graphics.setShader()

  --Depth Write
  love.graphics.setShader(depth_shader)
  love.graphics.setCanvas(depth_tex)
  for i=1, #z_points do
    depth_shader:send("z_points["..tostring(i-1).."]", z_points[i])
  end
  depth_shader:send("z_point_length", #z_points-1)
  love.graphics.polygon(mode, points)
  love.graphics.setCanvas()
  love.graphics.setShader()
end

function lib.vec3(x,y,z)
  return cpml.vec3(x,y,z)
end

local function loadObj(filename)
  local vertices = {}
  local faces = {}
  local normals = {}
  local uvs = {}

  for line in io.lines(filename) do
    if utils.string_starts(line, "v ") then
      local data = line:sub(3, #line)
      local t_data = utils.string_split(data, " ")
      local x = tonumber(t_data[1])
      local y = tonumber(t_data[2])
      local z = tonumber(t_data[3])
      table.insert(vertices, lib.vec3(x,y,z))
    elseif utils.string_starts(line, "f ") then
      local data = line:sub(3, #line)
      local t_data = utils.string_split(data, " ")
      local face_data = {}
      for i=1, #t_data do
        if string.find(t_data[i], "//") then
          local v = utils.string_split(t_data[i],"//")
          table.insert(face_data, {v=tonumber(v[1]),uv=-1,n=tonumber(v[2])})
        else
          local v = utils.string_split(t_data[i],"/")
          table.insert(face_data, {v=tonumber(v[1]),uv=tonumber(v[2]),n=tonumber(v[3])})
        end
      end
      table.insert(faces, face_data)
    elseif utils.string_starts(line, "vt ") then
      local data = line:sub(4, #line)
      table.insert(uvs, {x=tonumber(data[1]), y=tonumber(data[2])})
    elseif utils.string_starts(line, "vn ") then
      local data = line:sub(4, #line)
      local t_data = utils.string_split(data, " ")
      table.insert(normals, lib.vec3(tonumber(t_data[1]), tonumber(t_data[2]), tonumber(t_data[3])))
    end
  end

  return vertices, faces, normals, uvs
end

function mesh:new(name, uuid, pos, rot, vertices, faces, normals, uvs)
  local m = {}
  setmetatable(m, mesh)
  m.name = name
  m.uuid = uuid
  m.pos = pos
  m.rot = rot
  m.vertices = vertices
  m.faces = faces
  m.normals = normals
  m.uvs = uvs
  return m
end

function lib.getWidth()
  if lib.render_canvas then
    return lib.render_canvas:getWidth()
  end
  return love.graphics.getWidth()
end

function lib.getHeight()
  if lib.render_canvas then
    return lib.render_canvas:getHeight()
  end
  return love.graphics.getHeight()
end

function lib.clear()
  faces = {}
end

function lib.render()
  table.sort(faces, sort_faces)
  for i=1, #faces do
    local points = {}
    for j=1, #faces[i].vertices do
      local x,y,z = faces[i].vertices[j]:unpack()
      local sx = x / z + lib.getWidth()/2
      local sy = y / z + lib.getHeight()/2
      table.insert(points, sx)
      table.insert(points, sy)
    end
    if #points > 5 then
      lib.setColor(1,1,1)
      love.graphics.polygon("fill",points)
      if lib.outline then
        lib.setColor(0,0,0)
        love.graphics.polygon("line",points)
      end
    end
  end
end

function mesh:draw_untextured()
  for i=1, #self.faces do
    local face = {vertices={},center=lib.vec3(0,0,0)}
    local center = lib.vec3(0,0,0)
    for jr=0, #self.faces[i] do
      local j = jr
      if jr == 0 then
        j = #self.faces[i]
      end
      local data = self.faces[i][j]
      local v = data.v
      local pos = self.vertices[v]:rotate(math.rad(self.rot.x), cpml.vec3.unit_x):rotate(math.rad(self.rot.z), cpml.vec3.unit_z):rotate(math.rad(self.rot.y), cpml.vec3.unit_y) + self.pos - lib.camera_position
      center = center + pos
      local x,y,z = pos:unpack()
      if z > 0 then
        x = x * 50
        y = y * 50
        z = z / 5
        table.insert(face.vertices,lib.vec3(x,y,z))
      -- else
      --   local nv = v - 1
      --   if v == 1 then nv = #self.faces[i] end
      --   local prev_vert = self.vertices[nv]:rotate(math.rad(self.rot.x), cpml.vec3.unit_x):rotate(math.rad(self.rot.z), cpml.vec3.unit_z):rotate(math.rad(self.rot.y), cpml.vec3.unit_y) + self.pos - lib.camera_position
      --   local dir = (prev_vert - pos):normalize()
      --   local dist = -z-0.01
      --   local new_pos = pos - dir:mul(lib.vec3(dist,dist,dist))
      --   x,y,z = new_pos:unpack()
      --   x = x * 50
      --   y = y * 50
      --   z = z / 5
      --   table.insert(face.vertices,lib.vec3(x,y,z))
      end
    end
    face.center = center:div(lib.vec3(#self.faces[i], #self.faces[i], #self.faces[i]))
    table.insert(faces, face)
  end
end

function mesh:draw_wireframe_direct()
  for i=1, #self.faces do
    local points = {}
    for jr=0, #self.faces[i] do
      local j = jr
      if jr == 0 then
        j = #self.faces[i]
      end
      local data = self.faces[i][j]
      local v = data.v
      local pos = self.vertices[v]:rotate(math.rad(self.rot.x), cpml.vec3.unit_x):rotate(math.rad(self.rot.z), cpml.vec3.unit_z):rotate(math.rad(self.rot.y), cpml.vec3.unit_y) + self.pos - lib.camera_position
      local x,y,z = pos:unpack()
      if z > 0 then
        x = x * 50
        y = y * 50
        z = z / 5
        local sx = x / z + lib.getWidth()/2
        local sy = y / z + lib.getHeight()/2
        table.insert(points, sx)
        table.insert(points, sy)
      end
    end
    if #points > 3 then
      love.graphics.line(points)
    end
  end
end

function sort_faces(a, b)
  local ax,ay,az = a.center:unpack()
  local bx,by,bz = b.center:unpack()
  return az > bz
end

function mesh:draw_untextured_direct()
  local faces = {}
  for i=1, #self.faces do
    local center = lib.vec3(0,0,0)
    for jr=0, #self.faces[i] do
      local j = jr
      if jr == 0 then
        j = #self.faces[i]
      end
      local data = self.faces[i][j]
      local v = data.v
      local pos = self.vertices[v]:rotate(math.rad(self.rot.x), cpml.vec3.unit_x):rotate(math.rad(self.rot.z), cpml.vec3.unit_z):rotate(math.rad(self.rot.y), cpml.vec3.unit_y) + self.pos - lib.camera_position
      center = center + pos
    end
    center = center:div(lib.vec3(#self.faces[i], #self.faces[i], #self.faces[i]))
    local f = self.faces[i]
    f.center = center
    table.insert(faces, f)
  end
  table.sort(faces, sort_faces)
  for i=1, #faces do
    local points = {}
    local n = faces[i][1].n
    local f_nor = self.normals[n]:rotate(math.rad(self.rot.x), cpml.vec3_unit_x):rotate(math.rad(self.rot.z), cpml.vec3.unit_z):rotate(math.rad(self.rot.y), cpml.vec3.unit_y)
    for jr=0, #faces[i] do
      local j = jr
      if jr == 0 then
        j = #faces[i]
      end
      local data = faces[i][j]
      local v = data.v
      local pos = self.vertices[v]:rotate(math.rad(self.rot.x), cpml.vec3.unit_x):rotate(math.rad(self.rot.z), cpml.vec3.unit_z):rotate(math.rad(self.rot.y), cpml.vec3.unit_y) + self.pos - lib.camera_position

      local x,y,z = pos:unpack()
      if z > 0 then
        x = x * 50
        y = y * 50
        z = z / 5
        local sx = x / z + lib.getWidth()/2
        local sy = y / z + lib.getHeight()/2
        table.insert(points, sx)
        table.insert(points, sy)
      end
    end
    f_nor = f_nor:normalize()
    local nx,ny,nz = f_nor:unpack()
    local dif = f_nor:dot(l_dir)
    -- print(tostring(f_nor))
    if #points > 3 then -- and lib.camera_direction:normalize():dot(f_nor) < 0.5 and nz <= 0
      lib.setColor(dif,1,1)
      love.graphics.polygon("fill",points)
      if lib.mode == "normal" and lib.outline then
        lib.setColor(0,0,0)
        love.graphics.polygon("line",points)
      end
    end
    -- Draw normal lines
    if lib.show_normals then
      local n = self.normals[n] + faces[i].center + self.pos
      local fp = faces[i].center + self.pos
      n = n:rotate(math.rad(self.rot.x), cpml.vec3_unit_x):rotate(math.rad(self.rot.z), cpml.vec3.unit_z):rotate(math.rad(self.rot.y), cpml.vec3.unit_y)
      n = n - lib.camera_position
      fp = fp:rotate(math.rad(self.rot.x), cpml.vec3_unit_x):rotate(math.rad(self.rot.z), cpml.vec3.unit_z):rotate(math.rad(self.rot.y), cpml.vec3.unit_y)
      fp = fp - lib.camera_position
      local nxm,nym,nzm = n:unpack()
      nxm = nxm * 50
      nym = nym * 50
      nzm = nzm / 5
      local fpx,fpy,fpz = fp:unpack(0)
      if nzm > 0 and fpz > 0 then
        local sx1 = nxm / nzm + lib.getWidth()/2
        local sy1 = nym / nzm + lib.getHeight()/2
        local sx2 = fpx / fpz + lib.getWidth()/2
        local sy2 = fpy / fpz + lib.getHeight()/2
        lib.setColor(1,0,0)
        love.graphics.line(sx1,sy1,sx2,sy2)
      end
    end
  end
end

function mesh:rotate(x,y,z)
  self.rot.x = (self.rot.x + x) % 360
  self.rot.y = (self.rot.y + y) % 360
  self.rot.z = (self.rot.z + z) % 360
end

function lib.start_mode(m, c)
  if m == "ascii" then
    lib.mode = "ascii"
    lib.render_canvas = c or love.graphics.newCanvas(love.graphics.getWidth(), love.graphics.getHeight())
    lib.post_shader = love.graphics.newShader("mesh_lib/shaders/post/blackwhite.glsl")
  end

  if lib.render_canvas then
    love.graphics.setCanvas(lib.render_canvas)
  end
  if lib.post_shader then
    love.graphics.setShader(lib.post_shader)
  end
end

function getColChar(r)
  local fr = r
  if minor == 11 then
    fr = r * 255
  end
  if fr < 50 then
    return " "
  elseif fr < 100 then
    return "."
  elseif fr < 150 then
    return "-"
  elseif fr < 200 then
    return ":"
  end
  return "="
end

function lib.end_mode()
  love.graphics.setCanvas()
  love.graphics.setShader()
  local c = lib.render_canvas
  if lib.mode == "ascii" then
    lib.setColor(1,1,1)
    c = love.graphics.newCanvas(lib.render_canvas:getWidth() * lib.font:getWidth("w"), lib.render_canvas:getHeight() * lib.font:getHeight())
    local imgdata = lib.render_canvas:newImageData()
    love.graphics.setCanvas(c)
    local dy = 0
    for y=0, imgdata:getHeight()-1 do
      local str = ""
      for x=0, imgdata:getWidth()-1 do
        local r = imgdata:getPixel(x, y)
        str = str .. getColChar(r)
      end
      love.graphics.print(str, 0, dy)
      dy = dy + lib.font:getHeight()
    end
    love.graphics.setCanvas()
  end
  lib.mode = "normal"
  lib.render_canvas = nil
  return c
end

function lib.obj(filename, objectname, pos, rot)
  local vertices, faces, normals, uvs = loadObj(filename)
  local uuid = utils.uuid()
  local rx,ry,rz = rot:unpack()
  local r = {x=rx,y=ry,z=rz}
  return mesh:new(objectname, uuid, pos:mul(lib.vec3(0,-1,0)), r, vertices, faces, normals, uvs)
end

return lib
