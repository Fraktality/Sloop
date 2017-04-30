# Sloop
Simple and fast OOP model for Lua.

## Usage

Specify class members by enclosing them in curly braces:

```lua
local Person = Class{
	Say = function(self, phrase)
		print(self.name .. ':', phrase)
	end;
}
```

Instantiate a class instance by calling the class:

```lua
Person():Say('Hello, world!')
```

Specify parent classes by enclosing them in parenthesis before the class body:

```lua
local PersonWhoEatsBagels = Class(Person, BagelEater){}
```

Name a method `Init` to make it a constructor:

```lua
local PersonWhoEatsBagels = Class(Person, BagelEater){ -- Inherits from Person & BagelEater
	Init = function(self, name, bagelCount)
		rawset(self, 'name', name)
		rawset(self, 'bagelCount', bagelCount)
	end;
}
```

Tag methods are detected and handled automatically:

```lua
local Number = Class{
	Init = function(value)
		self.value = value
	end;
	__add = function(op0, op1)
		return op0.value + op1.value
	end;
	__tostring = function(self)
		return tostring(self.value)
	end;
}

print(Number(1) + Number(2)) --> 3
```
