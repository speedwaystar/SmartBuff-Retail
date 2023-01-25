-- local _;
S = SMARTBUFF_GLOBALS;

SMARTBUFF_PLAYERCLASS = "";
SMARTBUFF_CLASS_BUFFS = {};

---@enum Enum.Type
Enum.Type = {
  Spell             = 1,  -- spells which target the player (only). BuffInfo.Check contains conditions to check
  GroupSpell        = 2,  -- spells which can target the player or group. BuffInfo.Targets contains semicolon delimited target strings
  ForceSelfSpell    = 3,  -- CHECK: cast while shapeshifted, currently only used by BARKSKIN
  Enchantment       = 4,  -- spells which target an ItemInventorySlot
  Conjure           = 5,  -- BuffInfo.AuraID contains ConjuredItemID (e.g. healthstones, mage food)
  PetSummon         = 6,  -- spells which summon pets
  TrackingSkill     = 7,  -- tracking skill
  ClassStance       = 8,  -- class stances
  WeaponMod         = 9,  -- items which buff INVSLOT_MAINHAND or INVSLOT_OFFHAND
  RangedMod         = 10, -- items which buff INVSLOT_MAINHAND only
  Food              = 11, -- food
  Item              = 12, -- flasks, augment runes, scrolls, vantus runes, misc items
  Toy               = 13, -- toys which don't require a target
}

-- do not require an item to cast
Enum.SpellActionTypes = Enum.MakeEnum(Enum.Type.GroupSpell, Enum.Type.Spell, Enum.Type.ForceSelfSpell, Enum.Type.TrackingSkill, Enum.Type.ClassStance, Enum.Type.Conjure, Enum.Type.TrackingSkill, Enum.Type.PetSummon, Enum.Type.Toy )
-- conjuration is
-- do require an item to cast
Enum.ItemActionTypes = Enum.MakeEnum(Enum.Type.WeaponMod, Enum.Type.RangedMod, Enum.Type.Item, Enum.Type.Food)

---@alias ActionType "spell"|"item"
ACTION_TYPE_SPELL = "spell"
ACTION_TYPE_ITEM  = "item"

---universal settings
---@class BuffInfo
---@field BuffID integer    -- itemID|spellID
---@field Type Enum.Type    -- the action type (SMARTBUFF_CONST_SELF, SMARTBUFF_CONST_SCROLL etc)
---@field Name string       -- the buff name
---@field Hyperlink string  -- the buff link text
---@field Target Unit       -- the target name
---@field ActionType ActionType
---this section varies by SMARTBUFF_CONST_TYPE
---@field AuraID integer    -- the AuraID which becomes active when BuffID is cast
---@field Targets string    -- for SMARTBUFF_CONST_GROUP, a semicolon delimited string of legal target
---@field Check string      -- for SMARTBUFF_CONST_SELF, PETNEEDED"|"CHECKFISHINGPOLE"
---@field ConjuredID ItemID -- for SMARTBUFF_CONST_CONJURED, the itemID of the resulting item
---@field PetName string    -- for SMARTBUFF_CONST_PET, the pet's name
---links and chains
---@field Auras table       -- CHECK: a list of auras which, if active, should block BuffID from being cast
---@field Items table       -- CHECK: a list of items which, if in bags, should block BuffID from being cast
                            -- also includes shouts/stances/poisons (for some reason)
---icon info
---@field Icon Icon the icon
---@field SplashIcon string
---item info
---@field MinLevel integer
---@field ItemType string
---@field ItemSubType string
---@field InventorySlot Enum.InventorySlot
---@field ItemTypeID Enum.ItemType
---@field ItemSubTypeID integer
---weapon buff info
---@field HasMainHandEnchant boolean
---@field MainHandExpiration number
---@field MainHandCharges integer
---@field HasOffHandEnchant boolean
---@field OffHandExpiration number
---@field OffHandCharges integer
---group buff info
---@field GroupBuff integer
---@field GroupBuffDuration integer
---@field GroupBuffID integer
---@field IconGroup Icon
---@field Order table
---cooldown info
---@field Duration number   -- Cooldown duration in seconds, `0` if spell is ready to be cast.
---@field StartTime number  -- The time when the cooldown started (as returned by GetTime());
                            -- zero if no cooldown; current time if (enabled == 0).
---@field IsActive boolean  -- 0 if the spell is active (Stealth, Shadowmeld, Presence of Mind, etc)
                            -- and the cooldown will begin as soon as the spell is used/cancelled; 1 otherwise.
---@field RebuffTimer number
--spell info
---@field MinRange integer
---@field MaxRange integer
---misc info
---@field HasCharges boolean
---@field Charges integer
---@field HasExpired boolean
---@field TimeLeft  number

--- buff settings specific to each specialization/smartgroup
--- which coincide with the checkboxes in the UI
---@class BuffTemplate
---@field AddList table
---@field BuffEnabled boolean
---@field BuffInCombat boolean
---@field BuffMainHand boolean
---@field BuffOffHand boolean
---@field BuffOutOfCombat boolean
---@field BuffReminder boolean
---@field BuffRightHand boolean
---@field BuffSelfNot boolean
---@field BuffSelfOnly boolean
---@field EnableGroup boolean
---@field IgnoreList table
---@field ManaLimit integer
---@field IsEnabled boolean
---@field RebuffTimer number

local function addBuff(t, type, buffID, auraID, auras)
  auras = auras or {}
  table.insert(t, {buffID, 60, type, nil, auraID, auras});
end

local function addItem( buff, aura, auras)
  addBuff(SMARTBUFF_ITEMS, Enum.Type.Item, buff, aura, auras)
end

local function addToy( buff, aura, auras)
  addBuff(SMARTBUFF_TOYS, Enum.Type.Toy, buff, aura, auras)
end

CheckPet = "CHECKPET";
CheckPetNeeded = "CHECKPETNEEDED";
CheckFishingPole = "CHECKFISHINGPOLE";
NIL = "x";
Toybox = { };

local function LoadToys()
  printd("LoadToys")
	C_ToyBox.SetCollectedShown(true)
	C_ToyBox.SetAllSourceTypeFilters(true)
	C_ToyBox.SetFilterString("")
	if ((C_ToyBox.GetNumLearnedDisplayedToys() or 0) == 0) then return end

	for i = 1, C_ToyBox.GetNumTotalDisplayedToys() do
		local id, name, icon = C_ToyBox.GetToyInfo(C_ToyBox.GetToyFromIndex(i));
		if (id) then
		  if (PlayerHasToy(id)) then
        _,name = GetItemInfo(id)
		    Toybox[tostring(name)] = {id, icon};
		  end
		end
	end

  SMARTBUFF_AddMsgD("Toys initialized");
end

---Append all values in array `addedArray` to the end of `table`
---@param table table
---@param addedArray integer[]
local function tAppendTable(table, addedArray)
	for i, element in pairs(addedArray) do
		tinsert(table, element);
	end
end

