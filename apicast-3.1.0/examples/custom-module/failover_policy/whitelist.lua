-- whitelist.lua
function Set (list)
  local set = {}
  for _, l in ipairs(list) do set[l] = true end
  return set
end
 
-------------------------------------------------------
-- Whitelist with the applications identified by app_id
-- that should be allowed to go through in case 3scale
-- is not reachable
-------------------------------------------------------
 
local whitelist = Set{
  'b7eea392'
}
 
-------------------------------------------------------
 
return whitelist