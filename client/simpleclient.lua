local PATH, IP, USERNAME, PASSWORD = ...

IP = IP or "127.0.0.1"
USERNAME = USERNAME or "sunday1"
PASSWORD = PASSWORD or "123456"

package.path = table.concat({
		PATH.."/client/lualib/?.lua",
		PATH.."/common/lualib/?.lua",
		PATH.."/3rd/skynet/lualib/?.lua",
}, ";")
package.cpath = table.concat({
		PATH.."/client/luaclib/?.so",
		PATH.."/common/luaclib/?.so",
		PATH.."/server/luaclib/?.so",
		PATH.."/3rd/skynet/luaclib/?.so",
}, ";")

local crypt = require "client.crypt"
local message = require "simplemessage"
local cjsonutil = require "cjson.util"
local errcode = require "errcode.errcode"

local gddata = require "gddata.gamedata.Schema.schema"

local user = { username = USERNAME, password = PASSWORD }

do
	if not user.username then
		print([[Usage:
			lua client/simpleclient.lua <ip> <username> <password>
		]])
		return
	end
end

local cli = {
	authed = false,
	pingtime = os.time()
}

local common_handler = {
}

function common_handler:ping()
end


local login_handler = {
}

function login_handler:on_acknowledgment (args)
	user.acknumber = crypt.base64decode(args.acknumber)
	user.clientkey = crypt.randomkey()
	message.sendmsg ("login.handshake", {
		client_pub = crypt.base64encode(crypt.dhexchange(user.clientkey)),
	})
end

local cb_handshake = function(req, opflag, error_code)
	if not opflag then
		print(string.format("<error> RESPONSE login.handshake_ret errcode:%d(%s)", error_code, errcode.error_msg(error_code)))
		return
	end
	message.sendmsg("login.auth", {
		username = crypt.base64encode(crypt.desencode(user.secret, user.username)),
		password = crypt.base64encode(crypt.desencode(user.secret, user.password)),
	})
end

function login_handler:on_handshake(resp)
	if not resp then
		print(string.format("<error> RESPONSE login.on_handshake resp is nil:"))
		return
	end
	user.secret = crypt.dhsecret(crypt.base64decode(resp.secret), user.clientkey)
	print("sceret is ", crypt.hexencode(user.secret))

	local hmac = crypt.base64encode(crypt.hmac64(user.acknumber, user.secret))
	message.sendmsg("login.challenge", { hmac = hmac }, cb_handshake)
end

function login_handler:on_auth(resp)
	if not resp then
		print(string.format("<error> RESPONSE login.on_auth resp is nil:"))
		return
	end

	user.login_session = resp.login_session
	user.login_session_expire = resp.expire
	user.token = crypt.base64decode(resp.token)

	-- 跳转到游戏服务器
	--message.sendmsg ("login.switchgame", nil)

	cli.authed = true

	-- 请求角色列表
	message.sendmsg ("character.list", nil)
end

local character_handler = {}

function character_handler:on_list (resp)
	print(string.format("<== RESPONSE character.on_list resp: %s",
						cjsonutil.serialise_value(resp)))
	resp = resp or {}
	local character = resp.character or {}

	local character_id = next(character)
	if not character_id then
		local charname = string.format("%s-%s", user.username, "hello")
		print(string.format("create charname: %s", charname))
		message.sendmsg("character.create", {
			character = {
				name = charname,
				race = gddata.enums['common.ERaceType'].HUMAN,
				profession = gddata.enums['common.EProfessionType'].WARRIOR,
			},
		}, function (req, result, error_code)
			if error_code ~= errcode.SUCCESS then
				print(string.format("create character failed error_code:%d, req:%s", 
					error_code, cjsonutil.serialise_value(req)))
			end
		end)
	else
		print(string.format("choose characterId: %s", tostring(character_id)))
		message.sendmsg("character.pick", {
			id = character_id,
		})
	end
end

function character_handler:on_create ()
	message.sendmsg ("character.list")
end

function character_handler:on_pick (resp)
	print(string.format("<== RESPONSE character.on_pick character: %s",
						cjsonutil.serialise_value(resp)))
end

function cli:update()
	if self.authed then
		local timenow = os.time()
		if timenow - self.pingtime > 5 then
			self.pingtime = timenow
			message.sendmsg("common.ping")
		end
	end
end

message.register()
message.peer(IP, 9777)
message.connect()
message.bind('common', common_handler)
message.bind('login', login_handler)
message.bind('character', character_handler)

while true do
	message.update(5)
	cli:update()
end
