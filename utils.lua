local lib = {}

math.randomseed(os.clock()+os.time())
local random = math.random
function lib.uuid()
    local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function (c)
        local v = (c == 'x') and random(0, 0xf) or random(8, 0xb)
        return string.format('%x', v)
    end)
end

function lib.string_starts(String,Start)
   return string.sub(String,1,string.len(Start))==Start
end

function lib.string_ends(String,End)
   return End=='' or string.sub(String,-string.len(End))==End
end

function lib.string_split(string,sep)
   local sep, fields = sep or ":", {}
   local pattern = string.format("([^%s]+)", sep)
   string:gsub(pattern, function(c) fields[#fields+1] = c end)
   return fields
end

return lib
