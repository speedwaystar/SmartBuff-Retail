-------------------------------------------------------------------------------
-- Globals
-------------------------------------------------------------------------------

local addonName = ...

SMARTBUFF_GLOBALS = { };
S = SMARTBUFF_GLOBALS;

SMARTBUFF_TTC_R = 1;
SMARTBUFF_TTC_G = 1;
SMARTBUFF_TTC_B = 1;
SMARTBUFF_TTC_A = 1;

SMARTBUFF_OPTIONSFRAME_HEIGHT = 720;
SMARTBUFF_OPTIONSFRAME_WIDTH = 500;

SMARTBUFF_CONST_AUTOSOUND = "Deathbind Sound";
--SMARTBUFF_CONST_AUTOSOUND = "TaxiNodeDiscovered";
--SMARTBUFF_CONST_AUTOSOUND = "GLUECREATECHARACTERBUTTON";

--[[
SystemFont
GameFontNormal
GameFontNormalSmall
GameFontNormalLarge
GameFontHighlight
GameFontHighlightSmall
GameFontHighlightSmallOutline
GameFontHighlightLarge
GameFontDisable
GameFontDisableSmall
GameFontDisableLarge
GameFontGreen
GameFontGreenSmall
GameFontGreenLarge
GameFontRed
GameFontRedSmall
GameFontRedLarge
GameFontWhite
GameFontDarkGraySmall
NumberFontNormalYellow
NumberFontNormalSmallGray
QuestFontNormalSmall
DialogButtonHighlightText
ErrorFont
TextStatusBarText
CombatLogFont
NumberFontNormalLarge
NumberFontNormalHuge
]]--

Enum.InventorySlot = {
  EMPTY = -1,
  INVTYPE_NON_EQUIP	= 0,
  INVTYPE_HEAD = 1,
  INVTYPE_NECK = 2,
  INVTYPE_SHOULDER = 3,
  INVTYPE_BODY = 4,
  INVTYPE_CHEST = 5,
  INVTYPE_WAIST = 6,
  INVTYPE_LEGS = 7,
  INVTYPE_FEET = 8,
  INVTYPE_WRIST = 9,
  INVTYPE_HAND = 10,
  INVTYPE_FINGER1 = 11,
  INVTYPE_FINGER2 = 12,
  INVTYPE_TRINKET1 = 13,
  INVTYPE_TRINKET2 = 14,
  INVTYPE_BACK = 15,
  INVTYPE_MAINHAND = 16,
  INVTYPE_OFFHAND = 17,
  INVTYPE_RANGED = 18,
  INVTYPE_TABARD = 19
}

----------------------------------------------------------------------------

-- Returns an unumerated table.
---## Example
---```
---Enum.Animals = Enum.MakeEnum ( "Dog", "Cat", "Rabbit" )
---print( Enum.Animals.Cat ) -- prints "Cat"
---```
---@param ... ...
---@return table
function Enum.MakeEnum(...)
  return tInvert({...})
	-- 	for i = 1, #t do
	-- 		local v = t[i]
	-- 		--t[i] = nil
	-- 		t[v] = i
	-- end
	-- return t
end

-- Returns an unumerated table from an existing table.
---## Example
---```
---Fish = { "Loach", "Pike", "Herring" }
---Enum.Fish = Enum.MakeEnumFromTable(Fish)
---print(Enum.Fish.Herring) -- prints "Herring"
---```
function Enum.MakeEnumFromTable(t)
    return tInvert(t)
end

-- Returns a table `t` of self-indexed values
-- ## Example
-- ```lua
-- t = dict( "foo", "bar")
-- print(t.foo)  -- prints the string "foo"
-- ```
---@param tbl table
---@return table
function Enum.MakeDict(tbl)
	local t = {};
	for k, v in ipairs(tbl) do
		t[v] = v;
	end
	return t;
end

