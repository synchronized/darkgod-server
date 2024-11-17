local skynet = require "skynet"
local crypt = require "skynet.crypt"

local errcode= require "errcode.errcode"
local proxy = require "socket_proxy"
--local protoloader = require "proto/sproto_mgr"
local protobuf = require "proto/pb_mgr"
local log = require "log"
local cjsonutil = require "cjson.util"

local traceback = debug.traceback

require "extra.stringext"

local client = {}
local host
local handler = {}
local conf_client = {}

function client.handler()
	return handler
end

function client.readmessage( fd )
	proxy.subscribe(fd)
	local msg, sz = proxy.read(fd)
	return host:dispatch(msg, sz)
end

function client.writemessage( fd, msg, sz )
	proxy.write(fd, msg, sz)
end

function client.read( fd )
	proxy.subscribe(fd)
	return skynet.tostring(proxy.read(fd))
end

function client.write( fd, luastring)
	proxy.write(fd, skynet.pack(luastring))
end

function client.dispatch( c, ext_handlers)
	local fd = c.fd
	proxy.subscribe(fd)
	while true do
		local msg, sz = proxy.read(fd)
		if c.exit then
			return c
		end
		local bytemsg = skynet.tostring(msg, sz)
		if conf_client.islogmsg then
			log("=============receivemsg bytemsg:%s|", crypt.base64encode(bytemsg))
		end
		--NOTE:下面分开获取方便知道是哪一步出错了
		local msgname, client_session_id, bytes_body, n
		msgname, n = string.unpack(">s2", bytemsg)
		bytemsg = string.sub(bytemsg, n)
		client_session_id, n = string.unpack(">I4", bytemsg)
		bytemsg = string.sub(bytemsg, n)
		bytes_body = string.unpack(">s2", bytemsg)

		local args = nil
		if #bytes_body > 0 then
			args = assert(protobuf.decode(msgname, bytes_body))
		end
		if conf_client.islogmsg then
			log("=============receivemsg msgname:%s, bytes_body:%s|", msgname, crypt.base64encode(bytes_body))
			log("=============receivemsg msgname:%s, data:%s", msgname, cjsonutil.serialise_value(args))
		end

		local msgnames = msgname:split('.')
		if #msgnames < 2 then
			error(string.format("invalid msgname: %s", msgname))
			return
		end
		local cname = msgnames[1]
		local fname = msgnames[2]

		-- session_id is request type
		local f = ext_handlers and
			ext_handlers[cname] and
			ext_handlers[cname].REQUEST and
			ext_handlers[cname].REQUEST[fname] or
			handler[fname]
		if not f then
			-- unsupported command, disconnected
			error(string.format("request %s have no handler", msgname))
		else
			-- f may block , so fork and run
			skynet.fork(function()
				local ok, err, error_code = xpcall(f, traceback, c, args, client_session_id)
				--log("=============msgname: %s, ok:%s, err:%s, error_code:%s", msgname, tostring(ok), tostring(err), tostring(error_code))
				local msgresult = nil
				if not ok then
					log.printf("<error> response error = %s", err)
					if client_session_id > 0 then
						msgresult = {
							session = client_session_id,
							result = false,
							error_code = errcode.COMMON_SERVER_ERROR,
						}
					end
				elseif type(error_code) == "number" and type(err) == "boolean" then
					if client_session_id > 0 then
						msgresult = {
							session = client_session_id,
							result = err,
							error_code = error_code,
						}
					end
				elseif type(err) == "number" then
					if client_session_id > 0 then
						msgresult = {
							session = client_session_id,
							result = err == errcode.SUCCESS,
							error_code = err,
						}
					end
				elseif type(err) == "boolean" then
					if client_session_id > 0 then
						msgresult = {
							session = client_session_id,
							result = err,
							error_code = errcode.SUCCESS,
						}
					end
				else
					--error()
				end
				if msgresult ~= nil then
					client.sendmsg(c, 'common.on_msgresult', msgresult)
				end
			end)
		end
	end
end

function client.close(fd)
	proxy.close(fd)
end

function client.stop(fd)
	proxy.stop(fd)
end

function client.sendmsg(c, msgname, data)
	proxy.subscribe(c.fd)
	if conf_client.islogmsg then
		log("=============sendmsg msgname:%s, data:%s", msgname, cjsonutil.serialise_value(data))
	end
	local bytes_body = ""
	if data then
		bytes_body = assert(protobuf.encode(msgname, data))
	end
	local bytemsg = string.pack(">s2>s2", msgname, bytes_body)

	if conf_client.islogmsg then
		log("=============sendmsg msgname:%s, bytes_body:%s|", msgname, crypt.base64encode(bytes_body))
		log("=============sendmsg msgname:%s, bytemsg:%s|", msgname, crypt.base64encode(bytemsg))
	end

	proxy.write(c.fd, bytemsg)
end

function client.set_config(config)
	conf_client = config or {}
end

function client.init()
	return function ()
		--local protod = skynet.uniqueservice "protod"
		--local protoindex = assert(skynet.call(protod, "lua", "loadindex", name))
		--host, sender = protoloader.loadbyserver (protoindex)
	end
end

return client
