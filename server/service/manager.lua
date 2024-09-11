local skynet = require "skynet"

local service = require "service"
local log = require "log"

local conf_agent = require "config.agent"

local manager = {}
local users = {}
local kick_users = {} -- agent地址 =>踢下线的 账号id

local agent_pool = {}

local function new_agent()
	-- handle the agent
	local agent
	if #agent_pool == 0 then
		local addr = skynet.newservice ("agent", skynet.self())
		agent = {addr = addr}
		skynet.call(agent.addr, "lua", "init", conf_agent)
		log ("pool is empty, new agent addr=%d created", agent.addr)
	else
		agent = table.remove (agent_pool, 1)
		log ("agent addr=%d assigned, %d remain in pool", agent.addr, #agent_pool)
	end
	return agent
end

local function free_agent(agent)
	-- kill agent, todo: put it into a pool maybe better
	table.insert (agent_pool, agent)
end

function manager.open(conf)
	local selfaddr = skynet.self ()
	local n = tonumber(conf.agent_pool or 8)
	log ("manager.open agent pool size: %d", n)
	for _ = 1, n do
		local addr = skynet.newservice ("agent", selfaddr)
		local agent = {addr = addr}
		skynet.call(agent.addr, "lua", "init", conf_agent)
		table.insert (agent_pool, agent)
	end
end

function manager.assign(fd, account_id)
	-- assign agent

	--首先分配一个agent, 防止后面分配挂起导致重入问题
	local agent = new_agent()
	--检查当前账号是否已经登陆
	--如果已经登陆并没有断开连接需要先踢下线再做后面的操作
	while(users[account_id] and users[account_id].fd)
	do
		local orig_agent = users[account_id]
		users[account_id] = nil
		kick_users[orig_agent.addr] = orig_agent
		skynet.call(orig_agent.addr, "lua", "kick")
	end

	if users[account_id] then
		--这里的agent一定是断开链接的
		free_agent(agent)
		agent = users[account_id]
	end
	users[account_id] = agent
	agent.fd = fd
	agent.account_id = account_id
	skynet.call(agent.addr, "lua", "assign", fd, account_id)
	log("manager agent assign fd=%d account_id=%s addr=%s", fd, account_id, agent.addr)
end

function manager.disconnect(account_id, fd)
	log ("manager.disconnect fd=%d account_id=%d", fd, account_id)
	local agent = users[account_id]
	if agent and agent.fd == fd then
		agent.fd = nil
	end
end

function manager.kick(account_id)
	log ("manager.kick account_id: %d", account_id)
	local agent = users[account_id]
	if agent then
		users[account_id] = nil
		kick_users[agent.addr] = agent
		skynet.call(agent.addr, "lua", "kick")
	end
end

function manager.close(addr)
	log ("manager.close addr: %d", addr)
	local agent = kick_users[addr]
	if agent then
		agent.fd = nil
		agent.account_id = nil
		kick_users[addr] = nil
		free_agent(agent)
	end
end

service.init {
	command = manager,
	info = users,
	require = {
		"loginserver",
		"gdd",
		"world"
	},
}
