-------------------------------------------------------------------------------
-- SmartBuff
-- Originally created by Aeldra (EU-Proudmoore)
-- Retail version fixes / improvements by Codermik
-- Discord: https://discord.gg/R6EkZ94TKK
-- Cast the most important buffs on you, tanks or party/raid members/pets.

---@module "SmarBuff.globals.lua"
---@module "SmartBuff.buffs.lua"
---@module "Libs/Broker_SmartBuff/Broker_SmartBuff.lua"
---@module "SmartBuff.xml"

SMARTBUFF_DATE = "23-01-09";

SMARTBUFF_VERSION       = "r16alpha." .. SMARTBUFF_DATE;
SMARTBUFF_VERSIONNR     = 100002;
SMARTBUFF_TITLE         = "SmartBuff";
SMARTBUFF_SUBTITLE      = "Supports you in casting buffs";
SMARTBUFF_DESC          = "Cast the most important buffs on you, your tanks, party/raid members/pets";
SMARTBUFF_VERS_TITLE    = SMARTBUFF_TITLE .. " " .. SMARTBUFF_VERSION;
SMARTBUFF_OPTIONS_TITLE = SMARTBUFF_VERS_TITLE .. " Retail ";

-- addon name
local SmartbuffPrefix = "Smartbuff";
local SmartbuffSession = true;
local SmartbuffVerCheck = false; -- for my use when checking guild users/testers versions  :)
local buildInfo = select(4, GetBuildInfo())
local SmartbuffRevision = 14;
local SmartbuffVerNotifyList = {}

S = SMARTBUFF_GLOBALS;
local OG = nil; -- Options global
local O  = nil; -- Options local

---@type {[string]: any, [Templates]: any, [integer]: BuffInfo}
local B  = nil; -- Buff settings local
local _;

BINDING_HEADER_SMARTBUFF = "SmartBuff";
SMARTBUFF_BOOK_TYPE_SPELL = "spell";

SMARTBUFF_GC_SPELLID = 61304
local gcSeconds = tonumber( (select(2, GetSpellBaseCooldown(SMARTBUFF_GC_SPELLID))) )/1000; ---@type number
local MaxSkipCoolDown = 3;
local MaxRaid = 40;
local MaxBuffs = 40;
local MaxScrollButtons = 30;

local IsLoaded = false;
local IsPlayer = false;
local SmartBuff_Initialized = false;
local IsCombat = false;
local BuffsResetting = false;
local IsSetZone = false;
local IsFirstError = false;
local IsCTRA = true;
local IsSetUnits = false;
local IsKeyUpChanged = false;
local IsKeyDownChanged = false;
local IsAuraChanged = false;
local IsClearSplash = false;
local IsRebinding = false;
local IsParrot = false;
local IsSync = false;
local IsSyncReq = false;
local SmartBuff_ActionButtionInitialized = false;

local TimeStartZone = 0;
local TimeTicker = 0;
local TimeSync = 0;

local RealmName = nil;
local PlayerName = nil;
local PlayerID = nil;
local PlayerClass = nil;
local TimeLastChecked = 0;
local GroupSetup = -1;
local LastBuffSetup = -1;
local LastTexture = "";
local LastGroupSetup = -99;
local LastZone = "";
local TimeAutoBuff = 0;
local TimeDebuff = 0;
local MsgWarning = "";
local CurrentFont = 1;
local CurrentList = -1;
local LastPlayer = -1;

local IsPlayerMoving = false;

local Groups = {};
local ClassGroups = {};

---@alias BuffID integer

---table of buffs indexed by buffID
---@type {[BuffID]: BuffInfo}
local Buffs = {};

---list of active buffIDs
---@type BuffID[]
local BuffIndex = {};

local BuffTimer = {};
local Blacklist = {};
local Units = {};

---@class CombatBuff
---@field Unit Unit "player"
---@field Type Type
---@field ActionType ActionType

---@type {[SpellID]: CombatBuff}
local CombatBuffs = {};

local ScrBtnBO = nil;

local AddUnitList = {};
local IgnoreUnitList = {};

---@alias WeaponTypes "Daggers"|"Axes"|"Swords"|"Maces"|"Staves"|"Fist Weapons"|"Polearms"|"Thrown"|"Crossbows"|"Bows"

---@enum Enum.Class
Enum.Class     = { "DRUID", "HUNTER", "MAGE", "PALADIN", "PRIEST", "ROGUE", "SHAMAN", "WARLOCK", "WARRIOR", "DEATHKNIGHT", "MONK", "DEMONHUNTER", "EVOKER", "HPET", "WPET", "DKPET", "TANK", "HEALER", "DAMAGER" };
---@enum Enum.GroupOrder
Enum.GroupOrder  = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 };
---@enum Enum.Font
Enum.Font       = { "NumberFontNormal", "NumberFontNormalLarge", "NumberFontNormalHuge", "GameFontNormal", "GameFontNormalLarge", "GameFontNormalHuge", "ChatFontNormal", "QuestFont", "MailTextFontNormal", "QuestTitleFont" };

---@type string
local CurrentUnit = nil;
---@type integer
local CurrentSpell = nil;
---@type Templates
local CurrentTemplate = nil;
---@type integer
local CurrentSpec = nil;

local ImgSB       = "Interface\\Icons\\Spell_Nature_Purge";
local ImgIconOn   = "Interface\\AddOns\\SmartBuff\\Icons\\MiniMapButtonEnabled";
local ImgIconOff  = "Interface\\AddOns\\SmartBuff\\Icons\\MiniMapButtonDisabled";

local IconPaths = {
  ["Pet"]         = "Interface\\Icons\\spell_nature_spiritwolf",
  ["Roles"]       = "Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES",
  ["Classes"]     = "Interface\\WorldStateFrame\\Icons-Classes",
};

local Icons = {
  ["WARRIOR"]     = { IconPaths.Classes, 0.00, 0.25, 0.00, 0.25 },
  ["MAGE"]        = { IconPaths.Classes, 0.25, 0.50, 0.00, 0.25 },
  ["ROGUE"]       = { IconPaths.Classes, 0.50, 0.75, 0.00, 0.25 },
  ["DRUID"]       = { IconPaths.Classes, 0.75, 1.00, 0.00, 0.25 },
  ["HUNTER"]      = { IconPaths.Classes, 0.00, 0.25, 0.25, 0.50 },
  ["SHAMAN"]      = { IconPaths.Classes, 0.25, 0.50, 0.25, 0.50 },
  ["PRIEST"]      = { IconPaths.Classes, 0.50, 0.75, 0.25, 0.50 },
  ["WARLOCK"]     = { IconPaths.Classes, 0.75, 1.00, 0.25, 0.50 },
  ["PALADIN"]     = { IconPaths.Classes, 0.00, 0.25, 0.50, 0.75 },
  ["DEATHKNIGHT"] = { IconPaths.Classes, 0.25, 0.50, 0.50, 0.75 },
  ["MONK"]        = { IconPaths.Classes, 0.50, 0.75, 0.50, 0.75 },
  ["DEMONHUNTER"] = { IconPaths.Classes, 0.75, 1.00, 0.50, 0.75 },
  ["EVOKER"]      = { IconPaths.Classes, 0.75, 1.00, 0.50, 0.75 },
  ["PET"]         = { IconPaths.Pet, 0.08, 0.92, 0.08, 0.92 },
  ["TANK"]        = { IconPaths.Roles, 0.0, 19 / 64, 22 / 64, 41 / 64 },
  ["HEALER"]      = { IconPaths.Roles, 20 / 64, 39 / 64, 1 / 64, 20 / 64 },
  ["DAMAGER"]     = { IconPaths.Roles, 20 / 64, 39 / 64, 22 / 64, 41 / 64 },
  ["NONE"]        = { IconPaths.Roles, 20 / 64, 39 / 64, 22 / 64, 41 / 64 },
};

-- available sounds (25)
local Sounds = { 1141, 3784, 4574, 17318, 15262, 13830, 15273, 10042, 10720, 17316, 3337, 7894, 7914, 10033, 416, 57207,
  78626, 49432, 10571, 58194, 21970, 17339, 84261, 43765 }

local DebugChatFrame = DEFAULT_CHAT_FRAME;

-- Popup
StaticPopupDialogs["SMARTBUFF_DATA_PURGE"] = {
  text = SMARTBUFF_OFT_PURGE_DATA,
  button1 = SMARTBUFF_OFT_YES,
  button2 = SMARTBUFF_OFT_NO,
  OnAccept = function() SMARTBUFF_ResetAll() end,
  timeout = 0,
  whileDead = 1,
  hideOnEscape = 1
}

-- Rounds a number to the given number of decimal places.
local r_mult;
local function Round(num, idp)
  r_mult = 10 ^ (idp or 0);
  return math.floor(num * r_mult + 0.5) / r_mult;
end

-- Returns a chat color code string
local function BCC(r, g, b)
  return string.format("|cff%02x%02x%02x", (r * 255), (g * 255), (b * 255));
end

local BL  = BCC(0, 0, 1);
local BLD = BCC(0, 0, 0.7);
local BLL = BCC(0.5, 0.8, 1);
local GR  = BCC(0, 1, 0);
local GRD = BCC(0, 0.7, 0);
local GRL = BCC(0.6, 1, 0.6);
local RD  = BCC(1, 0, 0);
local RDD = BCC(0.7, 0, 0);
local RDL = BCC(1, 0.3, 0.3);
local YL  = BCC(1, 1, 0);
local YLD = BCC(0.7, 0.7, 0);
local YLL = BCC(1, 1, 0.5);
local OR  = BCC(1, 0.7, 0);
local ORD = BCC(0.7, 0.5, 0);
local ORL = BCC(1, 0.6, 0.3);
local WH  = BCC(1, 1, 1);
local CY  = BCC(0.5, 1, 1);

---@enum Enum.GroupType
Enum.GroupType = {
  Solo = 1,
  Party = 2,
  LFR = 3,
  Raid = 4,
  Mythic_Keystone = 5,
  Battleground = 6,
  Arena = 7,
  VoTI = 8,
  Custom1 = 9,
  Custom2 = 10,
  Custom3 = 11,
  Custom4 = 12,
  Custom5 = 13
}

---@enum Enum.Difficulty
Enum.Difficulty = {
  Dungeon_Normal = 1,
  Dungeon_Heroic = 2,
  Raid_Normal_10 = 3,
  Raid_Normal_25 = 4,
  Raid_Heroic_10 = 5,
  Raid_Heroic_25 = 6,
  LFR = 7,
  Mythic_Keystone = 8,
  Raid_Normal_40 = 9,
  Scenario_Heroic = 11,
  Scenario_Normal = 12,
  Raid_Normal_Flex = 14,
  Raid_Heroic_Flex = 15,
  Raid_Mythic = 16,
  LookingForRaid = 17,
  Event_Raid = 18,
  Event_Party = 19,
  Event_Scenario = 20,
  Dungeon_Mythic = 23,
  Dungeon_Timewalking = 24,
  Scenario_WorldPVP = 25,
  Scenario_PvEvP = 29,
  Scenario_Event2 = 30,
  Scenario_WorldPvp = 32,
  Raid_Timewalking = 33
}

---@enum Enum.Result
Enum.Result = {
  SUCCESS = 0,
  ON_COOLDOWN = 1,
  INVALID_TARGET = 2,
  OUT_OF_RANGE = 3,
  EXTENDED_COOLDOWN = 4,
  TARGET_MINLEVEL = 5,
  OUT_OF_MANA = 6,
  ALREADY_ACTIVE = 7,
  NO_ACTION_SLOT = 8,
  NO_SUCH_SPELL = 9,
  CANNOT_BUFF_TARGET = 10,
  ITEM_NOT_FOUND = 20,
  CANNOT_BUFF_WEAPON = 50
}
-- Enum.Result = tInvert(Enum.Result) -- reverse lookup

---@enum Enum.State
Enum.State = {
  STATE_START_BUFF = 0, -- casting next buff
  STATE_REBUFF_CHECK = 1, -- checking for needed buffs
  STATE_UI_BUSY = 2, -- spash screen is open
  STATE_END_BUFF = 5, -- next buff cast
  -- reverse lookup
  [0] = "STATE_START_BUFF",
  [1] = "STATE_REBUFF_CHECK",
  [2] = "STATE_UI_BUSY",
  [5] = "STATE_END_BUFF"
}

----------------------------------------
-- function to preview selected warning sound in options screen
function SMARTBUFF_PlaySpashSound()
  PlaySound(Sounds[O.AutoSoundSelection]);
end

