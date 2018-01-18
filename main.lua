local mesh = require "mesh"
local utils = require "utils"

local objects = {}
local lights = {}

local canvas = nil

local timestep = 1/60
local total_time = 0

function love.load()
  -- canvas = love.graphics.newCanvas(128,72)
  mesh.camera_position = mesh.vec3(0,0,-10)
  local o = mesh.obj("cube.obj", "cube", mesh.vec3(0,0,5), mesh.vec3(0,45,0))
  table.insert(objects, o)
  o = mesh.obj("plane.obj", "plane", mesh.vec3(0,-1,5), mesh.vec3(0,0,0))
  table.insert(objects, o)
end

function FixedUpdate()
  if love.keyboard.isDown("e") then
    mesh.camera_position = mesh.camera_position - mesh.vec3(0,2*timestep,0)
  elseif love.keyboard.isDown("q") then
    mesh.camera_position = mesh.camera_position + mesh.vec3(0,2*timestep,0)
  end
  for i=1, #objects do
    if objects[i].name == "cube" then
      objects[i]:rotate(45*timestep,45*timestep,0)
    end
  end
  -- for i=1, #lights do
  --   lights[i]:rotate(45*timestep,45*timestep,0)
  -- end
end

function love.update(dt)
  total_time = total_time + dt
  while total_time > timestep do
    FixedUpdate()
    total_time = total_time - timestep
  end
end

function love.draw()
  mesh.clear()

  for i=1, #objects do
    objects[i]:draw_untextured()
  end

  -- for i=1, #lights do
  --   lights[i]:render()
  -- end

  mesh.render()
end