function SMARTBUFF_InitItemList()

  -- Weapon mods (stones, oils and runes)
  __Mods = { 2862, 2863, 2871, 7964, 12404, 18262, 23528, 23529, 3239, 3240, 3241, 7965, 12643, 28420, 28421, 3824, 3829, 20745, 20747, 20748, 22521, 20744, 20746, 20750, 20749, 22522, 171285, 171286 }
  tAppendTable(__Mods,{
    194817, -- Buzzing Rune (Quality 1)
    194818, -- Buzzing Rune (Quality 2)
    194819, -- Buzzing Rune (Quality 3)
    194824, -- Chirping Rune (Quality 1)
    194825, -- Chirping Rune (Quality 2)
    194826, -- Chirping Rune (Quality 3)
    194821, -- Howling Rune (Quality 1)
    194822, -- Howling Rune (Quality 2)
    194820, -- Howling Rune (Quality 3)
    191943, -- Primal Weighstone (Quality 1)
    191944, -- Primal Weighstone (Quality 2)
    191945, -- Primal Weighstone (Quality 3)
    191933, -- Primal Whestone (Quality 1)
    191939, -- Primal Whestone (Quality 2)
    191940  -- Primal Whestone (Quality 3)
  } )
  ---@type SpellList
  SMARTBUFF_WEAPON_MODS = {}
  for _, id in pairs(__Mods) do
    table.insert(SMARTBUFF_WEAPON_MODS, {id, 60, Enum.Type.WeaponMod})
  end

  SMARTBUFF_RANGED_MODS = {}
  for _, id in pairs ( {
    SMARTBUFF_SafeRockets_1      = 198160; -- Completely Safe Rockets (Quality 1)
    SMARTBUFF_SafeRockets_2      = 198161; -- Completely Safe Rockets (Quality 2)
    SMARTBUFF_SafeRockets_3      = 198162; -- Completely Safe Rockets (Quality 3)
  } ) do
    table.insert(SMARTBUFF_RANGED_MODS, {id, 60, Enum.Type.RangedMod})
  end

  -- Food
  __Food = { 39691, 34125, 42779, 42997, 42998, 42999, 43000, 34767, 42995, 34769, 34754, 34758, 34766, 42994, 42996, 34756,34768, 42993, 34755, 43001, 34757, 34752, 34751, 34750,34749, 34764, 34765, 34763, 34762, 42942, 43268, 34748, 62651, 62652, 62653, 62654, 62655, 62656, 62657, 62658,62659, 62660, 62661, 62662, 62663, 62664, 62665, 62666, 62667, 62668, 62669, 62670, 62671, 62649, 74645, 74646, 74647, 74648, 74649, 74650, 74652, 74653, 74655, 74656, 86069, 86070, 86073, 86074, 81400, 81401, 81402, 81403, 81404, 81405, 81406, 81408, 81409, 81410, 81411, 81412, 81413, 81414, 111431, 111432, 111433, 111434, 111435, 111436, 111437, 111438, 111439, 111440, 111442, 111443, 111444, 111445, 111446, 111447, 111448, 111449, 111450, 111451, 111452, 111453, 111454, 127991, 111457, 111458, 118576, 33874, 33866, 35565, 22645, 27635, 35563, 27636, 24105, 31672, 31673, 27658, 33052, 27659, 27655, 33825, 27651, 27660, 27666, 33872, 27662, 27663, 34411, 33867, 27667, 27665, 27657, 27664, 30155, 21217, 133557, 133562, 133569, 133567, 133577, 133563, 133576, 118428, 133561, 143681, 154885, 154881, 154889, 154887, 154882, 154883, 154884, 154891, 154888, 154886, 163781, 168311, 168313, 168314, 168310, 168312, 172069, 172040, 172044, 184682, 172063, 172049, 172048, 172068, 172061, 172041, 172051, 172050, 172045 }
  tAppendTable(__Food,  {
    197778, -- Timely Demise (70 Haste)
    197779, -- Filet of Fangs (70 Crit)
    197780, -- Seamoth Surprise (70 Vers)
    197781, -- Salt-Baked Fishcake (70 Mastery)
    197782, -- Feisty Fish Sticks (45 Haste/Crit)
    197783, -- Aromatic Seafood Platter (45 Haste/Vers)
    197784, -- Sizzling Seafood Medley (45 Haste/Mastery)
    197785, -- Revenge, Served Cold (45 Crit/Verst)
    197786, -- Thousandbone Tongueslicer (45 Crit/Mastery)
    197787, -- Great Cerulean Sea (45 Vers/Mastery)
    197792, -- Fated Fortune Cookie (76 primary stat)
    197794, -- Feast: Grand Banquet of the Kalu'ak (76 primary stat)
    197795  -- Feast: Hoard of Draconic Delicacies (76 primary stat)
  } )
  ---@type SpellList
  SMARTBUFF_FOOD = {}
  for n, id in pairs(__Food) do
    table.insert(SMARTBUFF_FOOD, {id, 60, Enum.Type.Food})
  end

  -- Conjured mage food IDs
  SMARTBUFF_ManaBuns         = 113509; -- Conjured Mana Buns
  SMARTBUFF_Healthstone      =   5512; -- Healthstone
  SMARTBUFF_ManaGem          =  36799; -- Mana Gem
  SMARTBUFF_BrillianManaGem  =  81901; -- Brilliant Mana Gem
  ConjuredMageFood  = { 113509, 80618,  80610,  65499,  43523,  43518,  34062, 65517,  65516,  65515,  65500,  42955 };

  --SMARTBUFF_BCPETFOOD1          = 33874;  -- Kibler's Bits (Pet food)
  --SMARTBUFF_WOTLKPETFOOD1       = 43005;  -- Spiced Mammoth Treats (Pet food)


  -- fishing pole
  FishingPole = 6256;   -- Fishing Pole

  SMARTBUFF_AddMsgD("Item list initialized");
  -- i still want to load them regardless of the option to turn them off/hide them
  -- so that my settings are preserved and loaded should i turn it back on.
  LoadToys();
end

