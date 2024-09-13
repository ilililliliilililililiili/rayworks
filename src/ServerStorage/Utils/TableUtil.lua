local function Compare(old: {any}, new: {any}, identifier: string): ({any}, {any})
	local minus = {}
	local plus = {}

	for _, iV in pairs(old) do
		local found = false
		for _, kV in new do if iV[identifier] == kV[identifier] then found = true break end end
		if not found then table.insert(minus, iV) end
	end

	for _, iV in pairs(new) do
		local found = false
		for _, kV in old do if iV[identifier] == kV[identifier] then found = true break end end
		if not found then table.insert(plus, iV) end
	end

	return minus, plus
end

return {
    Compare = Compare
}