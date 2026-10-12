local client_socket = require "client.socket"

local socket = {}
local fd
local message

socket.error = setmetatable({}, { __tostring = function() return "[socket error]" end } )

function socket.connect(addr, port)
	assert(fd == nil)
	fd = client_socket.connect(addr, port)

	message = ""
end

function socket.isconnect(ti)
	if not fd then
		return false
	end
	local _, wt = client_socket.poll(nil, { fd }, ti)
	return wt ~= nil and next(wt) ~= nil
end

function socket.close()
	if fd then
		client_socket.close(fd)
	end
	fd = nil
	message = nil
end

function socket.read(ti)
	while true do
		local ok, msg, n = pcall(string.unpack, ">s2", message)
		if not ok then
			local rd = client_socket.poll({fd}, nil, ti)
			if not rd then
				return nil
			end
			if next(rd) == nil then
				return nil
			end
			local p, err = client_socket.recv(fd)
			if not p then
				if err then
					print("err"..err)
					error(debug.traceback(err, 3))
				end
				print("<error> socket close by peer")
				socket.close()
				return nil
			end
			message = message .. p
		else
			message = message:sub(n)
			return msg
		end
	end
end

function socket.write(msg)
	local pack = string.pack(">s2", msg)
	client_socket.send(fd, pack)
end

return socket