function SMARTBUFF_InitSpellIDs()

  -- Druid
  SMARTBUFF_DruidCatForm           = 768;    -- Cat Form
  SMARTBUFF_MarkOfTheWild          = 1126;   -- Mark of the Wild
  SMARTBUFF_TigersFury             = 5217;   -- Tiger's Fury
  SMARTBUFF_DruidTrackHumanoids    = 5225;   -- Track Humanoids
  SMARTBUFF_DruidBearForm          = 5487;   -- Bear Form
  SMARTBUFF_Barkskin               = 22812;  -- Barkskin
  SMARTBUFF_DruidMoonkinForm       = 24858;  -- Moonkin Form
  SMARTBUFF_DruidTreeForm          = 33891;  -- Incarnation: Tree of Life
  SMARTBUFF_SavageRoar             = 52610;  -- Savage Roar
  SMARTBUFF_CenarionWard           = 102351; -- Cenarion Ward
  SMARTBUFF_DruidTreantForm        = 114282; -- Treant Form

  -- Priest
  SMARTBUFF_PowerWordShield        = 17;     -- Power Word: Shield
  SMARTBUFF_Renew                  = 139;    -- Renew
  SMARTBUFF_Levitate               = 1706;   -- Levitate
  SMARTBUFF_VampiricEmbrace        = 15286;  -- Vampiric Embrace
  SMARTBUFF_PowerWordFortitude     = 21562;  -- Power Word: Fortitude
  SMARTBUFF_Shadowform             = 232698; -- Shadowform

  -- Mage
  SMARTBUFF_SlowFall               = 130;    -- Slow Fall
  SMARTBUFF_ConjureManaGem         = 759;    -- Conjure Mana Gem
  SMARTBUFF_ArcaneIntellect        = 1459;   -- Arcane Intellect
  SMARTBUFF_ConjureRefreshment     = 42955;  -- Conjure Refreshment
  SMARTBUFF_MageArmor              = 6117;   -- Mage Armor
  SMARTBUFF_FrostArmor             = 7302;   -- Frost Armor
  SMARTBUFF_IceBarrier             = 11426;  -- Ice Barrier
  SMARTBUFF_ArcanePower            = 12042;  -- Arcane Power
  SMARTBUFF_IcyVeins               = 12472;  -- Icy Veins
  SMARTBUFF_DalaranBrilliance      = 61316;  -- Dalaran Brilliance
  SMARTBUFF_SummonWaterElemental   = 31687;  -- Summon Water Elemental
  SMARTBUFF_ManaShield             = 35064;  -- Mana Shield
  SMARTBUFF_Combustion             = 110319; -- Combustion
  SMARTBUFF_TemporalShield         = 198111; -- Temporal Shield
  SMARTBUFF_ArcaneFamiliar         = 205022; -- Arcane Familiar
  SMARTBUFF_PresenceOfMind         = 205025; -- Presence of Mind
  SMARTBUFF_BlazingBarrier         = 235313; -- Blazing Barrier
  SMARTBUFF_PrismaticBarrier       = 235450; -- Prismatic Barrier
  SMARTBUFF_ImprovedPrismaticBarrier = 321745; -- Improved Prismatic Barrier
  -- Mage buff links
  MageArmorAuras                   = { SMARTBUFF_FrostArmor, SMARTBUFF_MageArmor };

  -- Warlock
  SMARTBUFF_AmplifyCurse           = 328774; -- Amplify Curse
  SMARTBUFF_DemonArmor             = 285933; -- Demon ARmor
  SMARTBUFF_DarkIntent             = 183582; -- Dark Intent
  SMARTBUFF_UnendingBreath         = 5697;   -- Unending Breath
  SMARTBUFF_SoulLink               = 108447; -- Soul Link
  SMARTBUFF_LifeTap                = 1454;   -- Life Tap
  SMARTBUFF_CreateHealthstone      = 6201;   -- Create Healthstone
  SMARTBUFF_Soulstone              = 20707;  -- Soulstone
  SMARTBUFF_GrimoireOfSacrifice    = 108503; -- Grimoire of Sacrifice
  SMARTBUFF_InquisitorsGaze        = 386344; -- Inquisitor's Gaze
  -- Warlock pets
  SMARTBUFF_SummonImp              = 688;    -- Summon Imp
  SMARTBUFF_SummonFelhunter        = 691;    -- Summon Fellhunter
  SMARTBUFF_SummonVoidwalker       = 697;    -- Summon Voidwalker
  SMARTBUFF_SummonSuccubus         = 712;    -- Summon Succubus
  SMARTBUFF_SummonInfernal         = 1122;   -- Summon Infernal
  SMARTBUFF_SummonDoomguard        = 18540;  -- Summon Doomguard
  SMARTBUFF_SummonFelguard         = 30146;  -- Summon Felguard
  SMARTBUFF_SummonFelImp           = 112866; -- Summon Fel Imp
  SMARTBUFF_SummonVoidlord         = 112867; -- Summon Voidlord
  SMARTBUFF_SummonShivarra         = 112868; -- Summon Shivarra
  SMARTBUFF_SummonObserver         = 112869; -- Summon Observer
  SMARTBUFF_SummonWRATHGUARD       = 112870; -- Summon Wrathguard

  -- Hunter
  SMARTBUFF_Volley                  = 194386; -- Volley
  SMARTBUFF_RapidFire               = 257044; -- Rapid Fire
  SMARTBUFF_Camouflage              = 199483; -- Camouflage
  SMARTBUFF_AspectOfTheCheetah      = 186257; -- Aspect of the Cheetah
  SMARTBUFF_AspectOfTheWild         = 193530; -- Aspect of the Wild
  -- Hunter pets
  SMARTBUFF_CallPet1                = 883;    -- Call Pet 1
  SMARTBUFF_CallPet2                = 83242;  -- Call Pet 2
  SMARTBUFF_CallPet3                = 83243;  -- Call Pet 3
  SMARTBUFF_CallPet4                = 83244;  -- Call Pet 4
  SMARTBUFF_CallPet5                = 83245;  -- Call Pet 5
  SMARTBUFF_REVIVE_PET              = 982;    -- Revive Pet
  SMARTBUFF_MEND_PET                = 136;    -- Mend Pet
  -- Hunter buff links
  HunterAspects                     = { SMARTBUFF_AspectOfTheCheetah, SMARTBUFF_AspectOfTheWild };

  -- Shaman
  SMARTBUFF_WaterWalking            = 546;    -- Water Walking
  SMARTBUFF_EarthShield             = 974;    -- Earth Shield
  SMARTBUFF_WaterShield             = 52127;  -- Water Shield
  SMARTBUFF_LightningShield         = 192106; -- Lightning Shield
  SMARTBUFF_WindfuryWeapon          = 33757;  -- Windfury Weapon
  SMARTBUFF_FlametongueWeapon       = 318038; -- Flametongue Weapon
  SMARTBUFF_ElementalMastery        = 16166;  -- Elemental Mastery
  SMARTBUFF_AscendanceElemental     = 114050; -- Ascendance (Elemental)
  SMARTBUFF_AscendanceEnhancement   = 114051; -- Ascendance (Enhancement)
  SMARTBUFF_AscendanceRestoration   = 114052; -- Ascendance (Restoration)
  -- Shaman buff links
  ShamanShields                     = { SMARTBUFF_LightningShield, SMARTBUFF_WaterShield, SMARTBUFF_EarthShield };

  -- Warrior
  SMARTBUFF_BattleShout             = 6673;   -- Battle Shout
  SMARTBUFF_RallyingCry             = 97462;  -- Rallying Cry
  SMARTBUFF_BerserkerRage           = 18499;  -- Berserker Rage
  SMARTBUFF_BattleStance            = 386164; -- Battle Stance
  SMARTBUFF_DefensiveStance         = 197690; -- Defensive Stance
  SMARTBUFF_ShieldBlock             = 2565;   -- Shield Block

  -- Warrior buff links
  ChainWarriorStance                = { SMARTBUFF_BattleStance, SMARTBUFF_DefensiveStance };
  ChainWarriorShout                 = { SMARTBUFF_BattleShout, SMARTBUFF_RallyingCry };

  -- Rogue
  SMARTBUFF_Stealth                 = 1784;   -- Stealth
  SMARTBUFF_SliceAndDice            = 5171;   -- Slice and Dice
  SMARTBUFF_Evasion                 = 5277;   -- Evasion
  SMARTBUFF_BladeFlurry             = 13877;  -- Blade Flurry
  SMARTBUFF_TricksOfTheTrade        = 57934;  -- Tricks of the Trade
  SMARTBUFF_HungerForBlood          = 60177;  -- Hunger For Blood
  SMARTBUFF_Recuperate              = 185311; -- Crimson Vial
  -- Poisons
  SMARTBUFF_DeadlyPoison            = 2823;   -- Deadly Poison
  SMARTBUFF_CripplingPoison         = 3408;   -- Crippling Poison
  SMARTBUFF_NumbingPoison           = 5761;   -- Numbing Poison
  SMARTBUFF_WoundPoison             = 8679;   -- Wound Poison
  SMARTBUFF_LeechingPoison          = 108211; -- Leeching Poison
  SMARTBUFF_InstantPoison           = 315584; -- Instant Poison
  SMARTBUFF_AtrophicPoison          = 381637; -- Atrophic Poison
  SMARTBUFF_AmplifyPoison           = 381664; -- Amplifying Poison

  -- Rogue buff links
  RoguePoisonsLethal           = { SMARTBUFF_DeadlyPoison, SMARTBUFF_WoundPoison, SMARTBUFF_InstantPoison, SMARTBUFF_AmplifyPoison };
  RoguePoisonsNonLethal        = { SMARTBUFF_CripplingPoison, SMARTBUFF_LeechingPoison, SMARTBUFF_NumbingPoison, SMARTBUFF_AtrophicPoison };

  -- Paladin
  SMARTBUFF_RighteousFury           = 25780;  -- Righteous Fury
  SMARTBUFF_AvengingWrath           = 31884;  -- Avenging Wrath
  SMARTBUFF_BlessingOfProtection    = 1022;   -- Blessing of Protection
  SMARTBUFF_BlessingOfFreedom       = 1044;   -- Blessing of Freedom
  SMARTBUFF_BlessingOfSalvation     = 204013; -- Blessing of Salvation
  SMARTBUFF_BeaconOfLight           = 53563;  -- Beacon of Light
  SMARTBUFF_BeaconOfFaith           = 156910; -- Beacon of Faith
  SMARTBUFF_DevotionAura            = 465;    -- Devotion Aura
  SMARTBUFF_CrusaderAura            = 32223;  -- Crusader Aura
  SMARTBUFF_RetributionAura         = 183435; -- Retribution Aura
  -- Paladin buff links
  PaladinAuras                      = { SMARTBUFF_CrusaderAura, SMARTBUFF_DevotionAura, SMARTBUFF_RetributionAura };
  PaladinSeals                      = { };
  PaladinBlessings                  = { };

  -- Death Knight
  SMARTBUFF_DancingRuneWeapon       = 49028; -- Dancing Rune Weapon
  SMARTBUFF_PathOfFrost             = 3714;  -- Path of Frost
  SMARTBUFF_HornOfWinter            = 57330; -- Horn of Winter
  SMARTBUFF_RaiseDead               = 46584; -- Raise Dead

  -- Monk
  SMARTBUFF_BlackOxStatue           = 115315; -- Summon Black Ox Statue
  SMARTBUFF_JadeSerpentStatue       = 115313; -- Summon Jade Serpent Statue
  SMARTBUFF_StanceOfTheFierceTiger  = 103985; -- Stance of the Fierce Tiger
  SMARTBUFF_Stagger                 = 115069; -- Stagger
  -- Monk buff links
  MonkStatues                       = { SMARTBUFF_BlackOxStatue, SMARTBUFF_JadeSerpentStatue };
  MonkStances                       = { SMARTBUFF_StanceOfTheFierceTiger, SMARTBUFF_Stagger };

  -- Evoker
  SMARTBUFF_BlessingOfTheBronze     = 364342;   -- Blessing of the Bronze
  SMARTBUFF_Visage                  = 351239;   -- Visage
  -- Demon Hunter

  ---@type SpellList
  SMARTBUFF_TRACKING = {}
  for _, id in pairs({
     2580, -- Find Minerals
     2383, -- Find Herbs
     2481, -- Find Treasure
    19883, -- Track Humanoids
     1494, -- Track Beasts
    19884, -- Track Undead
    19885, -- Track Hidden
    19880, -- Track Elementals
    19878, -- Track Demons
    19882, -- Track Giants
    19879  -- Track Dragonkin
  }) do
    table.insert(SMARTBUFF_TRACKING, {id, -1, Enum.Type.TrackingSkill})
  end

  ---@type SpellList
  SMARTBUFF_RACIAL = {}
  for _, id in pairs({
    7744,   -- Will of the Forsaken
    20594,  -- Stoneform
    20572,  -- Blood Fury -- 33697, 33702
    26297,  -- Berserking
    20549   -- War Stomp
  }) do
    table.insert(SMARTBUFF_RACIAL, {id, -1, Enum.Type.Spell})
  end

  -- Food
  SMARTBUFF_WellFedAura         = 46899; -- Well Fed
  SMARTBUFF_Food                = 433;   -- Food
  SMARTBUFF_Drink               = 430;   -- Drink
  -- "Food", "Drink", and "Food & Drink"
  GenericFoodAuras            = { 225737, 22734, 192002}
  -- Misc
  SMARTBUFF_Fishing             = 7620 or 111541; -- Fishing

  MultiStatAuras = { SMARTBUFF_MarkOfTheWild };
  StaminaAuras = { SMARTBUFF_PowerWordFortitude, SMARTBUFF_RallyingCry };
  ShoutAuras = { SMARTBUFF_HornOfWinter, SMARTBUFF_BattleShout };
  PetAuras = { };
  IntellectAuras = { SMARTBUFF_ArcaneIntellect, SMARTBUFF_DalaranBrilliance };

  SMARTBUFF_AddMsgD("Item IDs initialized");
