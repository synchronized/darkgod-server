local skynet = require "skynet"
local sharedata = require "skynet.sharedata"
local gdd = require "gddata.gamedata.gamedata"

skynet.start (function ()
	sharedata.new ("gdd", gdd)
end)
