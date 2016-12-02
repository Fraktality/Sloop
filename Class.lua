local Class do

	-- config ---------------------
	local CTOR_KEY  = 'Init'  -- Name of the class constructor
	local SHADOWING = false   -- Sets whether class member names can be shadowed
	local CLASSREF  = 'class' -- Class itself can be referred to in a method as self[CLASSREF]
	-------------------------------

	local l_metamethods = {
		__add      = true;
		__call     = true;
		__concat   = true;
		__div      = true;
		__eq       = true;
		__gc       = true;
		__le       = true;
		__len      = true;
		__lt       = true;
		__mod      = true;
		__mul      = true;
		__newindex = true;
		__pow      = true;
		__sub      = true;
		__tostring = true;
		__unm      = true;
	}

	local next = next
	local type = type
	local getmt = getmetatable
	local setmt = setmetatable

	local __tostring_class, __tostring_inst do
		local tostring = tostring
		local gsub = string.gsub

		local function Serialize(obj, id)
			local mt = getmt(obj)
			local _ts = mt.__tostring
			mt.__tostring = nil
			local r = gsub(tostring(obj), 'table', id)
			mt.__tostring = _ts
			return r
		end

		function __tostring_class(obj)
			return Serialize(obj, 'class')
		end

		function __tostring_inst(obj)
			return Serialize(obj, 'class_inst')
		end
	end

	local function Instantiate(t)
		local mt = {
			__index = t;
		}
		local ctor = t[CTOR_KEY]
		if ctor then
			t[CTOR_KEY] = nil
		end
		local __index = t.__index
		t.__index = nil
		local sto_mt = false
		for i, j in next, t do
			if l_metamethods[i] then
				sto_mt = true
				mt[i], t[i] = j, nil
			end
		end
		if not mt.__tostring then
			mt.__tostring = __tostring_inst
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
		if not mt.__call then
			mt.__call = __ctof
		end
		t[CLASSREF] = t
		return setmt(t, {
			__call = __ctof;
			__index = __index;
			__m = sto_mt and mt;
			__tostring = __tostring_class;
		})
	end

	local function EmptyCheck(t)
		if type(t) ~= 'table' then
			error(('Class body must be of type table (got %s)'):format(type(t)), 2)
		end
		return Instantiate(t)
	end
	
	function Class(...)
		if not ... then
			return EmptyCheck
		end
		local meta = getmt(...)
		if meta then
			local mli = {...}
			return function(t)
				if type(t) ~= 'table' then
					error(('Class body must be of type table (got %s)'):format(type(t)), 2)
				end
				local i = 1
				local lv = mli[i]
				repeat
					if meta.__index then
						if SHADOWING and not t.__index then
							t.__index = meta.__index
						elseif t.__index then
							error('Class member name conflict: __index', 2)
						end
					end
					local _m = meta.__m
					if _m then
						if SHADOWING then
							for j, k in next, _m do
								if not t[j] then
									t[j] = k
								end
							end
						else
							for j, k in next, _m do
								if t[j] then
									error(('Class member name conflict: %s'):format(j), 2)
								end
								t[j] = k
							end
						end
					end
					if SHADOWING then
						for j, k in next, lv do
							if not t[j] then
								t[j] = k
							end
						end
					else
						for j, k in next, lv do
							if t[j] then
								error(('Class member name conflict: %s'):format(j), 2)
							end
							t[j] = k
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
				error(('Class body must be of type table (got %s)'):format(type(t)), 2)
			end
			return Instantiate(t)
		end
	end
end