-- Returns a copy of `list` with `keys` and `values` inverted
-- ## Example
---```
---t = { "foo" = 1, "bar" = 2};
---s = tinvert(t);
---print(t.foo); -- prints the number 1
---print(s[1]); -- prints the string "foo";
---```
---@param tbl table
---@return table out
function table.invert(tbl)
  local out = {}
  for k, v in pairs(tbl) do
    out[v] = k
  end
  return out
end

local Default, Nil = {}, function () end -- for uniqueness
---@param case any
---@return any
-- Implements a `switch` statement in Lua.
-- ## Example
-- ```
-- switch(case) = {
--     [1] = function() print("one") end,
--     [2] = print,
--     [3] = math.sin,
--     default = function() print("default") end,
-- }
-- ```
function switch (case)
  return setmetatable({ case }, {
    __call = function (t, cases)
      local item = #t == 0 and Nil or t[1]
      return (cases[item] or cases[Default] or Nil)
    end
  })
end

-- Prints debuggin information using a formatted version of its variable
-- number of arguments following the description given in its first argument.
---
---[View documents](command:extension.lua.doc?["en-us/51/manual.html/pdf-string.format"])
---@param s any
---@param ... any
function printf(s, ...)
  print("   ",SMARTBUFF_TITLE,"::",string.format(s, ...))
end

-- Prints debug information to `stdout`. Receives any number of arguments,
-- converting each argument to a string following the same rules of
-- [tostring](command:extension.lua.doc?["en-us/51/manual.html/pdf-tostring"]).
---
--- [View documents](command:extension.lua.doc?["en-us/51/manual.html/pdf-print"])
---
function printd(...)
	print("   ",SMARTBUFF_TITLE,"::",...)
end

--- Prints the value of any global variable, table value, frame, function result, or any valid Lua expression. Output is color coded for easier reading. Tables display up to 30 values, the rest are skipped and a message is shown.
---@param t any
---@param startkey? any
function dump(t, startkey)
  DevTools_Dump(t, startkey)
end

---Add slash commands.
---## Example
---The following snippets do the same thing.
---```
---SlashCmdList_AddSlashCommand('MYADDON_SLASHCMD', function(msg)
---  DEFAULT_CHAT_FRAME:AddMessage(msg or 'nil')
---end, 'myaddon', 'ma')
---```
---and
---```
---SlashCmdList['MYADDON_SLASHCMD'] = function(msg)
---  DEFAULT_CHAT_FRAME:AddMessage(msg or 'nil')
---end
---SLASH_MYADDON_SLASHCMD1 = '/myaddon'
---SLASH_MYADDON_SLASHCMD2 = '/ma'
---```
---## Code
---```
---function SlashCmdList_AddSlashCommand(name, func, ...)
---  SlashCmdList[name] = func
---  local command = ''
---  for i = 1, select('#', ...) do
---      command = select(i, ...)
---      if strsub(command, 1, 1) ~= '/' then
---          command = '/' .. command
---      end
---      _G['SLASH_'..name..i] = command
---  end
---end
---```
---@param name string Unique identifier (e.g. MYADDON_SLASHCMD)
---@param func function The function (variable or actual function)
---@param ... any A list of commands with or without the leading slash
function SlashCmdList_AddSlashCommand(name, func, ...)
  SlashCmdList[name] = func
  local command = ''
  for i = 1, select('#', ...) do
      command = select(i, ...)
      if string.sub(command, 1, 1) ~= '/' then
          command = '/' .. command
      end
      _G['SLASH_'..name..i] = command
  end
end

-- Lua may not consider `""` and `0` to be `false` in condition tests, but I do.
---@param value any
---@return boolean
function truthy(value)
  return (value and value ~= 0 and value ~= "")
end

---Return an actually useful `tostring` value
---@param s any
---@return string
function truthytostring(s)
  if type(s) == "boolean" then return (s and "true" or "false")
  elseif type(s) == "nil" then return "<nil>"
  elseif s == "" then return '"<empty>"'
  elseif type(s) == "string" then return '"'..s..'"'
  elseif type(s) == "number" then return s.."."
  elseif type(s) == "table" then dump(s) end
  return s
end