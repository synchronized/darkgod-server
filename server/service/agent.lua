local skynet = require "skynet"

local traceback = debug.traceback

local service = require "service"
local client = require "client"
local log = require "log"

local protoloader = require "proto/sproto_mgr"
local character_handler = require "agent.character_handler"
local map_handler = require "agent.map_handler"
local aoi_handler = require "agent.aoi_handler"
local combat_handler = require "agent.combat_handler"

--[[
.user {
	fd : integer
	account_id : integer

	character : character
	world : integer
	map : integer
}
]]

local user = {
	--fd = nil
	--account_id = nil
	REQUEST = {},
	RESPONSE = {},
	CMD = {},
}

local helper = {
	last_heartbeat_time = 0,
	HEARTBEAT_TIME_MAX = 60 * 100,

	last_disconnect_time = 0,
	DESTROY_TIME_MAX = 60 * 100,
}

function helper.closeconnect ()
	if user.fd then
		local fd = user.fd
		local account_id = math.tointeger(user.account_id)
		log ("agent fd=%d account_id=%d close connect", fd, account_id)

		user.fd = nil
		client.close(fd)
		skynet.call(service.manager, "lua", "disconnect", account_id, fd)	-- report disconnect

		helper.last_disconnect_time = skynet.now()
		helper.checkdestroy()
	end
end

function helper.kickagent ()
	helper.closeconnect()
	if user.account_id then
		local fd = math.tointeger(user.fd)
		local account_id = math.tointeger(user.account_id)
		log ("agent fd=%d account_id=%d kick agent", fd, account_id)
		skynet.call(service.manager, "lua", "kick", account_id)	-- report kick
	end
end

--检查心跳
function helper.checkheartbeat ()
	if helper.HEARTBEAT_TIME_MAX <= 0 or not user.fd then return end

	local t = helper.last_heartbeat_time + helper.HEARTBEAT_TIME_MAX - skynet.now ()
	if t <= 0 then
		if user.fd or user.account_id then
			local fd = math.tointeger(user.fd)
			local account_id = math.tointeger(user.account_id)
			log ("agent fd=%d account_id=%d close connect for heatbeat timeout", fd, account_id)
		end
		helper.closeconnect()
		return
	end
	skynet.timeout (t, helper.checkheartbeat)
end

--检查断开连接后
function helper.checkdestroy ()
	if helper.DESTROY_TIME_MAX <= 0 or user.fd then return end

	local t = helper.last_disconnect_time + helper.DESTROY_TIME_MAX - skynet.now ()
	if t <= 0 then
		if user.fd or user.account_id then
			local fd = math.tointeger(user.fd)
			local account_id = math.tointeger(user.account_id)
			log ("agent fd=%d account_id=%d kick for disconnect timeout", fd, account_id)
		end
		helper.kickagent ()
		return
	end
	skynet.timeout (t, helper.checkdestroy)
end

local cli = client.handler()

function cli:ping()
	-- log ("account_id: %d ping", tonumber(user.account_id))
	helper.last_heartbeat_time = skynet.now()
	return nil
end

local agent = {
	-- CMD = {}
}

local function start_agent()
	assert(user, string.format("invalid user data"))
	local fd = user.fd
	local account_id = user.account_id
	local ok, error = pcall(client.dispatch, user)
	if not ok then
		log("agent fd=%d, account_id=%d is gone. error = %s", fd, account_id, tostring(error))
	end
	helper.closeconnect()
end

function agent.init (conf)
	client.set_config({ islogmsg = conf.islogmsg})
end

function agent.assign (fd, account_id)
	if user.fd then
		error(string.format("agent repeat assign account_id: %d, fd: %d, new account_id: %d, fd:%d",
			user.account_id, user.fd, account_id, fd))
	end

	log ("agent fd=%d account_id=%d has created", fd, account_id)

	user.fd = fd
	user.account_id = account_id

	agent.CMD = user.CMD

	character_handler:register(user)

	--开始检查心跳
	helper.last_heartbeat_time = skynet.now ()
	helper.checkheartbeat ()

	skynet.fork(start_agent)
	return true
end

function agent.kick ()
	if user.fd or user.account_id then
		local fd = math.tointeger(user.fd)
		local account_id = math.tointeger(user.account_id)
		log.printf ("agent fd=%d account_id=%d closed", fd, account_id)
	end

	if user.fd then
		local fd = user.fd
		user.fd = nil
		client.close(fd)
	end
	if user.account_id then
		if user.map then
			skynet.call (user.map, "lua", "character_leave", user.character.id)
		end

		if user.world then
			skynet.call (user.world, "lua", "character_leave", user.character.id)
		end

		character_handler.save (user.character)
		character_handler:unregister(user)

		user.account_id = nil
		agent.CMD = nil
	end
	skynet.call (service.manager, "lua", "close", skynet.self())
end

function agent.world_enter (world)
	if user.character then
		log ("agent character: %d(%s) world enter",
			user.character.id, user.character.general.name)
	end

	user.world = world
	character_handler:unregister(user)
end

function agent.world_leave (character_id)
	if user.character and user.character.id == character_id then
		log ("agent character: %d(%s) world leave",
			user.character.id, user.character.general.name)
		user.world = nil
	end
end

function agent.map_enter (map)
	if user.character then
		log ("agent character: %d(%s) map enter",
			user.character.id, user.character.general.name)
	end

	user.map = map

	map_handler:register (user)
	aoi_handler:register (user)
	combat_handler:register (user)
end

function agent.map_leave (character_id)
	if user.character and user.character.id == character_id then
		log ("agent character: %d(%s) map leave",
			user.character.id, user.character.general.name)
		user.map = nil
		map_handler:unregister (user)
		aoi_handler:unregister (user)
		combat_handler:unregister (user)
	end
end

service.init {
	command = agent,
	-- info = data,
	require = {
		"manager",
	},
	init = client.init (protoloader.GAME),
}
