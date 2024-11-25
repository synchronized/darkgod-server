local skynet = require "skynet"
local sharedata = require "skynet.sharedata"

local log = require "log"

local dbpacker = require "db.packer"
local cjsonutil = require "cjson.util"
local uuid = require "uuid"
local errcode = require "errcode.errcode"
local client = require "client"

local handler = require "agent.handler"

local configEnums = require "gddata.gamedata.Schema.schema".enums
local ECurrencyType = configEnums['item.ECurrencyType']

local REQUEST = {}
handler = handler.new ('character', REQUEST)

local user
local database
local gdd
local world

skynet.init(function ()
	database = skynet.uniqueservice ("database")
	gdd = sharedata.query ("gdd")
	world = skynet.uniqueservice ("world")
end)

handler:init (function (u)
	user = u
end)

local function load_list (account_id)
	local char_list = skynet.call (database, "lua", "character", "list", account_id)
	if char_list then
		char_list = dbpacker.unpack (char_list)
	else
		char_list = {}
	end
	return char_list
end

local function check_character (account_id, character_id)
	local char_list = load_list (account_id)
	for _, v in pairs (char_list) do
		if tostring(v) == tostring(character_id) then return true end
	end
	return false
end

local function create (name, race, profession)
	if not name then return errcode.CHARACTER_INVLID_CHARACTER_NAME end
	if not race then return errcode.CHARACTER_INVLID_CHARACTER_RACE end
	if not profession then return errcode.CHARACTER_INVLID_CHARACTER_PROFESSION end
	if #name <= 2 or #name > 24 then
		log (string.format("invalid character name: %s", name))
		return errcode.CHARACTER_INVLID_CHARACTER_NAME
	end
	if not gdd.racelevel[race] then
		log (string.format("invalid character race: %s", race))
		return errcode.CHARACTER_INVLID_CHARACTER_RACE
	end
	if not gdd.professionlevel[profession] then
		log (string.format("invalid character profession: %s", profession))
		return errcode.CHARACTER_INVLID_CHARACTER_PROFESSION
	end

	local map_id = gdd.globalconfig.mainCityMapId
	local conf_city = gdd.map[map_id]
	local born_position = conf_city.playerBornPosition
	local born_rotate = conf_city.playerBornRotate

	local character = {
		general = {
			name = name,
			race = race,
			profession = profession,
			map = map_id,
		},
		currency = {
		},
		attribute = {
			level = math.tointeger(1),
		},
		movement = {
			mode = 0,
			pos = {
				x = born_position.x,
				y = born_position.y,
				z = born_position.z,
				o = born_rotate.y,
			 },
		},
	}

	-- 初始化货币
	for _, v in pairs(ECurrencyType) do
		character.currency[v] = 0
	end

	return nil, character
end

local function on_enter_world (character)
	local temp_attribute = {
		[1] = {},
		[2] = {},
	}
	local attribute_count = #temp_attribute

	character.runtime = {
		temp_attribute = temp_attribute,
		attribute = temp_attribute[attribute_count],
	}

	local profession = character.general.profession
	local race = character.general.race
	local level = math.tointeger(character.attribute.level)

	local professionAttribute = gdd.professionlevel[profession].attribute[level]
	local raceAttribute = gdd.racelevel[race].attribute[level]

	local base = temp_attribute[1]

	base.strength         = raceAttribute.strength
	base.stamina_max      = raceAttribute.staminaMax
	base.attack_power     = 0
	base.health_max       = professionAttribute.healthMax
	base.physical_attack  = professionAttribute.physicalAttack
	base.magic_attack     = professionAttribute.magicAttack
	base.physical_defense = professionAttribute.physicalDefense
	base.magic_defense    = professionAttribute.magicDefense
	base.dodge            = professionAttribute.dodge
	base.penetration      = professionAttribute.penetration
	base.critical         = professionAttribute.critical

	local last = temp_attribute[attribute_count - 1]
	local final = temp_attribute[attribute_count]

	final.strength         = last.strength
	final.stamina_max      = last.stamina_max
	final.attack_power     = last.attack_power + final.strength
	final.health_max       = last.health_max
	final.physical_attack  = last.physical_attack
	final.magic_attack     = last.magic_attack
	final.physical_defense = last.physical_defense
	final.magic_defense    = last.magic_defense
	final.dodge            = last.dodge
	final.penetration      = last.penetration
	final.critical         = last.critical

	local attribute = setmetatable (character.attribute, { __index = character.runtime.attribute })

	attribute.strength         = final.strength
	attribute.stamina_max      = final.stamina_max
	attribute.attack_power     = final.attack_power + final.strength
	attribute.health_max       = final.health_max
	attribute.physical_attack  = final.physical_attack
	attribute.magic_attack     = final.magic_attack
	attribute.physical_defense = final.physical_defense
	attribute.magic_defense    = final.magic_defense
	attribute.dodge            = final.dodge
	attribute.penetration      = final.penetration
	attribute.critical         = final.critical

	local health = attribute.health
	if not health or health > attribute.health_max then
		attribute.health = attribute.health_max
	end

	local stamina = attribute.stamina
	if not stamina or stamina > attribute.stamina_max then
		attribute.stamina = attribute.stamina_max
	end
	return character
