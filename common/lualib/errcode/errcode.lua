
local confErrCodeMap = require "gddata.gamedata.Data.errcode_errcode"

local M = setmetatable({}, {
	__index = function (t, k)
		local confErrCode = confErrCodeMap[k]
		return confErrCode and confErrCode.errcode
	end
})

for _, v in pairs(confErrCodeMap) do
	M[v.errcode] = v
end

function M.error_msg(err_code)
	local confErrCode = M[err_code]
	return confErrCode and confErrCode.comment or "<unknow error>"
end

return M
