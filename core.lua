local component = require("component")

local module = {}

-- collect connected components
function module.collect_components()
  local components = {}
  for address, name in component.list() do
    local component_info = {}
    local methods = {}
    local proxy = component.proxy(address)

    for name, member in pairs(proxy) do
      if type(member) == "table" or type(member) == "function" then
        methods[name] = component.doc(address, name)
      end
    end

    component_info['name'] = name
    component_info['type'] = component.type(address)
    component_info['methods'] = methods
    component_info['open'] = function() return component.proxy(address) end

    components[address] = component_info
  end
  return components
end

-- logging
function module.log_info(text, ...)
  print(text, args)
end

-- logging
function module.log_error(text, ...)
  print(text, args)
end


return module