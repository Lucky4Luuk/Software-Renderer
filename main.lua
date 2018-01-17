local mesh = require "mesh"
local utils = require "utils"

local objects = {}

local timestep = 1/60
local total_time = 0

function love.load()
  mesh.camera_position = mesh.vec3(0,0,0)
  local o = mesh.obj("cube.obj", "cube", mesh.vec3(0,0,5), mesh.vec3(0,45,0))
  table.insert(objects, o)
end

function FixedUpdate()
  for i=1, #objects do
    objects[i]:rotate(45*timestep,45*timestep,45*timestep)
  end
end

function love.update(dt)
  total_time = total_time + dt
  while total_time > timestep do
    FixedUpdate()
    total_time = total_time - timestep
  end
end

function love.draw()
  for i=1, #objects do
    objects[i]:draw()
  end
end