end

function REQUEST:list ()
	local char_list = load_list (user.account_id)
	log ("<character_list> account_id: "..tostring(user.account_id)..", char_list: "..cjsonutil.serialise_value(char_list, "  "))
	local character = {}
	for _, character_id in pairs (char_list) do
		local c = skynet.call (database, "lua", "character", "load", character_id)
		if c then
			character[character_id] = dbpacker.unpack (c)
		end
	end

	log ("    character-list: "..cjsonutil.serialise_value(character, "  "))
	client.sendmsg(self, "character.on_list", { character = character })
	return true
end

function REQUEST:create (args)
	if not args then
		return errcode.COMMON_INVALID_REQUEST_PARMS
	end
	if not args.character then
		return errcode.COMMON_INVALID_REQUEST_PARMS
	end
	local char_req = args.character

	log ("<character_create> args: "..cjsonutil.serialise_value(char_req, "  "))

	local ret, character = create(char_req.name, char_req.race, char_req.profession)
	if ret then
		return ret -- 创建角色失败
	end

	local char_name = char_req.name
	local character_id = skynet.call(database, "lua", "character", "reserve", uuid.gen(), char_name)
	if not character_id then
		log ("    character_name: %s already exist", char_name)
		return errcode.CHARACTER_INVLID_CHARACTER_NAME
	end

	character.id = character_id
	local json = dbpacker.pack (character)
	if not skynet.call(database, "lua", "character", "save", character_id, json) then
		log ("    character_id: %d save failed data: %s", character_id, json)
		return errcode.CHARACTER_SAVE_DATA_FAILED
	end

	local list = load_list (user.account_id)
	table.insert (list, character_id)
	json = dbpacker.pack (list)

	if not skynet.call(database, "lua", "character", "savelist", user.account_id, json) then
		log ("    account_id: %d save failed char_list: %s", user.account_id, json)
		return errcode.CHARACTER_SAVE_DATA_FAILED
	end

	client.sendmsg(self, "character.on_create", { character = character })
	return true
end

function REQUEST:pick (args)
	if not args then
		return errcode.COMMON_INVALID_REQUEST_PARMS
	end
	if not args.id then
		log ("invalid character_id: %d", tonumber(args.id))
		return errcode.CHARACTER_INVLID_CHARACTER_ID
	end
	local character_id = args.id
	if not check_character (user.account_id, character_id) then
		log ("invalid character_id: %d", character_id)
		return errcode.CHARACTER_INVLID_CHARACTER_ID
	end

	log ("<character_pick> args: "..cjsonutil.serialise_value(args, "  "))

	if user.character then
 		log ("    current character_id: %d", user.character.id)
		-- 已经选择过角色, 如果是当前角色直接返回
		if user.character.id == character_id then
			client.sendmsg(self, "character.on_pick", { character = user.character })
			return true
		end

		-- 如果不是当前角色先将之前的角色离开地图
 		log ("    character_id: %d leave world", user.character.id)
		if user.map then
			skynet.call(user.map, "lua", "character_leave", user.character.id)
		end

		if user.world then
			skynet.call(user.world, "lua", "character_leave", user.character.id)
		end
	end

	local c = skynet.call(database, "lua", "character", "load", character_id)
	if not c then
		log ("character_id: %d load failed", character_id)
		return errcode.CHARACTER_LOAD_DATA_FAILED
	end
	local character = dbpacker.unpack (c)

	character = on_enter_world(character)
	user.character = character

	local map = user.character.general.map
	local pos =  user.character.movement.pos
	skynet.call (world, "lua", "character_enter", character_id, map, pos)
	log ("    character-pick: "..cjsonutil.serialise_value(character, "  "))
	client.sendmsg(self, "character.on_pick", { character = character })
	return true
end

function handler.save (character)
	if not character then return end

	local runtime = character.runtime
	character.runtime = nil
	local data = dbpacker.pack (character)
	character.runtime = runtime
	skynet.call (database, "lua", "character", "save", character.id, data)
end

return handler
