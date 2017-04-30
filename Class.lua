---------------------------------------------------------------------
-- Simple OOP model for Lua.
--
-- Copyright (c) 2017 Parker Stebbins. All rights reserved.
-- Released under the MIT license.
--
-- License & docs can be found at https://github.com/Fraktality/Sloop
---------------------------------------------------------------------



local Class do
	
	local CTOR_KEY   = 'Init'   -- Constructor name
	local STATIC_KEY = 'static' -- Key of a class instance used for accessing the class itself
	local TYPECHECK  = true     -- Sets whether the type of a class's body should be checked

	--------------------------------------------------------------

	local err_btype = TYPECHECK and 'Class body must be of type table (got %s)'

	local eventname = {
		__index = true, __newindex = true, __namecall = true;
		__gc = true, __mode = true, __len = true, __eq = true;
		__add = true, __sub = true, __mul = true, __mod = true, __pow = true;
		__div = true, __idiv = true;
		__band = true, __bor = true, __bxor = true, __shl = true, __shr = true;
		__unm = true, __bnot = true, __lt = true, __le = true;
		__concat = true, __call = true;
	}

	local next  = next
	local type  = type
	local getmt = getmetatable
	local setmt = setmetatable

	
	local function Instantiate(t)
		local mt, ctor, msto, cidx = {}, t[CTOR_KEY]
		t[CTOR_KEY] = nil
		if t.__index then
			cidx, t.__index = t.__index, nil
			function mt.__index(st, k)
				return t[k] or cidx(st, k)
			end
		else
			mt.__index = t
		end
		for i, j in next, t do
			if eventname[i] then
				msto, t[i], mt[i] = true, nil, j
			end
		end
		local __ctor_wrapper = ctor and function(_, ...)
			local this = setmt({}, mt)
			ctor(this, ...)
			return this
		end or function()
			return setmt({}, mt)
		end
		t[CTOR_KEY], t[STATIC_KEY] = __ctor_wrapper, t
		return setmt(t, {
			msto and mt;
			cidx;
			__call = __ctor_wrapper;
		})
	end


	local function EmptyInherit(t)
		if TYPECHECK and type(t) ~= 'table' then
			error(err_btype:format(type(t)), 2)
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
				if TYPECHECK and type(t) ~= 'table' then
					error(err_btype:format(type(t)), 2)
				end
				local lv, i = mli[1], 1
				repeat
					for j, k in next, lv do
						local ov = t[j]
						if not (ov and ov ~= k) and j ~= CTOR_KEY and j ~= STATIC_KEY then
							t[j] = k
						end
					end
					local events = meta[1]
					if events then
						for j, k in next, events do
							if j ~= '__index' and not (t[j] and t[j] ~= k) then
								t[j] = k
							end
						end
					end
					local cidx = meta[2]
					if cidx and not (t.__index and t.__index ~= cidx) then
						t.__index = cidx
					end
					i = i + 1
					lv = mli[i]
					meta = lv and getmt(lv)
				until not lv
				return Instantiate(t)
			end
		else
			if TYPECHECK and type(a0) ~= 'table' then
				error(err_btype:format(type(a0)), 2)
			end
			return Instantiate(a0)
		end
	end
end


return Class
