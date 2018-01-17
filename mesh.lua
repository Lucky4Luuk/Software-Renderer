local utils = require "utils"
local cpml = require "cpml"

local lib = {camera_position = cpml.vec3(x,y,z)}

local mesh = {}
mesh.__index = mesh

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
      table.insert(normals, {x=tonumber(data[1]), y=tonumber(data[2]), z=tonumber(data[3])})
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

function mesh:draw()
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
        local sx = x / z + love.graphics.getWidth()/2
        local sy = y / z + love.graphics.getHeight()/2
        table.insert(points, sx)
        table.insert(points, sy)
      end
    end
    if #points > 3 then
      love.graphics.line(points)
    end
  end
end

function mesh:rotate(x,y,z)
  self.rot.x = (self.rot.x + x) % 360
  self.rot.y = (self.rot.y + y) % 360
  self.rot.z = (self.rot.z + z) % 360
end

function lib.obj(filename, objectname, pos, rot)
  local vertices, faces, normals, uvs = loadObj(filename)
  local uuid = utils.uuid()
  local rx,ry,rz = rot:unpack()
  local r = {x=rx,y=ry,z=rz}
  return mesh:new(objectname, uuid, pos, r, vertices, faces, normals, uvs)
end

return lib