end

---@enum Enum.SpellList
Enum.SpellList =
{
  BuffID = 1;         -- an item or spell ID
  Duration = 2;       -- Duration (ignored, deprecated)
  Type = 3;           -- tye action type (SMARTBUFF_CONST_SELF, SMARTBUFF_CONST_SCROLL etc)
  -- MinLevel = 4;       -- deprecated/never used
  Variable = 5;       -- contents vary by SMARTBUFF_CONSTANT_TYPE as follows:
                      -- for most types, the auraID which results from BuffID use. possibly never used
                      -- for SMARTBUFF_CONST_GROUP, a semicolon delimited string of legal targets
                      -- for SMARTBUFF_CONST_SELF, "PETNEEDED"|"CHECKFISHINGPOLE"
                      -- for SMARTBUFF_CONST_PET, the name of the pet
                      -- for SMARTBUFF_CONST_CONJURED, the itemID of the resulting item
  Auras = 6;          -- a list of blocking auras
  Items = 7;          -- list of blocking items or self-only auras (shouts/stances/auras/poison/shields)
}

---@alias SpellList { buffID:integer, duration:number, type:Enum.Type, minLevel:table, variable:any, links:table, chain:table }

function SMARTBUFF_InitSpellList()
  if (SMARTBUFF_PLAYERCLASS == nil) then return; end

  -- Druid
  if (SMARTBUFF_PLAYERCLASS == "DRUID") then
    ---@type SpellList
    SMARTBUFF_CLASS_BUFFS = {
      {SMARTBUFF_DruidMoonkinForm, -1, Enum.Type.Spell},
      {SMARTBUFF_DruidTreantForm, -1, Enum.Type.Spell},
      {SMARTBUFF_DruidBearForm, -1, Enum.Type.Spell},
      {SMARTBUFF_DruidCatForm, -1, Enum.Type.Spell},
      {SMARTBUFF_DruidTreeForm, -1, Enum.Type.Spell},
      {SMARTBUFF_MarkOfTheWild, 60, Enum.Type.GroupSpell, {1,10,20,30,40,50,60,70,80}, "HPET;WPET;DKPET"},
      {SMARTBUFF_CenarionWard, 30/60, Enum.Type.GroupSpell, {1}, "WARRIOR;DRUID;SHAMAN;HUNTER;ROGUE;MAGE;PRIEST;PALADIN;WARLOCK;DEATHKNIGHT;MONK;DEMONHUNTER;EVOKER"},
      {SMARTBUFF_Barkskin, 8/60, Enum.Type.ForceSelfSpell},
      {SMARTBUFF_TigersFury, 10/60, Enum.Type.Spell, nil, SMARTBUFF_DruidCatForm},
      {SMARTBUFF_SavageRoar, 9/60, Enum.Type.Spell, nil, SMARTBUFF_DruidCatForm}
    };
  end

  -- Priest
  if (SMARTBUFF_PLAYERCLASS == "PRIEST") then
    ---@type SpellList
    SMARTBUFF_CLASS_BUFFS = {
      {SMARTBUFF_Shadowform, -1, Enum.Type.Spell},
      {SMARTBUFF_PowerWordFortitude, 60, Enum.Type.GroupSpell, {14}, "HPET;WPET;DKPET", StaminaAuras},
      {SMARTBUFF_Levitate, 10, Enum.Type.GroupSpell, {34}, "HPET;WPET;DKPET"},
      {SMARTBUFF_VampiricEmbrace, 15/60, Enum.Type.Spell},
      {SMARTBUFF_PowerWordShield, 15/60, Enum.Type.GroupSpell, {6}, "MAGE;WARLOCK;ROGUE;PALADIN;WARRIOR;DRUID;ASPEC;SHAMAN;DEATHKNIGHT;MONK;DEMONHUNTER;EVOKER;HPET;WPET;DKPET"},
      -- {SMARTBUFF_FEAR_WARD, 3, SMARTBUFF_CONST_GROUP, {54}, "HPET;WPET;DKPET"},
      -- {SMARTBUFF_CHAKRA1, 0.5, SMARTBUFF_CONST_SELF, nil, nil, LinkPriestChakra},
      -- {SMARTBUFF_CHAKRA2, 0.5, SMARTBUFF_CONST_SELF, nil, nil, LinkPriestChakra},
      -- {SMARTBUFF_CHAKRA3, 0.5, SMARTBUFF_CONST_SELF, nil, nil, LinkPriestChakra},
      -- {SMARTBUFF_LIGHTWELL, 3, SMARTBUFF_CONST_SELF}
    };
  end
  -- Mage
  if (SMARTBUFF_PLAYERCLASS == "MAGE") then
    ---@type SpellList
    SMARTBUFF_CLASS_BUFFS = {
      {SMARTBUFF_ArcaneIntellect, 60, Enum.Type.GroupSpell, {1,14,28,42,56,70,80}, nil, IntellectAuras},
      {SMARTBUFF_DalaranBrilliance, 60, Enum.Type.GroupSpell, {80,80,80,80,80,80,80}, nil, IntellectAuras},
      {SMARTBUFF_SummonWaterElemental, -1, Enum.Type.PetSummon, nil, CheckPet},
      {SMARTBUFF_FrostArmor, -1, Enum.Type.Spell, nil, nil, nil, MageArmorAuras},
      {SMARTBUFF_SlowFall, 0.5, Enum.Type.GroupSpell, {32}, "HPET;WPET;DKPET"},
      {SMARTBUFF_IceBarrier, 1, Enum.Type.Spell},
      {SMARTBUFF_Combustion, -1, Enum.Type.Spell},
      {SMARTBUFF_IcyVeins, 25/60, Enum.Type.Spell},
      {SMARTBUFF_ArcaneFamiliar, 60, Enum.Type.Spell, nil, CheckPet},
      {SMARTBUFF_PresenceOfMind, -1, Enum.Type.Spell},
      {SMARTBUFF_PrismaticBarrier, 1, Enum.Type.Spell},
      {SMARTBUFF_ImprovedPrismaticBarrier, 1, Enum.Type.Spell},
      {SMARTBUFF_BlazingBarrier, 1, Enum.Type.Spell},
      {SMARTBUFF_ConjureRefreshment, 0.03, Enum.Type.Conjure, nil, SMARTBUFF_ManaBuns, nil, ConjuredMageFood},
      {SMARTBUFF_ConjureManaGem, 0.03, Enum.Type.Conjure, nil, SMARTBUFF_ManaGem},
    };
  end

  -- Warlock
  if (SMARTBUFF_PLAYERCLASS == "WARLOCK") then
    ---@type SpellList
    SMARTBUFF_CLASS_BUFFS = {
      {SMARTBUFF_AmplifyCurse, 15/60, Enum.Type.Spell},
      {SMARTBUFF_InquisitorsGaze, 60, Enum.Type.Spell},
      {SMARTBUFF_SoulLink, -1, Enum.Type.Spell, nil, CheckPetNeeded},
      {SMARTBUFF_UnendingBreath, 10, Enum.Type.GroupSpell, {16}, "HPET;WPET;DKPET"},
      {SMARTBUFF_Soulstone, 15, Enum.Type.GroupSpell, {18}, "WARRIOR;DRUID;SHAMAN;HUNTER;ROGUE;MAGE;PRIEST;PALADIN;WARLOCK;DEATHKNIGHT;EVOKER;MONK;DEMONHUNTER;HPET;WPET;DKPET"},
      {SMARTBUFF_CreateHealthstone, -1, Enum.Type.Conjure, nil, SMARTBUFF_Healthstone},
      {SMARTBUFF_SummonImp, -1, Enum.Type.PetSummon, nil, CheckPet},
      {SMARTBUFF_SummonFelhunter, -1, Enum.Type.PetSummon, nil, CheckPet},
      {SMARTBUFF_SummonVoidwalker, -1, Enum.Type.PetSummon, nil, CheckPet},
      {SMARTBUFF_SummonSuccubus, -1, Enum.Type.PetSummon, nil, CheckPet},
      {SMARTBUFF_SummonInfernal, -1, Enum.Type.PetSummon, nil, CheckPet},
      {SMARTBUFF_SummonDoomguard, -1, Enum.Type.PetSummon, nil, CheckPet},
      {SMARTBUFF_SummonFelguard, -1, Enum.Type.PetSummon, nil, CheckPet},
      {SMARTBUFF_SummonFelImp, -1, Enum.Type.PetSummon, nil, CheckPet},
      {SMARTBUFF_SummonVoidlord, -1, Enum.Type.PetSummon, nil, CheckPet},
      {SMARTBUFF_SummonShivarra, -1, Enum.Type.PetSummon, nil, CheckPet},
      {SMARTBUFF_SummonObserver, -1, Enum.Type.PetSummon, nil, CheckPet},
      {SMARTBUFF_SummonWRATHGUARD, -1, Enum.Type.PetSummon, nil, CheckPet},
    };
  end

  -- Hunter
  if (SMARTBUFF_PLAYERCLASS == "HUNTER") then
    ---@type SpellList
    SMARTBUFF_CLASS_BUFFS = {
      {SMARTBUFF_AspectOfTheCheetah, -1, Enum.Type.Spell, nil, nil, HunterAspects},
      {SMARTBUFF_Camouflage, 1, Enum.Type.Spell},
      {SMARTBUFF_RapidFire, 1.7/60, Enum.Type.Spell},
      {SMARTBUFF_Volley, 6/60, Enum.Type.Spell},
      {SMARTBUFF_AspectOfTheWild, 20/60, Enum.Type.Spell, nil, nil, HunterAspects},
      {SMARTBUFF_CallPet1, -1, Enum.Type.PetSummon, nil, (select(2, GetStablePetInfo(1))) },
      {SMARTBUFF_CallPet2, -1, Enum.Type.PetSummon, nil, (select(2, GetStablePetInfo(2))) },
      {SMARTBUFF_CallPet3, -1, Enum.Type.PetSummon, nil, (select(2, GetStablePetInfo(3))) },
      {SMARTBUFF_CallPet4, -1, Enum.Type.PetSummon, nil, (select(2, GetStablePetInfo(4))) },
      {SMARTBUFF_CallPet5, -1, Enum.Type.PetSummon, nil, (select(2, GetStablePetInfo(5))) },
    };
  end

  -- Shaman
  if (SMARTBUFF_PLAYERCLASS == "SHAMAN") then
    ---@type SpellList
    SMARTBUFF_CLASS_BUFFS = {
      {SMARTBUFF_LightningShield, 60, Enum.Type.Spell, nil, nil, ShamanShields},
      {SMARTBUFF_WaterShield, 10, Enum.Type.Spell, nil, nil, ShamanShields},
      {SMARTBUFF_EarthShield, 10, Enum.Type.GroupSpell, {50,60,70,75,80}, "WARRIOR;DEATHKNIGHT;DRUID;SHAMAN;HUNTER;ROGUE;MAGE;PRIEST;PALADIN;WARLOCK;MONK;DEMONHUNTER;EVOKER;HPET;WPET;DKPET"},
      {SMARTBUFF_WindfuryWeapon, 60, Enum.Type.TrackingSkill},
      {SMARTBUFF_FlametongueWeapon, 60, Enum.Type.TrackingSkill},
      -- {SMARTBUFF_UNLEASHFLAME, 0.333, SMARTBUFF_CONST_SELF},
      {SMARTBUFF_AscendanceElemental, 0.25, Enum.Type.Spell},
      {SMARTBUFF_AscendanceEnhancement, 0.25, Enum.Type.Spell},
      {SMARTBUFF_AscendanceRestoration, 0.25, Enum.Type.Spell},
      {SMARTBUFF_ElementalMastery, 0.5, Enum.Type.Spell},
      {SMARTBUFF_WaterWalking, 10, Enum.Type.GroupSpell, {28}}
    };
  end

  -- Warrior
  if (SMARTBUFF_PLAYERCLASS == "WARRIOR") then
    ---@type SpellList
    SMARTBUFF_CLASS_BUFFS = {
      {SMARTBUFF_BattleShout, 60, Enum.Type.Spell, nil, nil, ShoutAuras, ChainWarriorShout},
      {SMARTBUFF_RallyingCry, 20, Enum.Type.Spell, nil, nil, StaminaAuras, ChainWarriorShout},
      {SMARTBUFF_BerserkerRage, 0.1, Enum.Type.Spell},
      {SMARTBUFF_ShieldBlock, 0.1, Enum.Type.Spell},
      {SMARTBUFF_BattleStance, -1, Enum.Type.ClassStance, nil, nil, nil, ChainWarriorStance},
      {SMARTBUFF_DefensiveStance, -1, Enum.Type.ClassStance, nil, nil, nil, ChainWarriorStance},
    };
  end

  -- Rogue
  if (SMARTBUFF_PLAYERCLASS == "ROGUE") then
    ---@type SpellList
    SMARTBUFF_CLASS_BUFFS = {
      {SMARTBUFF_Stealth, -1, Enum.Type.Spell},
      {SMARTBUFF_BladeFlurry, -1, Enum.Type.Spell},
      {SMARTBUFF_SliceAndDice, 0.2, Enum.Type.Spell},
      {SMARTBUFF_TricksOfTheTrade, 0.5, Enum.Type.GroupSpell, {75}, "WARRIOR;DEATHKNIGHT;DRUID;SHAMAN;HUNTER;ROGUE;MAGE;PRIEST;PALADIN;WARLOCK;MONK;DEMONHUNTER;EVOKER;HPET;WPET;DKPET"},
      {SMARTBUFF_HungerForBlood, 0.5, Enum.Type.Spell},
      {SMARTBUFF_Recuperate, 0.5, Enum.Type.Spell},
      {SMARTBUFF_Evasion, 0.2, Enum.Type.Spell},
      {SMARTBUFF_InstantPoison, 60, Enum.Type.Spell, nil, CheckFishingPole, nil, RoguePoisonsLethal},
      {SMARTBUFF_DeadlyPoison, 60, Enum.Type.Spell, nil, CheckFishingPole, nil, RoguePoisonsLethal},
      {SMARTBUFF_WoundPoison, 60, Enum.Type.Spell, nil, CheckFishingPole, nil, RoguePoisonsLethal},
      {SMARTBUFF_LeechingPoison, 60, Enum.Type.Spell, nil, CheckFishingPole, nil, RoguePoisonsNonLethal},
      {SMARTBUFF_NumbingPoison, 60, Enum.Type.Spell, nil, CheckFishingPole, nil, RoguePoisonsNonLethal},
      {SMARTBUFF_CripplingPoison, 60, Enum.Type.Spell, nil, CheckFishingPole, nil, RoguePoisonsNonLethal},
      {SMARTBUFF_AmplifyPoison, 60, Enum.Type.Spell, nil, CheckFishingPole, nil, RoguePoisonsNonLethal},
      {SMARTBUFF_AtrophicPoison, 60, Enum.Type.Spell, nil, CheckFishingPole, nil, RoguePoisonsNonLethal}
    };
  end

  -- Paladin
  if (SMARTBUFF_PLAYERCLASS == "PALADIN") then
    ---@type SpellList
    SMARTBUFF_CLASS_BUFFS = {
      {SMARTBUFF_RighteousFury, 30, Enum.Type.Spell},
      {SMARTBUFF_AvengingWrath, 0.333, Enum.Type.Spell},
      {SMARTBUFF_BlessingOfFreedom, 0.1, Enum.Type.GroupSpell, {52}, "WARRIOR;DEATHKNIGHT;DRUID;SHAMAN;HUNTER;ROGUE;MAGE;PRIEST;PALADIN;WARLOCK;MONK;DEMONHUNTER;EVOKER;HPET;WPET;DKPET"},
      {SMARTBUFF_BlessingOfSalvation, 0.1, Enum.Type.GroupSpell, {66}, "WARRIOR;DEATHKNIGHT;DRUID;SHAMAN;HUNTER;ROGUE;MAGE;PRIEST;PALADIN;WARLOCK;MONK;DEMONHUNTER;EVOKER;HPET;WPET;DKPET"},
      {SMARTBUFF_BeaconOfLight, 5, Enum.Type.GroupSpell, {39}, "WARRIOR;DRUID;SHAMAN;HUNTER;ROGUE;MAGE;PRIEST;PALADIN;WARLOCK;DEATHKNIGHT;MONK;DEMONHUNTER;EVOKER;HPET;WPET;DKPET"},
      {SMARTBUFF_BeaconOfFaith, 5, Enum.Type.GroupSpell, {39}, "WARRIOR;DRUID;SHAMAN;HUNTER;ROGUE;MAGE;PRIEST;PALADIN;WARLOCK;DEATHKNIGHT;MONK;DEMONHUNTER;EVOKER;HPET;WPET;DKPET"},
      {SMARTBUFF_CrusaderAura, -1, Enum.Type.Spell},
      {SMARTBUFF_DevotionAura, -1, Enum.Type.Spell, nil, nil, nil, PaladinAuras},
      {SMARTBUFF_RetributionAura, -1, Enum.Type.Spell, nil, nil, nil, PaladinAuras},
    };
  end

  -- Deathknight
  if (SMARTBUFF_PLAYERCLASS == "DEATHKNIGHT") then
    ---@type SpellList
    SMARTBUFF_CLASS_BUFFS = {
      {SMARTBUFF_DancingRuneWeapon, 0.2, Enum.Type.Spell},
      --{SMARTBUFF_BLOODPRESENCE, -1, SMARTBUFF_CONST_STANCE, nil, nil, nil, ChainDKPresence},
      --{SMARTBUFF_FROSTPRESENCE, -1, SMARTBUFF_CONST_STANCE, nil, nil, nil, ChainDKPresence},
      --{SMARTBUFF_UNHOLYPRESENCE, -1, SMARTBUFF_CONST_STANCE, nil, nil, nil, ChainDKPresence},
      {SMARTBUFF_HornOfWinter, 60, Enum.Type.Spell, nil, nil, ShoutAuras},
      -- {SMARTBUFF_BONESHIELD, 5, SMARTBUFF_CONST_SELF},
      {SMARTBUFF_RaiseDead, 1, Enum.Type.Spell, nil, CheckPet},
      {SMARTBUFF_PathOfFrost, -1, Enum.Type.Spell}
    };
  end

  -- Monk
  if (SMARTBUFF_PLAYERCLASS == "MONK") then
    ---@type SpellList
    SMARTBUFF_CLASS_BUFFS = {
      --{SMARTBUFF_LOTWT, 60, SMARTBUFF_CONST_GROUP, {81}},
      --{SMARTBUFF_LOTE, 60, SMARTBUFF_CONST_GROUP, {22}, nil, LinkStats},
      {SMARTBUFF_StanceOfTheFierceTiger, -1, Enum.Type.ClassStance, nil, nil, nil, MonkStances},
      {SMARTBUFF_Stagger, -1, Enum.Type.ClassStance, nil, nil, nil, MonkStances},
      --{SMARTBUFF_SOTWISESERPENT, -1, SMARTBUFF_CONST_STANCE, nil, nil, nil, ChainMonkStance},
      --{SMARTBUFF_SOTPIRITEDCRANE, -1, SMARTBUFF_CONST_STANCE, nil, nil, nil, ChainMonkStance},
      {SMARTBUFF_BlackOxStatue, 15, Enum.Type.Spell, nil, nil, nil, MonkStatues},
      { SMARTBUFF_JadeSerpentStatue, 15, Enum.Type.Spell, nil, nil, nil, MonkStatues}
    };
  end

  -- Demon Hunter
  if (SMARTBUFF_PLAYERCLASS == "DEMONHUNTER") then
    ---@type SpellList
    SMARTBUFF_CLASS_BUFFS = {
    };
  end

  -- Evoker
  if (SMARTBUFF_PLAYERCLASS == "EVOKER") then
    ---@type SpellList
    SMARTBUFF_CLASS_BUFFS = {
      {SMARTBUFF_BlessingOfTheBronze, 60, Enum.Type.Spell},
      {SMARTBUFF_Visage, -1, Enum.Type.Spell},
    };
  end

  -- Items
  ---@type SpellList
  SMARTBUFF_ITEMS = {}
  -- Scrolls
  addItem(    954,   8118 ) -- Scroll of Strength IX
  addItem(    955,   8096 ) -- Scroll of Intellect IX
  addItem(   1180,   8099 ) -- Scroll of Stamina IX
  addItem(   1181,   8112 ) -- Scroll of Spirit IX
  addItem(   1477,   8115 ) -- Scroll of Agility VIII
  addItem(   1711,   8099 ) -- Scroll of Stamina VIII
  addItem(   1712,   8112 ) -- Scroll of Spirit VIII
  addItem(   2289,   8118 ) -- Scroll of Strength VIII
  addItem(   2290,   8096 ) -- Scroll of Intellect VIII
  addItem(   3012,   8115 ) -- Scroll of Agility IX
  addItem(   4419,   8096 ) -- Scroll of Intellect VII
  addItem(   4422,   8099 ) -- Scroll of Stamina VII
  addItem(   4424,   8112 ) -- Scroll of Spirit VII
  addItem(   4425,   8115 ) -- Scroll of Agility VII
  addItem(   4426,   8118 ) -- Scroll of Strength VII
  addItem(  10306,   8112 ) -- Scroll of Spirit VI
  addItem(  10307,   8099 ) -- Scroll of Stamina VI
  addItem(  10308,   8096 ) -- Scroll of Intellect VI
  addItem(  10309,   8115 ) -- Scroll of Agility VI
  addItem(  10310,   8118 ) -- Scroll of Strength VI
  addItem(  27498,   8115 ) -- Scroll of Agility V
  addItem(  27499,   8096 ) -- Scroll of Intellect V
  addItem(  27501,   8112 ) -- Scroll of Spirit V
  addItem(  27502,   8099 ) -- Scroll of Stamina V
  addItem(  27503,   8118 ) -- Scroll of Strength V
  addItem(  33457,   8115 ) -- Scroll of Agility IV
  addItem(  33458,   8096 ) -- Scroll of Intellect IV
  addItem(  33460,   8112 ) -- Scroll of Spirit IV
  addItem(  33461,   8099 ) -- Scroll of Stamina IV
  addItem(  33462,   8118 ) -- Scroll of Strength IV
  addItem(  37091,   8096 ) -- Scroll of Intellect III
  addItem(  37092,   8096 ) -- Scroll of Intellect II
  addItem(  37093,   8099 ) -- Scroll of Stamina III
  addItem(  37094,   8099 ) -- Scroll of Stamina II
  addItem(  37097,   8112 ) -- Scroll of Spirit III
  addItem(  37098,   8112 ) -- Scroll of Spirit II
  addItem(  43463,   8115 ) -- Scroll of Agility III
  addItem(  43464,   8115 ) -- Scroll of Agility II
  addItem(  43465,   8118 ) -- Scroll of Strength III
  addItem(  43466,   8118 ) -- Scroll of Strength II
  addItem(  63303,   8115 ) -- Scroll of Agility I
  addItem(  63305,   8096 ) -- Scroll of Intellect I
  addItem(  63306,   8099 ) -- Scroll of Stamina I
  addItem(  63307,   8112 ) -- Scroll of Spirit I
  addItem(  63304,   8118 ) -- Scroll of Strength I
  addItem(  63308,  89344 ) -- Scroll of Protection IX
  -- Runes
  addItem(  86569, 127230 ) -- Crystal of Insanity
  addItem( 118922, 176151 ) -- Oralius' Whispering Crystal
  addItem( 128475, 190668, {175457,175456,175439 } ) -- Empowered Augment Rune (Horde)
  addItem( 128482, 190668, {175457,175456,175439 } ) -- Empowered Augment Rune (Alliance)
  addItem( 129192, 193456 ) -- Inquisitor's Menacing Eye
  addItem( 129210, 193547 ) -- Fel Crystal Fragments
  addItem( 147707, 242551 ) -- Repurposed Fel Focuser
  addItem( 153023, 224001 ) -- Lightforged Augment Rune
  addItem( 160053, 270058 ) -- Battle-Scarred Augment Rune
  addItem( 174906, 270058 ) -- Lightning-Forged Augment Rune
  addItem( 181468, 347901 ) -- Veiled Augment Rune
  addItem( 190384, 367405 ) -- Eternal Augment Rune
  -- Dragonflight
  addItem( 201325, 393438 ) -- Draconic Augment Rune
  addItem( 198491, 384154 ) -- Vantus Rune: Vault of the Incarnates (Quality 1)
  addItem( 198492, 384248 ) -- Vantus Rune: Vault of the Incarnates (Quality 2)
  addItem( 198493, 384306 ) -- Vantus Rune: Vault of the Incarnates (Quality 3)
  -- Flasks, Elixirs
  addItem(   9187,  11334 ) -- Elixir of Greater Agility
  addItem(  22827,  28493 ) -- Elixir of Major Frost Power
  addItem(  22833,  28501 ) -- Elixir of Major Firepower
  addItem(  22835,  28503 ) -- Elixir of Major Shadow Power
  addItem(  22840,  28509 ) -- Elixir of Major Mageblood
  addItem(  22848, 134870 ) -- Elixir of Empowerment
  addItem(  22851,  28518 ) -- Flask of Fortification
  addItem(  22853,  28519 ) -- Flask of Mighty Versatility
  addItem(  22854,  28520 ) -- Flask of Relentless Assault
  addItem(  22861,  28521 ) -- Flask of Blinding Light
  addItem(  22866,  28540 ) -- Flask of Pure Death
  addItem(  28103,  54452 ) -- Adept's Elixir (duplicate)
  addItem(  28104,  33726 ) -- Elixir of Mastery
  addItem(  32062,  39625 ) -- Elixir of Major Fortitude
  addItem(  22824,  28490 ) -- Elixir of Major Strangth
  addItem(  22825,  28491 ) -- Elixir of Healing Power
  addItem(  22831,  54494 ) -- Elixir of Major Agility
  addItem(  22834,  28502 ) -- Elixir of Major Defense
  addItem(  28102,  33720 ) -- Onslaught Elixir
  addItem(  28103,  54452 ) -- Adept's Elixir
  addItem(  31679,  38954 ) -- Fel Strength Elixir
  addItem(  32063,  39626 ) -- Earthen Elixir
  addItem(  32067,  39627 ) -- Elixir of Draenic Wisdom
  addItem(  32068,  39628 ) -- Elixir of Ironskin
  addItem(  39666,  28497 ) -- Elixir of Mighty Agility
  addItem(  40070,  33721 ) -- Spellpower Elixir
  addItem(  40072,  53747 ) -- Elixir of Spirit
  addItem(  40073,  53748 ) -- Elixir of Mighty Strength
  addItem(  40076,  53749 ) -- Guru's Elixir
  addItem(  40078,  53751 ) -- Elixir of Mighty Fortitude
  addItem(  40097,  53763 ) -- Elixir of Protection
  addItem(  44325,  60340 ) -- Elixir of Accuracy
  addItem(  44327,  60341 ) -- Elixir of Deadly Strikes
  addItem(  44328,  60343 ) -- Elixir of Mighty Defense
  addItem(  44329,  60344 ) -- Elixir of Expertise
  addItem(  44330,  80532 ) -- Elixir of Armor Piercing
  addItem(  44331,  60346 ) -- Elixir of Lightning Speed
  addItem(  44332,  60347 ) -- Elixir of Mighty Thoughts
  addItem(  46376,  53755 ) -- Flask of the Frost Wyrm
  addItem(  46377,  53760 ) -- Flask of Endless Rage
  addItem(  46378,  54212 ) -- Flask of Pure Mojo
  addItem(  46379,  53758 ) -- Flask of Stoneblood
  addItem(  58148,  79635 ) -- Elixir of the Master
  addItem(  58085,  79469 ) -- Flask of Steelskin
  addItem(  58086,  79470 ) -- Flask of the Draconic Mind
  addItem(  58087,  79471 ) -- Flask of the Winds
  addItem(  58088,  79472 ) -- Flask of Titanic Strength
  addItem(  58084,  79468 ) -- Ghost Elixir
  addItem(  58089,  79474 ) -- Elixir of the Naga
  addItem(  58092,  79477 ) -- Elixir of the Cobra
  addItem(  58093,  79480 ) -- Elixir of Deep Earth
  addItem(  58094,  79481 ) -- Elixir of Impossible Accuracy
  addItem(  58143,  79631 ) -- Prismatic Elixir
  addItem(  58144,  79632 ) -- Elixir of Mighty Speed
  addItem(  65455,  92679 ) -- Flask of Battle
  addItem(  67438,  94160 ) -- Flask of Flowing Water
  addItem(  76075, 105681 ) -- Mantid Elixir
  addItem(  76076, 105682 ) -- Mad Hozen Elixir
  addItem(  76077, 105683 ) -- Elixir of Weaponry
  addItem(  76078, 105684 ) -- Elixir of the Rapids
  addItem(  76079, 105685 ) -- Elixir of Peace
  addItem(  76080, 105686 ) -- Elixir of Perfection
  addItem(  76081, 105687 ) -- Elixir of Mirrors
  addItem(  76083, 105688 ) -- Monk's Elixir
  addItem(  75525, 105617 ) -- Alchemist's Flask
  addItem(  76087, 105694 ) -- Flask of the Earth
  addItem(  76086, 105693 ) -- Flask of Falling Leaves
  addItem(  76084, 105689 ) -- Flask of Spring Blossoms
  addItem(  76085, 105691 ) -- Flask of the Warm Sun
  addItem(  76088, 105696 ) -- Flask of Winter's Bite
  addItem( 109145, 156073 ) -- Draenic Agility Flask"
  addItem( 109147, 156070 ) -- Draenic Intellect Flask
  addItem( 109148, 156071 ) -- Draenic Strength Flask
  addItem( 109152,  56077 ) -- Draenic Stamina Flask
  addItem( 109153, 156064 ) -- Greater Draenic Agility Flask"
  addItem( 109155, 156079 ) -- Greater Draenic Intellect Flask
  addItem( 109156, 156080 ) -- Greater Draenic Strength Flask
  addItem( 109160, 156084 ) -- Greater Draenic Stamina Flask
  addItem( 127847, 188031 ) -- Flask of the Whispered Pact
  addItem( 127848, 188033 ) -- Flask of the Seventh Demon
  addItem( 127849, 188034 ) -- Flask of the Countless Armies
  addItem( 127850, 188035 ) -- Flask of Ten Thousand Scars
  addItem( 152638, 251836 ) -- Flask of the Currents
  addItem( 152639, 251837 ) -- Flask of Endless Fathoms
  addItem( 152640, 251838 ) -- Flask of the Vast Horizon
  addItem( 152641, 251839 ) -- Flask of the Undertow
  addItem( 168651, 298836 ) -- Greater Flask of the Currents
  addItem( 168652, 298837 ) -- Greather Flask of Endless Fathoms
  addItem( 168653, 298839 ) -- Greater Flask of the Vast Horizon
  addItem( 168654, 298841 ) -- Greater Flask of the Untertow
  addItem( 171276, 307185 ) -- Spectral Flask of Power
  addItem( 171278, 307187 ) -- Spectral Flask of Stamina
  -- Dragonflight
  addItem( 191318, 370438 ) -- Phial of the Eye in the Storm (Quality 1)
  addItem( 191319, 370438 ) -- Phial of the Eye in the Storm (Quality 2)
  addItem( 191320, 370438 ) -- Phial of the Eye in the Storm (Quality 3)
  addItem( 191321, 371204 ) -- Phial of Still Air (Quality 1)
  addItem( 191322, 371204 ) -- Phial of Still Air (Quality 2)
  addItem( 191323, 371204 ) -- Phial of Still Air (Quality 3)
  addItem( 191324, 371036 ) -- Phial of Icy Preservation (Quality 1)
  addItem( 191325, 371036 ) -- Phial of Icy Preservation (Quality 2)
  addItem( 191326, 371036 ) -- Phial of Icy Preservation (Quality 3)
  addItem( 191327, 374000 ) -- Iced Phial of Corrupting Rage (Quality 1)
  addItem( 191328, 374000 ) -- Iced Phial of Corrupting Rage (Quality 2)
  addItem( 191329, 374000 ) -- Iced Phial of Corrupting Rage (Quality 3)
  addItem( 191330, 371386 ) -- Phial of Charged Isolation (Quality 1)
  addItem( 191331, 371386 ) -- Phial of Charged Isolation (Quality 2)
  addItem( 191332, 371386 ) -- Phial of Charged Isolation (Quality 3)
  addItem( 191333, 373257 ) -- Phial of Glacial Fury (Quality 1)
  addItem( 191334, 373257 ) -- Phial of Glacial Fury (Quality 2)
  addItem( 191335, 373257 ) -- Phial of Glacial Fury (Quality 3)
  addItem( 191336, 370652 ) -- Phial of Static Empowerment (Quality 1)
  addItem( 191337, 370652 ) -- Phial of Static Empowerment (Quality 2)
  addItem( 191338, 370652 ) -- Phial of Static Empowerment (Quality 3)
  addItem( 191339, 371172 ) -- Phial of Tepid Versatility (Quality 1)
  addItem( 191340, 371172 ) -- Phial of Tepid Versatility (Quality 2)
  addItem( 191341, 371172 ) -- Phial of Tepid Versatility (Quality 3)
  addItem( 191342, 393700 ) -- Aerated Phial of Deftness (Quality 1)
  addItem( 191343, 393700 ) -- Aerated Phial of Deftness (Quality 2)
  addItem( 191344, 393700 ) -- Aerated Phial of Deftness (Quality 3)
  addItem( 191345, 393717 ) -- Steaming Phial of Finesse (Quality 1)
  addItem( 191346, 393717 ) -- Steaming Phial of Finesse (Quality 1)
  addItem( 191347, 393717 ) -- Steaming Phial of Finesse (Quality 1)
  addItem( 191348, 371186 ) -- Charged Phial of Alacrity (Quality 1)
  addItem( 191349, 371186 ) -- Charged Phial of Alacrity (Quality 2)
  addItem( 191350, 371186 ) -- Charged Phial of Alacrity (Quality 3)
  addItem( 191354, 393714 ) -- Crystalline Phial of Perception (Quality 1)
  addItem( 191355, 393714 ) -- Crystalline Phial of Perception (Quality 2)
  addItem( 191356, 393714 ) -- Crystalline Phial of Perception (Quality 3)
  addItem( 191357, 371348, { 371348, 371350, 371351, 371353 } ) -- Phial of Elemental Chaos (Quality 1)
  addItem( 191358, 371348, { 371348, 371350, 371351, 371353 } ) -- Phial of Elemental Chaos (Quality 2)
  addItem( 191359, 371348, { 371348, 371350, 371351, 371353 } ) -- Phial of Elemental Chaos (Quality 3)
  addItem( 197720, 393665 ) -- Aerated Phial of Quick Hands (Quality 1)
  addItem( 197721, 393665 ) -- Aerated Phial of Quick Hands (Quality 2)
  addItem( 197722, 393665 ) -- Aerated Phial of Quick Hands (Quality 3)

  -- Toys
  SMARTBUFF_TOYS = {}
  addToy(  69775,  98444 ) -- Vrykul Drinking Horn
  addToy(  85500, 124036 ) -- Anglers Fishing Raft
  addToy(  85973, 125167 ) -- Ancient Pandaren Fishing Charm
  addToy(  94604, 138927 ) -- Burning Seed
  addToy(  92738, 158486 ) -- Safari Hat
  addToy( 110424, 158474 ) -- Savage Safari Hat
  addToy( 164375, 281303 ) -- Bad Mojo Banana
  addToy( 129165, 193345 ) -- Barnacle-Encrusted Gem
  addToy( 116115, 170869 ) -- Blazing Wings
  addToy( 133997, 203533 ) -- Black Ice
  addToy( 122298, 181642 ) -- Bodyguard Miniaturization Device
  addToy( 163713, 279934 ) -- Brazier Cap
  addToy( 128310, 189363 ) -- Burning Blade
  addToy( 116440, 171554 ) -- Burning Defender's Medallion
  addToy( 128807, 192225 ) -- Coin of Many Faces
  addToy( 138878, 217668 ) -- Copy of Daglop's Contract
  addToy( 143662, 232613 ) -- Crate of Bobbers: Pepe
  addToy( 142529, 231319 ) -- Crate of Bobbers: Cat Head
  addToy( 142530, 231338 ) -- Crate of Bobbers: Tugboat
  addToy( 142528, 231291 ) -- Crate of Bobbers: Can of Worms
  addToy( 142532, 231349 ) -- Crate of Bobbers: Murloc Head
  addToy( 147308, 240800 ) -- Crate of Bobbers: Enchanted Bobber
  addToy( 142531, 231341 ) -- Crate of Bobbers: Squeaky Duck
  addToy( 147312, 240801 ) -- Crate of Bobbers: Demon Noggin
  addToy( 147307, 240803 ) -- Crate of Bobbers: Carved Wooden Helm
  addToy( 147309, 240806 ) -- Crate of Bobbers: Face of the Forest
  addToy( 147310, 240802 ) -- Crate of Bobbers: Floating Totem
  addToy( 147311, 240804 ) -- Crate of Bobbers: Replica Gondola
  addToy( 122117, 179872 ) -- Cursed Feather of Ikzan
  addToy(  54653,  75532 ) -- Darkspear Pride
  addToy( 108743, 160688 ) -- Deceptia's Smoldering Boots
  addToy( 129149, 193333 ) -- Death's Door Charm
  addToy( 159753, 279366 ) -- Desert Flute
  addToy( 164373, 281298 ) -- Enchanted Soup Stone
  addToy( 140780, 224992 ) -- Fal'dorei Egg
  addToy( 122304, 138927 ) -- Fandral's Seed Pouch
  addToy( 102463, 148429 ) -- Fire-Watcher's Oath
  addToy( 128471, 190655 ) -- Frostwolf Grunt's Battlegear
  addToy( 128462, 190653 ) -- Karabor Councilor's Attire
  addToy( 161342, 275089 ) -- Gem of Acquiescence
  addToy( 127659, 188228 ) -- Ghostly Iron Buccaneer's Hat
  addToy(  54651,  75531 ) -- Gnomeregan Pride
  addToy( 118716, 175832 ) -- Goren Garb
  addToy( 138900, 217708 ) -- Gravil Goldbraid's Famous Sausage Hat
  addToy( 159749, 277572 ) -- Haw'li's Hot & Spicy Chili
  addToy( 163742, 279997 ) -- Heartsbane Grimoire
  addToy( 140325, 223446 ) -- Home Made Party Mask
  addToy( 136855, 210642 ) -- Hunter's Call
  addToy(  43499,  58501 ) -- Iron Boot Flask
  addToy( 118244, 173956 ) -- Iron Buccaneer's Hat
  addToy( 170380, 304369 ) -- Jar of Sunwarmed Sand
  addToy( 127668, 187174 ) -- Jewel of Hellfire
  addToy(  86571, 127261 ) -- Kang's Bindstone
  addToy(  68806,  96312 ) -- Kalytha's Haunted Locket
  addToy( 163750, 280121 ) -- Kovork Kostume
  addToy( 164347, 281302 ) -- Magic Monkey Banana
  addToy( 118938, 176180 ) -- Manastorm's Duplicator
  addToy( 163775, 280133 ) -- Molok Morion
  addToy( 101571, 144787 ) -- Moonfang Shroud
  addToy( 105898, 145255 ) -- Moonfang's Paw
  addToy(  52201,  73320 ) -- Muradin's Favor
  addToy( 138873, 217597 ) -- Mystical Frosh Hat
  addToy( 163795, 280308 ) -- Oomgut Ritual Drum
  addToy(   1973,  16739 ) -- Orb of Deception
  addToy(  35275, 160331 ) -- Orb of the Sin'dorei
  addToy( 158149, 264091 ) -- Overtuned Corgi Goggles
  addToy( 130158, 195949 ) -- Path of Elothir
  addToy( 127864, 188172 ) -- Personal Spotlight
  addToy( 127394, 186842 ) -- Podling Camouflage
  addToy( 108739, 162402 ) -- Pretty Draenor Pearl
  addToy( 129093, 129999 ) -- Ravenbear Disguise
  addToy( 153179, 254485 ) -- Blue Conservatory Scroll
  addToy( 153180, 254486 ) -- Yellow Conservatory Scroll
  addToy( 153181, 254487 ) -- Red Conservatory Scroll
  addToy( 104294, 148529 ) -- Rime of the Time-Lost Mariner
  addToy( 119215, 176898 ) -- Robo-Gnomebobulator
  addToy( 119134, 176569 ) -- Sargerei Disguise
  addToy( 129055,  62089 ) -- Shoe Shine Kit
  addToy( 163436, 279977 ) -- Spectral Visage
  addToy( 156871, 261981 ) -- Spitzy
  addToy(  66888,   6405 ) -- Stave of Fur and Claw
  addToy( 111476, 169291 ) -- Stolen Breath
  addToy( 140160, 222630 ) -- Stormforged Vrykul Horn
  addToy( 163738, 279983 ) -- Syndicate Mask
  addToy( 130147, 195509 ) -- Thistleleaf Branch
  addToy( 113375, 166592 ) -- Vindicator's Armor Polish Kit
  addToy( 163924, 280632 ) -- Whiskerwax Candle
  addToy(  97919, 141917 ) -- Whole-Body Shrinka'
  addToy( 167698, 293671 ) -- Secret Fish Goggles
  addToy( 169109, 299445 ) -- Beeholder's Goggles
  addToy( 199902, 388275 ) -- Wayfarer's Compass
  addToy( 202019, 396172 ) -- Golden Dragon Goblet
  addToy( 198857, 385941 ) -- Lucky Duck

  SMARTBUFF_AddMsgD("Spell list initialized");

end
