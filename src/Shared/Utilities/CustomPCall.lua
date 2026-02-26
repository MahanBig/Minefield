function CustomPCall<T>(fn: () -> T, maxTries: number?): (boolean, T | string)
	local retries = 0
	local success
	local result
	maxTries = maxTries or 5

	repeat
		retries += 1
		success, result = pcall(fn)

		if success == false then
			warn("CustomPCall: Attempt #" .. retries .. " failed. Retrying...")
			task.wait(0.2 * retries)
		end
	until success == true or retries >= maxTries

	if success == false and maxTries then
		warn("CustomPCall: PCall failed after " .. maxTries .. " attempts. Error: " .. tostring(result))
	end

	return success, result
end
return CustomPCall
