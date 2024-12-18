local skynet = require "skynet"
local crypt = require "skynet.crypt"

local uuid = require "uuid"

local service = require "service"
local client = require "client"
local log = require "log"

local errcode = require "errcode.errcode"

local mainserver
local database
local auth_timeout
local session_expire_time
local session_expire_time_in_second
local connection = {}
local saved_session = {}

local handler_type = {
	handshake = 1, --握手
	challenge = 2, --质疑
	auth      = 3, --验证
	finish    = 4, --结束
}

local function close (fd)
	if connection[fd] then
		client.close (fd)
		connection[fd] = nil
	end
end

local cli = client.handler()

local kick = function(user)
	user.exit = true
	if user.fd then
		close(user.fd)
	end
end

function cli:handshake(args)
	if self.handle_type ~= handler_type.handshake then
		kick(self)
		return errcode.LOGIN_INVALID_HANDLE_TYPE --请求协议有误
	end
	if not args then
		kick(self)
		return errcode.COMMON_INVALID_REQUEST_PARMS --请求参数有误
	end
	if not args.client_pub then
		kick(self)
		return errcode.LOGIN_INVALID_CLIENT_PUB --clientkey 有误
	end

	self.clientkey = crypt.base64decode(args.client_pub)
	if #self.clientkey ~= 8 then
		kick(self)
		return errcode.LOGIN_INVALID_CLIENT_PUB --clientkey 有误
	end

	self.serverkey = crypt.randomkey()
	self.secret = crypt.dhsecret(self.clientkey, self.serverkey)

	self.handle_type = handler_type.challenge
	client.sendmsg(self, 'login.on_handshake', {
		secret = crypt.base64encode(crypt.dhexchange(self.serverkey)),
	})
	return true
end

function cli:challenge(args)
	if self.handle_type ~= handler_type.challenge then
		kick(self)
		return errcode.LOGIN_INVALID_HANDLE_TYPE --请求协议有误
	end
	if not args then
		kick(self)
		return errcode.COMMON_INVALID_REQUEST_PARMS --请求参数有误
	end
	if not args.hmac then
		kick(self)
		return errcode.LOGIN_INVALID_HMAC --hmac 有误
	end

	local hmac = crypt.base64encode(crypt.hmac64(self.acknumber, self.secret))
	if hmac ~= args.hmac then
		kick(self)
		return errcode.LOGIN_INVALID_HMAC --hmac 有误
	end
	self.handle_type = handler_type.auth
	return true
end

function cli:auth(args)
	if self.handle_type ~= handler_type.auth then
		kick(self)
		return errcode.LOGIN_INVALID_HANDLE_TYPE --请求协议有误
	end
	if not args then
		kick(self)
		return errcode.COMMON_INVALID_REQUEST_PARMS --请求参数有误
	end
	if not args.username then
		kick(self)
		return errcode.LOGIN_INVALID_USERNAME --用户名有误
	end
	if not args.password then
		kick(self)
		return errcode.LOGIN_INVALID_PASSWORD --密码有误
	end
	local username = crypt.desdecode(self.secret, crypt.base64decode(args.username))
	local password = crypt.desdecode(self.secret, crypt.base64decode(args.password))

	log ("<login> auth username: %s, password: %d", username, password)

	local account = assert(skynet.call (database, "lua", "account", "load", username),
						   string.format("load account username: %s failed", username))

	local account_id = tonumber (account.account_id)

	if not account_id then
		account_id = uuid.gen ()
		account.account_id = assert(skynet.call (database, "lua", "account", "create",
												 account_id, username, password),
									string.format ("create account %s/%d failed", username, account_id))

		log ("    account username: %s account_id: %d create", username, account_id)
	else
		if password ~= account.password then
			kick(self)
			return errcode.LOGIN_INVALID_USERNAME_OR_PASSWORD --账号或密码有误
		end
		log ("    account username: %s account_id: %d login", username, account_id)
	end

	self.account_id = account_id
	local token = crypt.randomkey()
	local login_session = skynet.call (mainserver, "lua", "save_session", account_id, self.clientkey, token)

	self.exit = true

	client.sendmsg(self, 'login.on_auth', {
		login_session = login_session,
		expire = session_expire_time_in_second,
		token = crypt.base64encode(token),
	})
	self.handle_type = handler_type.finish
	client.stop(self.fd) --主动中断监听消息
	return true
end

local loginwork = {}

-- call by loginserver
function loginwork.init (main, id, conf)
	mainserver = main
	database = skynet.uniqueservice ("database")

	auth_timeout = conf.auth_timeout * 100
	session_expire_time = conf.session_expire_time * 100
	session_expire_time_in_second = conf.session_expire_time

	client.set_config({ islogmsg = conf.islogmsg})
end

-- call by loginserver
local function auth (fd, addr)
	local user = {
		fd = fd,
		handle_type = handler_type.handshake,
		acknumber = crypt.randomkey(),
	}

	connection[fd] = user
	skynet.timeout (auth_timeout, function ()
		if connection[fd] == user then
			log ("connection %d from %s auth timeout!", fd, addr)
			close (fd)
		end
	end)

	-- acknowledgment
	client.sendmsg(user, "login.on_acknowledgment", {
		acknumber = crypt.base64encode(user.acknumber),
	})

	local ok, err = pcall(client.dispatch, user)
	if not ok then
		log("fd=%d is gone. error = %s", fd, tostring(err))
	end

	connection[fd] = nil
	return user.account_id
end

function loginwork.auth (fd, addr)
	local account_id = auth(fd, addr)
	if not account_id then
		close(fd)
	end
	return account_id
end

-- call by loginserver
function loginwork.save_session (login_session, account_id, client_key, token)
	log ("    account account_id: %d, login_session: %d savesession ",
		account_id, login_session)

	saved_session[login_session] = {
		account_id = account_id,
		key = client_key,
		token = token,
	}
	skynet.timeout (session_expire_time, function ()
		local t = saved_session[login_session]
		if t then
			if t and t.key == client_key then
				saved_session[login_session] = nil
			end
		end
	end)
end

-- call by loginserver
function loginwork.verify (login_session, token)
	log ("    account login_session: %d verify secret", login_session)

	local t = saved_session[login_session]
	if not t then
		return
	end

	assert (token == t.token,
		string.format("account login_session: %d verify token failed", login_session))
	t.token = nil

	return t.account_id
end

function loginwork.get_account_id (login_session)
	local t = saved_session[login_session]
	if not t then
		return
	end

	return t.account_id
end

service.init {
	command = loginwork,
	--info = users,
	init = client.init (),
}
