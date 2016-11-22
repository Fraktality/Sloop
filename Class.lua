local Class do

	-- config ---------------------
	local CTOR_KEY  = 'Constructor' -- Name of the class constructor
	local SHADOWING = true          -- Sets whether class member names can be shadowed
	local CLASSREF  = 'static'      -- Class itself can be referred to in a method as self[CLASSREF]
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
	local getmt = getmetatable
	local setmt = setmetatable

	local __tostring_class, __tostring_inst do
		local tostring = tostring
		local gsub = string.gsub

		local function Serialize(obj, name)
			local mt = getmt(obj)
			local _ts = mt.__tostring
			mt.__tostring = nil
			local r = gsub(tostring(obj), 'table', name)
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

	local function Instantiate(t, idx, mt, ctor)
		if not idx then
			idx = {}
			mt = {
				__index = idx;
				__tostring = __tostring_inst;
			}	
		end
		if t[CTOR_KEY] then
			ctor, t[CTOR_KEY] = t[CTOR_KEY], nil
		end
		for i, j in next, t do
			(l_metamethods[i] and mt or idx)[i] = j
		end
		idx[CLASSREF] = idx
		t = nil
		return setmt(idx, {
			c = ctor;
			m = mt;
			__call = ctor and function(_, ...)
				local this = setmt({}, mt)
				if ctor then
					ctor(this, ...)
				end
				return this
			end or function()
				return setmt({}, mt)
			end;
			__tostring = __tostring_class;
		})
	end

	function Class(...)
		local m0 = getmt(...)
		if m0 then
			local mli = {...}
			return function(t)
				local idx, mt, i, ctor = {}, {}, 1
				local lv = mli[i]
				repeat
					local _ctor = m0.c
					if _ctor then
						ctor = _ctor
					end
					for j, k in next, m0.m do
						if j ~= '__index' then
							mt[j] = k
						else
							error('Cannot define __index', 2)
						end
					end
					if SHADOWING then
						for j, k in next, lv do
							idx[j] = k
						end
					else
						for j, k in next, lv do
							if idx[j] or t[j] then
								error(('Member name conflict: `%s`'):format(j), 2)
							end
							idx[j] = k
						end
					end
					i = i + 1
					lv = mli[i]
					m0 = getmt(lv)
				until not lv
				mt.__index = idx
				return Instantiate(t, idx, mt, ctor)
			end
		else
			local arg = ...
			if type(arg) ~= 'table' then
				error(('Class body must be a table (got a %s)'):format(type(arg)), 2)
			end
			return Instantiate(arg)
		end
	end
end

return Class
