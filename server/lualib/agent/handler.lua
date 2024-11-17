local handler = {
	object = {},
}
local mt = { __index = handler }

function handler.new (name, request, response, cmd)
	return setmetatable ({
		name = name,
		init_func = {},
		REQUEST = request,
		RESPONSE = response,
		CMD = cmd,
	}, mt)
end

function handler:init (f)
	table.insert (self.init_func, f)
end

function handler:register (user, ext_handlers)
	for _, f in pairs (self.init_func) do
		f (user)
	end

	ext_handlers[self.name] = self
end

function handler:unregister (user, ext_handlers)
	ext_handlers[self.name] = nil
end

return handler