-- Reorders values in the table
---@param t table
---@param i any
---@param n integer
function table.reorder(t, i, n)
  if (t and type(t) == "table" and t[i]) then
    local s = t[i];
    table.remove(t, i);
    if (i + n < 1) then
      table.insert(t, 1, s);
    elseif (i + n > #t) then
      table.insert(t, s);
    else
      table.insert(t, i + n, s);
    end
  end
end

-- Finds `value` in `table` and returns the `key`
---@param t table
---@param s any
---@return integer|false
function table.find(t, s)
  if (t and type(t) == "table" and s) then
    for k, v in pairs(t) do
      if (v and v == s) then
        return k;
      end
    end
  end
  return false;
end

-- Replace `Nil` pointers with empty strings
---@param text string
---@return string|""
function string.check(text)
  return text or "";
end

---true if item found in bags
---@param buff BuffInfo
---@return boolean
local function IsItemInBags(buff)
  return select(3, SMARTBUFF_FindItemInfo(buff.BuffID, buff.Chain));
end

---Returns hyperlink from `spell ID`
---@param spell Spell
---@return string hyperlink
---@overload fun(spell:Spell):nil
local function SpellToLink(spell)
    return GetSpellLink(spell)
end

---Returns hyperlink from `item ID`
---@param item Item
---@return string hyperlink
---@overload fun(item:Item):nil
local function ItemToLink(item)
  if not GetSpellLink(item) then
    return select(2, GetItemInfo(item))
  end
end

---@param buff BuffInfo
---@return string hyperlink
local function BuffToLink(buff)
  return buff.HyperLink;
end

---return hyperlink of item or spell from `ID`
---@param id integer
---@return string hyperlink
local function IDToLink(id)
---@diagnostic disable-next-line: return-type-mismatch
    return SpellToLink(id) or ItemToLink(id)
end

---Returns name from `spell ID`
---@param spell Spell
---@return string name
---@overload fun(spell:Spell):nil
local function SpellToName(spell)
    return select(1, GetSpellInfo(spell))
end

---Returns name from `item ID`
---@param item Item
---@return string hyperlink
---@overload fun(item:Item):nil
local function ItemToName(item)
  if not GetSpellLink(item) then
    return select(1, GetItemInfo(item))
  end
end

---@param buff BuffInfo
---@return string hyperlink
local function BuffToName(buff)
  return buff.Name;
end

---return hyperlink of item or spell from `ID`
---@param id integer
---@return string hyperlink
---@overload fun(id:integer):nil
local function IDToName(id)
    return select(1, GetSpellInfo(id)) or select(1, GetItemInfo(id))
end

--is UI element visible to player?
local function IsVisibleToPlayer(self)
  if self then
    local w, h = UIParent:GetWidth(), UIParent:GetHeight();
    local x, y = self:GetLeft(), UIParent:GetHeight() - self:GetTop();
    --print(string.format("w = %.0f, h = %.0f, x = %.0f, y = %.0f", w, h, x, y));
    if (x >= 0 and x < (w - self:GetWidth()) and y >= 0 and y < (h - self:GetHeight())) then
      return true;
    end
  end
  return false;
end

-- return current specialization
---@return integer
local function CS()
  if (CurrentSpec == nil) then
    CurrentSpec = GetSpecialization();
  end
  if (CurrentSpec == nil) then
    CurrentSpec = 1;
    SMARTBUFF_AddMsgErr("Could not detect active talent group, set to default = 1");
  end
  return CurrentSpec;
end

-- return current buff template
---@return string
local function CT()
  return CurrentTemplate;
end

---@param buffID BuffID
---@return BuffTemplate
local function GetBuffTemplate(buffID)
  if (B and buffID) then
    return B[CS()][CT()][buffID];
  end
  return {};
end

---Initialize buff settings
---@param buff BuffInfo
---@param reset? boolean whether to reset
local function InitBuffTemplate(buff, reset)
  --- user's buff settings by specialization/smartgroup
  local template = GetBuffTemplate(buff.BuffID); ---@type BuffTemplate
  if (template == nil) then
    B[CS()][CT()][buff.BuffID] = {};
    template = B[CS()][CT()][buff.BuffID];
    reset = true;
  end
  if (reset) then
    table.wipe(template);
    template.BuffEnabled = false;
    template.EnableGroup = false;
    template.BuffSelfOnly = false;
    template.BuffSelfNot = false;
    template.BuffInCombat = false;
    template.BuffOutOfCombat = true;
    template.BuffMainHand = true; -- default to selected
    template.BuffOffHand = false;
    template.BuffRightHand = false;
    template.BuffReminder = true;
    template.RebuffTime = 0;
    template.ManaLimit = 0;
    if (buff.Type == SMARTBUFF_CONST_GROUP or buff.Type == SMARTBUFF_CONST_ITEMGROUP) then
      for i in pairs(Enum.Class) do
        --- init class arrays for any pet or role paramaters found
        template[Enum.Class[i]] = string.find(buff.Params, Enum.Class[i]);
      end
    end
  end
  -- Upgrades
  if (template.RebuffTime == 0) then
    template.BuffReminder = true;
  end -- to 1.10g
  if (template.ManaLimit == nil) then template.ManaLimit = 0; end -- to 1.12b
  if (template.BuffSelfNot == nil) then template.BuffSelfNot = false; end -- to 2.0i
  if (template.AddList == nil) then template.AddList = {}; end -- to 2.1a
  if (template.IgnoreList == nil) then template.IgnoreList = {}; end -- to 2.1a
  if (template.BuffRightHand == nil) then template.BuffRightHand = false; end -- to 4.0b

end

---initialize the buff order
---@param reset? boolean
local function InitBuffOrder(reset)
  if (B[CS()].Order == nil) then
    B[CS()].Order = {};
  end

  local ord = B[CS()].Order;
  if (reset) then
    table.wipe(ord);
    SMARTBUFF_AddMsgD("Reset buff order");
  end

  for k, v in pairs(ord) do
    if (v and BuffIndex[v] == nil) then
      SMARTBUFF_AddMsgD("Remove from buff order: " .. v);
      table.remove(ord, k);
    end
  end

  for i = 1, #Buffs do
    --print(i, BuffToString(Buffs[i]))
    local found = false;
    for _, v in pairs(ord) do
      if (v == Buffs[i].BuffID) then
        found = true;
        break;
      end
    end
    -- buff not found add it to order list
    if (not found) then
      table.insert(ord, Buffs[i].BuffID);
      SMARTBUFF_AddMsgD("Add to buff order: " .. BuffToLink(Buffs[i]));
    end
  end
end

---Return true if player's level equals or exceeds the minimum level for this buff
---@param buff BuffInfo
---@return boolean
---@return integer? itemMinLevel
local function IsItemMinLevel(buff)
  local _, _, _, _, itemMinLevel = GetItemInfo(buff.BuffID);
  if itemMinLevel and (itemMinLevel > UnitLevel("player")) then
    return false, itemMinLevel;
  end
  return true;
end

local function SendSmartbuffVersion(player, unit)
  -- if ive announced to this player / the player is me then just return.
  if player == UnitName("player") then return end
  for count, value in ipairs(SmartbuffVerNotifyList) do
    if value[1] == player then return end
  end
  -- not announced, add the player and announce.
  table.insert(SmartbuffVerNotifyList, { player, unit, GetTime() })
  C_ChatInfo.SendAddonMessage(SmartbuffPrefix, tostring(SmartbuffRevision), "WHISPER", player)
  SMARTBUFF_AddMsgD(string.format("%s was sent version instring.formation.", player))
end

local function IsTalentSkilled(t, i, name)
  local _, texture, _, _, tAvailable = GetTalentInfo(t, i);
  if (texture) then
    SMARTBUFF_AddMsgD("Talent: " .. texture .. ", Points = " .. tAvailable);
    if (name and name == texture and tAvailable > 0) then
      SMARTBUFF_AddMsgD("Debuff talent found: " .. name .. ", Points = " .. tAvailable);
      return true, tAvailable;
    end
  else
    SMARTBUFF_AddMsgD("Talent tree not available!");
  end
  return false, 0;
end

-- SMARTBUFF_OnLoad
function SMARTBUFF_OnLoad(self)
  self:RegisterEvent("ADDON_LOADED");
  self:RegisterEvent("PLAYER_LOGIN"); -- added
  self:RegisterEvent("PLAYER_ENTERING_WORLD");
  self:RegisterEvent("UNIT_NAME_UPDATE");
  self:RegisterEvent("GROUP_ROSTER_UPDATE");
  self:RegisterEvent("PLAYER_REGEN_ENABLED"); -- combat end
  self:RegisterEvent("PLAYER_REGEN_DISABLED"); -- combat start
  self:RegisterEvent("PLAYER_STARTED_MOVING"); -- added
  self:RegisterEvent("PLAYER_STOPPED_MOVING"); -- added
  self:RegisterEvent("PLAYER_TALENT_UPDATE");
  self:RegisterEvent("SPELLS_CHANGED");
  self:RegisterEvent("ACTIONBAR_HIDEGRID");
  self:RegisterEvent("UNIT_AURA");
  self:RegisterEvent("CHAT_MSG_ADDON");
  self:RegisterEvent("CHAT_MSG_CHANNEL");
  self:RegisterEvent("UPDATE_MOUSEOVER_UNIT");
  self:RegisterEvent("UNIT_SPELLCAST_FAILED");
  self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED");

  --One of them allows SmartBuff to be closed with the Escape key
  table.insert(UISpecialFrames, "SmartBuffOptionsFrame");
  UIPanelWindows["SmartBuffOptionsFrame"] = nil;

  SlashCmdList["SMARTBUFF"] = SMARTBUFF_command;
  SLASH_SMARTBUFF1 = "/sbo";
  SLASH_SMARTBUFF2 = "/sbuff";
  SLASH_SMARTBUFF3 = "/smartbuff";
  SLASH_SMARTBUFF3 = "/sb";

  SlashCmdList["SMARTBUFFMENU"] = SMARTBUFF_OptionsFrame_Toggle;
  SLASH_SMARTBUFFMENU1 = "/sbm";

  SlashCmdList["SmartReloadUI"] = function(msg) ReloadUI(); end;
  SLASH_SmartReloadUI1 = "/rui";

  SMARTBUFF_InitSpellIDs();

  SMARTBUFF_AddMsgD("SB OnLoad");
end
-- END SMARTBUFF_OnLoad

-- SMARTBUFF_OnEvent

---@param self table
---@param event string
---@param arg1 any
---@param arg2 any
---@param arg3 any
---@param arg4 any
---@param arg5 any
function SMARTBUFF_OnEvent(self, event, arg1, arg2, arg3, arg4, arg5)

  if ((event == "UNIT_NAME_UPDATE" and arg1 == "player") or event == "PLAYER_ENTERING_WORLD") then
    if IsInGuild() and event == "PLAYER_ENTERING_WORLD" then
      C_ChatInfo.SendAddonMessage(SmartbuffPrefix, tostring(SmartbuffRevision), "GUILD")
    end
    IsPlayer = true;
    if (event == "PLAYER_ENTERING_WORLD" and SmartBuff_Initialized and O.SmartBuff_Enabled) then
      IsSetZone = true;
      TimeStartZone = GetTime();
      --    elseif (event == "PLAYER_ENTERING_WORLD" and IsLoaded and IsPlayer and not IsInit and not InCombatLockdown()) then
      --        SMARTBUFF_Options_Init(self);
    end

  elseif (event == "ADDON_LOADED" and arg1 == SMARTBUFF_TITLE) then
    IsLoaded = true;
  end

  -- PLAYER_LOGIN
  if event == "PLAYER_LOGIN" then
    local _ = C_ChatInfo.RegisterAddonMessagePrefix(SmartbuffPrefix)
  end

  -- CHAT_MSG_ADDON
  if event == "CHAT_MSG_ADDON" then
    if arg1 == SmartbuffPrefix then
      -- its us.
      if arg2 then
        arg2 = tonumber(arg2)
        if arg2 > SmartbuffRevision and SmartbuffSession then
          DEFAULT_CHAT_FRAME:AddMessage(SMARTBUFF_MSG_NEWVER1 ..
            SMARTBUFF_VERSION .. SMARTBUFF_MSG_NEWVER2 .. arg2 .. SMARTBUFF_MSG_NEWVER3)
          SmartbuffSession = false
        end
        if arg5 and arg5 ~= UnitName("player") and SmartbuffVerCheck then
          DEFAULT_CHAT_FRAME:AddMessage("|cff00e0ffSmartbuff : |cffFFFF00" .. arg5 .. " (" .. arg3 .. ")|cffffffff has revision |cffFFFF00r" .. arg2 .. "|cffffffff installed.")
        end
      end
    end
  end

  if (event == "SMARTBUFF_UPDATE" and IsLoaded and IsPlayer and not SmartBuff_Initialized and not InCombatLockdown()) then
    SMARTBUFF_Options_Init(self);
    SMARTBUFF_AddMsgD(buildInfo)
  end

  if (not SmartBuff_Initialized or O == nil) then
    return;
  end

  if (event == "GROUP_ROSTER_UPDATE") then
    IsSetUnits = true;

    -- PLAYER ENTERED COMBAT
  elseif (event == "PLAYER_REGEN_DISABLED") then
    SMARTBUFF_Ticker(true);

    if (O.SmartBuff_Enabled) then
      if (O.InCombat) then
        for buffID, data in pairs(CombatBuffs) do
          if (data and data.Unit and data.ActionType) then
            if (data.Type == SMARTBUFF_CONST_SELF or data.Type == SMARTBUFF_CONST_FORCESELF or data.Type == SMARTBUFF_CONST_STANCE or data.Type == SMARTBUFF_CONST_CONJURE) then
              SmartBuff_KeyButton:SetAttribute("unit", nil);
            else
              SmartBuff_KeyButton:SetAttribute("unit", data.Unit);
            end
            SmartBuff_KeyButton:SetAttribute("type", data.ActionType);
            SmartBuff_KeyButton:SetAttribute("spell", SpellToLink(buffID));
            SmartBuff_KeyButton:SetAttribute("item", nil);
            SmartBuff_KeyButton:SetAttribute("target-slot", nil);
            SmartBuff_KeyButton:SetAttribute("target-item", nil);
            SmartBuff_KeyButton:SetAttribute("macrotext", nil);
            SmartBuff_KeyButton:SetAttribute("action", nil);
            SMARTBUFF_AddMsgD("Enter Combat, set button: " .. SpellToLink(buffID) .. " on " .. data.Unit .. ", " .. data.ActionType);
            break;
          end
        end
      end
      SMARTBUFF_SyncBuffTimers();
      SMARTBUFF_NextBuffCheck(Enum.State.STATE_REBUFF_CHECK, true);
    end

    -- PLAYER LEFT COMBAT
  elseif (event == "PLAYER_REGEN_ENABLED") then
    SMARTBUFF_Ticker(true);

    if (O.SmartBuff_Enabled) then
      if (O.InCombat) then
        SmartBuff_KeyButton:SetAttribute("type", nil);
        SmartBuff_KeyButton:SetAttribute("unit", nil);
        SmartBuff_KeyButton:SetAttribute("spell", nil);
      end
      SMARTBUFF_SyncBuffTimers();
      SMARTBUFF_NextBuffCheck(Enum.State.STATE_REBUFF_CHECK, true);
    end

    -- PLAYER_STARTED_MOVING / PLAYER_STOPPED_MOVING
  elseif (event == "PLAYER_STARTED_MOVING") then
    IsPlayerMoving = true;

  elseif (event == "PLAYER_STOPPED_MOVING") then
    IsPlayerMoving = false;

  elseif (event == "PLAYER_TALENT_UPDATE") then
    if (SmartBuffOptionsFrame:IsVisible()) then
      SmartBuffOptionsFrame:Hide();
    end
    if (CurrentSpec ~= GetSpecialization()) then
      CurrentSpec = GetSpecialization();
      if (B[CurrentSpec] == nil) then
        B[CurrentSpec] = {};
      end
      SMARTBUFF_AddMsg(string.format(SMARTBUFF_MSG_SPECCHANGED, tostring(CurrentSpec)), true);
      BuffsResetting = true;
    end

  elseif (event == "SPELLS_CHANGED" or event == "ACTIONBAR_HIDEGRID") then
    BuffsResetting = true;
  end

  if (not O.SmartBuff_Enabled) then
    return;
  end

  if (event == "UNIT_AURA") then

    if (UnitAffectingCombat("player") and (arg1 == "player" or string.find(arg1, "^party") or string.find(arg1, "^raid"))) then
      IsSyncReq = true;
    end

    -- checks if aspect of cheetah or pack is active and cancel it if someone gets dazed
    if (PlayerClass == "HUNTER" and O.AntiDaze and (arg1 == "player" or string.find(arg1, "^party") or string.find(arg1, "^raid") or string.find(arg1, "pet"))) then
      local _, _, stuntex = GetSpellInfo(1604); --get Dazed icon
      if (SMARTBUFF_IsDebuffTexture(arg1, stuntex)) then
        local buff;
        if (arg1 == "player" and C_UnitAuras.GetAuraDataByAuraInstanceID(arg1, SMARTBUFF_ASPECTOFTHECHEETAH)) then
          buff = SMARTBUFF_ASPECTOFTHECHEETAH;
        end
        if (buff) then
          if (O.ToggleReminderSplash and not SmartBuffOptionsFrame:IsVisible()) then
            SmartBuffSplashFrame:Clear();
            SmartBuffSplashFrame:SetTimeVisible(1);
            SmartBuffSplashFrame:AddMessage("!!! CANCEL " .. IDToLink(buff) .. " !!!", O.ColSplashFont.r, O.ColSplashFont.g,
              O.ColSplashFont.b, 1.0);
          end
          if (O.ToggleReminderChat) then
            SMARTBUFF_AddMsgWarn("!!! CANCEL " .. IDToLink(buff) .. " !!!", true);
          end
        end
      end
    end
  end

  if (event == "UI_ERROR_MESSAGE") then
    SMARTBUFF_AddMsgD(string.format("Error message: %s", arg1));
  end

  if (event == "UNIT_SPELLCAST_FAILED") then
    ---@type string|nil
    SMARTBUFF_AddMsgD(string.format("Spell failed: %s",arg1));
    if (CurrentUnit and (string.find(CurrentUnit, "party") or string.find(CurrentUnit, "raid") or (CurrentUnit == "target" and O.Debug))) then
      if (UnitName(CurrentUnit) ~= PlayerName and O.BlacklistTimer > 0) then
        Blacklist[CurrentUnit] = GetTime();
        if (CurrentUnit and UnitName(CurrentUnit)) then
        end
      end
    end
    CurrentUnit = nil;

  elseif (event == "UNIT_SPELLCAST_SUCCEEDED") then
    if (arg1 and arg1 == "player") then
      local unit = nil;
      local spell = nil;
      local target = nil;

      if (arg1 and arg2) then
        if (not arg3) then arg3 = ""; end
        if (not arg4) then arg4 = ""; end
        SMARTBUFF_AddMsgD("Spellcast succeeded: target " ..
          arg1 .. ", spell ID " .. arg3 .. " (" .. SpellToLink(arg3) .. "), " .. arg4)
        if (string.find(arg1, "party") or string.find(arg1, "raid")) then
          spell = arg2;
        end
        --SMARTBUFF_SetButtonTexture(SmartBuff_KeyButton, ImgSB);
      end

      if (CurrentUnit and CurrentSpell and CurrentUnit ~= "target") then
        unit = CurrentUnit;
        spell = CurrentSpell;
      end

      if (unit) then
        local name = UnitName(unit);
        if (BuffTimer[unit] == nil) then
          BuffTimer[unit] = {};
        end
        BuffTimer[unit][spell] = GetTime();
        if (name ~= nil) then
          SMARTBUFF_AddMsg(name .. ": " .. IDToLink(spell) .. " " .. SMARTBUFF_MSG_BUFFED);
          CurrentUnit = nil;
          CurrentSpell = nil;
        end
      end

      if (IsClearSplash) then
        IsClearSplash = false;
        SMARTBUFF_Splash_Clear();
      end
    end
  end
end
-- END SMARTBUFF_OnEvent

---@param self table
---@param elapsed integer
function SMARTBUFF_OnUpdate(self, elapsed)
  if not self.Elapsed then
    self.Elapsed = 0.2
  end
  self.Elapsed = self.Elapsed - elapsed
  if self.Elapsed > 0 then
    return
  end
  self.Elapsed = 0.2

  if (not SmartBuff_Initialized) then
    if (IsLoaded and GetTime() > TimeAutoBuff + 0.5) then
      TimeAutoBuff = GetTime();
      local specID = GetSpecialization()
      if (specID) then
        SMARTBUFF_OnEvent(self, "SMARTBUFF_UPDATE");
      end
    end
  else
    if (IsSetZone and GetTime() > (TimeStartZone + 4)) then
      SMARTBUFF_CheckLocation();
    end
    SMARTBUFF_Ticker();
    SMARTBUFF_NextBuffCheck(Enum.State.STATE_REBUFF_CHECK);
  end
end

---@param force? boolean
function SMARTBUFF_Ticker(force)
  if (force or GetTime() > TimeTicker + 1) then
    TimeTicker = GetTime();

    if (IsSetUnits) then
      IsSetUnits = false;
      SMARTBUFF_SetUnits();
      Req = true;
    end

    if (IsSyncReq or TimeTicker > TimeSync + 10) then
      SMARTBUFF_SyncBuffTimers();
    end

    if (IsAuraChanged) then
      IsAuraChanged = false;
      SMARTBUFF_NextBuffCheck(Enum.State.STATE_REBUFF_CHECK, true);
    end

  end
end

-- Will dump the value of msg to the default chat window
---@param force? boolean override toggle message setting
function SMARTBUFF_AddMsg(msg, force)
  if (DEFAULT_CHAT_FRAME and (force or not O.ToggleMsgNormal)) then
    DEFAULT_CHAT_FRAME:AddMessage(YLL .. msg .. "|r");
  end
end

---Prints an error message to the defaut chat frame
---@param force? boolean override toggle errors setting
function SMARTBUFF_AddMsgErr(msg, force)
  if (DEFAULT_CHAT_FRAME and (force or not O.ToggleMsgError)) then
    DEFAULT_CHAT_FRAME:AddMessage(RDL .. SMARTBUFF_TITLE .. ": " .. msg .. "|r");
  end
end

---Prints a warning message to the default chat frame
---@param force? boolean override toggle warning setting
function SMARTBUFF_AddMsgWarn(msg, force)
  if (DEFAULT_CHAT_FRAME and (force or not O.ToggleMsgWarning)) then
    if (IsParrot) then
      Parrot:ShowMessage(CY .. msg .. "|r");
    else
      DEFAULT_CHAT_FRAME:AddMessage(CY .. msg .. "|r");
    end
  end
end

---Prints a debug message to the debug chat frame
---@param msg string
---@param r? integer red
---@param g? integer green
---@param b? integer blue
function SMARTBUFF_AddMsgD(msg, r, g, b)
  if (r == nil) then r = 0.5; end
  if (g == nil) then g = 0.8; end
  if (b == nil) then b = 1; end
  if (DebugChatFrame and O and O.Debug) then
    DebugChatFrame:AddMessage(msg, r, g, b);
  end
end

--instantiate group and instance handling
function SMARTBUFF_SetUnits()
  --GroupType = dict { "Solo", "Party", "LFR", "Raid", "MythicKeystone", "Battleground", "Arena", "VoTI", "Custom1", "Custom2", "Custom3", "Custom4", "Custom5" };

  --Difficulty = enum { "NormalDungeon","HeroicDungeon", "Raid10", "Raid25", "HeroicRaid10", "HeroicPlayer25", "LFR", "MythicKeystone", "Raid40Player", "", "HeroicScenario", "NormalScenario", "", "NormalRaid", "HeroicRaid", "MythicRaid", "LookingForRaid", "EventRaid", "EventParty", "EventScenario", "", "", "MythicParty", "TimewalkingParty", "WorldPVPScenario", "", "", "", "PvEvPScenario", "EventScenario", "", "WorldPvpScenario", "TimewalkingRaid" };

  if (InCombatLockdown()) then
    IsSetUnits = true;
    return;
  end

  if (SmartBuffOptionsFrame:IsVisible()) then return; end

  if (SMARTBUFF_IsActiveBattlefield() > 0) then
    SMARTBUFF_CheckLocation();
  end

  local _, instanceType, difficulty, _, _, _, _, _, _, LfgDungeonID = GetInstanceInfo()

  ---@type Enum.GroupType
  local group = Enum.GroupType.Solo;

  if IsInRaid() then
    group = Enum.GroupType.Raid;
  elseif IsInGroup() then
    group = Enum.GroupType.Raid;
  end

  -- check instance instanceType (allows solo raid clearing, etc)
  if instanceType == "raid" then
    group = Enum.GroupType.Raid;
    if LfgDungeonID then
      group = Enum.GroupType.LFR;
    end
  elseif instanceType == "party" then
    group = Enum.GroupType.Party;
    if ( difficulty == Enum.Difficulty.Mythic_Keystone ) then
      group = Enum.GroupType.Mythic_Keystone;
    end
  end

  if (group ~= S.Group) then
    S.Group = group;
    table.wipe(Blacklist);
    table.wipe(BuffTimer);
    if (SMARTBUFF_TEMPLATES[group] == nil) then
      SMARTBUFF_SetBuffs();
    end
    local tmp = SMARTBUFF_TEMPLATES[group];
    if (SMARTBUFF_Options.AutoSwitchTemplate and CurrentTemplate ~= tmp and SMARTBUFF_IsActiveBattlefield() == 0) then
      SMARTBUFF_AddMsg(SMARTBUFF_OFT_AUTOSWITCHTMP .. ": " .. CurrentTemplate .. " -> " .. tmp);
      CurrentTemplate = tmp;
      SMARTBUFF_SetBuffs();
    end
    --SMARTBUFF_AddMsgD("Group instanceType changed");
  end

  table.wipe(Units);
  table.wipe(Groups);
  ClassGroups = nil;
  table.wipe(AddUnitList);
  table.wipe(IgnoreUnitList);
  -- Raid Setup
  if (group == Enum.GroupType.Raid) then
    ClassGroups = { };
    local raidUnit = nil;
    local foundPlayer = false;
    local j = 1;

    for n = 1, MaxRaid, 1 do
      local name, _, subgroup = GetRaidRosterInfo(n);
      if (name) then
        local server = nil;
        local i = string.find(name, "-", 1, true);
        if (i and i > 0) then
          server = string.sub(name, i + 1);
          name = string.sub(name, 1, i - 1);
          SMARTBUFF_AddMsgD(name .. ", " .. server);
        end
        raidUnit = "raid"..n;

        --SMARTBUFF_AddMsgD(name .. ", " .. raidUnit .. ", " .. UnitName(raidUnit));

        SMARTBUFF_AddUnitToClass("raid", n);
        SmartBuff_AddToUnitList(1, raidUnit, subgroup);
        SmartBuff_AddToUnitList(2, raidUnit, subgroup);

        if (SMARTBUFF_Options.ToggleGrp[subgroup]) then
          local s = "";
          if (name == UnitName(raidUnit)) then
            if (Groups[subgroup] == nil) then
              Groups[subgroup] = { };
            end
            if (name == UnitName("player") and not server) then foundPlayer = true; end
            Groups[subgroup][j] = raidUnit;
            j = j + 1;
          end
        end
        -- attempt to announce the addon version (if they have it)
        -- seems to be an issue with cross-realm, need to look at this later
        -- but in the meantime I am disabling it...  CM
--		if online then SendSmartbuffVersion(name, raidUnit) end
      end
    end --end for

    if not foundPlayer and (B[CS()][CurrentTemplate].SelfFirst) then
      SMARTBUFF_AddSoloSetup();
      --SMARTBUFF_AddMsgD("Player not in selected groups or buff self first");
    end

    SMARTBUFF_AddMsgD("Raid Unit-Setup finished");

  -- Party Setup
  elseif (group == Enum.GroupType.Party) then
    ClassGroups = { };
    if (SMARTBUFF_Buffs[CS()][CurrentTemplate].SelfFirst) then
      SMARTBUFF_AddSoloSetup();
      --SMARTBUFF_AddMsgD("Buff self first");
    end

    Groups[1] = { };
    Groups[1][0] = "player";
    SMARTBUFF_AddUnitToClass("player", 0);
    for j = 1, 4, 1 do
      Groups[1][j] = "party"..j;
      SMARTBUFF_AddUnitToClass("party", j);
      SmartBuff_AddToUnitList(1, "party"..j, 1);
      SmartBuff_AddToUnitList(2, "party"..j, 1);
	  local name, _, _, _, _, _, _, online, _, _ = GetRaidRosterInfo(j);
	  if name and online then SendSmartbuffVersion(name, "party") end
    end
    SMARTBUFF_AddMsgD("Party Unit-Setup finished");

  -- Solo Setup
  else
    SMARTBUFF_AddSoloSetup();
    SMARTBUFF_AddMsgD("Solo Unit-Setup finished");
  end

  --collectgarbage();
end

function SMARTBUFF_AddUnitToClass(unit, i)
  local u = unit;
  local up = "pet";
  if (unit ~= "player") then
    u = unit .. i;
    up = unit .. "pet" .. i;
  end
  if (UnitExists(u)) then
    if (not Units[1]) then
      Units[1] = {};
    end
    Units[1][i] = u;
    SMARTBUFF_AddMsgD("Unit added: " .. UnitName(u) .. ", " .. u);

    local _, class = UnitClass(u);
    if (class and not ClassGroups[class]) then
      ClassGroups[class] = {};
    end
    if (class) then
      ClassGroups[class][i] = u;
    end
  end
end

function SMARTBUFF_AddSoloSetup()
  Groups[0] = {};
  Groups[0][0] = "player";
  Units[0] = {};
  Units[0][0] = "player";
  if (PlayerClass == "HUNTER" or PlayerClass == "WARLOCK" or PlayerClass == "DEATHKNIGHT" or PlayerClass == "MAGE") then Groups
      [0][1] = "pet"; end

  if (B[CS()][CurrentTemplate] and B[CS()][CurrentTemplate].SelfFirst) then
    if (not ClassGroups) then
      ClassGroups = {};
    end
    ClassGroups[0] = {};
    ClassGroups[0][0] = "player";
  end
end
-- END SMARTBUFF_SetUnits

---@return boolean
local function IsPlayerAlchemist()
  local p1, p2 = GetProfessions()
  return (GetProfessionInfo(p1) == "Alchemy") or (GetProfessionInfo(p2) == "Alchemy")
end

--=Calculate potion duration multiplier
---@param type Type
---@return integer multiplier
local function AlchemyBonusMultiplier(type)
  if type == SMARTBUFF_CONST_POTION and IsPlayerAlchemist() then
    return 2
  end
  return 1
end

---check tracking skills
---@param id integer
---@return boolean
---@return integer? texture
local function IsTrackingKnown(id)
  for n = 1, C_Minimap.GetNumTrackingTypes() do
    local name, texture = C_Minimap.GetTrackingInfo(n);
    if (name == GetSpellInfo(id)) then
      return true, texture
    end
  end
  return false
end

-- check for duplicate keys in buff list
-- unclear if collision might occur in the future
-- if they become an issue, consider using unique table GUID as index
local function CheckForDuplicates()
  local buffs = {}
  local buffLists = {
    SMARTBUFF_BUFFLIST,SMARTBUFF_WEAPON,SMARTBUFF_RACIAL,SMARTBUFF_TRACKING,SMARTBUFF_POTION,SMARTBUFF_SCROLL,SMARTBUFF_FOOD
  }
  SMARTBUFF_AddMsgD("Checking for duplicate buff keys")
  for _, type in pairs(buffLists) do
    for _, buff in pairs(type) do
      local key = buff[1];
      local exists = buffs[key];
      if exists then
        SMARTBUFF_AddMsgWarn(string.format("SmartBuff warning: %s and %s use the same key (%d)", BuffToLink(buff), BuffToLink(exists), key));
      else
        buffs[key] = buff;
      end
    end
  end
end

-- Set the buff array
function SMARTBUFF_SetBuffs()
  if (B == nil) then return; end

  local n = 1;
  local ct = CurrentTemplate;

  if (B[CS()] == nil) then
    B[CS()] = {};
  end

  SMARTBUFF_InitItemList();
  SMARTBUFF_InitSpellList();

  if (B[CS()][ct] == nil) then
    B[CS()][ct] = {};
    B[CS()][ct].SelfFirst = false;
  end

  table.wipe(Buffs);
  table.wipe(BuffIndex);

  CheckForDuplicates()

  for _, buff in pairs(SMARTBUFF_BUFFLIST) do
    n = SMARTBUFF_SetBuff(buff, n, true);
  end

  for _, buff in pairs(SMARTBUFF_WEAPON) do
    n = SMARTBUFF_SetBuff(buff, n);
  end

  for _, buff in pairs(SMARTBUFF_RACIAL) do
    n = SMARTBUFF_SetBuff(buff, n);
  end

  for _, buff in pairs(SMARTBUFF_TRACKING) do
    n = SMARTBUFF_SetBuff(buff, n);
  end

  for _, buff in pairs(SMARTBUFF_POTION) do
    n = SMARTBUFF_SetBuff(buff, n);
  end

  for _, buff in pairs(SMARTBUFF_SCROLL) do
    n = SMARTBUFF_SetBuff(buff, n);
  end

  for _, buff in pairs(SMARTBUFF_FOOD) do
    n = SMARTBUFF_SetBuff(buff, n);
  end

  table.wipe(CombatBuffs);
  SMARTBUFF_SetInCombatBuffs();

  InitBuffOrder();

  BuffsResetting = false;
end

---add spell (if known) or item (if in bags) to the BuffIndex array
---@param buff table
---@param key integer key
---@param isClassAbility? boolean true if class ability
---@return integer key new key
-- refactoring notes
-- .BuffID =.BuffS
-- .Duration = DurationS
-- .MinLevel = LevelS
-- disturbingly, AuraID is *never* read from the table...
-- BuffN = ???
function SMARTBUFF_SetBuff(buff, key, isClassAbility)
  if (buff == nil or buff[1] == nil) then return key; end

  Buffs[key] = {};   ---@type BuffInfo[]
  local b = Buffs[key]; ---@type BuffInfo -- pointer into to Buffs:Buff table
  b.BuffID = buff[Enum.SpellList.BuffID]; -- itemID (IsItem()) or spell ID (for IsSpell())
  -- duration in secondsdouble potion duration for Alchemists
  -- b.Duration = buff[Enum.SpellList.Duration]; -- duration in seconds
  b.Type = buff[Enum.SpellList.Type];
  if SMARTBUFF_IsSpell(b.Type) then
    b.BuffName = GetSpellInfo(b.BuffID) ---@type string
    b.HyperLink = GetSpellLink(b.BuffID) ---@type string
    b.StartTime, b.Duration = GetSpellCooldown(b.BuffID) ---@type number
  else
    b.HyperLink, b.BuffName = GetItemInfo(b.BuffID) ---@type string
    b.StartTime, b.Duration = GetItemCooldown(b.BuffID) ---@type number
  end
  b.MinLevel = buff[Enum.SpellList.MinLevel]; -- FIXME: b.MinLevel is never used
  if isClassAbility then
    b.Params = (buff[Enum.SpellList.Params] or S.NIL); -- e.g."WARRIOR;HUNTER;ROGUE" or "HPET;WPET;DKPET"
  else
    b.AuraID = buff[Enum.SpellList.AuraID]; -- FIXME: b.AurauID is never used
  end
  b.Links = buff[Enum.SpellList.Links]; -- a table of buffs which would be overwritten by the current buff
  b.Chain = buff[Enum.SpellList.Chain];
  b.HasCharges = false;
  b.Duration = ceil((b.Duration * 60) * AlchemyBonusMultiplier(b.Type));
  b.ExpirationTime = b.StartTime + b.Duration ---@type number
  b.TimeLeft = math.max( 0, b.ExpirationTime - GetTime() ); ---@type number
  b.HasBuffExpired = false; ---@type boolean
  b.RebuffTime = 0; ---@type number
  b.BuffTime = 0; ---@type number

  -- item info
  b.HandType = Enum.InventoryType.EMPTY; ---@type Enum.InventorySlot
  b.Charges = -1; ---@type integer
  b.InventoryItemID = 0; ---@type Enum.InventorySlot
  b.InventorySlot = Enum.InventoryType.EMPTY; ---@type Enum.InventoryType
  --  check for required level, tracking abilities, spell knowledge and item presence
  if (b.Type == SMARTBUFF_CONST_TRACK and IsTrackingKnown(b.BuffID))
      or (SMARTBUFF_IsSpell(b.Type) and IsSpellKnownOrOverridesKnown(b.BuffID))
      or (SMARTBUFF_IsItem(b.Type) and IsItemInBags(b)) then

    -- get icon texture from AuraID (if any)
    b.Icon = GetSpellTexture(b.AuraID) or GetSpellTexture(b.BuffID)
    if SMARTBUFF_IsSpell(b.Type) then
      b.Icon = select(3, GetSpellInfo(b.BuffID))
    else
      b.Icon = select(10, GetItemInfo(b.BuffID))
    end

    -- currently unconditionally adding which is NOT RIGHT
    SMARTBUFF_AddMsgD("Add "..BuffToLink(b));
    BuffIndex[b.BuffID] = key;
    InitBuffTemplate(b);
    return key + 1;
  end
  -- buff check failed
  Buffs[key] = nil
  return key
end

function SMARTBUFF_SetInCombatBuffs()
  local ct = CurrentTemplate;
  if (ct == nil or B[CS()] == nil or B[CS()][ct] == nil) then
    return;
  end
  for buffID, data in pairs(B[CS()][ct]) do
    --SMARTBUFF_AddMsgD(name .. ", type = " .. type(data));
    if (
        type(data) == "table" and BuffIndex[buffID] and (B[CS()][ct][buffID].IsEnabled or B[CS()][ct][buffID].EnableGroup) and
            B[CS()][ct][buffID].BuffInCombat) then
      if (CombatBuffs[buffID]) then
        table.wipe(CombatBuffs[buffID]);
      else
        CombatBuffs[buffID] = {};
      end
      CombatBuffs[buffID].Unit = "player";
      CombatBuffs[buffID].Type = Buffs[BuffIndex[buffID]].Type;
      CombatBuffs[buffID].ActionType = SMARTBUFF_ACTION_SPELL;
      SMARTBUFF_AddMsgD("Set combat spell: " .. SpellToLink(buffID));
      --break;
    end
  end
end
-- END SMARTBUFF_SetInCombatBuffs

function SMARTBUFF_IsTalentFrameVisible()
  return PlayerTalentFrame and PlayerTalentFrame:IsVisible();
end

-- Main Check functions

-- Returns false if addon is not initialized or disabled, check timer has not
-- expired, or player is mounted or dead.
---@param state Enum.State
---@param force? boolean
---@return boolean preCheckPassed
function SMARTBUFF_PreCheck(state, force)
  if not SmartBuff_Initialized then return false end

  if (not SmartBuff_ActionButtionInitialized) then
    SMARTBUFF_InitActionButtonPos();
  end

  if (not O.SmartBuff_Enabled) then
    if (state == Enum.State.STATE_START_BUFF) then
      SMARTBUFF_AddMsg(SMARTBUFF_MSG_DISABLED);
    end
    return false;
  end

  if (state == Enum.State.STATE_REBUFF_CHECK and not force) then
    if ((GetTime() - TimeLastChecked) < O.TimeBetweenChecks) then
      return false;
    end
  end
  --SMARTBUFF_AddMsgD(string.format("%.2f, %.2f", GetTime(), GetTime() - TimeLastChecked));
  TimeLastChecked = GetTime();

  -- If buffs can't be cast, hide UI elements
  if (C_PetBattles.IsInBattle() or UnitInVehicle("player") or UnitHasVehicleUI("player")) then
    if (not InCombatLockdown() and SmartBuff_KeyButton:IsVisible()) then
      SmartBuff_KeyButton:Hide();
    end
    return false;
  else
    SMARTBUFF_ShowSAButton();
  end

  SMARTBUFF_SetButtonTexture(SmartBuff_KeyButton, ImgSB);
  if (SmartBuffOptionsFrame:IsVisible()) then return false; end

  -- check for mount-spells
  if (PlayerClass == "PALADIN" and (IsMounted() or IsFlying()) and not C_UnitAuras.GetAuraDataByAuraInstanceID("player", SMARTBUFF_CRUSADERAURA)) or
    (PlayerClass == "DEATHKNIGHT" and IsMounted() and not C_UnitAuras.GetAuraDataByAuraInstanceID("player", SMARTBUFF_PATHOFFROST)) then
    return true;
  end

  if ((state == Enum.State.STATE_REBUFF_CHECK and not O.ToggleReminder) or IsMounted() or IsFlying() or LootFrame:IsVisible()
      or UnitOnTaxi("player") or UnitIsDeadOrGhost("player") or UnitIsCorpse("player")
      or (state ~= Enum.State.STATE_REBUFF_CHECK and (SMARTBUFF_IsPicnic("player") or SMARTBUFF_IsFishing("player")))
      or (UnitInVehicle("player") or UnitHasVehicleUI("player"))
      --or (state == State.STATE_ONE and (O.ToggleAutoRest and IsResting()) and not UnitIsPVP("player"))
      or (not O.BuffInCities and IsResting() and not UnitIsPVP("player"))) then

    if (UnitIsDeadOrGhost("player")) then
      SMARTBUFF_CheckBuffTimers();
    end

    return false;
  end
  --SMARTBUFF_AddMsgD("2: " .. GetTime() - TimeLastChecked);

  if (UnitAffectingCombat("player")) then
    IsCombat = true;
    --SMARTBUFF_AddMsgD("In combat");
  else
    IsCombat = false;
    --SMARTBUFF_AddMsgD("Out of combat");
  end

  if (not IsCombat and BuffsResetting) then
    SMARTBUFF_SetBuffs();
    IsSyncReq = true;
  end

  MsgWarning = "";
  IsFirstError = true;

  return true;
end

-- Bufftimer check functions
function SMARTBUFF_CheckBuffTimers()
  local n = 0;
  local ct = CurrentTemplate;
  --SMARTBUFF_AddMsgD("SMARTBUFF_CheckBuffTimers");
  local group = Units;
  for subgroup in pairs(group) do
    n = 0;
    if (group[subgroup] ~= nil) then
      for _, unit in pairs(group[subgroup]) do
        if (unit) then
          if (SMARTBUFF_CheckUnitBuffTimers(unit)) then
            n = n + 1;
          end
        end
      end
      if (BuffTimer[subgroup]) then
        BuffTimer[subgroup] = nil;
        SMARTBUFF_AddMsgD("Group " .. subgroup .. ": group timer reseted");
      end
    end
  end
end
-- END SMARTBUFF_CheckBuffTimers

-- if unit is dead, remove all timers
function SMARTBUFF_CheckUnitBuffTimers(unit)
  if (UnitExists(unit) and UnitIsConnected(unit) and UnitIsFriend("player", unit) and UnitIsPlayer(unit) and UnitIsDeadOrGhost(unit)) then
    local _, class = UnitClass(unit);
    local fd = nil;
    if (class == "HUNTER") then
      fd = UnitIsFeignDeath(unit);
    end
    if (not fd) then
      if (BuffTimer[unit]) then
        BuffTimer[unit] = nil;
        SMARTBUFF_AddMsgD(UnitName(unit) .. ": unit timer reset");
      end
      if (BuffTimer[class]) then
        BuffTimer[class] = nil;
        SMARTBUFF_AddMsgD(class .. ": class timer reset");
      end
      return true;
    end
  end
end
-- END SMARTBUFF_CheckUnitBuffTimers

-- Reset the buff timers and set them to running out soon
function SMARTBUFF_ResetBuffTimers()
  if (not SmartBuff_Initialized) then return; end

  local ct = CurrentTemplate;
  local t = GetTime();
  local rebuffTime = 0;
  local i = 0;
  local d = 0;
  local tl = 0;
  local buffID = nil;
  local buff = nil;
  local unit = nil;
  local obj = nil;
  local class = nil;

  local group = Groups;
  for subgroup in pairs(group) do
    local n = 0;
    if (group[subgroup] ~= nil) then

      for _, unit in pairs(group[subgroup]) do
        if (unit and UnitExists(unit) and UnitIsConnected(unit) and UnitIsFriend("player", unit) and UnitIsPlayer(unit) and not UnitIsDeadOrGhost(unit)) then
          _, class = UnitClass(unit);
          i = 1;
          while (Buffs[i] and Buffs[i].BuffID) do
            d = -1;
            buff = nil;
            rebuffTime = 0;
            buffID = Buffs[i].BuffID;

            rebuffTime = B[CS()][ct][buffID].RebuffTime;
            if (rebuffTime <= 0) then
              rebuffTime = O.RebuffTimer;
            end

            if (Buffs[i].GroupBuff and B[CS()][ct][buffID].EnableGroup and Buffs[i].GroupBuffID ~= nil and Buffs[i].GroupBuffDuration > 0) then
              d = Buffs[i].GroupBuffDuration;
              buff = Buffs[i].GroupBuff;
              obj = subgroup;
            end

            if (d > 0 and buff) then
              if (not BuffTimer[obj]) then
                BuffTimer[obj] = {};
              end
              BuffTimer[obj][buff] = t - d + rebuffTime - 1;
            end

            buff = nil;
            if (buffID and B[CS()][ct][buffID].IsEnabled and Buffs[i].BuffID ~= nil and Buffs[i].Duration > 0
                and class and B[CS()][ct][buffID][class]) then
              d = Buffs[i].Duration;
              buff = buffID;
              obj = unit;
            end

            if (d > 0 and buff) then
              if (not BuffTimer[obj]) then
                BuffTimer[obj] = {};
              end
              BuffTimer[obj][buff] = t - d + rebuffTime - 1;
            end

            i = i + 1;
          end

        end
      end
    end
  end
  --IsAuraChanged = true;
  SMARTBUFF_NextBuffCheck(Enum.State.STATE_REBUFF_CHECK, true);
end

function SMARTBUFF_ShowBuffTimers()
  if (not SmartBuff_Initialized) then return; end

  local ct = CurrentTemplate;
  local t = GetTime();
  local rebuffTime = 0;
  local i = 0;
  local d = 0;
  local tl = 0;
  local buffID = nil;

  for unit in pairs(BuffTimer) do
    for buff in pairs(BuffTimer[unit]) do
      if (unit and buff and BuffTimer[unit][buff]) then

        d = -1;
        buffID = nil;
        if (BuffIndex[buff]) then
          i = BuffIndex[buff];
          if (Buffs[i].BuffID == buff and Buffs[i].Duration > 0) then
            d = Buffs[i].Duration;
            buffID = Buffs[i].BuffID;
          elseif (Buffs[i].GroupBuff == buff and Buffs[i].GroupBuffDuration > 0) then
            d = Buffs[i].GroupBuffDuration;
            buffID = Buffs[i].BuffID;
          end
          i = i + 1;
        end

        if (buffID and B[CS()][ct][buffID] ~= nil) then
          if (d > 0) then
            rebuffTime = B[CS()][ct][buffID].RebuffTime;
            if (rebuffTime <= 0) then
              rebuffTime = O.RebuffTimer;
            end
            tl = BuffTimer[unit][buff] + d - t;
            if (tl >= 0) then
              local s = "";
              if (
                  string.find(unit, "^party") or string.find(unit, "^raid") or string.find(unit, "^player") or
                      string.find(unit, "^pet")) then
                local unitName = UnitName(unit) or "none";
                if (unitName) then
                  unitName = " (" .. unitName .. ")";
                else
                  unitName = "";
                end
                s = "Unit " .. unit .. unitName;
              elseif (string.find(unit, "^%d$")) then
                s = "Grp " .. unit;
              else
                s = "Class " .. unit;
              end
              --SMARTBUFF_AddMsg(s .. ": " .. IDToString(buff) .. ", time left: " .. string.format(": %.0f", tl) .. ", rebuff time: " .. rebuffTime);
              SMARTBUFF_AddMsg(string.format("%s: %s, time left: %.0f, rebuff time: %.0f", s, buff, tl, rebuffTime));
            else
              BuffTimer[unit][buff] = nil;
            end
          else
            --SMARTBUFF_AddMsgD("Removed: " .. IDToString(buff));
            BuffTimer[unit][buff] = nil;
          end
        end
      end
    end
  end
end
-- END SMARTBUFF_ShowBuffTimers

-- Synchronize the internal buff timers with the UI timers
function SMARTBUFF_SyncBuffTimers()
  if (not SmartBuff_Initialized or IsSync or BuffsResetting or SMARTBUFF_IsTalentFrameVisible()) then return; end
  IsSync = true;
  TimeSync = GetTime();

  local ct = CurrentTemplate;
  local rebuffTime = 0;
  local i = 0;
  local buffID = nil;

  local group = Groups;
  for subgroup in pairs(group) do
    local n = 0;
    if (group[subgroup] ~= nil) then
      for _, unit in pairs(group[subgroup]) do
        if (unit and UnitExists(unit) and UnitIsConnected(unit) and UnitIsFriend("player", unit) and UnitIsPlayer(unit) and not UnitIsDeadOrGhost(unit)) then
          local _, class = UnitClass(unit);
          i = 1;
          while (Buffs[i] and Buffs[i].BuffID) do
            rebuffTime = 0;
            buffID = Buffs[i].BuffID;
            -- TOCHECK
            rebuffTime = B[CS()][ct][buffID].RebuffTime;
            if (rebuffTime <= 0) then
              rebuffTime = O.RebuffTimer;
            end

            if (buffID and B[CS()][ct][buffID].IsEnabled and Buffs[i].BuffID ~= nil and Buffs[i].Duration > 0) then
              if (Buffs[i].Type ~= SMARTBUFF_CONST_SELF or (Buffs[i].Type == SMARTBUFF_CONST_SELF and UnitIsUnit(unit, "player"))) then
                SMARTBUFF_SyncBuffTimer(unit, unit, Buffs[i]);
              end
            end
            i = i + 1;
          end -- END while
        end
      end -- END for
    end
  end -- END for

  IsSync = false;
  IsSyncReq = false;
end

-- Synchronize buff timers
---@param unit Unit
---@param group integer
---@param buff BuffInfo
function SMARTBUFF_SyncBuffTimer(unit, group, buff)
  if (not unit or not group or not buff) then return end
  local duration = buff.Duration;
  local buffID = buff.BuffID;
  if (duration >= 0) then
    local aura, _, _, timeLeft = SMARTBUFF_GetUnitBuffInfo(unit, buffID, buff.Type, buff.Links, buff.Chain);
    if (aura == 0 and timeLeft ~= nil) then
      if (not BuffTimer[group]) then BuffTimer[group] = {} end
      local startTime = Round(GetTime() + timeLeft - duration, 2);
      if (not BuffTimer[group][buff] or (BuffTimer[group][buff] and BuffTimer[group][buff] ~= startTime)) then
        BuffTimer[group][buff] = startTime;
        if (timeLeft > 60) then
          SMARTBUFF_AddMsgD("Buff timer sync: " ..
            group .. ", " .. BuffToLink(buff) .. ", " .. string.format("%.1f", timeLeft / 60) .. "min");
        else
          SMARTBUFF_AddMsgD("Buff timer sync: " ..
            group .. ", " .. BuffToLink(buff) .. ", " .. string.format("%.1f", timeLeft) .. "sec");
        end
      end
    end
  end
end

-- returns shapeshift `form` if active, or `false` if not. since Treant and
-- Moonkin forms do not preclude casting, they are not treated as shapeshift
-- forms.
---@return string|false form
function SMARTBUFF_ShapeshiftForm()
  if (PlayerClass == "SHAMAN") and (GetShapeshiftForm(true) > 0) then
    return "Ghost Wolf";
  elseif (PlayerClass == "DRUID") then
    for i = 1, GetNumShapeshiftForms(), 1 do
      local _, active, castable, spell = GetShapeshiftFormInfo(i);
      local name = GetSpellInfo(spell);
      if (active and castable and name ~= SMARTBUFF_DRUID_TREANT and name ~= SMARTBUFF_DRUID_MOONKIN) then
        return name;
      end
    end
  end
  return false
end
-- END SMARTBUFF_ShapeshiftForm

local IsChecking = false;

--Returns details about the next queued buff.
---@param state Enum.State
---@return Enum.Result result
---@return ActionType actionType
---@return integer buffID
---@return integer slot
---@return Unit unit
---@return Type buffType
---@overload fun(state:Enum.State, force?:boolean)
function SMARTBUFF_NextBuffCheck(state, force)
  local unitsGroup;
  if (IsChecking or not SMARTBUFF_PreCheck(state, force)) then return; end
  IsChecking = true;

  local units = nil;

  SMARTBUFF_checkBlacklist();

  -- 1. check in combat buffs
  if (InCombatLockdown()) then -- and O.InCombat
    for buffID in pairs(CombatBuffs) do
      if (buffID) then
        local result = SMARTBUFF_TryBuffUnit("player", 0, state, buffID)
        SMARTBUFF_AddMsgD("SMARTBUFF_NextBuffCheck :: Check combat spell: " .. buffID .. ", ret = " .. result);
        if result == Enum.Result.SUCCESS then
          IsChecking = false;
          return;
        end
      end
    end
  end

  -- 2. buff target, if enabled
  if ((state == Enum.State.STATE_START_BUFF or state == Enum.State.STATE_END_BUFF) and O.BuffTarget) then
    for i, buffID in pairs(B[CS()].Order) do
      local result, actionType, buff, slot, _, buffType = SMARTBUFF_TryBuffUnit("target", 0, state, buffID);
      if (result == Enum.Result.SUCCESS) or (result == Enum.Result.ON_COOLDOWN) then
        IsChecking = false;
        return result, actionType, buff, slot, "target", buffType;
      end
    end
  end

  -- 3. check groups
  local order = Enum.GroupOrder;
  for _, subgroup in pairs(order) do
    --SMARTBUFF_AddMsgD("Checking subgroup " .. subgroup .. ", " .. GetTime());
    if (Groups[subgroup] ~= nil or subgroup == 1) then
      units = Groups[subgroup];
      if (Units and subgroup == 1) then
        unitsGroup = Units[1];
      else
        unitsGroup = units;
      end

      -- check buffs
      if (units) then
        for _, unit in pairs(units) do
          if (BuffsResetting) then break; end
          SMARTBUFF_AddMsgD("Checking single unit = " .. unit);
          for i, buffID in pairs(B[CS()].Order) do
            local result, actionType, buff, slot, _, buffType = SMARTBUFF_TryBuffUnit(unit, subgroup, state, buffID);
            --printd("SMARTBUFF_NextBuffCheck :: ", Enum.State[state], IDToString(buffID), "on", unit, "result", table.find(Enum.Result, result) )
            if (result == Enum.Result.SUCCESS) or (result == Enum.Result.ON_COOLDOWN) then
              IsChecking = false;
              return result, actionType, buff, slot, unit, buffType;
            end
          end
        end
      end
    end
  end -- for groups

  if (state == Enum.State.STATE_START_BUFF) then
    if (MsgWarning == "" or MsgWarning == " ") then
      SMARTBUFF_AddMsg(SMARTBUFF_MSG_NOTHINGTODO);
    else
      SMARTBUFF_AddMsgWarn(MsgWarning);
      MsgWarning = "";
    end
  end
  --TimeLastCheck = GetTime();
  IsChecking = false;
end
-- END SMARTBUFF_Check

-- FIXME: nested if nightmare
-- Populates and returns the BuffInfo class if `buffID` can be cast on `unit`, or an `error
-- code` if not.
---@param subgroup SubType
---@param state Enum.State
---@param buffID SpellID
---@return Enum.Result result
---@return ActionType actionType
---@return SpellID buff
---@return Enum.InventorySlot slot
---@return Unit unit
---@return Type buffType
---@overload fun(target:Unit, subgroup:Enum.SubType, state:Enum.State, buffID:SpellID): Enum.Result
function SMARTBUFF_TryBuffUnit(target, subgroup, state, buffID)

  if (BuffsResetting or SmartBuffOptionsFrame:IsVisible()) then return Enum.Result.GENERIC_ERROR end
  SMARTBUFF_CheckUnitBuffTimers(target);
  local b = Buffs[BuffIndex[buffID]]; ---@type BuffInfo

  -- caster and target info
  target = UnitName(target) or "none"; ---@type Unit
  local targetClass = UnitClass(target) ---@type string
  local targetName = UnitName("player") ---@type Unit
  local targetRole = UnitGroupRolesAssigned(target); ---@type string
  local targetCreatureClass = UnitCreatureType(target); ---@type string
  local targetCreatureFamily = UnitCreatureFamily(target); ---@type string
  -- if (targetName) then printd("group", subgroup, " checking ", targetName, " (", target, "/", targetClass, "/", targetRole, "/", (targetCreatureClass or "nil"), "/", (targetCreatureFamily or "nil"), ")", 0, 1, 0.5); end

  -- buff settings specific to current specialization/smartgroup
  local template = B[CS()][CT()][b.BuffID];---@type BuffTemplate
  local aura = 0; ---@type SpellID
  local result; ---@type Enum.Result

  ---@type Enum.Range
  Enum.Range = {
    Invalid = nil,
    OutOfRange = 0,
    InRange = 1
  }
  local isSpellUsable, outOfMana = IsUsableSpell(b.BuffID)
  -- check for gross errors which prevent the buff from being cast, (i.e. player
  -- dead, target is anenemy, disconnected, mounted, PVP flagged if the player
  -- hasn't opted to buff in PVP, etc)
  FailTable = {
    ["BUFF_DISABLED"]     = not (template.BuffEnabled or template.IsEnabled),
    ["TARGET_IS_PVP"]     = UnitIsPVP(target) and ((O.BuffPvp ~= true) or not UnitIsPVP("player")),
    ["TARGET_NOT_PVP"]    = not UnitIsPVP(target) and ((O.BuffPvp == true) and UnitIsPVP("player")),
    ["TARGET_IGNORED"]    = Blacklist[target] or SMARTBUFF_IsInList(target, targetName, template.IgnoreList),
    ["PLAYER_FLYING"]     = IsFlying(),
    ["NO_SUCH_TARGET"]    = not UnitIsFriend("player", target),
    ["TARGET_IS_DEAD"]    = UnitIsDeadOrGhost(target) or UnitIsCorpse(target),
    ["TARGET_OFFLINE"]    = not ( UnitIsConnected(target) and UnitIsVisible(target) ),
    ["TARGET_MOUNTED"]    = UnitOnTaxi(target) or
                            (IsMounted() and not (PlayerClass == "PALADIN" and target == SMARTBUFF_CRUSADERAURA)
                            and not (PlayerClass == "DEATHKNIGHT" and target == SMARTBUFF_PATHOFFROST)),
    ["SELF_BUFF_TYPE"]    = b.Type == SMARTBUFF_CONST_SELF and not UnitIsUnit(target, "player"),
    ["OUT_OF_RANGE"]      = IsSpellInRange(IDToLink(b.BuffID),target) == Enum.Range.OutOfRange,
    ["SPELL_UNUSABLE"]    = SafePack(IsUsableSpell(b.BuffID))[1],
    ["OUT_OF_MANA"]       = SafePack(IsUsableSpell(b.BuffID))[2],
    ["BUFF_SELF_NOT"]     = template.BuffSelfNot and UnitIsUnit(target, "player"),
    ["PLAYER_FISHING"]    = b.Params == S.CheckFishingPole and SMARTBUFF_IsFishingPoleEquipped(),
    ["PET_IS_OUT"]        = b.Params == S.CheckPet and UnitExists("pet"),
    ["PET_IS_NOT_OUT"]    = b.Params == S.CheckPetNeeded and not UnitExists("pet"),
    ["NO_COMBAT_BUFF"]    = UnitAffectingCombat("player") and not template.BuffInCombat,
    ["BUFF_IN_COMBAT"]    = not UnitAffectingCombat("player") and template.BuffOutOfCombat,
    ["BUFF_SELF_ONLY"]    = template.BuffSelfOnly and not UnitIsUnit(target, "player"),
    ["CLASS_BUFF_ONLY"]   = template[targetClass] and UnitIsPlayer(target),
    ["GROUP_BUFF_ONLY"]   = b.Type == SMARTBUFF_CONST_GROUP or b.Type == SMARTBUFF_CONST_ITEMGROUP,
    ["DK_PET_ONLY"]       = template["DKPET"] and targetCreatureClass ~= SMARTBUFF_UNDEAD,
    ["HUNTER_PET_ONLY"]   = template["HPET"] and targetCreatureClass ~= SMARTBUFF_BEAST,
    ["WARLOCK_PET_ONLY"]  = template["WPET"] and targetCreatureClass ~= SMARTBUFF_DEMON,
    ["SHAMAN_PET_ONLY"]   = template["SPET"] and targetCreatureClass ~= SMARTBUFF_ELEMENTAL,
    -- ["BUFFTYPE_ITEM"]     = SMARTBUFF_IsItem(b.Type),
    -- ["BUFFTYPE_SPELL"]    = SMARTBUFF_IsSpell(b.Type),
  }
  -- temporary measure to add new error states to enum
  local t = table.invert(Enum.Result)
  for key, value in pairs(FailTable) do
    tInsertUnique(t, key)
  end
  Enum.Result = table.invert(t)
  result = FindInTableIf(FailTable, function(v) return v end) or "SUCCESS";
  if result then return Enum.Result[result] end

  printd(b.Duration, gcSeconds)  -----------------------------------------------------------------------------------------
  if b.Duration <= 0 or (state == Enum.State.STATE_REBUFF_CHECK and b.Duration <= gcSeconds) then
    printd(b.Duration, gcSeconds)
    if (b.BuffID and MsgWarning == SMARTBUFF_MSG_CD) then MsgWarning = " " end
    b.RebuffTime = template.RebuffTime;
    if (b.RebuffTime <= 0) then b.RebuffTime = O.RebuffTimer end
    SMARTBUFF_AddMsgD(targetClass .. " " .. CT());
  end

  -- Tracking ability ------------------------------------------------------------------------
  if (b.Type == SMARTBUFF_CONST_TRACK) then

    --print("Check tracking: "..BuffID)
    local count = C_Minimap.GetNumTrackingTypes();
    for n = 1, C_Minimap.GetNumTrackingTypes() do
      local name, _, active, category, _ = C_Minimap.GetTrackingInfo(n);
      if (name ~= nil and not active) then
        SMARTBUFF_AddMsgD(n .. ". " .. name .. " (" .. category .. ")");
        if (name == GetSpellInfo(b.BuffID)) then
          if (PlayerClass == "DRUID" and b.BuffID == SMARTBUFF_DRUID_TRACK) then
            if (SMARTBUFF_ShapeshiftForm() == SMARTBUFF_DRUID_CAT) then
              aura = b.BuffID;
              C_Minimap.SetTracking(n, true);
            end
          else
            aura = b.BuffID;
            C_Minimap.SetTracking(n, true);
            --print("SetTracking: "..n)
          end
          if (aura ~= 0) then
            SMARTBUFF_AddMsgD("Tracking enabled: " .. IDToLink(aura));
            aura = 0;
          end
        end
      end
    end

    -- Food, Scroll, Potion or conjured items ------------------------------------------------------------------------
  elseif (b.Type == SMARTBUFF_CONST_FOOD or b.Type == SMARTBUFF_CONST_SCROLL or
          b.Type == SMARTBUFF_CONST_POTION or b.Type == SMARTBUFF_CONST_CONJURE or
          b.Type == SMARTBUFF_CONST_ITEMGROUP) then

    if (b.Type == SMARTBUFF_CONST_CONJURE) then
      b.buffTime = 0;
      aura = 0;
      if (aura) then
        local reagentCount = SMARTBUFF_CountReagent(aura, b.Chain);
        SMARTBUFF_AddMsgD(reagentCount .. " " .. aura .. " found");
        if (reagentCount == 0) then
          aura = aura;
        end
      end

      -- dont attempt to use food while moving or we will waste them.
    elseif (b.Type == SMARTBUFF_CONST_FOOD and IsPlayerMoving == false) then
      if (not SMARTBUFF_IsPicnic(target)) then
        aura, _, b.BuffName, b.BuffTime, b.Charges = SMARTBUFF_GetUnitBuffInfo(target, SMARTBUFF_FOOD_AURA, b.Type, b.Links, b.Chain);
      end
    else
      if (b.Params) then
        if (b.Links and b.Links == S.CheckFishingPole) then
          if (SMARTBUFF_IsFishingPoleEquipped()) then
            aura, _, b.BuffName, b.BuffTime, b.Charges = SMARTBUFF_GetUnitBuffInfo(target, aura, b.Type);
          else
            aura = 0;
          end
        else
          aura, _, b.BuffName, b.BuffTime, b.Charges = SMARTBUFF_GetUnitBuffInfo(target, aura, b.Type, b.Links, b.Chain);
        end
        SMARTBUFF_AddMsgD("Buff time (" .. aura .. ") = " .. tostring(b.BuffTime));
      else
        aura = 0;
      end
    end

    if (aura == 0 and b.Duration >= 1 and b.RebuffTime > 0) then
      if (b.Charges == nil) then b.Charges = -1; end
      if (b.Charges > 1) then b.HasCharges = true; end
      b.BuffTarget = "none";
    end
    printd("aura", aura, "duration", b.Duration, "rebufftime", b.RebuffTime, "buffTime", b.BuffTime)
    if (b.BuffTime and b.BuffTime <= b.RebuffTime) then
      printd("Buff expired #1")
      aura = b.BuffID;
      b.HasBuffExpired = true;
    end

    if (aura) then
      if (b.Type ~= SMARTBUFF_CONST_CONJURE) then
        local reagentCount, chain = SMARTBUFF_CountReagent(b.BuffID, b.Chain);
        if (reagentCount > 0) then
          aura = b.BuffID;
          if (b.Type == SMARTBUFF_CONST_ITEMGROUP or b.Type == SMARTBUFF_CONST_SCROLL) then
            b.StartTime, b.Duration = GetItemCooldown(b.BuffID);
            b.Duration = (b.StartTime + b.Duration) - GetTime();
            SMARTBUFF_AddMsgD(reagentCount .. " " .. IDToLink(b.BuffID) .. " found, duration = " .. b.Duration);
            if (b.Duration > 0) then
              aura = 0;
            end
          end
          SMARTBUFF_AddMsgD(reagentCount .. " " .. IDToLink(b.BuffID) .. " found");
        else
          SMARTBUFF_AddMsgD("No " .. IDToLink(b.BuffID) .. " found");
          aura = 0;
          printd("Buff not expired")
          b.HasBuffExpired = false;
        end
      end
    end

    -- Weapon buff ------------------------------------------------------------------------
  elseif (b.Type == SMARTBUFF_CONST_WEAPON or b.Type == SMARTBUFF_CONST_INV) then
    SMARTBUFF_AddMsgD("Check weapon Buff");
    local hasMainHandEnchant, mainHandExpiration, mainHandCharges, mainHandEnchantID, HasOffHandEnchant, OffHandExpiration, OffHandCharges, OffHandEnchantID = GetWeaponEnchantInfo();
    if (template.BuffMainHand) then
      b.InventorySlot = Enum.InventorySlot.INVTYPE_MAINHAND;
      InventoryItemID = GetInventoryItemID("player", b.InventorySlot);
      if (b.InventoryItemID and SMARTBUFF_CanApplyWeaponBuff(b.BuffID, b.InventorySlot)) then
        if (hasMainHandEnchant) then
          if (b.RebuffTime > 0 and b.Duration >= 1) then
            --if (mainHandExpiration == nil) then mainHandExpiration = 0; end
            mainHandExpiration = math.floor(mainHandExpiration / 1000);
            b.Charges = mainHandCharges;
            if (b.Charges == nil) then b.Charges = -1; end
            if (b.Charges > 1) then b.HasCharges = true; end
            SMARTBUFF_AddMsgD(targetName .. " (WMH): " .. IDToLink(b.BuffID) .. string.format(" %.0f sec left", mainHandExpiration) .. ", " .. b.Charges .. " charges left");
            if (mainHandExpiration <= b.RebuffTime or (O.CheckCharges and b.HasCharges and b.Charges > 0 and b.Charges <= O.MinCharges)) then
              aura = b.BuffID;
              b.BuffTime = mainHandExpiration;
              b.HasBuffExpired = true;
              printd("Buff expired #2")
            end
          end
        else
          b.HandType = Enum.InventorySlot.INVTYPE_MAINHAND;
          aura = b.BuffID;
        end
      else
        SMARTBUFF_AddMsgD("Weapon Buff cannot be cast, no mainhand weapon equipped or wrong weapon/stone type");
      end
    end

    if (template.BuffOffHand and not b.HasBuffExpired and b.HandType == Enum.InventoryType.EMPTY) then
      b.InventorySlot = Enum.InventorySlot.INVTYPE_OFFHAND;
      b.InventoryItemID = GetInventoryItemID("player", b.InventorySlot) or 0;
      if (b.InventoryItemID and SMARTBUFF_CanApplyWeaponBuff(b.BuffID, b.InventorySlot)) then
        if (b.HasOffHandEnchant) then
          if (b.RebuffTime > 0 and b.Duration >= 1) then
            --if (offHandExpiration == nil) then offHandExpiration = 0; end
            b.OffHandExpiration = math.floor(b.OffHandExpiration / 1000);
            b.Charges = b.OffHandCharges;
            if (b.Charges == nil) then b.Charges = -1; end
            if (b.Charges > 1) then b.HasCharges = true; end
            SMARTBUFF_AddMsgD(targetName ..
              " (WOH): " .. IDToLink(b.BuffID) .. string.format(" %.0f sec left", b.OffHandExpiration) .. ", " .. b.Charges .. " charges left");
            if (b.OffHandExpiration <= b.RebuffTime or (O.CheckCharges and b.HasCharges and b.Charges > 0 and b.Charges <= O.MinCharges)) then
              aura = b.BuffID;
              b.BuffTime = b.OffHandExpiration;
              b.HasBuffExpired = true;
              printd("buff expired #3")
            end
          end
        else
          b.HandType = Enum.InventorySlot.INVTYPE_OFFHAND;
          aura = b.BuffID;
        end
      else
        SMARTBUFF_AddMsgD("Weapon Buff cannot be cast, no offhand weapon equipped or wrong weapon/stone type");
      end
    end

    if (aura and b.Type == SMARTBUFF_CONST_INV) then
      local reagentCount = SMARTBUFF_CountReagent(b.BuffID, b.Chain);
      if (reagentCount > 0) then
        SMARTBUFF_AddMsgD(reagentCount .. " " .. IDToLink(b.BuffID) .. " found");
      else
        SMARTBUFF_AddMsgD("No " .. IDToLink(b.BuffID) .. " found");
        aura = 0;
      end
    end
    -- Normal buff ------------------------------------------------------------------------
  else
    local index = nil;

    -- check timer object
    aura, index, b.BuffName, b.BuffTime, b.Charges = SMARTBUFF_GetUnitBuffInfo(target, b.BuffID, b.Type, b.Links,
      b.Chain);
    if (b.Charges == nil) then b.Charges = -1; end
    if (b.Charges > 1) then b.HasCharges = true; end

    if (target ~= "target" and aura == 0 and b.Duration >= 1 and b.RebuffTime > 0) then
      if (UnitIsUnit(target, "player")) then
        if (BuffTimer[target] ~= nil and BuffTimer[target][b.BuffID] ~= nil) then
          local totalBuffTime = b.Duration - (GetTime() - BuffTimer[target][b.BuffID]);
          if (not b.BuffTime or b.BuffTime - totalBuffTime > b.RebuffTime) then
            b.BuffTime = totalBuffTime;
          end
        end
        --if (charges == nil) then charges = -1; end
        --if (charges > 1) then Buff.HasCharges = true; end
        b.BuffTarget = "none";
        --SMARTBUFF_AddMsgD(unitName .. " (P): " .. index .. ". " .. GetPlayerBuffTexture(index) .. "(" .. charges .. ") - " .. IDToString(buffID) .. string.format(" %.0f sec left", buffTime));
      elseif (BuffTimer[target] ~= nil and BuffTimer[target][b.BuffID] ~= nil) then
        b.BuffTime = b.Duration - (GetTime() - BuffTimer[target][b.BuffID]);
        b.BuffTarget = "none";
        --SMARTBUFF_AddMsgD(unitName .. " (S): " .. IDToString(buffID) .. string.format(" %.0f sec left", buffTime));
      elseif (
          b.GroupBuff ~= nil and BuffTimer[subgroup] ~= nil and BuffTimer[subgroup][b.GroupBuff] ~= nil) then
        b.BuffTime = b.GroupBuffDuration - (GetTime() - BuffTimer[subgroup][b.GroupBuff]);
        if (type(subgroup) == "number") then
          b.BuffTarget = SMARTBUFF_MSG_GROUP .. " " .. subgroup;
        else
          b.BuffTarget = SMARTBUFF_MSG_CLASS .. " " .. UnitClass(target);
        end
        --SMARTBUFF_AddMsgD(bufftarget .. ": " .. Buff.GroupBuff .. string.format(" %.0f sec left", buffTime));
      elseif (b.GroupBuff ~= nil and BuffTimer[targetClass] ~= nil and BuffTimer[targetClass][b.GroupBuff] ~= nil) then
        b.BuffTime = b.GroupBuffDuration - (GetTime() - BuffTimer[targetClass][b.GroupBuff]);
        b.BuffTarget = SMARTBUFF_MSG_CLASS .. " " .. UnitClass(target);
        --SMARTBUFF_AddMsgD(bufftarget .. ": " .. Buff.GroupBuff .. string.format(" %.0f sec left", buffTime));
      else
        b.BuffTime = 0;
      end

      if ((b.BuffTime and b.BuffTime <= b.RebuffTime) or (O.CheckCharges and b.HasCharges and b.Charges > 0 and b.Charges <= O.MinCharges)) then
        if (b.BuffName) then
          _, _, _, _, _, _, aura = GetSpellInfo(b.BuffName);
        else
          aura = b.BuffID;
        end
        b.HasBuffExpired = true;
        printd("buff expired #4")
      end
    end

    -- check if the group buff is active, in this case it is not possible to cast the single buff
    if (b.BuffName and state ~= Enum.State.STATE_REBUFF_CHECK and b.BuffName ~= IDToLink(b.BuffID)) then
      aura = 0;
      --SMARTBUFF_AddMsgD("Group buff is active, single buff canceled!");
      --printd("Group buff is active, single buff canceled!");
    end

  end -- END normal buff
  -- check if shapeshifted and cancel buff if it is not possible to cast it
  if (aura and b.Type ~= SMARTBUFF_CONST_TRACK and b.Type ~= SMARTBUFF_CONST_FORCESELF) then
    local form = SMARTBUFF_ShapeshiftForm();
    if (form) then
      if (string.find(tostring(aura), form)) then
        --SMARTBUFF_AddMsgD("Cast " .. IDToString(buff) .. " while shapeshifted");
      else
        if (aura == SMARTBUFF_DRUID_CAT) then
          aura = 0;
        end
        if (aura and state ~= Enum.State.STATE_REBUFF_CHECK and not O.InShapeshift and (form ~= SMARTBUFF_DRUID_MOONKIN and form ~= SMARTBUFF_DRUID_TREANT)) then
          --MsgWarning = SMARTBUFF_MSG_SHAPESHIFT .. ": " .. ShapeshiftName;
          aura = 0;
        end
      end
    elseif (aura == SMARTBUFF_DRUID_CAT) then
      aura = 0;
    end
  end
  if (aura) then

  -- we have a buff, set the cvar - this will be reverted back
  -- once smartbuff has finished its work.  If we are in combat
  -- lockdown then keep it at 0

  if not InCombatLockdown() and O.SBButtonFix then
    C_CVar.SetCVar("ActionButtonUseKeyDown", 1);
  elseif O.SBButtonFix then
    C_CVar.SetCVar("ActionButtonUseKeyDown", O.SBButtonDownVal);
  end
  if (b.BuffID) then
    SMARTBUFF_AddMsgD("Checking " .. BuffToLink(b) .. " " .. IDToLink(b.BuffID));
  end

  -- Cast state ---------------------------------------------------------------------------------------
  if (state == Enum.State.STATE_START_BUFF or state == Enum.State.STATE_END_BUFF) then
    CurrentUnit = nil;
    CurrentSpell = nil;
    --try to apply weapon buffs on main/off hand
    if (b.Type == SMARTBUFF_CONST_INV) then
      if (b.InventorySlot and (b.HandType ~= "" or b.HasBuffExpired)) then
        local bag, slot, count = SMARTBUFF_FindItemInfo(b.BuffID, b.Chain);
        if (count > 0) then
          MsgWarning = "";
          return Enum.Result.SUCCESS, SMARTBUFF_ACTION_ITEM, b.BuffID, b.InventorySlot, "player", b.Type;
        end
      end
      result = Enum.Result.CANNOT_BUFF_WEAPON;
    elseif (b.Type == SMARTBUFF_CONST_WEAPON) then
      if (b.InventoryItemID and (b.HandType ~= "" or b.HasBuffExpired)) then
        MsgWarning = "";
        return Enum.Result.SUCCESS, SMARTBUFF_ACTION_SPELL, b.BuffID, b.InventorySlot, "player", b.Type;
        --return Enum.Result.SUCCESS, SMARTBUFF_ACTION_SPELL, buffID, inventoryItemID, "player", Buff.Type;
      end
      result = Enum.Result.CANNOT_BUFF_WEAPON;

      -- eat food or use scroll or potion
    elseif (b.Type == SMARTBUFF_CONST_FOOD or b.Type == SMARTBUFF_CONST_SCROLL or
            b.Type == SMARTBUFF_CONST_POTION) then
      local bag, slot, count = SMARTBUFF_FindItemInfo(b.BuffID, b.Chain);
      if (count > 0 or b.HasBuffExpired) then
        MsgWarning = "";
        return Enum.Result.SUCCESS, SMARTBUFF_ACTION_ITEM, b.BuffID, 0, "player", b.Type;
      end
      result = Enum.Result.ITEM_NOT_FOUND;

      -- use item on a unit
    elseif (b.Type == SMARTBUFF_CONST_ITEMGROUP) then
      local bag, slot, count = SMARTBUFF_FindItemInfo(b.BuffID, b.Chain);
      if (count > 0) then
        MsgWarning = "";
        return Enum.Result.SUCCESS, SMARTBUFF_ACTION_ITEM, b.BuffID, 0, target, b.Type;
      end
      result = Enum.Result.ITEM_NOT_FOUND;

      -- create item
    elseif (b.Type == SMARTBUFF_CONST_CONJURE) then
      result = Enum.Result.ITEM_NOT_FOUND;
      local bag, slot, count = SMARTBUFF_FindItemInfo(aura, b.Chain);
      if (count == 0) then
        result = SMARTBUFF_CheckCast(target, b.BuffID, IDToLink(b.BuffID), b.MinLevel, b.Type);
        if (result == Enum.Result.SUCCESS) then
          CurrentUnit = target;
          CurrentSpell = b.BuffID;
        end
      end

      -- cast spell
    else
      result = SMARTBUFF_CheckCast(target, b.BuffID, IDToLink(b.BuffID), b.MinLevel, b.Type);
      --printd(table.find(Enum.Result,result)," = SMARTBUFF_CheckCast(",target, Buff.BuffID, IDToString(buffID), Buff.MinLevel, Buff.Type);
      if (result == Enum.Result.SUCCESS) then
        CurrentUnit = target;
        CurrentSpell = b.BuffID;
      end
    end

    -- Check state ---------------------------------------------------------------------------------------
  elseif (state == Enum.State.STATE_REBUFF_CHECK) then
    CurrentUnit = nil;
    CurrentSpell = nil;
    if (b.BuffTarget == "") then b.BuffTarget = targetName; end

    if (b.BuffID ~= nil or SMARTBUFF_IsItem(b.Type) or b.Type == SMARTBUFF_CONST_TRACK) then
      -- clean up buff timer, if expired
      printd(IDToLink(b.BuffID) , b.Type, b.BuffTime, b.HasBuffExpired, BuffTimer[target])
      if (b.BuffTime and b.BuffTime < 0 and b.HasBuffExpired) then
        b.BuffTime = 0;
        if (BuffTimer[target] ~= nil and BuffTimer[target][b.BuffID] ~= nil) then
          BuffTimer[target][b.BuffID] = nil;
          --SMARTBUFF_AddMsgD(unitName .. " (S): " .. IDToString(buffID) .. " timer reset");
        end
        if (b.GroupBuffID ~= nil) then
          if (BuffTimer[subgroup] ~= nil and BuffTimer[subgroup][b.GroupBuff] ~= nil) then
            BuffTimer[subgroup][b.GroupBuff] = nil;
            --SMARTBUFF_AddMsgD("Group " .. subgroup .. ": " .. IDToString(buffID) .. " timer reset");
          end
          if (BuffTimer[targetClass] ~= nil and BuffTimer[targetClass][b.GroupBuff] ~= nil) then
            BuffTimer[targetClass][b.GroupBuff] = nil;
            --SMARTBUFF_AddMsgD("Class " .. class .. ": " .. Buff.GroupBuff .. " timer reset");
          end
        end
        TimeLastChecked = GetTime() - O.TimeBetweenChecks + 0.5;
        return Enum.Result.SUCCESS;
      end
      SMARTBUFF_SetMissingBuffMessage(b.BuffTarget, aura, b.Icon, b.HasCharges, b.Charges, b.BuffTime, b.HasBuffExpired);
      SMARTBUFF_SetButtonTexture(SmartBuff_KeyButton, b.Icon);
      return Enum.Result.SUCCESS;
    end
  end

    if result == Enum.Result.SUCCESS then
      -- target buffed
      -- Message will printed in the "SPELLCAST_STOP" event
      MsgWarning = "";
      return Enum.Result.SUCCESS, SMARTBUFF_ACTION_SPELL, b.BuffID, Enum.InventoryType.EMPTY, target, b.Type;
    end
    if state == Enum.State.STATE_START_BUFF then
      BuffUnit_Errors = {
        [Enum.Result.ON_COOLDOWN]           = IDToLink(b.BuffID) .. " " .. SMARTBUFF_MSG_CD,
        [Enum.Result.INVALID_TARGET]        = "Unable to target " .. targetName,
        [Enum.Result.OUT_OF_RANGE]          = targetName .. " " .. SMARTBUFF_MSG_OOR,
        [Enum.Result.EXTENDED_COOLDOWN]     = IDToLink(b.BuffID) .. " " .. SMARTBUFF_MSG_CD .. " > " .. MaxSkipCoolDown,
        [Enum.Result.TARGET_MINLEVEL]       = targetName .. "'s level is too low for  " .. IDToLink(b.BuffID),
        [Enum.Result.OUT_OF_MANA]           = SMARTBUFF_MSG_OOM,
        [Enum.Result.ALREADY_ACTIVE]        = IDToLink(b.BuffID) .. " can't be used because other ability is already active",
        [Enum.Result.NO_ACTION_SLOT]        = IDToLink(b.BuffID) .. " has no actionslot",
        [Enum.Result.NO_SUCH_SPELL]         = IDToLink(b.BuffID) .. ": no such spell",
        [Enum.Result.CANNOT_BUFF_TARGET]    = IDToLink(b.BuffID) .. " can't be used on " .. targetName,
        [Enum.Result.ITEM_NOT_FOUND]        = IDToLink(b.BuffID) .. " could not be found",
        [Enum.Result.CANNOT_BUFF_WEAPON]    = IDToLink(b.BuffID) .. " could not be applied to your weapon",
        [Enum.Result.GENERIC_ERROR]       = "Undefined error"
      }
      local s = BuffUnit_Errors[Enum.Result] or SMARTBUFF_MSG_CHAT;
      SMARTBUFF_AddMsgWarn(s);
      return result
    end
    -- finished
    if O.SBButtonFix then C_CVar.SetCVar("ActionButtonUseKeyDown", O.SBButtonDownVal); end
    -- target does not need this buff
    if O.SBButtonFix then C_CVar.SetCVar("ActionButtonUseKeyDown", O.SBButtonDownVal); end
    -- duration
    if (MsgWarning == "") then MsgWarning = SMARTBUFF_MSG_CD; end
  end
  return Enum.Result.GENERIC_ERROR; -- catchall
end
-- END SMARTBUFF_TryBuffUnit

function SMARTBUFF_IsInList(unit, unitname, list)
  for un in pairs(list) do
    if (UnitIsPlayer(unit) and un == unitname) then
      return true;
    end
  end
  return false;
end

-- Show a splash screen with the next buff that is queued for casting
--
---@param target Unit
---@param buff BuffID
---@param icon Icon
---@param canCharge boolean
---@param charges integer
---@param timeLeft number
---@param hasExpired boolean
function SMARTBUFF_SetMissingBuffMessage(target, buff, icon, canCharge, charges, timeLeft, hasExpired)
  printd(target, IDToLink(buff), icon, canCharge, charges, timeLeft, hasExpired )
  local f = SmartBuffSplashFrame;
  -- show splash buffID message
  if (f and O.ToggleReminderSplash and not SmartBuffOptionsFrame:IsVisible()) then
    local s;
    local sd = O.SplashDuration;
    local splashIcon = "";

    if (OG.SplashIcon and icon) then
      local n = O.SplashIconSize;
      if (n == nil or n <= 0) then
        n = O.CurrentFontSize;
      end
      splashIcon = string.format("\124T%s:%d:%d:1:0\124t ", icon, n, n) or "";
    else
      splashIcon = ("[icon:"..IDToLink(buff).."] ");
    end
    printd("SMARTBUFF_SetMissingBuffMessage(",target, IDToLink(buff), splashIcon, canCharge, charges, timeLeft, hasExpired)
    if (OG.SplashMsgShort and splashIcon == "") then splashIcon = IDToLink(buff) end
    if (O.TimeBetweenChecks < 4) then
      sd = 1;
      f:Clear();
    end

    f:SetTimeVisible(sd);
    if (not charges) then charges = 0; end
    if (O.CheckCharges and canCharge and charges > 0 and charges <= O.MinCharges and hasExpired) then
      if (OG.SplashMsgShort) then
        s = target .. " > " .. splashIcon .. " < " .. string.format(SMARTBUFF_ABBR_CHARGES_OL, charges);
      else
        s = target ..
            "\n" ..
            SMARTBUFF_MSG_REBUFF .. " " .. splashIcon .. IDToLink(buff) .. ": " .. string.format(SMARTBUFF_MSG_CHARGES, charges) .. " " .. SMARTBUFF_MSG_LEFT;
      end
    elseif (hasExpired) then
      if (OG.SplashMsgShort) then
        s = target .. " > " .. splashIcon .. " < " .. string.format(SMARTBUFF_ABBR_SECONDS, timeLeft);
      else
        s = target ..
            "\n" ..
            SMARTBUFF_MSG_REBUFF .. " " .. splashIcon .. IDToLink(buff) ..
            ": " .. string.format(SMARTBUFF_MSG_SECONDS, timeLeft) .. " " .. SMARTBUFF_MSG_LEFT;
      end
    else
      if (OG.SplashMsgShort) then
        s = target .. " > " .. splashIcon;
      else
        printd(target, " ", SMARTBUFF_MSG_NEEDS, " ", splashIcon, IDToLink(buff));

        s = target .. " " .. SMARTBUFF_MSG_NEEDS .. " " .. splashIcon .. IDToLink(buff);
      end
    end
    f:AddMessage(s, O.ColSplashFont.r, O.ColSplashFont.g, O.ColSplashFont.b, 1.0);
  end

  -- show chat buffID message
  if (O.ToggleReminderChat) then
    if (O.CheckCharges and canCharge and charges > 0 and charges <= O.MinCharges and hasExpired) then
      SMARTBUFF_AddMsgWarn(target ..
        ": " .. SMARTBUFF_MSG_REBUFF .. " " .. IDToLink(buff) ..
        ", " .. string.format(SMARTBUFF_MSG_CHARGES, charges) .. " " .. SMARTBUFF_MSG_LEFT, true);
    elseif (hasExpired) then
      SMARTBUFF_AddMsgWarn(target ..
        ": " .. SMARTBUFF_MSG_REBUFF .. " " .. IDToLink(buff) .. string.format(SMARTBUFF_ABBR_SECONDS, timeLeft) .. " " .. SMARTBUFF_MSG_LEFT,
        true);
    else
      SMARTBUFF_AddMsgWarn(target .. " " .. SMARTBUFF_MSG_NEEDS .. " " .. IDToLink(buff), true);
    end
  end

  -- play sound
  if (O.ToggleReminderSound) then
    PlaySound(Sounds[O.AutoSoundSelection]);
  end
end

-- Returns `true` and `weaponType` if a spell/reagent could be applied on a
-- weapon, `false` otherwise.
---@param buff BuffID
---@param slot Enum.InventorySlot
---@return true
---@return WeaponTypes weaponTypes
---@overload fun(buff: integer, slot:Enum.InventorySlot): false
function SMARTBUFF_CanApplyWeaponBuff(buff, slot)
  if (string.find(GetSpellInfo(buff), SMARTBUFF_WEAPON_SHARP_PATTERN)) then
    WeaponTypes = SMARTBUFF_WEAPON_SHARP;
  elseif (string.find(GetSpellInfo(buff), SMARTBUFF_WEAPON_BLUNT_PATTERN)) then
    Enum.WeaponTypes = SMARTBUFF_WEAPON_BLUNT;
  else
    Enum.WeaponTypes = SMARTBUFF_WEAPON_STANDARD;
  end

  local itemLink = GetInventoryItemLink("player", slot);
  local _, _, itemCode = string.find(itemLink, "(%d+):");
  local _, _, _, _, _, itemType, itemSubType = GetItemInfo(itemCode);
  printd(itemType, itemSubType)

  --if (itemType and itemSubType) then
  --  SMARTBUFF_AddMsgD("Type: " .. itemType .. ", Subtype: " .. itemSubType);
  --end

    ---BUG: i don't think this is going to work
    for _, weaponType in pairs(Enum.WeaponTypes) do
      printd(weaponType, itemSubType)
      --SMARTBUFF_AddMsgD(weapon);
      if (string.find(itemSubType, weaponType)) then
        --SMARTBUFF_AddMsgD("Can apply " .. IDToString(buffID) .. " on " .. itemSubType);
        return true, weaponType;
      end
  end
  return false;
end
-- END SMARTBUFF_CanApplyWeaponBuff

-- Check the unit blacklist
function SMARTBUFF_checkBlacklist()
  local t = GetTime();
  for unit in pairs(Blacklist) do
    if (t > (Blacklist[unit] + O.BlacklistTimer)) then
      Blacklist[unit] = nil;
    end
  end
end
-- END SMARTBUFF_checkBlacklist

-- Check if spell can be cast for the 900th time (not out of range, have mana, etc)
---@param unit Unit
---@param buff SpellID
---@param name string
---@param minLevel table
---@param type Type
---@return Enum.Result
function SMARTBUFF_CheckCast(unit, buff, name, minLevel, type)
  if (buff == nil) then return Enum.Result.NO_SUCH_SPELL; end

  if (type == SMARTBUFF_CONST_TRACK) then
    for i=1,C_Minimap.GetNumTrackingTypes() do
      local trackName, texture, active = C_Minimap.GetTrackingInfo(i);
      if active and SpellToLink(buff) == trackName then
        SMARTBUFF_AddMsgD("Track already enabled: " .. texture);
      end
      return Enum.Result.ALREADY_ACTIVE;
    end
  end

  -- check if spell has duration
  local _, duration = GetSpellCooldown(buff)
  if (not duration) then
    -- move on
  elseif (duration > MaxSkipCoolDown) then
    return Enum.Result.EXTENDED_COOLDOWN;
  elseif (duration > 0) then
    return Enum.Result.ON_COOLDOWN;
  end

  local IN_RANGE = 1;
  local OUT_OF_RANGE = 0;
  -- Rangecheck
  if (type == SMARTBUFF_CONST_GROUP or type == SMARTBUFF_CONST_ITEMGROUP) then
    -- takes spellName ONLY as argument
    if (SpellHasRange(GetSpellInfo(buff))) then
      -- also takes spellName ONLY as argument
      if (IsSpellInRange(GetSpellInfo(buff), unit) == OUT_OF_RANGE) then
        return Enum.Result.OUT_OF_RANGE;
      end
    else
      if not UnitInRange(unit) then
        return Enum.Result.OUT_OF_RANGE;
      end
    end
  end

  -- check if you have enough mana/energy/rage to cast
  local _, noMana = IsUsableSpell(buff);
  if (noMana) then
    return Enum.Result.OUT_OF_MANA;
  end
  return 0
end
-- END SMARTBUFF_CheckCast

-- Returns the `spell ID` to cast in order to refresh `buff`, or `nil` if none
---@param unit Unit
---@param buff SpellID
---@param type Type
---@param links table|nil
---@param chain table|nil
---@return SpellID auraInstanceID
---@return integer key
---@return SpellID chainAuraID
---@return number timeLeft
---@return integer count
---@overload fun(unit:string, aura:integer, type:Type, links:table|nil, chain:table|nil): auraInstanceID:SpellID
function SMARTBUFF_GetUnitBuffInfo(unit, buff, type, links, chain)
  printd("SMARTBUFF_GetUnitBuffInfo (", unit, buff, type, links, chain, ")");
  if (not unit or (not buff and not links)) then return 0 end
  local unitName = UnitName(unit) or "none";
  local spellID = buff or links[1]
  -- Stance/Presence/Seal check, these are not in the aura list
  local n = BuffIndex[spellID];
  printd("buff aura found", BuffToLink(Buffs[n]))
  if (Buffs[n] and Buffs[n].Type == SMARTBUFF_CONST_STANCE) then
    if (spellID and chain and #chain >= 1) then
      for index, stance in B[CS()].Order do
        --SMARTBUFF_AddMsgD("Check chained stance: "..auraInstanceID);
        print("Check for chained stance: "..stance);
        if stance and table.find(chain, stance) then
          local v = GetBuffTemplate(stance);
          if (v and v.BuffEnabled) then
            for j = 1, GetNumShapeshiftForms(), 1 do
              local _, name, active, castable = GetShapeshiftFormInfo(j);
              printd(stance..", "..name..", active = "..(active or "nil"));
              if (name and not active and castable and name == stance) then
                return spellID
              elseif (active and castable and name == stance) then
                printd("Chained stance found: "..stance);
                return 0, index, spellID, 1800, -1;
              end
            end
          end
        end
      end
    end
    print("returning",spellID)
    return spellID
  end

  -- Check linked buffs
  if (links) then
    printd("checking links",type)
    if (not O.LinkSelfBuffCheck and type == SMARTBUFF_CONST_SELF) then
      -- Do not check linked self buffs
    elseif (not O.LinkGrpBuffCheck and type == SMARTBUFF_CONST_GROUP) then
      -- Do not check linked group buffs
    else
      for k, link in pairs(links) do
        if (link and link == spellID) then
          SMARTBUFF_AddMsgD("Check linked buff (" .. unitName or "nil" .. "): " .. (IDToLink(link) or "nil"));
          printd("Check linked buff (", unitName, "):", link, (IDToLink(link)), "vs aura", spellID );
          local auraInfo = C_UnitAuras.GetAuraDataByAuraInstanceID(unit, spellID)
          if auraInfo then
            local timeLeft = math.max( 0, auraInfo.expirationTime - GetTime() );
            SMARTBUFF_AddMsgD("Linked buff found: " .. IDToLink(spellID) .. ", " .. timeLeft .. ", " .. auraInfo.icon);
            return 0, k, spellID, timeLeft, auraInfo.charges;
          end
        end
      end
    end
  end

  -- Check chained buffs
  if (spellID and chain and #chain > 1) then
    local t = B[CS()].Order;
    if (t and #t > 1) then
      --SMARTBUFF_AddMsgD("Check chained buff ("..unitName.."): "..defBuff);
      for i = 1, #t, 1 do
        if (t[i] and table.find(chain, t[i])) then
          local v = GetBuffTemplate(t[i]);
          if (v and v.BuffEnabled) then
            local auraInfo = C_UnitAuras.GetAuraDataByAuraInstanceID(unit, t[i])
            if auraInfo and links and auraInfo.source == "player" then
              --SMARTBUFF_AddMsgD("Chained buff found: "..t[i]..", "..auraInfo.timeLeft
              if (SMARTBUFF_CheckLinkedAuras(unit, t[i], type, links)) then
                return 0, i, spellID, auraInfo.timeLeft, -1;
              end
            elseif t[i] == spellID then
              return spellID
            end
          end
        end
      end
    end
  end

  -- Check aura instance ID
  if (spellID) then
    SMARTBUFF_AddMsgD("Check default buff (" .. unitName .. "): " .. IDToLink(spellID));
    local auraInfo = C_UnitAuras.GetAuraDataByAuraInstanceID(unit, spellID)
    if (auraInfo) then
      local timeLeft = math.max(0, auraInfo.expirationTime - GetTime());
      if (UnitIsUnit(auraInfo.source, "player")) then
        SMARTBUFF_UpdateBuffDuration(auraInfo.auraInstanceID, auraInfo.duration);
      end
      SMARTBUFF_AddMsgD("Default buff found: " .. IDToLink(auraInfo.auraInstanceID) .. ", " .. timeLeft .. ", " .. auraInfo.icon);
      return 0, 0, auraInfo.auraInstanceID, timeLeft, auraInfo.count;
    end
  end

  -- Buff not found, return default buff
  return spellID;
end

--- check linked auras
---@param unit Unit
---@param aura SpellID
---@param type Type
---@param links table
---@return SpellID spellID
---@return integer index
---@return SpellID auraID
---@return number timeLeft
---@return integer charges
---@overload fun(unit:Unit, aura:SpellID, type:Type, links:table): aura:SpellID
function SMARTBUFF_CheckLinkedAuras(unit, aura, type, links)
  -- Check linked buffs
  if (links) then
    if (not O.LinkSelfBuffCheck and type == SMARTBUFF_CONST_SELF) then
      -- Do not check linked self buffs
    elseif (not O.LinkGrpBuffCheck and type == SMARTBUFF_CONST_GROUP) then
      -- Do not check linked group buffs
    else
      for index, auraID in pairs(links) do
        if auraID == aura then
          SMARTBUFF_AddMsgD("Check linked buff (" .. unit .. "): " .. IDToLink(auraID));
          local auraInfo = C_UnitAuras.GetAuraDataByAuraInstanceID(unit, auraID)
          if (auraInfo) then
            local timeLeft = math.max( 0, auraInfo.expirationTime - GetTime() );
            SMARTBUFF_AddMsgD("Linked aura found: " .. IDToLink(aura) .. ", " .. auraInfo.expirationTime .. ", " .. auraInfo.icon);
            return 0, index, aura, timeLeft, auraInfo.charges;
          end
        end
      end
    end
  end
  return aura;
end

--- check chained auras
---@param unit Unit
---@param aura SpellID
---@param chain table
---@return SpellID auraID
---@return integer index
---@return SpellID aura
---@return number timeLeft
---@return integer charges
---@overload fun(unit:Unit, aura:SpellID, chain:table): aura:SpellID
function SMARTBUFF_CheckChainedAuras(unit, aura, chain)
  if (aura and chain and #chain > 1) then
    local t = B[CS()].Order;
    for index, auraID in pairs(t) do
      SMARTBUFF_AddMsgD("Check chained buff: " .. IDToLink(aura));
      if (auraID == aura and table.find(chain, index)) then
        local auraInfo = C_UnitAuras.GetAuraDataByAuraInstanceID(unit, auraID)
        if (auraInfo) and auraInfo.source == "player" then
          SMARTBUFF_AddMsgD("Chained buff found: " .. auraID);
          return 0, index, aura, auraInfo.timeLeft, -1;
        end
      end
    end
  end
  return aura;
end

function SMARTBUFF_UpdateBuffDuration(buff, duration)
  local i = BuffIndex[buff];
  if (i ~= nil and Buffs[i] ~= nil and buff == Buffs[i].BuffID) then
    if (Buffs[i].Duration ~= nil and Buffs[i].Duration > 0 and Buffs[i].Duration ~= duration) then
      SMARTBUFF_AddMsgD("Updated buff duration: " .. IDToLink(buff) .. " = " .. duration .. "sec, old = " .. Buffs[i].Duration);
      Buffs[i].Duration = duration;
    end
  end
end

-- Returns the name/description of the buff
---@param unit Unit
---@param buffIndex integer
---@param line any
function SMARTBUFF_GetBuffName(unit, buffIndex, line)
  local i = buffIndex;
  local name = nil;
  if (i < 0 or i > MaxBuffs) then
    return nil;
  end
  --SmartBuffTooltip:SetOwner(SmartBuffFrame, "ANCHOR_NONE");
  SmartBuffTooltip:ClearLines();
  SmartBuffTooltip:SetUnitBuff(unit, i);
  local obj = _G["SmartBuffTooltipTextLeft" .. line];
  if (obj) then
    name = obj:GetText();
  end
  return name;
end

-- END SMARTBUFF_GetBuffName

-- IsPicnic(unit)
---@param unit Unit
---@return boolean
function SMARTBUFF_IsPicnic(unit)
  return not SMARTBUFF_GetUnitBuffInfo (unit, SMARTBUFF_FOOD_SPELL, SMARTBUFF_CONST_FOOD, { SMARTBUFF_FOOD_SPELL, SMARTBUFF_DRINK_SPELL } );
end
-- END SMARTBUFF_IsPicnic

-- IsFishing(unit)
function SMARTBUFF_IsFishing(unit)
  -- spell, rank, displayName, icon, startTime, endTime, isTradeSkill = UnitChannelInfo("unit")
  local spell = UnitChannelInfo(unit);
  if (spell ~= nil and SMARTBUFF_FISHING ~= nil and spell == SMARTBUFF_FISHING) then
    --SMARTBUFF_AddMsgD("Channeling "..SMARTBUFF_FISHING);
    return true;
  end
  return false;
end

function SMARTBUFF_IsFishingPoleEquipped()
  local link = GetInventoryItemLink("player", GetInventorySlotInfo("MainHandSlot"));
  local _, _, _, _, _, _, subType = GetItemInfo(link);
  return (S and S.FishingPole and subType and (S.FishgPole == subType))
end

-- END SMARTBUFF_IsFishing

-- Returns `true` if buff is a spell
---@param type Type
---@return boolean isSpell
function SMARTBUFF_IsSpell(type)
  return type == SMARTBUFF_CONST_GROUP or type == SMARTBUFF_CONST_GROUPALL or type == SMARTBUFF_CONST_SELF or type == SMARTBUFF_CONST_FORCESELF or type == SMARTBUFF_CONST_WEAPON or type == SMARTBUFF_CONST_STANCE or type == SMARTBUFF_CONST_CONJURE or type ==SMARTBUFF_CONST_TRACK
end
-- END SMARTBUFF_IsSpell

-- Returns `true` if buff is an item
---@param type Type
---@return boolean isItem
function SMARTBUFF_IsItem(type)
  return type == SMARTBUFF_CONST_INV or type == SMARTBUFF_CONST_FOOD or type == SMARTBUFF_CONST_SCROLL or type == SMARTBUFF_CONST_POTION or type == SMARTBUFF_CONST_ITEMGROUP;
end

-- END SMARTBUFF_IsItem


-- Loops through all of the debuffs currently active looking for a texture string match
function SMARTBUFF_IsDebuffTexture(unit, debufftex)
  local active = false;
  local i = 1;
  local name, icon;
  -- name,rank,icon,count,type = UnitDebuff("unit", id or "name"[,"rank"])
  while (UnitDebuff(unit, i)) do
    name, icon, _, _ = UnitDebuff(unit, i);
    --SMARTBUFF_AddMsgD(i .. ". " .. name .. ", " .. icon);
    if (string.find(tostring(icon), debufftex)) then
      active = true;
      break
    end
    i = i + 1;
  end
  return active;
end

-- END SMARTASPECT_IsDebuffTex


-- Returns the number of a reagent currently in player's bag
function SMARTBUFF_CountReagent(reagent, chain)
  local total = 0;
  local id = nil;

  if (reagent == nil) then
    return -1, nil;
  end
  if (SMARTBUFF_Options.IncludeToys) then
    local toy = S.Toybox[reagent];
    if (toy) then
      return 1, toy[1];
    end
  end
  if not (chain) then chain = { reagent }; end
  for bag = 0, NUM_BAG_FRAMES do
    for slot = 1, C_Container.GetContainerNumSlots(bag) do
      local itemID = C_Container.GetContainerItemID(bag, slot)
      if itemID then
        local containerInfo = C_Container.GetContainerItemInfo(bag, slot);
        --SMARTBUFF_AddMsgD("Reagent found: " .. C_Container.GetContainerItemLink(bag.slot));
        for i = 1, #chain, 1 do
          if chain[i] == itemID then
            id = itemID
            total = total + containerInfo.stackCount;
          end
        end
      end
    end
  end
  return total, id;
end

-- these two functions are basically identical and should be merged
---@param itemID ItemID
---@param chain? table
---@return Enum.BagIndex bag
---@return integer slot
---@return integer stackCount
---@return Icon icon
function SMARTBUFF_FindItemInfo(itemID, chain)
  if (itemID == 0) then
    return 0, 0, -1, 0;
  end
  if (SMARTBUFF_Options.IncludeToys) then
    local toy = S.Toybox[itemID];
    if (toy) then
      return 0, toy[1], 1, toy[2];
    end
  end
  if not (chain) then chain = { itemID }; end
  for bag = 0, _G.NUM_BAG_FRAMES do
    for slot = 1, C_Container.GetContainerNumSlots(bag) do
      local bagItemID = C_Container.GetContainerItemID(bag, slot);
      if (bagItemID) then
        --SMARTBUFF_AddMsgD("Reagent found: " .. C_Container.GetContainerItemLink(bag.slot));
        for i = 1, #chain, 1 do
          if chain[i] == bagItemID then
            local containerInfo = C_Container.GetContainerItemInfo(bag, slot);
            return bag, slot, containerInfo.stackCount, containerInfo.iconFileID;
          end
        end
      end
    end
  end
  return 0, 0, 0, 0;
end

-- END Reagent functions

-- check the current zone and set buff template
function SMARTBUFF_CheckLocation()
  if (not O.AutoSwitchTemplate and not O.AutoSwitchTemplateInst) then return; end

  -- if in LFR, we don't want to use specific instance templates
  if CurrentTemplate == SMARTBUFF_TEMPLATES[Enum.GroupType.LFR] then return; end

  local zone = GetRealZoneText();
  if (zone == nil) then
    SMARTBUFF_AddMsgD("No zone found, try again...");
    TimeStartZone = GetTime();
    IsSetZone = true;
    return;
  end

  IsSetZone = false;
  local tmp = nil;
  local b = false;

  SMARTBUFF_AddMsgD("Current zone: " .. zone .. ", last zone: " .. LastZone);
  if (zone ~= LastZone) then
    LastZone = zone;
    if (IsActiveBattlefieldArena()) then
      tmp = SMARTBUFF_TEMPLATES[Enum.GroupType.Arena];
    elseif (SMARTBUFF_IsActiveBattlefield(zone) == 1) then
      tmp = SMARTBUFF_TEMPLATES[Enum.GroupType.Battleground];
    else
      if (O.AutoSwitchTemplateInst) then
        local i = 1;
        for _ in pairs(SMARTBUFF_INSTANCES) do
          if (string.find(string.lower(zone), string.lower(SMARTBUFF_INSTANCES[i]))) then
            b = true;
            break;
          end
          i = i + 1;
        end
        tmp = nil;
        if (b) then
          if SMARTBUFF_TEMPLATES[i + Enum.GroupType.Arena] then
            tmp = SMARTBUFF_TEMPLATES[i + Enum.GroupType.Arena]
          end
        end
      end
    end

    SMARTBUFF_AddMsgD("Current tmpl: " .. CurrentTemplate or "nil" .. " - new tmpl: " .. tmp or "nil");
    if (tmp and CurrentTemplate ~= tmp) then
      SMARTBUFF_AddMsg(SMARTBUFF_OFT_AUTOSWITCHTMP .. ": " .. CurrentTemplate .. " -> " .. tmp);
      CurrentTemplate = tmp;
      SMARTBUFF_SetBuffs();
    end
  end
end

-- END SMARTBUFF_CheckLocation


-- checks if the player is inside a battlefield
function SMARTBUFF_IsActiveBattlefield(zone)
  local i, status, map, instanceID, teamSize;
  for i = 1, GetMaxBattlefieldID() do
    status, map, instanceID, _, _, teamSize = GetBattlefieldStatus(i);
    if (status and status ~= "none") then
      SMARTBUFF_AddMsgD("Battlefield status = " ..
        string.check(status) ..
        ", buffID = " .. string.check(tostring(instanceID)) .. ", TS = " .. string.check(teamSize) .. ", Map = " .. string.check(map) ..
        ", Zone = " .. string.check(zone));
    else
      SMARTBUFF_AddMsgD("Battlefield status = none");
    end
    if (status and status == "active" and map) then
      if (teamSize and type(teamSize) == "number" and teamSize > 0) then
        return 2;
      end
      return 1;
    end
  end
  return 0;
end

-- END IsActiveBattlefield


-- Helper functions ---------------------------------------------------------------------------------------
function SMARTBUFF_toggleBool(b, msg)
  if (not b or b == nil) then
    b = true;
    SMARTBUFF_AddMsg(SMARTBUFF_TITLE .. ": " .. msg .. GR .. "On", true);
  else
    b = false
    SMARTBUFF_AddMsg(SMARTBUFF_TITLE .. ": " .. msg .. RD .. "Off", true);
  end
  return b;
end

function SMARTBUFF_BoolState(b, msg)
  if (b) then
    SMARTBUFF_AddMsg(SMARTBUFF_TITLE .. ": " .. msg .. GR .. "On", true);
  else
    SMARTBUFF_AddMsg(SMARTBUFF_TITLE .. ": " .. msg .. RD .. "Off", true);
  end
end

function SMARTBUFF_Split(msg, char)
  local arr = {};
  while (string.find(msg, char)) do
    local iStart, iEnd = string.find(msg, char);
    table.insert(arr, string.sub(msg, 1, iStart - 1));
    msg = string.sub(msg, iEnd + 1, string.len(msg));
  end
  if (string.len(msg) > 0) then
    table.insert(arr, msg);
  end
  return arr;
end

-- END Bool helper functions


-- Init the SmartBuff variables ---------------------------------------------------------------------------------------
function SMARTBUFF_Options_Init(self)

  if (SmartBuff_Initialized) then return; end

  self:UnregisterEvent("CHAT_MSG_CHANNEL");
  self:UnregisterEvent("UPDATE_MOUSEOVER_UNIT");

  --DebugChatFrame:AddMessage("Starting init SB");

  _, PlayerClass = UnitClass("player");
  RealmName = GetRealmName();
  PlayerName = UnitName("player");
  PlayerID = RealmName .. ":" .. PlayerName;
  --AutoSelfCast = GetCVar("autoSelfCast");

  SMARTBUFF_PLAYERCLASS = PlayerClass;

  if (not SMARTBUFF_Buffs) then SMARTBUFF_Buffs = {}; end
  B = SMARTBUFF_Buffs;
  if (not SMARTBUFF_Options) then SMARTBUFF_Options = {}; end
  O = SMARTBUFF_Options;

  SMARTBUFF_BROKER_SetIcon();


  if (O.SmartBuff_Enabled == nil) then O.SmartBuff_Enabled = true; end
  if (O.ToggleReminder == nil) then O.ToggleReminder = true; end
  if (O.TimeBetweenChecks == nil) then O.TimeBetweenChecks = 5; end
  if (O.BlacklistTimer == nil) then O.BlacklistTimer = 5; end
  if (O.ToggleReminderCombat == nil) then O.ToggleReminderCombat = false; end
  if (O.ToggleReminderChat == nil) then O.ToggleReminderChat = false; end
  if (O.ToggleReminderSplash == nil) then O.ToggleReminderSplash = true; end
  if (O.ToggleReminderSound == nil) then O.ToggleReminderSound = true; end
  if (O.AutoSoundSelection == nil) then O.AutoSoundSelection = 4; end
  if (O.CheckCharges == nil) then O.CheckCharges = true; end
  --if (O.ToggleAutoRest == nil) then  O.ToggleAutoRest = true; end
  if (O.RebuffTimer == nil) then O.RebuffTimer = 20; end
  if (O.SplashDuration == nil) then O.SplashDuration = 2; end
  if (O.SplashIconSize == nil) then O.SplashIconSize = 16; end

  if (O.BuffTarget == nil) then O.BuffTarget = false; end
  if (O.BuffPvP == nil) then O.BuffPvP = false; end
  if (O.BuffInCities == nil) then O.BuffInCities = true; end
  if (O.LinkSelfBuffCheck == nil) then O.LinkSelfBuffCheck = true; end
  if (O.LinkGrpBuffCheck == nil) then O.LinkGrpBuffCheck = true; end
  if (O.AntiDaze == nil) then O.AntiDaze = true; end

  if (O.ScrollWheel ~= nil and O.ScrollWheelUp == nil) then O.ScrollWheelUp = O.ScrollWheel; end
  if (O.ScrollWheel ~= nil and O.ScrollWheelDown == nil) then O.ScrollWheelDown = O.ScrollWheel; end
  if (O.ScrollWheelUp == nil) then O.ScrollWheelUp = true; end
  if (O.ScrollWheelDown == nil) then O.ScrollWheelDown = true; end

  if (O.InCombat == nil) then O.InCombat = true; end
  if (O.IncludeToys == nil) then O.IncludeToys = false; end
  if (O.AutoSwitchTemplate == nil) then O.AutoSwitchTemplate = true; end
  if (O.AutoSwitchTemplateInst == nil) then O.AutoSwitchTemplateInst = true; end
  if (O.InShapeshift == nil) then O.InShapeshift = true; end

  O.ToggleGrp = { true, true, true, true, true, true, true, true };

  if (O.ToggleMsgNormal == nil) then O.ToggleMsgNormal = false; end
  if (O.ToggleMsgWarning == nil) then O.ToggleMsgWarning = false; end
  if (O.ToggleMsgError == nil) then O.ToggleMsgError = false; end

  if (O.HideMmButton == nil) then O.HideMmButton = false; end
  if (O.HideSAButton == nil) then O.HideSAButton = false; end

  if (O.SBButtonFix == nil) then O.SBButtonFix = false; end
  if (O.SBButtonDownVal == nil) then O.SBButtonDownVal = C_CVar.GetCVar("ActionButtonUseKeyDown"); end

  if (O.MinCharges == nil) then
    if (PlayerClass == "SHAMAN" or PlayerClass == "PRIEST") then
      O.MinCharges = 1;
    else
      O.MinCharges = 3;
    end
  end

  if (not O.AddList) then O.AddList = {}; end
  if (not O.IgnoreList) then O.IgnoreList = {}; end

  if (O.LastTemplate == nil) then O.LastTemplate = SMARTBUFF_TEMPLATES[1]; end
  local found = false;

  for i=1, #SMARTBUFF_TEMPLATES do
    if (SMARTBUFF_TEMPLATES[i] == O.LastTemplate) then
      found = true;
      break;
    end
  end
  if (not found) then
    O.LastTemplate = SMARTBUFF_TEMPLATES[1];
  end

  CurrentTemplate = O.LastTemplate;
  CurrentSpec = GetSpecialization();

  if (O.OldWheelUp == nil) then O.OldWheelUp = ""; end
  if (O.OldWheelDown == nil) then O.OldWheelDown = ""; end

  SMARTBUFF_InitActionButtonPos();

  if (O.SplashX == nil) then O.SplashX = 100; end
  if (O.SplashY == nil) then O.SplashY = -100; end
  if (O.CurrentFont == nil) then O.CurrentFont = 9; end
  if (O.ColSplashFont == nil) then
    O.ColSplashFont = {};
    O.ColSplashFont.r = 1.0;
    O.ColSplashFont.g = 1.0;
    O.ColSplashFont.b = 1.0;
  end
  CurrentFont = O.CurrentFont;

  if (O.Debug == nil) then O.Debug = false; end

  -- Cosmos support
  if (EarthFeature_AddButton) then
    EarthFeature_AddButton(
      { id = SMARTBUFF_TITLE;
        name = SMARTBUFF_TITLE;
        subtext = SMARTBUFF_TITLE;
        tooltip = "";
        icon = ImgSB;
        callback = SMARTBUFF_OptionsFrame_Toggle;
        test = nil;
      })
  elseif (Cosmos_RegisterButton) then
    Cosmos_RegisterButton(SMARTBUFF_TITLE, SMARTBUFF_TITLE, SMARTBUFF_TITLE, ImgSB, SMARTBUFF_OptionsFrame_Toggle);
  end

  if (IsAddOnLoaded("Parrot")) then
    IsParrot = true;
  end

  SMARTBUFF_FindItemInfo(0);

  SMARTBUFF_AddMsg(SMARTBUFF_VERS_TITLE .. " " .. SMARTBUFF_MSG_LOADED, true);
  SMARTBUFF_AddMsg("/sbm - " .. SMARTBUFF_OFT_MENU, true);
  SmartBuff_Initialized = true;

  SMARTBUFF_CheckMiniMapButton();
  SMARTBUFF_MinimapButton_OnUpdate(SmartBuff_MiniMapButton);
  SMARTBUFF_ShowSAButton();
  SMARTBUFF_Splash_Hide();

  if (O.UpgradeToDualSpec == nil) then
    for n = 1, GetNumSpecGroups(), 1 do
      if (B[n] == nil) then
        B[n] = {};
      end
      for k, v in pairs(SMARTBUFF_TEMPLATES) do
        SMARTBUFF_AddMsgD(v);
        if (B[v] ~= nil) then
          B[n][v] = B[v];
        end
      end
    end
    for k, v in pairs(SMARTBUFF_TEMPLATES) do
      if (B[v] ~= nil) then
        table.wipe(B[v]);
        B[v] = nil;
      end
    end
    O.UpgradeToDualSpec = true;
    SMARTBUFF_AddMsg("Upgraded to dual spec", true);
  end

  for k, v in pairs(Enum.Class) do
    if (SMARTBUFF_CLASSES[k] == nil) then
      SMARTBUFF_CLASSES[k] = v;
    end
  end

  if (O.VersionNr == nil or O.VersionNr < SMARTBUFF_VERSIONNR) then
    O.VersionNr = SMARTBUFF_VERSIONNR;
    SMARTBUFF_SetBuffs();
    InitBuffOrder(true);
    SMARTBUFF_AddMsg("Upgraded SmartBuff to " .. SMARTBUFF_VERSION);
  end

  if (SMARTBUFF_OptionsGlobal == nil) then SMARTBUFF_OptionsGlobal = {}; end
  OG = SMARTBUFF_OptionsGlobal;
  if (OG.SplashIcon == nil) then OG.SplashIcon = true; end
  if (OG.SplashMsgShort == nil) then OG.SplashMsgShort = false; end
  if (OG.FirstStart == nil) then OG.FirstStart = "V0"; end

  SMARTBUFF_Splash_ChangeFont(Enum.State.STATE_START_BUFF);
  SMARTBUFF_BuffOrderReset();
  if (OG.FirstStart ~= SMARTBUFF_VERSION) then
    OG.FirstStart = SMARTBUFF_VERSION;
    SMARTBUFF_OptionsFrame_Open(true);

    if (OG.Tutorial == nil) then
      OG.Tutorial = SMARTBUFF_VERSIONNR;
      SMARTBUFF_ToggleTutorial();
    end

    SmartBuffWNF_lblText:SetText(SMARTBUFF_WHATSNEW);
    SmartBuffWNF:Show();
    SMARTBUFF_BuffOrderReset()

  else
    SMARTBUFF_SetBuffs();
  end

  if (not IsVisibleToPlayer(SmartBuff_KeyButton)) then
    SmartBuff_KeyButton:ClearAllPoints();
    SmartBuff_KeyButton:SetPoint("CENTER", UIParent, "CENTER", 0, 100);
  end

  SMARTBUFF_SetUnits();
  SMARTBUFF_RebindKeys();
  IsSyncReq = true;
end
-- END SMARTBUFF_Options_Init

function SMARTBUFF_InitActionButtonPos()
  if (InCombatLockdown()) then return end

  SmartBuff_ActionButtionInitialized = true;
  if (O.ActionBtnX == nil) then
    SMARTBUFF_SetButtonPos(SmartBuff_KeyButton);
  else
    SmartBuff_KeyButton:ClearAllPoints();
    SmartBuff_KeyButton:SetPoint("TOPLEFT", UIParent, "TOPLEFT", O.ActionBtnX, O.ActionBtnY);
  end
  --print(string.format("x = %.0f, y = %.0f", O.ActionBtnX, O.ActionBtnY));
end

function SMARTBUFF_ResetAll()
  table.wipe(SMARTBUFF_Buffs);
  table.wipe(SMARTBUFF_Options);
  ReloadUI();
end

function SMARTBUFF_SetButtonPos(self)
  local x, y = self:GetLeft(), self:GetTop() - UIParent:GetHeight();
  O.ActionBtnX = x;
  O.ActionBtnY = y;
  --print(string.format("x = %.0f, y = %.0f", x, y));
end

function SMARTBUFF_RebindKeys()
  local i;
  IsRebinding = true;
  for i = 1, GetNumBindings(), 1 do
    local s = "";
    local command, key1, key2 = GetBinding(i);

    --if (command and key1) then
    --  SMARTBUFF_AddMsgD(i .. " = " .. command .. " - " .. key1;
    --end

    if (key1 and key1 == "MOUSEWHEELUP" and command ~= "SmartBuff_KeyButton") then
      O.OldWheelUp = command;
      --SMARTBUFF_AddMsgD("Old wheel up: " .. command);
    elseif (key1 and key1 == "MOUSEWHEELDOWN" and command ~= "SmartBuff_KeyButton") then
      O.OldWheelDown = command;
      --SMARTBUFF_AddMsgD("Old wheel down: " .. command);
    end

    if (command and command == "SMARTBUFF_BIND_TRIGGER") then
      --s = i .. " = " .. command;
      if (key1) then
        --s = s .. ", key1 = " .. key1 .. " rebound";
        SetBindingClick(key1, "SmartBuff_KeyButton");
      end
      if (key2) then
        --s = s .. ", key2 = " .. key2 .. " rebound";
        SetBindingClick(key2, "SmartBuff_KeyButton");
      end
      --SMARTBUFF_AddMsgD(s);
      break;
    end
  end

  if (O.ScrollWheelUp) then
    IsKeyUpChanged = true;
    SetOverrideBindingClick(SmartBuffFrame, false, "MOUSEWHEELUP", "SmartBuff_KeyButton", "MOUSEWHEELUP");
    --SMARTBUFF_AddMsgD("Set wheel up");
  else
    if (IsKeyUpChanged) then
      IsKeyUpChanged = false;
      SetOverrideBinding(SmartBuffFrame, false, "MOUSEWHEELUP");
      --SMARTBUFF_AddMsgD("Set old wheel up: " .. O.OldWheelUp);
    end
  end

  if (O.ScrollWheelDown) then
    IsKeyDownChanged = true;
    SetOverrideBindingClick(SmartBuffFrame, false, "MOUSEWHEELDOWN", "SmartBuff_KeyButton", "MOUSEWHEELDOWN");
    --SMARTBUFF_AddMsgD("Set wheel down");
  else
    if (IsKeyDownChanged) then
      IsKeyDownChanged = false;
      SetOverrideBinding(SmartBuffFrame, false, "MOUSEWHEELDOWN");
      --SMARTBUFF_AddMsgD("Set old wheel down: " .. O.OldWheelDown);
    end
  end
  IsRebinding = false;
end

function SMARTBUFF_ResetBindings()
  if (not IsRebinding) then
    IsRebinding = true;
    if (O.OldWheelUp == "SmartBuff_KeyButton") then
      SetBinding("MOUSEWHEELUP", "CAMERAZOOMIN");
    else
      SetBinding("MOUSEWHEELUP", O.OldWheelUp);
    end
    if (O.OldWheelDown == "SmartBuff_KeyButton") then
      SetBinding("MOUSEWHEELDOWN", "CAMERAZOOMOUT");
    else
      SetBinding("MOUSEWHEELDOWN", O.OldWheelDown);
    end
    SaveBindings(GetCurrentBindingSet());
    SMARTBUFF_RebindKeys();
  end
end

-- SmartBuff commandline menu ---------------------------------------------------------------------------------------
function SMARTBUFF_command(msg)
  if (not SmartBuff_Initialized) then
    SMARTBUFF_AddMsgWarn(SMARTBUFF_VERS_TITLE .. " not initialized correctly!", true);
    return;
  end

  if (msg == "toggle" or msg == "t") then
    SMARTBUFF_OToggle();
    SMARTBUFF_SetUnits();
  elseif (msg == "menu") then
    SMARTBUFF_OptionsFrame_Toggle();
  elseif (msg == "rbt") then
    SMARTBUFF_ResetBuffTimers();
  elseif (msg == "sbt") then
    SMARTBUFF_ShowBuffTimers();
  elseif (msg == "target") then
    if (SMARTBUFF_PreCheck(Enum.State.STATE_START_BUFF)) then
      SMARTBUFF_checkBlacklist();
      for i, buffID in pairs(B[CS()].Order) do
        SMARTBUFF_TryBuffUnit("target", 0, Enum.State.STATE_START_BUFF, buffID);
      end
    end
  elseif (msg == "debug") then
    O.Debug = SMARTBUFF_toggleBool(O.Debug, "Debug active = ");
  elseif (msg == "open") then
    SMARTBUFF_OptionsFrame_Open(true);
  elseif (msg == "sync") then
    SMARTBUFF_SyncBuffTimers();
  elseif (msg == "rb") then
    SMARTBUFF_ResetBindings();
    SMARTBUFF_AddMsg("SmartBuff key and mouse bindings reset.", true);
  elseif (msg == "rafp") then
    SmartBuffSplashFrame:ClearAllPoints();
    SmartBuffSplashFrame:SetPoint("CENTER", UIParent, "CENTER");
    SmartBuff_MiniMapButton:ClearAllPoints();
    SmartBuff_MiniMapButton:SetPoint("TOPLEFT", Minimap, "TOPLEFT");
    SmartBuff_KeyButton:ClearAllPoints();
    SmartBuff_KeyButton:SetPoint("CENTER", UIParent, "CENTER");
    SmartBuffOptionsFrame:ClearAllPoints();
    SmartBuffOptionsFrame:SetPoint("CENTER", UIParent, "CENTER");
  elseif (msg == "test") then

    -- Test Code ******************************************
    -- ****************************************************
    --local spellname = "Mind--numbing Poison";
    --SMARTBUFF_AddMsg("Original: " .. spellname, true);
    --if (string.find(spellname, "%-%-") ~= nil) then
    --  spellname = string.gsub(spellname, "%-%-", "%-");
    --end
    --SMARTBUFF_AddMsg("Modified: " .. spellname, true);
    -- ****************************************************
    -- ****************************************************
  elseif (msg == "changes") then
    SMARTBUFF_OptionsFrame_Open(true);
    SmartBuffWNF_lblText:SetText(SMARTBUFF_WHATSNEW);
    SmartBuffWNF:Show();
  elseif (msg == "reload") then
    SMARTBUFF_BuffOrderReset();
    SMARTBUFF_OptionsFrame_Open(true);
  elseif (msg == "changelog") then
    SmartBuffWNF_lblText:SetText(SMARTBUFF_WHATSNEW);
    SmartBuffWNF:Show();
  else
    --SMARTBUFF_Check(0);
    SMARTBUFF_AddMsg(SMARTBUFF_VERS_TITLE, true);
    SMARTBUFF_AddMsg("Syntax: /sbo [command] or /sbuff [command] or /smartbuff [command]", true);
    SMARTBUFF_AddMsg("toggle -  " .. SMARTBUFF_OFT, true);
    SMARTBUFF_AddMsg("menu  -  " .. SMARTBUFF_OFT_MENU, true);
    SMARTBUFF_AddMsg("target  -  " .. SMARTBUFF_OFT_TARGET, true);
    SMARTBUFF_AddMsg("rbt       -  " .. "Reset buff timers", true);
    SMARTBUFF_AddMsg("sbt      -  " .. "Show buff timers", true);
    SMARTBUFF_AddMsg("rafp     -  " .. "Reset all frame positions", true);
    SMARTBUFF_AddMsg("sync    -  " .. "Sync buff timers with UI", true);
    SMARTBUFF_AddMsg("rb        -  " .. "Reset key/mouse bindings", true);
    SMARTBUFF_AddMsg("new     - "  .. "Show changelog", true)
    SMARTBUFF_AddMsg("changes    -  " .. "Display changelog", true);
    SMARTBUFF_AddMsg("reload    -  " .. "Reset buff list", true)
  end
end

-- END SMARTBUFF_command


-- SmartBuff options toggle ---------------------------------------------------------------------------------------
function SMARTBUFF_OToggle()
  if (not SmartBuff_Initialized) then return; end
  O.SmartBuff_Enabled = SMARTBUFF_toggleBool(O.SmartBuff_Enabled, "Active = ");
  SMARTBUFF_CheckMiniMapButton();
  if (O.SmartBuff_Enabled) then
    SMARTBUFF_SetUnits();
  end
end

function SMARTBUFF_OToggleAuto()
  O.ToggleReminder = not O.ToggleReminder;
end

function SMARTBUFF_OToggleAutoCombat()
  O.ToggleReminderCombat = not O.ToggleReminderCombat;
end

function SMARTBUFF_OToggleAutoChat()
  O.ToggleReminderChat = not O.ToggleReminderChat;
end

function SMARTBUFF_OToggleAutoSplash()
  O.ToggleReminderSplash = not O.ToggleReminderSplash;
end

function SMARTBUFF_OToggleAutoSound()
  O.ToggleReminderSound = not O.ToggleReminderSound;
end

--function SMARTBUFF_OToggleCheckCharges()
--  O.ToggleCheckCharges = not O.ToggleCheckCharges;
--end
--function SMARTBUFF_OToggleAutoRest()
--  O.ToggleAutoRest = not O.ToggleAutoRest;
--end

function SMARTBUFF_OAutoSwitchTmp()
  O.AutoSwitchTemplate = not O.AutoSwitchTemplate;
end

function SMARTBUFF_OAutoSwitchTmpInst()
  O.AutoSwitchTemplateInst = not O.AutoSwitchTemplateInst;
end

function SMARTBUFF_OBuffTarget()
  O.BuffTarget = not O.BuffTarget;
end

function SMARTBUFF_OBuffPvP()
  O.BuffPvP = not O.BuffPvP;
end

function SMARTBUFF_OBuffInCities()
  O.BuffInCities = not O.BuffInCities;
end

function SMARTBUFF_OLinkSelfBuffCheck()
  O.LinkSelfBuffCheck = not O.LinkSelfBuffCheck;
end

function SMARTBUFF_OLinkGrpBuffCheck()
  O.LinkGrpBuffCheck = not O.LinkGrpBuffCheck;
end

function SMARTBUFF_OAntiDaze()
  O.AntiDaze = not O.AntiDaze;
end

function SMARTBUFF_OScrollWheelUp()
  O.ScrollWheelUp = not O.ScrollWheelUp;
  IsKeyUpChanged = true;
end

function SMARTBUFF_OScrollWheelDown()
  O.ScrollWheelDown = not O.ScrollWheelDown;
  IsKeyDownChanged = true;
end

function SMARTBUFF_OInShapeshift()
  O.InShapeshift = not O.InShapeshift;
end

function SMARTBUFF_OInCombat()
  O.InCombat = not O.InCombat;
end

function SMARTBUFF_OIncludeToys()
  O.IncludeToys = not O.IncludeToys;
  SMARTBUFF_Options_OnShow();
  SMARTBUFF_BuffOrderReset();
end

function SMARTBUFF_OToggleMsgNormal()
  O.ToggleMsgNormal = not O.ToggleMsgNormal;
end

function SMARTBUFF_OToggleMsgWarning()
  O.ToggleMsgWarning = not O.ToggleMsgWarning;
end

function SMARTBUFF_OToggleMsgError()
  O.ToggleMsgError = not O.ToggleMsgError;
end

function SMARTBUFF_OHideMmButton()
  O.HideMmButton = not O.HideMmButton;
  SMARTBUFF_CheckMiniMapButton();
end

function SMARTBUFF_OHideSAButton()
  O.HideSAButton = not O.HideSAButton;
  SMARTBUFF_ShowSAButton();
end

function SMARTBUFF_OSelfFirst()
  B[CS()][CurrentTemplate].SelfFirst = not B[CS()][CurrentTemplate].SelfFirst;
end

function SMARTBUFF_OToggleBuff(s, i)
  local settings = GetBuffTemplate(Buffs[i].BuffID);
  if (settings == nil) then
    return;
  end

  if (s == "S") then
    settings.BuffEnabled = not settings.BuffEnabled;
    --SMARTBUFF_AddMsgD("OToggleBuff = "..Buffs[i].BuffID..", "..tostring(settings.IsEnabled));
    if (settings.BuffEnabled) then
      SmartBuff_BuffSetup_Show(i);
    else
      SmartBuff_BuffSetup:Hide();
      LastBuffSetup = -1;
      SmartBuff_PlayerSetup:Hide();
    end
  elseif (s == "G") then
    settings.EnableGroup = not settings.EnableGroup;
  end

end

function SMARTBUFF_OToggleDebug()
  O.Debug = not O.Debug;
end

function SMARTBUFF_ToggleFixBuffing()
  O.SBButtonFix = not O.SBButtonFix;
  if not O.SBButtonFix then C_CVar.SetCVar("ActionButtonUseKeyDown", O.SBButtonDownVal); end
end

function SMARTBUFF_OptionsFrame_Toggle()
  if (not SmartBuff_Initialized) then return; end

  if (SmartBuffOptionsFrame:IsVisible()) then
    if (LastBuffSetup > 0) then
      SmartBuff_BuffSetup:Hide();
      LastBuffSetup = -1;
      SmartBuff_PlayerSetup:Hide();
    end
    SmartBuffOptionsFrame:Hide();
  else
    SmartBuffOptionsCredits_lblText:SetText(SMARTBUFF_CREDITS);
    SmartBuffOptionsFrame:Show();
    SmartBuff_PlayerSetup:Hide();
  end

  SMARTBUFF_MinimapButton_CheckPos();
end

function SMARTBUFF_OptionsFrame_Open(force)
  if (not SmartBuff_Initialized) then return; end
  if (not SmartBuffOptionsFrame:IsVisible() or force) then
    SmartBuffOptionsFrame:Show();
  end
end

function SmartBuff_BuffSetup_Show(i)
  local icon1 = Buffs[i].Icon;
  local icon2 = Buffs[i].IconGroup;
  local buffID = Buffs[i].BuffID;
  local btype = Buffs[i].Type;
  local hidden = true;
  local n = 0;
  local template = GetBuffTemplate(buffID);

  if (buffID == nil or btype == SMARTBUFF_CONST_TRACK) then
    SmartBuff_BuffSetup:Hide();
    LastBuffSetup = -1;
    SmartBuff_PlayerSetup:Hide();
    return;
  end

  if (SmartBuff_BuffSetup:IsVisible() and i == LastBuffSetup) then
    SmartBuff_BuffSetup:Hide();
    LastBuffSetup = -1;
    SmartBuff_PlayerSetup:Hide();
    return;
  else
    if (btype == SMARTBUFF_CONST_GROUP or btype == SMARTBUFF_CONST_ITEMGROUP) then
      hidden = false;
    end

    if (icon2 and template and template.EnableGroup) then
      SmartBuff_BuffSetup_BuffIcon2:SetNormalTexture(icon2);
      SmartBuff_BuffSetup_BuffIcon2:Show();
    else
      SmartBuff_BuffSetup_BuffIcon2:Hide();
    end
    if (icon1) then
      SmartBuff_BuffSetup_BuffIcon1:SetNormalTexture(icon1);
      if (icon2 and template.EnableGroup) then
        SmartBuff_BuffSetup_BuffIcon1:SetPoint("TOPLEFT", 44, -30);
      else
        SmartBuff_BuffSetup_BuffIcon1:SetPoint("TOPLEFT", 64, -30);
      end
      SmartBuff_BuffSetup_BuffIcon1:Show();
    else
      SmartBuff_BuffSetup_BuffIcon1:SetPoint("TOPLEFT", 24, -30);
      SmartBuff_BuffSetup_BuffIcon1:Hide();
    end
    local obj = SmartBuff_BuffSetup_BuffText;
    if (buffID) then
      obj:SetText(IDToLink(buffID));
      SMARTBUFF_AddMsgD("button text:"..IDToLink(buffID));
    else
      obj:SetText("");
    end

    SmartBuff_BuffSetup_cbSelf:SetChecked(template.BuffSelfOnly);
    SmartBuff_BuffSetup_cbSelfNot:SetChecked(template.BuffSelfNot);
    SmartBuff_BuffSetup_cbCombatIn:SetChecked(template.BuffInCombat);
    SmartBuff_BuffSetup_cbCombatOut:SetChecked(template.BuffOutOfCombat);
    SmartBuff_BuffSetup_cbMH:SetChecked(template.BuffMainHand);
    SmartBuff_BuffSetup_cbOH:SetChecked(template.BuffOffHand);
    SmartBuff_BuffSetup_cbRH:SetChecked(template.BuffRightHand);
    SmartBuff_BuffSetup_cbReminder:SetChecked(template.BuffReminder);
    SmartBuff_BuffSetup_txtManaLimit:SetNumber(template.ManaLimit);

    --SMARTBUFF_AddMsgD("Test Buff setup show 1");
    if (Buffs[i].Duration > 0) then
      SmartBuff_BuffSetup_RBTime:SetMinMaxValues(0, Buffs[i].Duration);
      _G[SmartBuff_BuffSetup_RBTime:GetName() .. "High"]:SetText(Buffs[i].Duration);
      if (Buffs[i].Duration <= 60) then
        SmartBuff_BuffSetup_RBTime:SetValueStep(1);
      elseif (Buffs[i].Duration <= 180) then
        SmartBuff_BuffSetup_RBTime:SetValueStep(5);
      elseif (Buffs[i].Duration <= 600) then
        SmartBuff_BuffSetup_RBTime:SetValueStep(10);
      else
        SmartBuff_BuffSetup_RBTime:SetValueStep(30);
      end
      SmartBuff_BuffSetup_RBTime:SetValue(template.RebuffTime);
      _G[SmartBuff_BuffSetup_RBTime:GetName() .. "Text"]:SetText(template.RebuffTime .. "\nsec");
      SmartBuff_BuffSetup_RBTime:Show();
    else
      SmartBuff_BuffSetup_RBTime:Hide();
    end
    --SMARTBUFF_AddMsgD("Test Buff setup show 2");

    SmartBuff_BuffSetup_txtManaLimit:Hide();
    if (Buffs[i].Type == SMARTBUFF_CONST_INV or Buffs[i].Type == SMARTBUFF_CONST_WEAPON) then
      SmartBuff_BuffSetup_cbMH:Show();
      SmartBuff_BuffSetup_cbOH:Show();
      SmartBuff_BuffSetup_cbRH:Hide();
    else
      SmartBuff_BuffSetup_cbMH:Hide();
      SmartBuff_BuffSetup_cbOH:Hide();
      SmartBuff_BuffSetup_cbRH:Hide();
      if (
          Buffs[i].Type ~= SMARTBUFF_CONST_FOOD and Buffs[i].Type ~= SMARTBUFF_CONST_SCROLL and
              Buffs[i].Type ~= SMARTBUFF_CONST_POTION) then
        SmartBuff_BuffSetup_txtManaLimit:Show();
        --SMARTBUFF_AddMsgD("Show ManaLimit");
      end
    end

    if (Buffs[i].Type == SMARTBUFF_CONST_GROUP or Buffs[i].Type == SMARTBUFF_CONST_ITEMGROUP) then
      SmartBuff_BuffSetup_cbSelf:Show();
      SmartBuff_BuffSetup_cbSelfNot:Show();
      SmartBuff_BuffSetup_btnPriorityList:Show();
      SmartBuff_BuffSetup_btnIgnoreList:Show();
    else
      SmartBuff_BuffSetup_cbSelf:Hide();
      SmartBuff_BuffSetup_cbSelfNot:Hide();
      SmartBuff_BuffSetup_btnPriorityList:Hide();
      SmartBuff_BuffSetup_btnIgnoreList:Hide();
      SmartBuff_PlayerSetup:Hide();
    end

    local checkBox = nil;
    local btn = nil;
    n = 0;
    --SMARTBUFF_AddMsgD("Test Buff setup show 3");
    for _ in pairs(Enum.Class) do
      n = n + 1;
      checkBox = _G["SmartBuff_BuffSetup_cbClass" .. n];
      btn = _G["SmartBuff_BuffSetup_ClassIcon" .. n];
      if (hidden) then
        checkBox:Hide();
        btn:Hide();
      else
        checkBox:SetChecked(template[Enum.Class[n]]);
        checkBox:Show();
        btn:Show();
      end
    end
    LastBuffSetup = i;
    --SMARTBUFF_AddMsgD("Test Buff setup show 4");
    SmartBuff_BuffSetup:Show();

    if (SmartBuff_PlayerSetup:IsVisible()) then
      SmartBuff_PS_Show(CurrentList);
    end
  end
end

function SmartBuff_BuffSetup_ManaLimitChanged(self)
  local i = LastBuffSetup;
  if (i <= 0) then
    return;
  end
  local ct = CurrentTemplate;
  local buffID = Buffs[i].BuffID;
  B[CS()][ct][buffID].ManaLimit = self:GetNumber();
end

function SmartBuff_BuffSetup_OnClick()
  local i = LastBuffSetup;
  local ct = CurrentTemplate;
  if (i <= 0) then
    return;
  end
  local buffID = Buffs[i].BuffID;
  local Buff = GetBuffTemplate(buffID);

  Buff.BuffSelfOnly    = SmartBuff_BuffSetup_cbSelf:GetChecked();
  Buff.BuffSelfNot     = SmartBuff_BuffSetup_cbSelfNot:GetChecked();
  Buff.BuffInCombat    = SmartBuff_BuffSetup_cbCombatIn:GetChecked();
  Buff.BuffOutOfCombat = SmartBuff_BuffSetup_cbCombatOut:GetChecked();
  Buff.BuffMainHand    = SmartBuff_BuffSetup_cbMH:GetChecked();
  Buff.BuffOffHand     = SmartBuff_BuffSetup_cbOH:GetChecked();
  Buff.BuffRightHand   = SmartBuff_BuffSetup_cbRH:GetChecked();
  Buff.BuffReminder    = SmartBuff_BuffSetup_cbReminder:GetChecked();

  Buff.RebuffTime = SmartBuff_BuffSetup_RBTime:GetValue();
  _G[SmartBuff_BuffSetup_RBTime:GetName() .. "Text"]:SetText(Buff.RebuffTime .. "\nsec");

  if (Buffs[i].Type == SMARTBUFF_CONST_GROUP or Buffs[i].Type == SMARTBUFF_CONST_ITEMGROUP) then
    local n = 0;
    ---@type Widget
    local checkBox = nil;
    for _ in pairs(Enum.Class) do
      n = n + 1;
      checkBox = _G["SmartBuff_BuffSetup_cbClass" .. n];
      Buff[Enum.Class[n]] = checkBox:GetChecked();
    end
  end
  SMARTBUFF_AddMsgD("Buff setup saved");
end

function SmartBuff_BuffSetup_ToolTip(state)
  local i = LastBuffSetup;
  if (i <= 0) then
    return;
  end

  GameTooltip:ClearLines();
  if (SMARTBUFF_IsItem(Buffs[i].Type)) then
    local bag, slot, count, texture = SMARTBUFF_FindItemInfo(Buffs[i].BuffID, Buffs[i].Chain);
    if (bag and slot) then
      if (bag == 999) then -- Toy
        GameTooltip:SetToyByItemID(slot);
      else
        GameTooltip:SetBagItem(bag, slot);
      end
    end
  else
    if (state == Enum.State.STATE_REBUFF_CHECK and Buffs[i].BuffID) then
      local link = BuffToLink(Buffs[i]);
      if (link) then GameTooltip:SetHyperlink(link); end
    elseif (state == Enum.State.STATE_UI_BUSY and Buffs[i].GroupBuffID) then
      local link = GetSpellLink(Buffs[i].GroupBuffID);
      if (link) then GameTooltip:SetHyperlink(link); end
    end
  end
  GameTooltip:Show();
end

-- END SmartBuff options toggle


-- Options frame functions ---------------------------------------------------------------------------------------
function SMARTBUFF_Options_OnLoad(self)
end

function SMARTBUFF_Options_OnShow()
  -- Check if the options frame is out of screen area
  local top    = GetScreenHeight() - math.abs(SmartBuffOptionsFrame:GetTop());
  local bottom = GetScreenHeight() - math.abs(SmartBuffOptionsFrame:GetBottom());
  local left   = SmartBuffOptionsFrame:GetLeft();
  local right  = SmartBuffOptionsFrame:GetRight();

  --SMARTBUFF_AddMsgD("X: " .. GetScreenWidth() .. ", " .. left .. ", " .. right);
  --SMARTBUFF_AddMsgD("Y: " .. GetScreenHeight() .. ", " .. top .. ", " .. bottom);

  if (GetScreenWidth() < left + 20 or GetScreenHeight() < top + 20 or right < 20 or bottom < 20) then
    SmartBuffOptionsFrame:SetPoint("TOPLEFT", UIParent, "CENTER", -SmartBuffOptionsFrame:GetWidth() / 2,
      SmartBuffOptionsFrame:GetHeight() / 2);
  end

  SmartBuff_ShowControls("SmartBuffOptionsFrame", true);

  INT_SPELL_DURATION_SEC = _G.INT_SPELL_DURATION_SEC

  SmartBuffOptionsFrame_cbSB:SetChecked(O.SmartBuff_Enabled);
  SmartBuffOptionsFrame_cbAuto:SetChecked(O.ToggleReminder);
  SmartBuffOptionsFrameAutoTimer:SetValue(O.TimeBetweenChecks);
  SmartBuff_SetSliderText(SmartBuffOptionsFrameAutoTimer, SMARTBUFF_OFT_AUTOTIMER, O.TimeBetweenChecks, INT_SPELL_DURATION_SEC);
  SmartBuffOptionsFrame_cbAutoCombat:SetChecked(O.ToggleReminderCombat);
  SmartBuffOptionsFrame_cbAutoChat:SetChecked(O.ToggleReminderChat);
  SmartBuffOptionsFrame_cbAutoSplash:SetChecked(O.ToggleReminderSplash);
  SmartBuffOptionsFrame_cbAutoSound:SetChecked(O.ToggleReminderSound);

  --SmartBuffOptionsFrame_cbCheckCharges:SetChecked(O.ToggleCheckCharges);
  --SmartBuffOptionsFrame_cbAutoRest:SetChecked(O.ToggleAutoRest);
  SmartBuffOptionsFrame_cbAutoSwitchTmp:SetChecked(O.AutoSwitchTemplate);
  SmartBuffOptionsFrame_cbAutoSwitchTmpInst:SetChecked(O.AutoSwitchTemplateInst);
  SmartBuffOptionsFrame_cbBuffPvP:SetChecked(O.BuffPvP);
  SmartBuffOptionsFrame_cbBuffTarget:SetChecked(O.BuffTarget);
  SmartBuffOptionsFrame_cbBuffInCities:SetChecked(O.BuffInCities);
  SmartBuffOptionsFrame_cbInShapeshift:SetChecked(O.InShapeshift);
  SmartBuffOptionsFrame_cbFixBuffIssue:SetChecked(O.SBButtonFix);

  SmartBuffOptionsFrame_cbAntiDaze:SetChecked(O.AntiDaze);
  SmartBuffOptionsFrame_cbLinkGrpBuffCheck:SetChecked(O.LinkGrpBuffCheck);
  SmartBuffOptionsFrame_cbLinkSelfBuffCheck:SetChecked(O.LinkSelfBuffCheck);

  SmartBuffOptionsFrame_cbScrollWheelUp:SetChecked(O.ScrollWheelUp);
  SmartBuffOptionsFrame_cbScrollWheelDown:SetChecked(O.ScrollWheelDown);
  SmartBuffOptionsFrame_cbInCombat:SetChecked(O.InCombat);
  SmartBuffOptionsFrame_cbIncludeToys:SetChecked(O.IncludeToys);
  SmartBuffOptionsFrame_cbMsgNormal:SetChecked(O.ToggleMsgNormal);
  SmartBuffOptionsFrame_cbMsgWarning:SetChecked(O.ToggleMsgWarning);
  SmartBuffOptionsFrame_cbMsgError:SetChecked(O.ToggleMsgError);
  SmartBuffOptionsFrame_cbHideMmButton:SetChecked(O.HideMmButton);
  SmartBuffOptionsFrame_cbHideSAButton:SetChecked(O.HideSAButton);

  SmartBuffOptionsFrameRebuffTimer:SetValue(O.RebuffTimer);
  SmartBuff_SetSliderText(SmartBuffOptionsFrameRebuffTimer, SMARTBUFF_OFT_REBUFFTIMER, O.RebuffTimer,
    INT_SPELL_DURATION_SEC);
  SmartBuffOptionsFrameBLDuration:SetValue(O.BlacklistTimer);
  SmartBuff_SetSliderText(SmartBuffOptionsFrameBLDuration, SMARTBUFF_OFT_BLDURATION, O.BlacklistTimer,
    INT_SPELL_DURATION_SEC);

  SMARTBUFF_SetCheckButtonBuffs(0);

  SmartBuffOptionsFrame_cbSelfFirst:SetChecked(B[CS()][CurrentTemplate].SelfFirst);

  SMARTBUFF_Splash_Show();

  SMARTBUFF_AddMsgD("Option frame updated: " .. CurrentTemplate);
end

function SMARTBUFF_ShowSubGroups(frame, grpTable)
  for i = 1, 8, 1 do
    local obj = _G[frame .. "_cbGrp" .. i];
    if (obj) then
      obj:SetChecked(grpTable[i]);
    end
  end
end

function SMARTBUFF_Options_OnHide()
  if (SmartBuffWNF:IsVisible()) then
    SmartBuffWNF:Hide();
  end
  SMARTBUFF_ToggleTutorial(true);
  SmartBuffOptionsFrame:SetHeight(SMARTBUFF_OPTIONSFRAME_HEIGHT);
  --SmartBuff_BuffSetup:SetHeight(SMARTBUFF_OPTIONSFRAME_HEIGHT);
  table.wipe(CombatBuffs);
  SMARTBUFF_SetInCombatBuffs();
  SmartBuff_BuffSetup:Hide();
  SmartBuff_PlayerSetup:Hide();
  SMARTBUFF_SetUnits();
  SMARTBUFF_Splash_Hide();
  SMARTBUFF_RebindKeys();
  --collectgarbage();
end

function SmartBuff_ShowControls(sName, bShow)
  local children = { _G[sName]:GetChildren() };
  for i, child in pairs(children) do
    --SMARTBUFF_AddMsgD(i .. ": " .. child:GetName());
    if (i > 1 and string.find(child:GetName(), "^" .. sName .. ".+")) then
      if (bShow) then
        child:Show();
      else
        child:Hide();
      end
    end
  end
end

function SmartBuffOptionsFrameSlider_OnLoad(self, low, high, step, labels)
  GameFontNormalSmall = _G.GameFontNormalSmall;
  _G[self:GetName() .. "Text"]:SetFontObject(_G.GameFontNormalSmall);
  if (labels) then
    if (self:GetOrientation() ~= "VERTICAL") then
      _G[self:GetName() .. "Low"]:SetText(low);
    else
      _G[self:GetName() .. "Low"]:SetText("");
    end
    _G[self:GetName() .. "High"]:SetText(high);
  else
    _G[self:GetName() .. "Low"]:SetText("");
    _G[self:GetName() .. "High"]:SetText("");
  end
  self:SetMinMaxValues(low, high);
  self:SetValueStep(step);
  self:SetStepsPerPage(step);

  if (step < 1) then return; end

  self.GetValueBase = self.GetValue;
  self.GetValue = function()
    local n = self:GetValueBase();
    if (n) then
      local returnValue = Round(n);
      if (returnValue ~= n) then
        self:SetValue(n);
      end
      return returnValue;
    end
    return low;
  end;
end

function SmartBuff_SetSliderText(self, text, value, valformat, setval)
  if (not self or not value) then return end
  local s;
  if (setval) then self:SetValue(value) end
  if (valformat) then
    s = string.format(valformat, value);
  else
    s = tostring(value);
  end
  _G[self:GetName() .. "Text"]:SetText(text .. " " .. WH .. s .. "|r");

end

function SmartBuff_BuffSetup_RBTime_OnValueChanged(self)
  _G[SmartBuff_BuffSetup_RBTime:GetName() .. "Text"]:SetText(WH .. string.format("%.0f", self:GetValue()) .. "\nsec|r");
end

function SMARTBUFF_SetCheckButtonBuffs(state)
  local objS;
  local objG;
  local i = 1;
  local ct = CurrentTemplate;

  if (state == Enum.State.STATE_START_BUFF) then
    SMARTBUFF_SetBuffs();
  end

  SmartBuffOptionsFrame_cbAntiDaze:Hide();

  if (PlayerClass == "HUNTER" or PlayerClass == "ROGUE" or PlayerClass == "WARRIOR") then
    SmartBuffOptionsFrameBLDuration:Hide();
    if (PlayerClass == "HUNTER") then
      SmartBuffOptionsFrame_cbLinkGrpBuffCheck:Hide();
      SmartBuffOptionsFrame_cbAntiDaze:Show();
    end
  end

  if (PlayerClass == "DRUID" or PlayerClass == "SHAMAN") then
    SmartBuffOptionsFrame_cbInShapeshift:Show();
  else
    SmartBuffOptionsFrame_cbInShapeshift:Hide();
  end

  SMARTBUFF_BuffOrderOnScroll();
end

function SMARTBUFF_DropDownTemplate_OnShow(self)
  local i = 0;
  for _, tmp in pairs(SMARTBUFF_TEMPLATES) do
    i = i + 1;
    --SMARTBUFF_AddMsgD(i .. "." .. tmp);
    if (tmp == CurrentTemplate) then
      break;
    end
  end
  UIDropDownMenu_Initialize(self, SMARTBUFF_DropDownTemplate_Initialize);
  UIDropDownMenu_SetSelectedValue(SmartBuffOptionsFrame_ddTemplates, i);
  UIDropDownMenu_SetWidth(SmartBuffOptionsFrame_ddTemplates, 135);
end

function SMARTBUFF_DropDownTemplate_Initialize()
  local info = UIDropDownMenu_CreateInfo();
  info.text = ALL;
  info.value = -1;
  info.func = SMARTBUFF_DropDownTemplate_OnClick;
  for k, v in pairs(SMARTBUFF_TEMPLATES) do
    info.text = SMARTBUFF_TEMPLATES[k];
    info.value = k;
    info.func = SMARTBUFF_DropDownTemplate_OnClick;
    info.checked = nil;
    UIDropDownMenu_AddButton(info);
  end
end

function SMARTBUFF_DropDownTemplate_OnClick(self)
  local i = self.value;
  local tmp = nil;
  UIDropDownMenu_SetSelectedValue(SmartBuffOptionsFrame_ddTemplates, i);
  tmp = SMARTBUFF_TEMPLATES[i];
  --SMARTBUFF_AddMsgD("Selected/Current Buff-Template: " .. tmp .. "/" .. CurrentTemplate);
  if (CurrentTemplate ~= tmp) then
    SmartBuff_BuffSetup:Hide();
    LastBuffSetup = -1;
    SmartBuff_PlayerSetup:Hide();

    CurrentTemplate = tmp;
    SMARTBUFF_Options_OnShow();
    O.LastTemplate = CurrentTemplate;
  end
end

-- END Options frame functions


-- Splash screen functions ---------------------------------------------------------------------------------------
function SMARTBUFF_Splash_Show()
  if (not SmartBuff_Initialized) then return; end
  SMARTBUFF_Splash_ChangeFont(Enum.State.STATE_REBUFF_CHECK);
  SmartBuffSplashFrame:EnableMouse(true);
  SmartBuffSplashFrame:Show();
  SmartBuffSplashFrame:SetTimeVisible(60);
  SmartBuffSplashFrameOptions:Show();
end

function SMARTBUFF_Splash_Hide()
  if (not SmartBuff_Initialized) then return; end
  SMARTBUFF_Splash_Clear();
  SMARTBUFF_Splash_ChangePos();
  SmartBuffSplashFrame:EnableMouse(false);
  SmartBuffSplashFrame:SetFadeDuration(O.SplashDuration);
  SmartBuffSplashFrame:SetTimeVisible(O.SplashDuration);
  SmartBuffSplashFrameOptions:Hide();
end

function SMARTBUFF_Splash_Clear()
  SmartBuffSplashFrame:Clear();
end

function SMARTBUFF_Splash_ChangePos()
  local x, y = SmartBuffSplashFrame:GetLeft(), SmartBuffSplashFrame:GetTop() - UIParent:GetHeight();
  if (O) then
    O.SplashX = x;
    O.SplashY = y;
  end
end

function SMARTBUFF_Splash_ChangeFont(state)
  local f = SmartBuffSplashFrame;
  if (state > Enum.State.STATE_REBUFF_CHECK) then
    SMARTBUFF_Splash_ChangePos();
    CurrentFont = CurrentFont + 1;
  end
  if (not Enum.Font[CurrentFont]) then
    CurrentFont = 1;
  end
  O.CurrentFont = CurrentFont;
  f:ClearAllPoints();
  f:SetPoint("TOPLEFT", O.SplashX, O.SplashY);

  local fo = f:GetFontObject();
  local fName, fHeight, fFlags = _G[Enum.Font[CurrentFont]]:GetFont();
  if (state > Enum.State.STATE_REBUFF_CHECK or O.CurrentFontSize == nil) then
    O.CurrentFontSize = fHeight;
  end
  fo:SetFont(fName, O.CurrentFontSize, fFlags);
  SmartBuffSplashFrameOptions.size:SetValue(O.CurrentFontSize);

  f:SetInsertMode("TOP");
  f:SetJustifyV("MIDDLE");
  if (state > Enum.State.STATE_START_BUFF) then
    local splashIcon = "";
    if (OG.SplashIcon) then
      local n = O.SplashIconSize;
      if (n == nil or n <= 0) then
        n = O.CurrentFontSize;
      end
      splashIcon = string.format(" \124T%s:%d:%d:1:0\124t", "Interface\\Icons\\INV_Misc_QuestionMark", n, n) or "";
    else
      splashIcon = " BuffXYZ";
    end
    SMARTBUFF_Splash_Clear();
    if (OG.SplashMsgShort) then
      f:AddMessage(Enum.Font[CurrentFont] .. " >" .. splashIcon .. "\ndrag'n'drop to move", O.ColSplashFont.r, O.ColSplashFont.g,
        O.ColSplashFont.b, 1.0);
    else
      f:AddMessage(Enum.Font[CurrentFont] .. " " .. SMARTBUFF_MSG_NEEDS .. splashIcon .. "\ndrag'n'drop to move", O.ColSplashFont.r
        , O.ColSplashFont.g, O.ColSplashFont.b, 1.0);
    end
  end
end

-- END Splash screen events


-- Playerlist functions ---------------------------------------------------------------------------------------
function SmartBuff_PlayerSetup_OnShow()
end

function SmartBuff_PlayerSetup_OnHide()
end

function SmartBuff_PS_GetList()
  if (LastBuffSetup <= 0) then return {} end

  local buffID = Buffs[LastBuffSetup].BuffID;
  if (buffID) then
    if (CurrentList == 1) then
      return B[CS()][CurrentTemplate][buffID].AddList;
    else
      return B[CS()][CurrentTemplate][buffID].IgnoreList;
    end
  end
end

function SmartBuff_PS_GetUnitList()
  if (CurrentList == 1) then
    return AddUnitList;
  else
    return IgnoreUnitList;
  end
end

function SmartBuff_UnitIsAdd(unit)
  return unit and AddUnitList[unit];
end

function SmartBuff_UnitIsIgnored(unit)
  return unit and IgnoreUnitList[unit];
end

function SmartBuff_PS_Show(i)
  CurrentList = i;
  LastPlayer = -1;
  ---@type Widget
  local obj = SmartBuff_PlayerSetup_Title;
  if (CurrentList == 1) then
    obj:SetText("Additional list");
  else
    obj:SetText("Ignore list");
  end
  obj:ClearFocus();
  SmartBuff_PlayerSetup_EditBox:ClearFocus();
  SmartBuff_PlayerSetup:Show();
  SmartBuff_PS_SelectPlayer(0);
end

function SmartBuff_PS_AddPlayer()
  local cList = SmartBuff_PS_GetList();
  local unitName = UnitName("target") or "none";
  if (unitName and UnitIsPlayer("target") and (UnitInRaid("target") or UnitInParty("target") or O.Debug)) then
    if (not cList[unitName]) then
      cList[unitName] = true;
      SmartBuff_PS_SelectPlayer(0);
    end
  end
end

function SmartBuff_PS_RemovePlayer()
  local n = 0;
  local cList = SmartBuff_PS_GetList();
  for player in pairs(cList) do
    n = n + 1;
    if (n == LastPlayer) then
      cList[player] = nil;
      break;
    end
  end
  SmartBuff_PS_SelectPlayer(0);
end

function SmartBuff_AddToUnitList(idx, unit, subgroup)
  CurrentList = idx;
  local cList = SmartBuff_PS_GetList();
  local cUnitList = SmartBuff_PS_GetUnitList();
  if (unit and subgroup) then
    local unitName = UnitName(unit) or "none";
    if (unitName and cList[unitName]) then
      cUnitList[unit] = subgroup;
      --SMARTBUFF_AddMsgD("Added to UnitList:" .. unitName .. "(" .. unit .. ")");
    end
  end
end

function SmartBuff_PS_SelectPlayer(iOp)
  local idx = LastPlayer + iOp;
  local cList = SmartBuff_PS_GetList();
  local s = "";

  local tn = 0;
  for player in pairs(cList) do
    tn = tn + 1;
    s = s .. player .. "\n";
  end

  -- update list in textbox
  if (iOp == 0) then
    SmartBuff_PlayerSetup_EditBox:SetText(s);
    --SmartBuff_PlayerSetup_EditBox:ClearFocus();
  end

  -- highlight selected player
  if (tn > 0) then
    if (idx > tn) then idx = tn; end
    if (idx < 1) then idx = 1; end
    LastPlayer = idx;
    --SmartBuff_PlayerSetup_EditBox:ClearFocus();
    local n = 0;
    local i = 0;
    local w = 0;
    for player in pairs(cList) do
      n = n + 1;
      w = string.len(player);
      if (n == idx) then
        SmartBuff_PlayerSetup_EditBox:HighlightText(i + n - 1, i + n + w);
        break;
      end
      i = i + w;
    end
  end
end

function SmartBuff_PS_Resize()
  local h = SmartBuffOptionsFrame:GetHeight();
  local b = true;

  if (h < 200) then
    SmartBuffOptionsFrame:SetHeight(SMARTBUFF_OPTIONSFRAME_HEIGHT);
    --SmartBuff_BuffSetup:SetHeight(SMARTBUFF_OPTIONSFRAME_HEIGHT);
    b = true;
  else
    SmartBuffOptionsFrame:SetHeight(40);
    --SmartBuff_BuffSetup:SetHeight(40);
    b = false;
  end
  SmartBuff_ShowControls("SmartBuffOptionsFrame", b);
  if (b) then
    SMARTBUFF_SetCheckButtonBuffs(1);
  end
end
-- END Playerlist functions

-- Secure button functions, NEW TBC ---------------------------------------------------------------------------------------
function SMARTBUFF_ShowSAButton()
  if (not InCombatLockdown()) then
    if (O.HideSAButton) then
      SmartBuff_KeyButton:Hide();
    else
      SmartBuff_KeyButton:Show();
    end
  end
end

local sScript;
function SMARTBUFF_OnClick(obj)
  SMARTBUFF_AddMsgD("OnClick");
end

S.LastBuffType = "";
--- Buff the target if scrollwheel clicked. This is a SmartBuff_KeyButton
--  event, fired immediately before OnClick
---@param self self
---@param button "MOUSEWHEELUP"|"MOUSEWHEELDOWN"
---@param isButtonDown boolean
function SMARTBUFF_OnPreClick(self, button, isButtonDown)
  if (SmartBuff_Initialized) then
    local state = Enum.State.STATE_START_BUFF;
    if (button == "MOUSEWHEELUP" or button == "MOUSEWHEELDOWN") and isButtonDown then
      state = Enum.State.STATE_END_BUFF;
    end
    if (not InCombatLockdown()) then
      self:SetAttribute("type", nil);
      self:SetAttribute("unit", nil);
      self:SetAttribute("spell", nil);
      self:SetAttribute("item", nil);
      self:SetAttribute("macrotext", nil);
      self:SetAttribute("target-slot", nil);
      self:SetAttribute("target-item", nil);
      self:SetAttribute("action", nil);
    end

    --sScript = self:GetScript("OnClick");
    --self:SetScript("OnClick", SMARTBUFF_OnClick);

    local duration = gcSeconds;
    if (S.LastBuffType == "") then
      duration = 0.8;
    end
    --SMARTBUFF_AddMsgD("Last buff type: " .. S.LastBuffType .. ", set duration: " .. duration);

    --if player is channeling, add some time
    if (UnitCastingInfo("player")) then
      --print("Channeling...reset AutoBuff timer");
      TimeAutoBuff = GetTime() + 0.7;
      return;
    end

    if (GetTime() < (TimeAutoBuff + duration)) then return end

    SMARTBUFF_AddMsgD("next buff check");
    TimeAutoBuff = GetTime();
    CurrentUnit = nil;
    CurrentSpell = nil;

    -- perform the spell, or use the item, by clicking on an invisible macro button
    if (not InCombatLockdown()) then
      local result, actionType, buffID, slot, unit, buffType = SMARTBUFF_NextBuffCheck(state);
      -- if result == nil then
      --   printd("SMARTBUFF_CHECK (", table.find( Enum.State, state ) , ") nothing to do")
      -- else
      --   printd("SMARTBUFF_Check ( ", table.find( Enum.State, state ) , ") returned", table.find (Enum.Result, result) or "nil", actionType, buffID, slot, unit, buffType)
      -- end
      if ( (result == Enum.Result.SUCCESS) and actionType and buffID and unit) then
        S.lastBuffType = buffType;
        self:SetAttribute("type", actionType);
        self:SetAttribute("unit", unit);
        if (actionType == SMARTBUFF_ACTION_SPELL) then
          local spellHyperlink, spellName = SpellToLink(buffID)
          if (slot and slot > 0 and unit == "player") then
            self:SetAttribute("type", "macro");
            self:SetAttribute("macrotext", string.format("/use %s\n/use %i\n/click StaticPopup1Button1", spellName, slot));
            --printd("macrotext", string.format("/use %s\n/use %i\n/click StaticPopup1Button1", spellName, slot));
            --self:SetAttribute("target-item", slot);
            SMARTBUFF_AddMsgD("Weapon buff " .. spellName .. ", " .. slot);
          else
            --printd("SetAttribute:spell", spellName)
            self:SetAttribute("spell", spellName);
          end

          if (BuffIndex[buffID]) then
            CurrentUnit = unit;
            CurrentSpell = buffID;
          end
        elseif (actionType == SMARTBUFF_ACTION_ITEM and slot) then
          --- FIXME: macro cannot take hyperlink text, which makes it impossible to select specific quality items
          local itemHyperlink, itemName = ItemToLink(buffID)
          --printd("actiontype", actionType, "slot", slot)
          self:SetAttribute("item", itemHyperlink); -- or name?
          if (slot > 0) then
            self:SetAttribute("type", "macro");
            self:SetAttribute("macrotext", string.format("/use %s\n/use %i\n/click StaticPopup1Button1", itemName, slot));
            --printd("macrotext", string.format("/use %s\n/use %i\n/click StaticPopup1Button1", itemName, slot));
          end
        elseif (actionType == "action" and slot) then
          --printd("SetAttribute:action:", slot)
          self:SetAttribute("action", slot);
        else
          SMARTBUFF_AddMsgD("Preclick: not supported actiontype -> " .. actionType);
        end
        TimeLastChecked = GetTime() - O.TimeBetweenChecks + gcSeconds;
      end
    end
  end
end

-- TODO: add option to disable camera zooming on mousewheel
function SMARTBUFF_OnPostClick(self, button, down)
  if (SmartBuff_Initialized) then
    if (button) then
      if (button == "MOUSEWHEELUP") then
        CameraZoomIn(1);
      elseif (button == "MOUSEWHEELDOWN") then
       CameraZoomOut(1);
      end
    end

    if (InCombatLockdown()) then return end

    self:SetAttribute("type", nil);
    self:SetAttribute("unit", nil);
    self:SetAttribute("spell", nil);
    self:SetAttribute("item", nil);
    self:SetAttribute("target-slot", nil);
    self:SetAttribute("target-item", nil);
    self:SetAttribute("macrotext", nil);
    self:SetAttribute("action", nil);

    SMARTBUFF_SetButtonTexture(SmartBuff_KeyButton, ImgSB);

    --SMARTBUFF_AddMsgD("Button reset, " .. button);
    --self:SetScript("OnClick", sScript);
  end
end

function SMARTBUFF_SetButtonTexture(button, texture, text)
  --if (InCombatLockdown()) then return; end

  if (button and texture and texture ~= LastTexture) then
    LastTexture = texture;
    button:SetNormalTexture(texture);
    SMARTBUFF_AddMsgD("Button slot texture set -> " .. texture);
    if (text) then
      --button.title:SetText(spell);
    end
  end
end
-- END secure button functions

-- Minimap button functions ---------------------------------------------------------------------------------------
-- Sets the correct icon on the minimap button
function SMARTBUFF_CheckMiniMapButton()
  if (O.SmartBuff_Enabled) then
    SmartBuff_MiniMapButton:SetNormalTexture(ImgIconOn);
  else
    SmartBuff_MiniMapButton:SetNormalTexture(ImgIconOff);
  end

  if (O.HideMmButton) then
    SmartBuff_MiniMapButton:Hide();
  else
    SmartBuff_MiniMapButton:Show();
  end

  -- Update the Titan Panel icon
  if (TitanPanelBarButton and TitanPanelSmartBuffButton_SetIcon ~= nil) then
    TitanPanelSmartBuffButton_SetIcon();
  end

  -- Update the FuBar icon
  if (IsAddOnLoaded("FuBar") and IsAddOnLoaded("FuBar_SmartBuffFu") and SMARTBUFF_Fu_SetIcon ~= nil) then
    SMARTBUFF_Fu_SetIcon();
  end

  -- Update the Broker icon
  SMARTBUFF_BROKER_SetIcon();

end

function SMARTBUFF_MinimapButton_CheckPos()
  if (not SmartBuff_Initialized or not SmartBuff_MiniMapButton) then return; end
  local x = SmartBuff_MiniMapButton:GetLeft();
  local y = SmartBuff_MiniMapButton:GetTop();
  if (x == nil or y == nil) then return; end
  x = x - Minimap:GetLeft();
  y = y - Minimap:GetTop();
  if (math.abs(x) < 180 and math.abs(y) < 180) then
    O.MMCPosX = x;
    O.MMCPosY = y;
    --SMARTBUFF_AddMsgD("x = " .. O.MMCPosX .. ", y = " .. O.MMCPosY);
  end
end

-- Function to move the minimap button arround the minimap
function SMARTBUFF_MinimapButton_OnUpdate(self, move)
  if (not SmartBuff_Initialized or self == nil or not self:IsVisible()) then
    return;
  end

  local xpos, ypos;
  self:ClearAllPoints()
  if (move or O.MMCPosX == nil) then
    local pos, r
    local xmin, ymin = Minimap:GetLeft(), Minimap:GetBottom();
    xpos, ypos       = GetCursorPosition();
    xpos             = xmin - xpos / Minimap:GetEffectiveScale() + 70;
    ypos             = ypos / Minimap:GetEffectiveScale() - ymin - 70;
    pos              = math.deg(math.atan2(ypos, xpos));
    r                = math.sqrt(xpos * xpos + ypos * ypos);
    --SMARTBUFF_AddMsgD("x = " .. xpos .. ", y = " .. ypos .. ", r = " .. r .. ", pos = " .. pos);

    if (r < 75) then
      r = 75;
    elseif (r > 105) then
      r = 105;
    end

    xpos = 52 - r * math.cos(pos);
    ypos = r * math.sin(pos) - 52;
    O.MMCPosX = xpos;
    O.MMCPosY = ypos;
    --SMARTBUFF_AddMsgD("Update minimap button position");
  else
    xpos = O.MMCPosX;
    ypos = O.MMCPosY;
    --SMARTBUFF_AddMsgD("Load minimap button position");
  end
  self:ClearAllPoints()
  self:SetPoint("TOPLEFT", "Minimap", "TOPLEFT", xpos, ypos);
  --SMARTBUFF_AddMsgD("x = " .. O.MMCPosX .. ", y = " .. O.MMCPosY);
  --SmartBuff_MiniMapButton:SetUserPlaced(true);
  --SMARTBUFF_AddMsgD("Update minimap button");
end

-- END Minimap button functions



-- Scroll frame functions ---------------------------------------------------------------------------------------

local ScrBtnSize = 20;
local ScrLineHeight = 18;
local function SetPosScrollButtons(parent, cBtn)
  local btn;
  local name;
  for i = 1, #cBtn, 1 do
    btn = cBtn[i];
    btn:ClearAllPoints();
    btn:SetPoint("TOPLEFT", parent, "TOPLEFT", 2, -2 - ScrLineHeight * (i - 1));
  end
end

local StartY, EndY;
local function CreateScrollButton(name, parent, cBtn, onClick, onDragStop)
  ---@type Widget
  local btn = CreateFrame("CheckButton", name, parent, "UICheckButtonTemplate");
  btn:SetWidth(ScrBtnSize);
  btn:SetHeight(ScrBtnSize);
  --btn:RegisterForClicks("LeftButtonUp");
  btn:SetScript("OnClick", onClick);
  --	btn:SetScript("OnMouseUp", onClick);

  if (onDragStop ~= nil) then
    btn:SetMovable(true);
    btn:RegisterForDrag("LeftButton");
    btn:SetScript("OnDragStart", function(self, b)
      StartY = self:GetTop();
      self:StartMoving();
    end
    );
    btn:SetScript("OnDragStop", function(self, b)
      EndY = self:GetTop();
      local i = tonumber(self:GetID()) + FauxScrollFrame_GetOffset(parent);
      local n = math.floor((StartY - EndY) / ScrLineHeight);
      self:StopMovingOrSizing();
      SetPosScrollButtons(parent, cBtn);
      onDragStop(i, n);
    end
    );
  end

  ---@type Widget
  local text = btn:CreateFontString(nil, nil, "GameFontNormal");
  text:SetJustifyH("LEFT");
  --text:SetAllPoints(btn);
  text:SetPoint("TOPLEFT", btn, "TOPLEFT", ScrBtnSize, 0);
  text:SetWidth(parent:GetWidth() - ScrBtnSize);
  text:SetHeight(ScrBtnSize);
  btn:SetFontString(text);
  btn:SetHighlightFontObject("GameFontHighlight");

  ---@type Widget
  local highlight = btn:CreateTexture();
  --highlight:SetAllPoints(btn);
  highlight:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, -2);
  highlight:SetWidth(parent:GetWidth());
  highlight:SetHeight(ScrLineHeight - 3);

  highlight:SetTexture("Interface/QuestFrame/UI-QuestTitleHighlight");
  btn:SetHighlightTexture(highlight);

  return btn;
end

local function CreateScrollButtons(self, cBtn, sBtnName, onClick, onDragStop)
  local btn;
  for i = 1, MaxScrollButtons, 1 do
    ---@type Widget
    btn = CreateScrollButton(sBtnName .. i, self, cBtn, onClick, onDragStop);
    btn:SetID(i);
    cBtn[i] = btn;
  end
  SetPosScrollButtons(self, cBtn);
end

local function OnScroll(self, cData, sBtnName)
  local num = #cData;
  local n, numToDisplay;

  if (num <= MaxScrollButtons) then
    numToDisplay = num - 1;
  else
    numToDisplay = MaxScrollButtons;
  end

  FauxScrollFrame_Update(self, num, math.floor(numToDisplay / 3 + 0.5), ScrLineHeight);
  local t = B[CS()][CT()];
  for i = 1, MaxScrollButtons, 1 do
    n = i + FauxScrollFrame_GetOffset(self);
    local btn = _G[sBtnName .. i];
    if (btn) then
      if (n <= num) then
        btn:SetNormalFontObject("GameFontNormalSmall");
        btn:SetHighlightFontObject("GameFontHighlightSmall");
        btn:SetText(IDToLink(cData[n]))
        btn:SetChecked(t[cData[n]].IsEnabled);
        btn:Show();
      else
        btn:Hide();
      end
    end
  end
end

function SMARTBUFF_BuffOrderOnScroll(self, arg1)
  if (not self) then
    self = SmartBuffOptionsFrame_ScrollFrameBuffs;
  end

  local name = "SMARTBUFF_BtnScrollBO";
  if (not ScrBtnBO and self) then
    ScrBtnBO = {};
    CreateScrollButtons(self, ScrBtnBO, name, SMARTBUFF_BuffOrderBtnOnClick, SMARTBUFF_BuffOrderBtnOnDragStop);
  end

  if (B[CS()].Order == nil) then
    B[CS()].Order = {};
  end

  local t = {};
  for _, v in pairs(B[CS()].Order) do
    if (v) then

      table.insert(t, v);
    end
  end
  OnScroll(self, t, name);
end

function SMARTBUFF_BuffOrderBtnOnClick(self, button)
  local n = self:GetID() + FauxScrollFrame_GetOffset(self:GetParent());
  local i = BuffIndex[B[CS()].Order[n]];
  --SMARTBUFF_AddMsgD("Buff OnClick = "..n..", "..button);
  if (button == "LeftButton") then
    SMARTBUFF_OToggleBuff("S", i);
  else
    SmartBuff_BuffSetup_Show(i);
  end
end

function SMARTBUFF_BuffOrderBtnOnDragStop(i, n)
  table.reorder(B[CS()].Order, i, n);
  SMARTBUFF_BuffOrderOnScroll();
end

function SMARTBUFF_BuffOrderReset()
  InitBuffOrder(true);
  SMARTBUFF_BuffOrderOnScroll();
end

-- Help plate functions ---------------------------------------------------------------------------------------

local HelpPlateList = {
  FramePos = { x = 20, y = -20 },
  FrameSize = { width = 480, height = 500 },
  [1] = { ButtonPos = { x = 344, y = -80 }, HighLightBox = { x = 260, y = -50, width = 204, height = 410 },
    ToolTipDir = "DOWN", ToolTipText = "Spell list\nDrag'n'Drop to change the priority order" },
  [2] = { ButtonPos = { x = 105, y = -110 }, HighLightBox = { x = 10, y = -30, width = 230, height = 125 },
    ToolTipDir = "DOWN", ToolTipText = "Buff reminder options" },
  [3] = { ButtonPos = { x = 105, y = -250 }, HighLightBox = { x = 10, y = -165, width = 230, height = 135 },
    ToolTipDir = "DOWN", ToolTipText = "Character based options" },
  [4] = { ButtonPos = { x = 200, y = -320 }, HighLightBox = { x = 10, y = -300, width = 230, height = 90 },
    ToolTipDir = "RIGHT", ToolTipText = "Additional UI options" },
}

function SMARTBUFF_ToggleTutorial(close)
  local helpPlate = HelpPlateList;
  if (not helpPlate) then return end

  local b = HelpPlate_IsShowing(helpPlate);
  if (close) then
    HelpPlate_Hide(false);
    return;
  end

  if (not b) then
    HelpPlate_Show(helpPlate, SmartBuffOptionsFrame, SmartBuffOptionsFrame_TutorialButton);
  else
    HelpPlate_Hide(true);
  end
end
