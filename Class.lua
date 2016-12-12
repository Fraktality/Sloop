local Class do
	---------------------------
	local CTOR_KEY   = 'Init'   -- Name of the class constructor
	local STATIC_KEY = 'static' -- Class itself can be referred to in a method as self[STATIC_KEY]
	local SHADOWLESS = true     -- If true, members can't be shadowed.
	---------------------------

	local err_btype  = 'Class body must be of type table (got %s)'
	local err_shadow = 'Member `%s` already exists in another parent class.'

	local fmt   = string.format
	local next  = next
	local type  = type
	local getmt = getmetatable
	local setmt = setmetatable
	
	local l_eventname = {
		__eq     = true; __le       = true; __lt       = true; __add       = true;
		__div    = true; __len      = true; __mod      = true; __mul       = true;
		__pow    = true; __sub      = true; __unm      = true; __call      = true;
		__concat = true; __newindex = true; __tostring = true; __metatable = true;
	}
	
	local function Instantiate(t)
		local mt, ctor = {}, t[CTOR_KEY]
		t[CTOR_KEY] = nil
		local msto, cidx
		if t.__index then
			cidx, t.__index = t.__index, nil
			function mt.__index(st, k)
				return t[k] or cidx(st, k)
			end
		else
			mt.__index = t
		end
		for i, j in next, t do
			if l_eventname[i] then
				msto, t[i], mt[i] = true, nil, j
			end
		end
		local call = ctor and function(_, ...)
			local this = setmt({}, mt)
			ctor(this, ...)
			return this
		end or function()
			return setmt({}, mt)
		end
		t[CTOR_KEY], t[STATIC_KEY] = call, t
		return setmt(t, {
			msto and mt;
			cidx;
			__call = call;
		})
	end

	local function EmptyInherit(t)
		if type(t) ~= 'table' then
			error(fmt(err_btype, type(t)), 2)
		end
		return Instantiate(t)
	end
	
	function Class(...)
		local a0 = ...
		if not a0 then
			return EmptyInherit
		end
		local meta = getmt(a0)
		if meta then
			local mli = {...}
			return function(t)
				if type(t) ~= 'table' then
					error(fmt(err_btype, type(t)), 2)
				end
				local i = 1
				local lv = mli[i]
				repeat
					for j, k in next, lv do
						if t[j] and t[j] ~= k or j == CTOR_KEY or j == STATIC_KEY then
							if SHADOWLESS and j ~= CTOR_KEY and j ~= STATIC_KEY then
								error(fmt(err_shadow, j), 2)
							end
						else
							t[j] = k
						end
					end
					local events = meta[1]
					if events then
						for j, k in next, events do
							if j ~= '__index' then
								if t[j] and t[j] ~= k then
									if SHADOWLESS then
										error(fmt(err_shadow, j), 2)
									end
								else
									t[j] = k
								end
							end
						end
					end
					local cidx = meta[2]
					if cidx then
						if t.__index and t.__index ~= cidx then
							if SHADOWLESS then
								error(fmt(err_shadow, '__index'), 2)
							end
						else
							t.__index = cidx
						end
					end
					i = i + 1
					lv = mli[i]
					meta = lv and getmt(lv)
				until not lv
				return Instantiate(t)
			end
		else
			if type(a0) ~= 'table' then
				error(fmt(err_btype, type(a0)), 2)
			end
			return Instantiate(a0)
		end
	end
end

return Class
