local skynet = require "skynet"
local log = require "log"

local service = {}

function service.init(mod)
	local handler = mod.command
	local ext_handlers = mod.ext_handlers
	if mod.info then
		skynet.info_func(function()
			return mod.info
		end)
	end
	skynet.start(function()
		if mod.require then
			local s = mod.require
			for _, name in ipairs(s) do
				service[name] = skynet.uniqueservice(name)
			end
		end
		if mod.init then
			mod.init()
		end
		skynet.dispatch("lua", function (_,_, cmd, ...)
			local f = nil
			if ext_handlers then
				for _, ext_handler in pairs(ext_handlers) do
					f = ext_handler and ext_handler.CMD and ext_handler.CMD[cmd] or ext_handler[cmd]
					if f ~= nil then
						break
					end
				end
			end
			if f == nil then
				f = handler[cmd]
			end
			if f then
				skynet.ret(skynet.pack(f(...)))
			else
				log("Unknown command : [%s]", cmd)
				skynet.response()(false)
			end
		end)
	end)
end

return service
