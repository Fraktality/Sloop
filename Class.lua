local Class do
	-----------------------------
	local CTOR_KEY   = 'Init'   -- Name of the class constructor
	local SHADOWLESS = true     -- If true, members can't be shadowed.
	local CLASSREF   = 'static' -- Class itself can be referred to in a method as self[CLASSREF]
	-----------------------------

	local err_btype  = 'Class body must be of type table (got %s)'
	local err_shadow = 'Class member name conflict: %s'

	local next = next
	local type = type
	local getmt = getmetatable
	local setmt = setmetatable

	local l_eventname = {
		__add       = true;
		__call      = true;
		__concat    = true;
		__div       = true;
		__eq        = true;
		__gc        = true;
		__le        = true;
		__len       = true;
		__lt        = true;
		__metatable = true;
		__mod       = true;
		__mul       = true;
		__newindex  = true;
		__pow       = true;
		__sub       = true;
		__tostring  = true;
		__unm       = true;
	}

	local function Instantiate(t)
		local mt, ctor = {}, t[CTOR_KEY]
		t[CTOR_KEY] = nil
		local msto, cidx
		if t.__index then
			cidx = t.__index
			function mt.__index(st, k)
				return t[k] or cidx(st, k)
			end
			t.__index = nil
		else
			mt.__index = t
		end
		for i, j in next, t do
			if l_eventname[i] then
				msto, mt[i], t[i] = true, j, nil
			end
		end
		local __ctof = ctor and function(_, ...)
			local this = setmt({}, mt)
			if ctor then
				ctor(this, ...)
			end
			return this
		end or function()
			return setmt({}, mt)
		end
		t[CTOR_KEY], t[CLASSREF] = __ctof, t
		return setmt(t, {
			__call = __ctof;
			msto and mt;
			cidx;
		})
	end

	local function EmptyInherit(t)
		if type(t) ~= 'table' then
			error(err_btype:format(type(t)), 2)
		end
		return Instantiate(t)
	end
	
	function Class(...)
		if not ... then
			return EmptyInherit
		end
		local meta = getmt(...)
		if meta then
			local mli = {...}
			return function(t)
				if type(t) ~= 'table' then
					error(err_btype:format(type(t)), 2)
				end
				local i = 1
				local lv = mli[i]
				repeat
					for j, k in next, lv do
						if t[j] ~= k and j ~= CTOR_KEY and SHADOWLESS then
							error(err_shadow:format(j), 2)
						else
							t[j] = k
						end
					end
					local events = meta[1]
					if events then
						for j, k in next, events do
							if t[j] ~= k and SHADOWLESS then
								error(err_shadow:format(j), 2)
							else
								t[j] = k
							end
						end
					end
					local cidx = meta[2]
					if cidx then
						if t.__index ~= cidx and SHADOWLESS then
							error(err_shadow:format('__index'), 2)
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
			local t = ...
			if type(t) ~= 'table' then
				error(err_btype:format(type(t)), 2)
			end
			return Instantiate(t)
		end
	end
end


return Class
