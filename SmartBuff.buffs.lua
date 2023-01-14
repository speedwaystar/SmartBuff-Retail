 local _;
S = SMARTBUFF_GLOBALS;

SMARTBUFF_PLAYERCLASS = nil;
SMARTBUFF_CLASSBUFFS = {};

-- buff categories
---@alias Type
---| "ALL" # unused
---| "GROUP" # spells which buff group members
---| "GROUPALL" # spells which buff the entire group
---| "SELF" # self-only spells
---| "FORCESELF" # buffs which can be cast while shapeshifted
---| "TRACK" # tracking skills
---| "WEAPON" # weapon buff spells (e.g. windfury)
---| "INVENTORY" # weapon buff items (oils, runes, stones)]
---| "FOOD" # items which give the well fed buff
---| "SCROLL" # items without cooldowns (scrolls, toys, augment runes)
---| "POTION" # items with cooldowns (phials, flasks, potions)
---| "STANCE" # class stancess
---| "ITEM" # conjured items (manastones, mage food)
---| "ITEMGROUP" # unused (items which buff party members, e.g. battle standards?)
---| "TOY" # toys (curently treated as SCROLLS)
SMARTBUFF_CONST_ALL       = "ALL";        -- not used
SMARTBUFF_CONST_GROUP     = "GROUP";      -- SMARTBUFF_IsSpell, arg1 = spellID
SMARTBUFF_CONST_GROUPALL  = "GROUPALL";   -- arg1 = spellID
SMARTBUFF_CONST_SELF      = "SELF";       -- arg1 = spellID
SMARTBUFF_CONST_FORCESELF = "FORCESELF";  -- arg1 = spellID
SMARTBUFF_CONST_TRACK     = "TRACK";      -- special case, but should be spellID (to test)
SMARTBUFF_CONST_WEAPON    = "WEAPON";     -- SMARTBUFF_IsItem, arg1 = itemID
SMARTBUFF_CONST_INV       = "INVENTORY";  -- arg1 = itemID
SMARTBUFF_CONST_FOOD      = "FOOD";       -- arg1 = itemID
SMARTBUFF_CONST_SCROLL    = "SCROLL";     -- arg1 = itemID
SMARTBUFF_CONST_POTION    = "POTION";     -- arg1 = itemID
SMARTBUFF_CONST_STANCE    = "STANCE";     -- arg1 = spellID
SMARTBUFF_CONST_CONJURE   = "ITEM";       -- arg1 = spellID (sic) conjured items
SMARTBUFF_CONST_ITEMGROUP = "ITEMGROUP";  -- items used on units. unused
-- toys are currently handled by a special case, so this constant isn't used (yet)
SMARTBUFF_CONST_TOY       = "TOY";        -- arg1 = itemID

Enum.Spells = Enum.MakeEnum(SMARTBUFF_CONST_GROUP, SMARTBUFF_CONST_FOOD, SMARTBUFF_CONST_GROUPALL, SMARTBUFF_CONST_SELF, SMARTBUFF_CONST_FORCESELF, SMARTBUFF_CONST_WEAPON, SMARTBUFF_CONST_STANCE, SMARTBUFF_CONST_CONJURE, SMARTBUFF_CONST_TRACK)

Enum.Items = Enum.MakeEnum(SMARTBUFF_CONST_INV, SMARTBUFF_CONST_SCROLL, SMARTBUFF_CONST_POTION, SMARTBUFF_CONST_ITEMGROUP)

--- universal settings for a buff
---@class BuffInfo
---@field BuffID integer itemID|spellID
---@field Duration number Cooldown duration in seconds, `0` if spell is ready to be cast.
---@field Type Type
---@field AuraID integer spellID of buff aura
---@field Params string e.g."WARRIOR;HUNTER;ROGUE" or "HPET;WPET;DKPET"
---@field MinLevel table required level (deprecated)
---@field Links table aura IDs overwritten by the buff
---@field Chain table
---@field Name string
---@field Hyperlink string
---@field Target Unit
---@field GroupBuff integer
---@field GroupBuffDuration integer
---@field GroupBuffID integer
---@field Icon Icon
---@field IconGroup Icon
---@field Order table
---@field HasMainHandEnchant boolean
---@field MainHandExpiration number
---@field MainHandCharges integer
---@field HasOffHandEnchant boolean
---@field OffHandExpiration number
---@field OffHandCharges integer
---@field HasCharges boolean
---@field Charges integer
---@field RebuffTimer number
---@field StartTime number The time when the cooldown started (as returned by `GetTime())`; zero if no cooldown
---@field expirationTime number
---@field TimeLeft number
---@field HasExpired boolean
---@field InventorySlot integer
---@field ActionType ActionType
---@field SplashIcon string

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

---@enum Enum.SpellList
Enum.SpellList =
{
  BuffID = 1;
  Duration = 2;
  Type = 3;
  MinLevel = 4;
  AuraID = 5;
  Params = 5;
  Links = 6;
  Chain = 7;
}

S.CheckPet = "CHECKPET";
S.CheckPetNeeded = "CHECKPETNEEDED";
S.CheckFishingPole = "CHECKFISHINGPOLE";
S.NIL = "x";
S.Toybox = { };

local function GetItems(items)
  local t = { };
  for _, id in pairs(items) do
    --printd("Item found:", _G.GetItemInfo(id));
    table.insert(t, id);
  end
  return t;
end

local function InsertItem(t, type, itemId, spellId, duration, link)
  local _,item = GetItemInfo(itemId); -- item link
  local spell = GetSpellInfo(spellId);
  if (item and spell) then
    --printd("Item found: "..itemId..", "..spellId);
    table.insert(t, {item, duration, type, nil, spell, link});
  end
end

local function AddItemScroll(itemId, spellId, duration, link)
  InsertItem(SMARTBUFF_SCROLL, SMARTBUFF_CONST_SCROLL, itemId, spellId, duration, link);
end

local function LoadToys()
	C_ToyBox.SetCollectedShown(true)
	C_ToyBox.SetAllSourceTypeFilters(true)
	C_ToyBox.SetFilterString("")
	local nTotal = C_ToyBox.GetNumTotalDisplayedToys();
	local nLearned = C_ToyBox.GetNumLearnedDisplayedToys() or 0;
	if (nLearned <= 0) then
	  return;
	end

	for i = 1, nTotal do
		local num = C_ToyBox.GetToyFromIndex(i);
		local id, name, icon = C_ToyBox.GetToyInfo(num);
		if (id) then
		  if (PlayerHasToy(id)) then
        _,name = GetItemInfo(id)
		    S.Toybox[tostring(name)] = {id, icon};
		  end
		end
	end

  for i = 1, nTotal do
    local num = C_ToyBox.GetToyFromIndex(i);
    local id, _, icon = C_ToyBox.GetToyInfo(num);
    if (id) then
      if (PlayerHasToy(id)) then
        S.Toybox[id] = {id, icon};
      end
    end
  end

  SMARTBUFF_AddMsgD("Toys initialized");
end

function SMARTBUFF_InitItemList()
  -- Stones and oils
  SMARTBUFF_HEALTHSTONE         = 5512;   -- Healthstone
  SMARTBUFF_MANAGEM             = 36799;  -- Mana Gem
  SMARTBUFF_BRILLIANTMANAGEM    = 81901;  -- Brilliant Mana Gem
  SMARTBUFF_SSROUGH             = 2862;   -- Rough Sharpening Stone
  SMARTBUFF_SSCOARSE            = 2863;   -- Coarse Sharpening Stone
  SMARTBUFF_SSHEAVY             = 2871;   -- Heavy Sharpening Stone
  SMARTBUFF_SSSOLID             = 7964;   -- Solid Sharpening Stone
  SMARTBUFF_SSDENSE             = 12404;  -- Dense Sharpening Stone
  SMARTBUFF_SSELEMENTAL         = 18262;  -- Elemental Sharpening Stone
  SMARTBUFF_SSFEL               = 23528;  -- Fel Sharpening Stone
  SMARTBUFF_SSADAMANTITE        = 23529;  -- Adamantite Sharpening Stone
  SMARTBUFF_WSROUGH             = 3239;   -- Rough Weightstone
  SMARTBUFF_WSCOARSE            = 3240;   -- Coarse Weightstone
  SMARTBUFF_WSHEAVY             = 3241;   -- Heavy Weightstone
  SMARTBUFF_WSSOLID             = 7965;   -- Solid Weightstone
  SMARTBUFF_WSDENSE             = 12643;  -- Dense Weightstone
  SMARTBUFF_WSFEL               = 28420;  -- Fel Weightstone
  SMARTBUFF_WSADAMANTITE        = 28421;  -- Adamantite Weightstone
  SMARTBUFF_SHADOWOIL           = 3824;   -- Shadow Oil
  SMARTBUFF_FROSTOIL            = 3829;   -- Frost Oil
  SMARTBUFF_MANAOIL1            = 20745;  -- Minor Mana Oil
  SMARTBUFF_MANAOIL2            = 20747;  -- Lesser Mana Oil
  SMARTBUFF_MANAOIL3            = 20748;  -- Brilliant Mana Oil
  SMARTBUFF_MANAOIL4            = 22521;  -- Superior Mana Oil
  SMARTBUFF_WIZARDOIL1          = 20744;  -- Minor Wizard Oil
  SMARTBUFF_WIZARDOIL2          = 20746;  -- Lesser Wizard Oil
  SMARTBUFF_WIZARDOIL3          = 20750;  -- Wizard Oil
  SMARTBUFF_WIZARDOIL4          = 20749;  -- Brilliant Wizard Oil
  SMARTBUFF_WIZARDOIL5          = 22522;  -- Superior Wizard Oil
  SMARTBUFF_SHADOWCOREOIL       = 171285; -- Shadowcore Oil
  SMARTBUFF_EMBALMERSOIL        = 171286; -- Embalmer's Oil"
  -- Dragonflight
  SMARTBUFF_SafeRockets_q1      = 198160; -- Completely Safe Rockets (Quality 1)
  SMARTBUFF_SafeRockets_q2      = 198161; -- Completely Safe Rockets (Quality 2)
  SMARTBUFF_SafeRockets_q3      = 198162; -- Completely Safe Rockets (Quality 3)
  SMARTBUFF_BuzzingRune_q1      = 194817; -- Buzzing Rune (Quality 1)
  SMARTBUFF_BuzzingRune_q2      = 194818; -- Buzzing Rune (Quality 2)
  SMARTBUFF_BuzzingRune_q3      = 194819; -- Buzzing Rune (Quality 3)
  SMARTBUFF_ChirpingRune_q1     = 194824; -- Chirping Rune (Quality 1)
  SMARTBUFF_ChirpingRune_q2     = 194825; -- Chirping Rune (Quality 2)
  SMARTBUFF_ChirpingRune_q3     = 194826; -- Chirping Rune (Quality 3)
  SMARTBUFF_HowlingRune_q1      = 194821; -- Howling Rune (Quality 1)
  SMARTBUFF_HowlingRune_q2      = 194822; -- Howling Rune (Quality 2)
  SMARTBUFF_HowlingRune_q3      = 194820; -- Howling Rune (Quality 3)
  SMARTBUFF_PrimalWeighstone_q1 = 191943; -- Primal Weighstone (Quality 1)
  SMARTBUFF_PrimalWeighstone_q2 = 191944; -- Primal Weighstone (Quality 2)
  SMARTBUFF_PrimalWeighstone_q3 = 191945; -- Primal Weighstone (Quality 3)
  SMARTBUFF_PrimalWhetstone_q1  = 191933; -- Primal Whestone (Quality 1)
  SMARTBUFF_PrimalWhetstone_q2  = 191939; -- Primal Whestone (Quality 2)
  SMARTBUFF_PrimalWhetstone_q3  = 191940; -- Primal Whestone (Quality 3)

  -- Food
--  SMARTBUFF_KIBLERSBITS         = 33874; -- Kibler's Bits
--  SMARTBUFF_STORMCHOPS          = 33866; -- Stormchops
  SMARTBUFF_JUICYBEARBURGER     = 35565;  -- Juicy Bear Burger
  SMARTBUFF_CRUNCHYSPIDER       = 22645;  -- Crunchy Spider Surprise
  SMARTBUFF_LYNXSTEAK           = 27635;  -- Lynx Steak
  SMARTBUFF_CHARREDBEARKABOBS   = 35563;  -- Charred Bear Kabobs
  SMARTBUFF_BATBITES            = 27636;  -- Bat Bites
  SMARTBUFF_ROASTEDMOONGRAZE    = 24105;  -- Roasted Moongraze Tenderloin
  SMARTBUFF_MOKNATHALSHORTRIBS  = 31672;  -- Mok'Nathal Shortribs
  SMARTBUFF_CRUNCHYSERPENT      = 31673;  -- Crunchy Serpent
  SMARTBUFF_ROASTEDCLEFTHOOF    = 27658;  -- Roasted Clefthoof
  SMARTBUFF_FISHERMANSFEAST     = 33052;  -- Fisherman's Feast
  SMARTBUFF_WARPBURGER          = 27659;  -- Warp Burger
  SMARTBUFF_RAVAGERDOG          = 27655;  -- Ravager Dog
  SMARTBUFF_SKULLFISHSOUP       = 33825;  -- Skullfish Soup
  SMARTBUFF_BUZZARDBITES        = 27651;  -- Buzzard Bites
  SMARTBUFF_TALBUKSTEAK         = 27660;  -- Talbuk Steak
  SMARTBUFF_GOLDENFISHSTICKS    = 27666;  -- Golden Fish Sticks
  SMARTBUFF_SPICYHOTTALBUK      = 33872;  -- Spicy Hot Talbuk
  SMARTBUFF_FELTAILDELIGHT      = 27662;  -- Feltail Delight
  SMARTBUFF_BLACKENEDSPOREFISH  = 27663;  -- Blackened Sporefish
  SMARTBUFF_HOTAPPLECIDER       = 34411;  -- Hot Apple Cider
  SMARTBUFF_BROILEDBLOODFIN     = 33867;  -- Broiled Bloodfin
  SMARTBUFF_SPICYCRAWDAD        = 27667;  -- Spicy Crawdad
  SMARTBUFF_POACHEDBLUEFISH     = 27665;  -- Poached Bluefish
  SMARTBUFF_BLACKENEDBASILISK   = 27657;  -- Blackened Basilisk
  SMARTBUFF_GRILLEDMUDFISH      = 27664;  -- Grilled Mudfish
  SMARTBUFF_CLAMBAR             = 30155;  -- Clam Bar
  SMARTBUFF_SAGEFISHDELIGHT     = 21217;  -- Sagefish Delight
  SMARTBUFF_SALTPEPPERSHANK     = 133557; -- Salt & Pepper Shank
  SMARTBUFF_PICKLEDSTORMRAY     = 133562; -- Pickled Stormray
  SMARTBUFF_DROGBARSTYLESALMON  = 133569; -- Drogbar-Style Salmon
  SMARTBUFF_BARRACUDAMRGLGAGH   = 133567; -- Barracuda Mrglgagh
  SMARTBUFF_FIGHTERCHOW         = 133577; -- Fighter Chow
  SMARTBUFF_FARONAARFIZZ        = 133563; -- Faronaar Fizz
  SMARTBUFF_BEARTARTARE         = 133576; -- Bear Tartare
  SMARTBUFF_LEGIONCHILI         = 118428; -- Legion Chili
  SMARTBUFF_DEEPFRIEDMOSSGILL   = 133561; -- Deep-Fried Mossgill
  SMARTBUFF_MONDAZI             = 154885; -- Mon'Dazi
  SMARTBUFF_KULTIRAMISU         = 154881; -- Kul Tiramisu
  SMARTBUFF_GRILLEDCATFISH      = 154889; -- Grilled Catfish
  SMARTBUFF_LOALOAF             = 154887; -- Loa Loaf
  SMARTBUFF_HONEYHAUNCHES       = 154882; -- Honey-Glazed Haunches
  SMARTBUFF_RAVENBERRYTARTS     = 154883; -- Ravenberry Tarts
  SMARTBUFF_SWAMPFISHNCHIPS     = 154884; -- Swamp Fish 'n Chips
  SMARTBUFF_SEASONEDLOINS       = 154891; -- Seasoned Loins
  SMARTBUFF_SAILORSPIE          = 154888; -- Sailor's Pie
  SMARTBUFF_SPICEDSNAPPER       = 154886; -- Spiced Snapper
  --SMARTBUFF_HEARTSBANEHEXWURST = 163781; -- Heartsbane Hexwurst
  SMARTBUFF_ABYSSALFRIEDRISSOLE = 168311; -- Abyssal-Fried Rissole
  SMARTBUFF_BAKEDPORTTATO       = 168313; -- Baked Port Tato
  SMARTBUFF_BILTONG             = 168314; -- Bil'Tong
  SMARTBUFF_BIGMECH             = 168310; -- Mech-Dowel's 'Big Mech'
  SMARTBUFF_FRAGRANTKAKAVIA     = 168312; -- Fragrant Kakavia
  SMARTBUFF_BANANABEEFPUDDING   = 172069; -- Banana Beef Pudding
  SMARTBUFF_BUTTERSCOTCHRIBS    = 172040; -- Butterscotch Marinated Ribs
  SMARTBUFF_CINNAMONBONEFISH    = 172044; -- Cinnamon Bonefish Stew
  SMARTBUFF_EXTRALEMONYFILET    = 184682; -- Extra Lemony Herb Filet
  SMARTBUFF_FRIEDBONEFISH       = 172063; -- Friedn Bonefish
  SMARTBUFF_IRIDESCENTRAVIOLI   = 172049; -- Iridescent Ravioli with Apple Sauce
  SMARTBUFF_MEATYAPPLEDUMPLINGS = 172048; -- Meaty Apple Dumplings
  SMARTBUFF_PICKLEDMEATSMOOTHIE = 172068; -- Pickled Meat Smoothie
  SMARTBUFF_SERAPHTENDERS       = 172061; -- Seraph Tenders
  SMARTBUFF_SPINEFISHSOUFFLE    = 172041; -- Spinefish Souffle and Fries
  SMARTBUFF_STEAKALAMODE        = 172051; -- Steak ala Mode
  SMARTBUFF_SWEETSILVERGILL     = 172050; -- Sweet Silvergill Sausages
  SMARTBUFF_TENEBROUSCROWNROAST = 172045; -- Tenebrous Crown Roast Aspic
  -- Dragonflight
  SMARTBUFF_TimelyDemise        = 197778; -- Timely Demise (70 Haste)
  SMARTBUFF_FiletOfFangs        = 197779; -- Filet of Fangs (70 Crit)
  SMARTBUFF_SeamothSurprise     = 197780; -- Seamoth Surprise (70 Vers)
  SMARTBUFF_SaltBakedFishcake   = 197781; -- Salt-Baked Fishcake (70 Mastery)
  SMARTBUFF_FeistyFishSticks    = 197782; -- Feisty Fish Sticks (45 Haste/Crit)
  SMARTBUFF_SeafoodPlatter      = 197783; -- Aromatic Seafood Platter (45 Haste/Vers)
  SMARTBUFF_SeafoodMedley       = 197784; -- Sizzling Seafood Medley (45 Haste/Mastery)
  SMARTBUFF_RevengeServedCold   = 197785; -- Revenge, Served Cold (45 Crit/Verst)
  SMARTBUFF_Tongueslicer        = 197786; -- Thousandbone Tongueslicer (45 Crit/Mastery)
  SMARTBUFF_GreatCeruleanSea    = 197787; -- Great Cerulean Sea (45 Vers/Mastery)
  SMARTBUFF_FatedFortuneCookie  = 197792; -- Fated Fortune Cookie (76 primary stat)
  SMARTBUFF_KaluakBanquet       = 197794; -- Feast: Grand Banquet of the Kalu'ak (76 primary stat)
  SMARTBUFF_HoardOfDelicacies   = 197795; -- Feast: Hoard of Draconic Delicacies (76 primary stat)

  -- Food item IDs
  S.FoodItems = GetItems({
                                -- WotLK
                                  39691, 34125, 42779, 42997, 42998, 42999, 43000, 34767,
                                  42995, 34769, 34754, 34758, 34766, 42994, 42996,34756,
                                  34768, 42993, 34755, 43001, 34757, 34752, 34751, 34750,
                                  34749, 34764, 34765, 34763, 34762, 42942, 43268, 34748,
                                -- CT
                                  62651, 62652, 62653, 62654, 62655, 62656, 62657, 62658,
                                  62659, 62660, 62661, 62662, 62663, 62664, 62665, 62666,
                                  62667, 62668, 62669, 62670, 62671, 62649,
                                -- MoP
                                  74645, 74646, 74647, 74648, 74649, 74650, 74652, 74653,
                                  74655, 74656, 86069, 86070, 86073, 86074, 81400, 81401,
                                  81402, 81403, 81404, 81405, 81406, 81408, 81409, 81410,
                                  81411, 81412, 81413, 81414,
                                -- WoD
                                  111431, 111432, 111433, 111434, 111435, 111436, 111437,
                                  111438, 111439, 111440, 111442, 111443, 111444,
                                  111445, 111446, 111447, 111448, 111449, 111450, 111451,
                                  111452, 111453, 111454, 127991, 111457, 111458, 118576,
                                });
   -- Conjured mage food IDs
  SMARTBUFF_CONJUREDMANA        = 113509; -- Conjured Mana Buns
  S.FoodMage = GetItems({
                                  113509, 80618,  80610,  65499,  43523,  43518,  34062,
                                  65517,  65516,  65515,  65500,  42955
                                });

  --SMARTBUFF_BCPETFOOD1          = 33874;  -- Kibler's Bits (Pet food)
  --SMARTBUFF_WOTLKPETFOOD1       = 43005;  -- Spiced Mammoth Treats (Pet food)

  -- Scrolls
  SMARTBUFF_SOAGILITY1          = 3012;   -- Scroll of Agility I
  SMARTBUFF_SOAGILITY2          = 1477;   -- Scroll of Agility II
  SMARTBUFF_SOAGILITY3          = 4425;   -- Scroll of Agility III
  SMARTBUFF_SOAGILITY4          = 10309;  -- Scroll of Agility IV
  SMARTBUFF_SOAGILITY5          = 27498;  -- Scroll of Agility V
  SMARTBUFF_SOAGILITY6          = 33457;  -- Scroll of Agility VI
  SMARTBUFF_SOAGILITY7          = 43463;  -- Scroll of Agility VII
  SMARTBUFF_SOAGILITY8          = 43464;  -- Scroll of Agility VIII
  SMARTBUFF_SOAGILITY9          = 63303;  -- Scroll of Agility IX
  SMARTBUFF_SOINTELLECT1        = 955;    -- Scroll of Intellect I
  SMARTBUFF_SOINTELLECT2        = 2290;   -- Scroll of Intellect II
  SMARTBUFF_SOINTELLECT3        = 4419;   -- Scroll of Intellect III
  SMARTBUFF_SOINTELLECT4        = 10308;  -- Scroll of Intellect IV
  SMARTBUFF_SOINTELLECT5        = 27499;  -- Scroll of Intellect V
  SMARTBUFF_SOINTELLECT6        = 33458;  -- Scroll of Intellect VI
  SMARTBUFF_SOINTELLECT7        = 37091;  -- Scroll of Intellect VII
  SMARTBUFF_SOINTELLECT8        = 37092;  -- Scroll of Intellect VIII
  SMARTBUFF_SOINTELLECT9        = 63305;  -- Scroll of Intellect IX
  SMARTBUFF_SOSTAMINA1          = 1180;   -- Scroll of Stamina I
  SMARTBUFF_SOSTAMINA2          = 1711;   -- Scroll of Stamina II
  SMARTBUFF_SOSTAMINA3          = 4422;   -- Scroll of Stamina III
  SMARTBUFF_SOSTAMINA4          = 10307;  -- Scroll of Stamina IV
  SMARTBUFF_SOSTAMINA5          = 27502;  -- Scroll of Stamina V
  SMARTBUFF_SOSTAMINA6          = 33461;  -- Scroll of Stamina VI
  SMARTBUFF_SOSTAMINA7          = 37093;  -- Scroll of Stamina VII
  SMARTBUFF_SOSTAMINA8          = 37094;  -- Scroll of Stamina VIII
  SMARTBUFF_SOSTAMINA9          = 63306;  -- Scroll of Stamina IX
  SMARTBUFF_SOSPIRIT1           = 1181;   -- Scroll of Spirit I
  SMARTBUFF_SOSPIRIT2           = 1712;   -- Scroll of Spirit II
  SMARTBUFF_SOSPIRIT3           = 4424;   -- Scroll of Spirit III
  SMARTBUFF_SOSPIRIT4           = 10306;  -- Scroll of Spirit IV
  SMARTBUFF_SOSPIRIT5           = 27501;  -- Scroll of Spirit V
  SMARTBUFF_SOSPIRIT6           = 33460;  -- Scroll of Spirit VI
  SMARTBUFF_SOSPIRIT7           = 37097;  -- Scroll of Spirit VII
  SMARTBUFF_SOSPIRIT8           = 37098;  -- Scroll of Spirit VIII
  SMARTBUFF_SOSPIRIT9           = 63307;  -- Scroll of Spirit IX
  SMARTBUFF_SOSTRENGHT1         = 954;    -- Scroll of Strength I
  SMARTBUFF_SOSTRENGHT2         = 2289;   -- Scroll of Strength II
  SMARTBUFF_SOSTRENGHT3         = 4426;   -- Scroll of Strength III
  SMARTBUFF_SOSTRENGHT4         = 10310;  -- Scroll of Strength IV
  SMARTBUFF_SOSTRENGHT5         = 27503;  -- Scroll of Strength V
  SMARTBUFF_SOSTRENGHT6         = 33462;  -- Scroll of Strength VI
  SMARTBUFF_SOSTRENGHT7         = 43465;  -- Scroll of Strength VII
  SMARTBUFF_SOSTRENGHT8         = 43466;  -- Scroll of Strength VIII
  SMARTBUFF_SOSTRENGHT9         = 63304;  -- Scroll of Strength IX
  SMARTBUFF_SOPROTECTION9       = 63308;  -- Scroll of Protection IX

  SMARTBUFF_MiscItem1           = 178512;  -- Celebration Package
  SMARTBUFF_MiscItem2           = 44986;  -- Warts-B-Gone Lip Balm
  SMARTBUFF_MiscItem3           = 69775;  -- Vrykul Drinking Horn
  SMARTBUFF_MiscItem4           = 86569;  -- Crystal of Insanity
  SMARTBUFF_MiscItem5           = 85500;  -- Anglers Fishing Raft
  SMARTBUFF_MiscItem6           = 85973;  -- Ancient Pandaren Fishing Charm
  SMARTBUFF_MiscItem7           = 94604;  -- Burning Seed
  SMARTBUFF_MiscItem9           = 92738;  -- Safari Hat
  SMARTBUFF_MiscItem10          = 110424; -- Savage Safari Hat
  SMARTBUFF_MiscItem11          = 118922; -- Oralius' Whispering Crystal
  SMARTBUFF_MiscItem12          = 129192; -- Inquisitor's Menacing Eye
  SMARTBUFF_MiscItem13          = 129210; -- Fel Crystal Fragments
  SMARTBUFF_MiscItem14          = 128475; -- Empowered Augment Rune
  SMARTBUFF_MiscItem15          = 128482; -- Empowered Augment Rune
  SMARTBUFF_MiscItem17          = 147707; -- Repurposed Fel Focuser
  --Shadowlands
  SMARTBUFF_AugmentRune         = 190384; -- Eternal Augment Rune
  SMARTBUFF_VieledAugment       = 181468; -- Veiled Augment Rune
  --Dragonflight
  SMARTBUFF_DraconicRune        = 201325; -- Draconic Augment Rune
  SMARTBUFF_VantusRune_VotI_q1  = 198491; -- Vantus Rune: Vault of the Incarnates (Quality 1)
  SMARTBUFF_VantusRune_VotI_q2  = 198492; -- Vantus Rune: Vault of the Incarnates (Quality 2)
  SMARTBUFF_VantusRune_VotI_q3  = 198493; -- Vantus Rune: Vault of the Incarnates (Quality 3)

  SMARTBUFF_FLASKTBC1           = 22854;  -- Flask of Relentless Assault
  SMARTBUFF_FLASKTBC2           = 22866;  -- Flask of Pure Death
  SMARTBUFF_FLASKTBC3           = 22851;  -- Flask of Fortification
  SMARTBUFF_FLASKTBC4           = 22861;  -- Flask of Blinding Light
  SMARTBUFF_FLASKTBC5           = 22853;  -- Flask of Mighty Versatility
  SMARTBUFF_FLASK1              = 46377;  -- Flask of Endless Rage
  SMARTBUFF_FLASK2              = 46376;  -- Flask of the Frost Wyrm
  SMARTBUFF_FLASK3              = 46379;  -- Flask of Stoneblood
  SMARTBUFF_FLASK4              = 46378;  -- Flask of Pure Mojo
  SMARTBUFF_FLASKCT1            = 58087;  -- Flask of the Winds
  SMARTBUFF_FLASKCT2            = 58088;  -- Flask of Titanic Strength
  SMARTBUFF_FLASKCT3            = 58086;  -- Flask of the Draconic Mind
  SMARTBUFF_FLASKCT4            = 58085;  -- Flask of Steelskin
  SMARTBUFF_FLASKCT5            = 67438;  -- Flask of Flowing Water
  SMARTBUFF_FLASKCT7            = 65455;  -- Flask of Battle
  SMARTBUFF_FLASKMOP1           = 75525;  -- Alchemist's Flask
  SMARTBUFF_FLASKMOP2           = 76087;  -- Flask of the Earth
  SMARTBUFF_FLASKMOP3           = 76086;  -- Flask of Falling Leaves
  SMARTBUFF_FLASKMOP4           = 76084;  -- Flask of Spring Blossoms
  SMARTBUFF_FLASKMOP5           = 76085;  -- Flask of the Warm Sun
  SMARTBUFF_FLASKMOP6           = 76088;  -- Flask of Winter's Bite
  SMARTBUFF_FLASKWOD1           = 109152; -- Draenic Stamina Flask
  SMARTBUFF_FLASKWOD2           = 109148; -- Draenic Strength Flask
  SMARTBUFF_FLASKWOD3           = 109147; -- Draenic Intellect Flask
  SMARTBUFF_FLASKWOD4           = 109145; -- Draenic Agility Flask"
  SMARTBUFF_GRFLASKWOD1         = 109160; -- Greater Draenic Stamina Flask
  SMARTBUFF_GRFLASKWOD2         = 109156; -- Greater Draenic Strength Flask
  SMARTBUFF_GRFLASKWOD3         = 109155; -- Greater Draenic Intellect Flask
  SMARTBUFF_GRFLASKWOD4         = 109153; -- Greater Draenic Agility Flask"
  SMARTBUFF_FLASKLEG1           = 127850; -- Flask of Ten Thousand Scars
  SMARTBUFF_FLASKLEG2           = 127849; -- Flask of the Countless Armies
  SMARTBUFF_FLASKLEG3           = 127847; -- Flask of the Whispered Pact
  SMARTBUFF_FLASKLEG4           = 127848; -- Flask of the Seventh Demon
  SMARTBUFF_FLASKBFA1           = 152639; -- Flask of Endless Fathoms
  SMARTBUFF_FLASKBFA2           = 152638; -- Flask of the Currents
  SMARTBUFF_FLASKBFA3           = 152641; -- Flask of the Undertow
  SMARTBUFF_FLASKBFA4           = 152640; -- Flask of the Vast Horizon
  SMARTBUFF_GRFLASKBFA1         = 168652; -- Greather Flask of Endless Fathoms
  SMARTBUFF_GRFLASKBFA2         = 168651; -- Greater Flask of the Currents
  SMARTBUFF_GRFLASKBFA3         = 168654; -- Greather Flask of teh Untertow
  SMARTBUFF_GRFLASKBFA4         = 168653; -- Greater Flask of the Vast Horizon
  SMARTBUFF_FLASKSL1            = 171276; -- Spectral Flask of Power
  SMARTBUFF_FLASKSL2            = 171278; -- Spectral Flask of Stamina

  SMARTBUFF_FlaskDF1_q1         = 191318; -- Phial of the Eye in the Storm (Quality 1)
  SMARTBUFF_FlaskDF1_q2         = 191319; -- Phial of the Eye in the Storm (Quality 2)
  SMARTBUFF_FlaskDF1_q3         = 191320; -- Phial of the Eye in the Storm (Quality 3)

  SMARTBUFF_FlaskDF2_q1         = 191321; -- Phial of Still Air (Quality 1)
  SMARTBUFF_FlaskDF2_q2         = 191322; -- Phial of Still Air (Quality 2)
  SMARTBUFF_FlaskDF2_q3         = 191323; -- Phial of Still Air (Quality 3)

  SMARTBUFF_FlaskDF3_q1         = 191324; -- Phial of Icy Preservation (Quality 1)
  SMARTBUFF_FlaskDF3_q2         = 191325; -- Phial of Icy Preservation (Quality 2)
  SMARTBUFF_FlaskDF3_q3         = 191326; -- Phial of Icy Preservation (Quality 3)

  SMARTBUFF_FlaskDF4_q1         = 191327; -- Iced Phial of Corrupting Rage (Quality 1)
  SMARTBUFF_FlaskDF4_q2         = 191328; -- Iced Phial of Corrupting Rage (Quality 2)
  SMARTBUFF_FlaskDF4_q3         = 191329; -- Iced Phial of Corrupting Rage (Quality 3)

  SMARTBUFF_FlaskDF5_q1         = 191330; -- Phial of Charged Isolation (Quality 1)
  SMARTBUFF_FlaskDF5_q2         = 191331; -- Phial of Charged Isolation (Quality 2)
  SMARTBUFF_FlaskDF5_q3         = 191332; -- Phial of Charged Isolation (Quality 3)

  SMARTBUFF_FlaskDF6_q1         = 191333; -- Phial of Glacial Fury (Quality 1)
  SMARTBUFF_FlaskDF6_q2         = 191334; -- Phial of Glacial Fury (Quality 2)
  SMARTBUFF_FlaskDF6_q3         = 191335; -- Phial of Glacial Fury (Quality 3)

  SMARTBUFF_FlaskDF7_q1         = 191336; -- Phial of Static Empowerment (Quality 1)
  SMARTBUFF_FlaskDF7_q2         = 191337; -- Phial of Static Empowerment (Quality 2)
  SMARTBUFF_FlaskDF7_q3         = 191338; -- Phial of Static Empowerment (Quality 3)

  SMARTBUFF_FlaskDF8_q1         = 191339; -- Phial of Tepid Versatility (Quality 1)
  SMARTBUFF_FlaskDF8_q2         = 191340; -- Phial of Tepid Versatility (Quality 2)
  SMARTBUFF_FlaskDF8_q3         = 191341; -- Phial of Tepid Versatility (Quality 3)

  SMARTBUFF_FlaskDF9_q1         = 191342; -- Aerated Phial of Deftness (Quality 1)
  SMARTBUFF_FlaskDF9_q2         = 191343; -- Aerated Phial of Deftness (Quality 2)
  SMARTBUFF_FlaskDF9_q3         = 191344; -- Aerated Phial of Deftness (Quality 3)

  SMARTBUFF_FlaskDF10_q1        = 191345; -- Steaming Phial of Finesse (Quality 1)
  SMARTBUFF_FlaskDF10_q2        = 191346; -- Steaming Phial of Finesse (Quality 1)
  SMARTBUFF_FlaskDF10_q3        = 191347; -- Steaming Phial of Finesse (Quality 1)

  SMARTBUFF_FlaskDF11_q1        = 191348; -- Charged Phial of Alacrity (Quality 1)
  SMARTBUFF_FlaskDF11_q2        = 191349; -- Charged Phial of Alacrity (Quality 2)
  SMARTBUFF_FlaskDF11_q3        = 191350; -- Charged Phial of Alacrity (Quality 3)

  SMARTBUFF_FlaskDF12_q1        = 191354; -- Crystalline Phial of Perception (Quality 1)
  SMARTBUFF_FlaskDF12_q2        = 191355; -- Crystalline Phial of Perception (Quality 2)
  SMARTBUFF_FlaskDF12_q3        = 191356; -- Crystalline Phial of Perception (Quality 3)

  SMARTBUFF_FlaskDF13_q1        = 191357; -- Phial of Elemental Chaos (Quality 1)
  SMARTBUFF_FlaskDF13_q2        = 191358; -- Phial of Elemental Chaos (Quality 2)
  SMARTBUFF_FlaskDF13_q3        = 191359; -- Phial of Elemental Chaos (Quality 3)

  SMARTBUFF_FlaskDF14_q1        = 197720; -- Aerated Phial of Quick Hands (Quality 1)
  SMARTBUFF_FlaskDF14_q2        = 197721; -- Aerated Phial of Quick Hands (Quality 2)
  SMARTBUFF_FlaskDF14_q3        = 197722; -- Aerated Phial of Quick Hands (Quality 3)

  SMARTBUFF_ELIXIRTBC1          = 22831;  -- Elixir of Major Agility
  SMARTBUFF_ELIXIRTBC2          = 28104;  -- Elixir of Mastery
  SMARTBUFF_ELIXIRTBC3          = 22825;  -- Elixir of Healing Power
  SMARTBUFF_ELIXIRTBC4          = 22834;  -- Elixir of Major Defense
  SMARTBUFF_ELIXIRTBC5          = 22824;  -- Elixir of Major Strangth
  SMARTBUFF_ELIXIRTBC6          = 32062;  -- Elixir of Major Fortitude
  SMARTBUFF_ELIXIRTBC7          = 22840;  -- Elixir of Major Mageblood
  SMARTBUFF_ELIXIRTBC8          = 32067;  -- Elixir of Draenic Wisdom
  SMARTBUFF_ELIXIRTBC9          = 28103;  -- Adept's Elixir
  SMARTBUFF_ELIXIRTBC10         = 22848;  -- Elixir of Empowerment
  SMARTBUFF_ELIXIRTBC11         = 28102;  -- Onslaught Elixir
  SMARTBUFF_ELIXIRTBC12         = 22835;  -- Elixir of Major Shadow Power
  SMARTBUFF_ELIXIRTBC13         = 32068;  -- Elixir of Ironskin
  SMARTBUFF_ELIXIRTBC14         = 32063;  -- Earthen Elixir
  SMARTBUFF_ELIXIRTBC15         = 22827;  -- Elixir of Major Frost Power
  SMARTBUFF_ELIXIRTBC16         = 31679;  -- Fel Strength Elixir
  SMARTBUFF_ELIXIRTBC17         = 22833;  -- Elixir of Major Firepower
  SMARTBUFF_ELIXIR1             = 39666;  -- Elixir of Mighty Agility
  SMARTBUFF_ELIXIR2             = 44332;  -- Elixir of Mighty Thoughts
  SMARTBUFF_ELIXIR3             = 40078;  -- Elixir of Mighty Fortitude
  SMARTBUFF_ELIXIR4             = 40073;  -- Elixir of Mighty Strength
  SMARTBUFF_ELIXIR5             = 40072;  -- Elixir of Spirit
  SMARTBUFF_ELIXIR6             = 40097;  -- Elixir of Protection
  SMARTBUFF_ELIXIR7             = 44328;  -- Elixir of Mighty Defense
  SMARTBUFF_ELIXIR8             = 44331;  -- Elixir of Lightning Speed
  SMARTBUFF_ELIXIR9             = 44329;  -- Elixir of Expertise
  SMARTBUFF_ELIXIR10            = 44327;  -- Elixir of Deadly Strikes
  SMARTBUFF_ELIXIR11            = 44330;  -- Elixir of Armor Piercing
  SMARTBUFF_ELIXIR12            = 44325;  -- Elixir of Accuracy
  SMARTBUFF_ELIXIR13            = 40076;  -- Guru's Elixir
  SMARTBUFF_ELIXIR14            = 9187;   -- Elixir of Greater Agility
  -- SMARTBUFF_ELIXIR15            = 28103;  -- Adept's Elixir (duplicate)
  SMARTBUFF_ELIXIR16            = 40070;  -- Spellpower Elixir"
  SMARTBUFF_ELIXIRCT1           = 58148;  -- Elixir of the Master
  SMARTBUFF_ELIXIRCT2           = 58144;  -- Elixir of Mighty Speed
  SMARTBUFF_ELIXIRCT3           = 58094;  -- Elixir of Impossible Accuracy
  SMARTBUFF_ELIXIRCT4           = 58143;  -- Prismatic Elixir
  SMARTBUFF_ELIXIRCT5           = 58093;  -- Elixir of Deep Earth
  SMARTBUFF_ELIXIRCT6           = 58092;  -- Elixir of the Cobra
  SMARTBUFF_ELIXIRCT7           = 58089;  -- Elixir of the Naga
  SMARTBUFF_ELIXIRCT8           = 58084;  -- Ghost Elixir
  SMARTBUFF_ELIXIRMOP1          = 76081;  -- Elixir of Mirrors
  SMARTBUFF_ELIXIRMOP2          = 76079;  -- Elixir of Peace
  SMARTBUFF_ELIXIRMOP3          = 76080;  -- Elixir of Perfection
  SMARTBUFF_ELIXIRMOP4          = 76078;  -- Elixir of the Rapids
  SMARTBUFF_ELIXIRMOP5          = 76077;  -- Elixir of Weaponry
  SMARTBUFF_ELIXIRMOP6          = 76076;  -- Mad Hozen Elixir
  SMARTBUFF_ELIXIRMOP7          = 76075;  -- Mantid Elixir
  SMARTBUFF_ELIXIRMOP8          = 76083;  -- Monk's Elixir

  -- Draught of Ten Lands
  SMARTBUFF_EXP_POTION          = 166750; -- Draught of Ten Lands

  -- fishing pole
  S.FishingPole = 6256;   -- Fishing Pole

  SMARTBUFF_AddMsgD("Item list initialized");
  -- i still want to load them regardless of the option to turn them off/hide them
  -- so that my settings are preserved and loaded should i turn it back on.
  LoadToys();
end


function SMARTBUFF_InitSpellIDs()
  SMARTBUFF_TESTSPELL           = 774;

  -- Druid
  SMARTBUFF_DRUID_CAT           = 768;    -- Cat Form
  SMARTBUFF_DRUID_TREE          = 33891;  -- Incarnation: Tree of Life
  SMARTBUFF_DRUID_TREANT        = 114282; -- Treant Form
  SMARTBUFF_DRUID_MOONKIN       = 24858;  -- Moonkin Form
  --SMARTBUFF_DRUID_MKAURA        = 24907;  -- Moonkin Aura
  SMARTBUFF_DRUID_TRACK         = 5225;   -- Track Humanoids
  SMARTBUFF_MOTW                = 1126;   -- Mark of the Wild
  SMARTBUFF_BARKSKIN            = 22812;  -- Barkskin
  SMARTBUFF_TIGERSFURY          = 5217;   -- Tiger's Fury
  SMARTBUFF_SAVAGEROAR          = 52610;  -- Savage Roar
  SMARTBUFF_CENARIONWARD        = 102351; -- Cenarion Ward
  SMARTBUFF_DRUID_BEAR          = 5487;   -- Bear Form

  -- Priest
  SMARTBUFF_POWERWORDFORTITUDE  = 21562;  -- Power Word: Fortitude
  SMARTBUFF_POWERWORDSHIELD     = 17;     -- Power Word: Shield
  --SMARTBUFF_FEARWARD          = 6346;   -- Fear Ward
  SMARTBUFF_RENEW               = 139;    -- Renew
  SMARTBUFF_LEVITATE            = 1706;   -- Levitate
  SMARTBUFF_SHADOWFORM          = 232698; -- Shadowform
  SMARTBUFF_VAMPIRICEMBRACE     = 15286;  -- Vampiric Embrace
  --SMARTBUFF_LIGHTWELL           = 724;   -- Lightwell
  --SMARTBUFF_CHAKRA1             = 81206  -- Chakra Sanctuary
  --SMARTBUFF_CHAKRA2             = 81208  -- Chakra Serenity
  --SMARTBUFF_CHAKRA3             = 81209  -- Chakra Chastise
  -- Priest buff links
  S.LinkPriestChakra            = { --[[ SMARTBUFF_CHAKRA1, SMARTBUFF_CHAKRA2,
                                    SMARTBUFF_CHAKRA3 ]]
                                  };

  -- Mage
  SMARTBUFF_ARCANEINTELLECT     = 1459;   -- Arcane Intellect
  SMARTBUFF_DALARANBRILLIANCE   = 61316;  -- Dalaran Brilliance
  SMARTBUFF_FROSTARMOR          = 7302;   -- Frost Armor
  SMARTBUFF_MAGEARMOR           = 6117;   -- Mage Armor
  --SMARTBUFF_MOLTENARMOR         = 30482; -- Molten Armor
  SMARTBUFF_MANASHIELD          = 35064;  -- Mana Shield
  --SMARTBUFF_ICEWARD             = 111264;-- Ice Ward
  SMARTBUFF_ICEBARRIER          = 11426;  -- Ice Barrier
  --SMARTBUFF_COMBUSTION          = 11129; -- Combustion
  SMARTBUFF_ARCANEPOWER         = 12042;  -- Arcane Power
  SMARTBUFF_PRESENCEOFMIND      = 205025; -- Presence of Mind
  SMARTBUFF_ICYVEINS            = 12472;  -- Icy Veins
  SMARTBUFF_SUMMONWATERELE      = 31687;  -- Summon Water Elemental
  SMARTBUFF_SLOWFALL            = 130;    -- Slow Fall
  SMARTBUFF_REFRESHMENT         = 42955;  -- Conjure Refreshment
  SMARTBUFF_TEMPSHIELD          = 198111; -- Temporal Shield
  --SMARTBUFF_AMPMAGIC            = 159916; -- Amplify Magic

  SMARTBUFF_PRISBARRIER         = 235450; -- Prismatic Barrier
  SMARTBUFF_IMPPRISBARRIER      = 321745; -- Improved Prismatic Barrier

  SMARTBUFF_BLAZBARRIER         = 235313; -- Blazing Barrier
  SMARTBUFF_ARCANEFAMILIAR      = 205022; -- Arcane Familiar
  SMARTBUFF_CREATEMG            = 759;    -- Conjure Mana Gem

  -- Mage buff links
  S.ChainMageArmor              = { SMARTBUFF_FROSTARMOR, SMARTBUFF_MAGEARMOR,
                                    SMARTBUFF_MOLTENARMOR
                                  };

  -- Warlock
  SMARTBUFF_AMPLIFYCURSE        = 328774; -- Amplify Curse
  SMARTBUFF_DEMONARMOR          = 285933; -- Demon ARmor
  SMARTBUFF_DARKINTENT          = 183582; -- Dark Intent
  SMARTBUFF_UNENDINGBREATH      = 5697;   -- Unending Breath
  SMARTBUFF_SOULLINK            = 108447; -- Soul Link
  SMARTBUFF_LIFETAP             = 1454;   -- Life Tap
  SMARTBUFF_CREATEHS            = 6201;   -- Create Healthstone
  SMARTBUFF_SOULSTONE           = 20707;  -- Soulstone
  SMARTBUFF_GOSACRIFICE         = 108503; -- Grimoire of Sacrifice
  --SMARTBUFF_BLOODHORROR         = 111397; -- Blood Horror
  -- Warlock pets
  SMARTBUFF_SUMMONIMP           = 688;    -- Summon Imp
  SMARTBUFF_SUMMONFELHUNTER     = 691;    -- Summon Fellhunter
  SMARTBUFF_SUMMONVOIDWALKER    = 697;    -- Summon Voidwalker
  SMARTBUFF_SUMMONSUCCUBUS      = 712;    -- Summon Succubus
  SMARTBUFF_SUMMONINFERNAL      = 1122;   -- Summon Infernal
  SMARTBUFF_SUMMONDOOMGUARD     = 18540;  -- Summon Doomguard
  SMARTBUFF_SUMMONFELGUARD      = 30146;  -- Summon Felguard
  SMARTBUFF_SUMMONFELIMP        = 112866; -- Summon Fel Imp
  SMARTBUFF_SUMMONVOIDLORD      = 112867; -- Summon Voidlord
  SMARTBUFF_SUMMONSHIVARRA      = 112868; -- Summon Shivarra
  SMARTBUFF_SUMMONOBSERVER      = 112869; -- Summon Observer
  SMARTBUFF_SUMMONWRATHGUARD    = 112870; -- Summon Wrathguard

  -- Hunter
  SMARTBUFF_VOLLEY              = 194386; -- Volley
  SMARTBUFF_RAPIDFIRE           = 257044; -- Rapid Fire
  SMARTBUFF_CAMOUFLAGE          = 199483; -- Camouflage
  SMARTBUFF_ASPECTOFTHECHEETAH  = 186257; -- Aspect of the Cheetah
  SMARTBUFF_ASPECTOFTHEWILD     = 193530; -- Aspect of the Wild
  -- Hunter pets
  SMARTBUFF_CALL_PET_1          = 883;    -- Call Pet 1
  SMARTBUFF_CALL_PET_2          = 83242;  -- Call Pet 2
  SMARTBUFF_CALL_PET_3          = 83243;  -- Call Pet 3
  SMARTBUFF_CALL_PET_4          = 83244;  -- Call Pet 4
  SMARTBUFF_CALL_PET_5          = 83245;  -- Call Pet 5
  -- Hunter buff links
  S.LinkAspects                 = { SMARTBUFF_ASPECTOFTHECHEETAH, SMARTBUFF_ASPECTOFTHEWILD };

  -- Shaman
  SMARTBUFF_LIGHTNINGSHIELD     = 192106; -- Lightning Shield
  SMARTBUFF_WATERSHIELD         = 52127;  -- Water Shield
  SMARTBUFF_EARTHSHIELD         = 974;    -- Earth Shield
  SMARTBUFF_WATERWALKING        = 546;    -- Water Walking
  SMARTBUFF_EMASTERY            = 16166;  -- Elemental Mastery
  SMARTBUFF_ASCENDANCE_ELE      = 114050; -- Ascendance (Elemental)
  SMARTBUFF_ASCENDANCE_ENH      = 114051; -- Ascendance (Enhancement)
  SMARTBUFF_ASCENDANCE_RES      = 114052; -- Ascendance (Restoration)
  SMARTBUFF_WINDFURYW           = 33757;  -- Windfury Weapon
  SMARTBUFF_FLAMETONGUEW        = 318038; -- Flametongue Weapon
  SMARTBUFF_EVERLIVINGW         = 382021; -- Everliving Weapon

  -- Shaman buff links
  S.ChainShamanShield           = { SMARTBUFF_LIGHTNINGSHIELD, SMARTBUFF_WATERSHIELD,
                                    SMARTBUFF_EARTHSHIELD
                                  };

  -- Warrior
  SMARTBUFF_BATTLESHOUT         = 6673;   -- Battle Shout
  --SMARTBUFF_COMMANDINGSHOUT     = 97462;    -- Reallying Cry
  SMARTBUFF_BERSERKERRAGE       = 18499;  -- Berserker Rage
  SMARTBUFF_BATSTANCE           = 386164; -- Battle Stance
  SMARTBUFF_DEFSTANCE           = 197690; -- Defensive Stance
  SMARTBUFF_GLADSTANCE          = 156291; -- Gladiator Stance
  SMARTBUFF_SHIELDBLOCK         = 2565;   -- Shield Block

  -- Warrior buff links
  S.ChainWarriorStance          = { SMARTBUFF_BATSTANCE, SMARTBUFF_DEFSTANCE,
                                    SMARTBUFF_GLADSTANCE
                                  };
  S.ChainWarriorShout           = { SMARTBUFF_BATTLESHOUT, SMARTBUFF_COMMANDINGSHOUT };

  -- Rogue
  SMARTBUFF_STEALTH             = 1784;   -- Stealth
  SMARTBUFF_BLADEFLURRY         = 13877;  -- Blade Flurry
  SMARTBUFF_SAD                 = 5171;   -- Slice and Dice
  SMARTBUFF_EVASION             = 5277;   -- Evasion
  SMARTBUFF_HUNGERFORBLOOD      = 60177;  -- Hunger For Blood
  SMARTBUFF_TRICKS              = 57934;  -- Tricks of the Trade
  SMARTBUFF_RECUPERATE          = 185311; -- Crimson Vial
  -- Poisons
  SMARTBUFF_WOUNDPOISON         = 8679;   -- Wound Poison
  SMARTBUFF_CRIPPLINGPOISON     = 3408;   -- Crippling Poison
  SMARTBUFF_DEADLYPOISON        = 2823;   -- Deadly Poison
  SMARTBUFF_LEECHINGPOISON      = 108211; -- Leeching Poison
  SMARTBUFF_INSTANTPOISON       = 315584; -- Instant Poison
  SMARTBUFF_NUMBINGPOISON       = 5761;   -- Numbing Poison
  SMARTBUFF_AMPLIFYPOISON       = 381664; -- Amplifying Poison
  SMARTBUFF_ATROPHICPOISON      = 381637; -- Atrophic Poison

  -- Rogue buff links
  S.ChainRoguePoisonsLethal     = {
                                    SMARTBUFF_DEADLYPOISON, SMARTBUFF_WOUNDPOISON,
                                    SMARTBUFF_INSTANTPOISON, --[[ SMARTBUFF_AGONIZINGPOISON, ]]
                                    SMARTBUFF_AMPLIFYPOISON
                                  };
  S.ChainRoguePoisonsNonLethal  = {
                                    SMARTBUFF_CRIPPLINGPOISON, SMARTBUFF_LEECHINGPOISON,
                                    SMARTBUFF_NUMBINGPOISON, SMARTBUFF_ATROPHICPOISON
                                  };

  -- Paladin
  SMARTBUFF_RIGHTEOUSFURY       = 25780;  -- Righteous Fury
  --SMARTBUFF_HOLYSHIELD          = 20925;  -- Sacred Shield
  SMARTBUFF_BOK                 = 203538; -- Greater Blessing of Kings"
  --SMARTBUFF_BOM                 = 203528; -- Greater Blessing of Might
  SMARTBUFF_BOW                 = 203539; -- Greater Blessing of Wisdom
  SMARTBUFF_HOF                 = 1044;   -- Blessing of Freedom"
  SMARTBUFF_HOP                 = 1022;   -- Blessing of Protection
  SMARTBUFF_HOSAL               = 204013; -- Blessing of Salvation
  --SMARTBUFF_SOJUSTICE           = 20164;  -- Seal of Justice
  --SMARTBUFF_SOINSIGHT           = 20165;  -- Seal of Insight
  --SMARTBUFF_SORIGHTEOUSNESS     = 20154;  -- Seal of Righteousness
  --SMARTBUFF_SOTRUTH             = 31801;  -- Seal of Truth
  --SMARTBUFF_SOCOMMAND           = 105361; -- Seal of Command
  SMARTBUFF_AVENGINGWARTH       = 31884;  -- Avenging Wrath
  SMARTBUFF_BEACONOFLIGHT       = 53563;  -- Beacon of Light
  SMARTBUFF_BEACONOFAITH        = 156910; -- Beacon of Faith
  SMARTBUFF_CRUSADERAURA        = 32223;  -- Crusader Aura
  SMARTBUFF_DEVOTIONAURA        = 465;    -- Devotion Aura
  SMARTBUFF_RETRIBUTIONAURA     = 183435; -- Retribution Aura
  -- Paladin buff links
  S.ChainPaladinAura            = { SMARTBUFF_DEVOTIONAURA, SMARTBUFF_RETRIBUTIONAURA };
  S.ChainPaladinSeal            = { SMARTBUFF_SOCOMMAND, --[[ SMARTBUFF_SOTRUTH, ]]
                                    SMARTBUFF_SOJUSTICE, --[[ SMARTBUFF_SOINSIGHT ,]]
                                    SMARTBUFF_SORIGHTEOUSNESS
                                  };
  S.ChainPaladinBlessing        = { SMARTBUFF_BOK, SMARTBUFF_BOM, SMARTBUFF_BOW };

  -- Death Knight
  SMARTBUFF_DANCINGRW           = 49028; -- Dancing Rune Weapon
  --SMARTBUFF_BLOODPRESENCE       = 48263; -- Blood Presence
  --SMARTBUFF_FROSTPRESENCE       = 48266; -- Frost Presence
  --SMARTBUFF_UNHOLYPRESENCE      = 48265; -- Unholy Presence"
  SMARTBUFF_PATHOFFROST         = 3714;  -- Path of Frost
  --SMARTBUFF_BONESHIELD          = 49222; -- Bone Shield
  SMARTBUFF_HORNOFWINTER        = 57330; -- Horn of Winter
  SMARTBUFF_RAISEDEAD           = 46584; -- Raise Dead
  --SMARTBUFF_POTGRAVE            = 155522; -- Power of the Grave" (P)
  -- Death Knight buff links
  S.ChainDKPresence             = { --[[ SMARTBUFF_BLOODPRESENCE, SMARTBUFF_FROSTPRESENCE,
                                    SMARTBUFF_UNHOLYPRESENCE ]]
                                  };

  -- Monk
  --SMARTBUFF_LOTWT               = 116781; -- Legacy of the White Tiger
  --SMARTBUFF_LOTE                = 115921; -- Legacy of the Emperor
  SMARTBUFF_BLACKOX             = 115315; -- Summon Black Ox Statue
  SMARTBUFF_JADESERPENT         = 115313; -- Summon Jade Serpent Statue
  SMARTBUFF_SOTFIERCETIGER      = 103985; -- Stance of the Fierce Tiger
  SMARTBUFF_SOTSTURDYOX         = 115069; -- Stagger
  --SMARTBUFF_SOTWISESERPENT      = 115070; -- Stance of the Wise Serpent
  --SMARTBUFF_SOTSPIRITEDCRANE    = 154436; -- Stance of the Spirited Crane

  -- Monk buff links
  S.ChainMonkStatue             = { SMARTBUFF_BLACKOX, SMARTBUFF_JADESERPENT };
  S.ChainMonkStance             = { SMARTBUFF_SOTFIERCETIGER, SMARTBUFF_SOTSTURDYOX,
                                    --[[ SMARTBUFF_SOTWISESERPENT, SMARTBUFF_SOTSPIRITEDCRANE ]]
                                  };

  -- Evoker
  SMARTBUFF_BRONZEBLESSING      = 364342;   -- Blessing of the Bronze

  -- Demon Hunter


  -- Tracking
  SMARTBUFF_FINDMINERALS        = 2580;  -- Find Minerals
  SMARTBUFF_FINDHERBS           = 2383;  -- Find Herbs
  SMARTBUFF_FINDTREASURE        = 2481;  -- Find Treasure
  SMARTBUFF_TRACKHUMANOIDS      = 19883; -- Track Humanoids
  SMARTBUFF_TRACKBEASTS         = 1494;  -- Track Beasts
  SMARTBUFF_TRACKUNDEAD         = 19884; -- Track Undead
  SMARTBUFF_TRACKHIDDEN         = 19885; -- Track Hidden
  SMARTBUFF_TRACKELEMENTALS     = 19880; -- Track Elementals
  SMARTBUFF_TRACKDEMONS         = 19878; -- Track Demons
  SMARTBUFF_TRACKGIANTS         = 19882; -- Track Giants
  SMARTBUFF_TRACKDRAGONKIN      = 19879; -- Track Dragonkin

  -- Racial
  SMARTBUFF_STONEFORM           = 20594; -- Stoneform
  SMARTBUFF_BLOODFURY           = 20572; -- Blood Fury" 33697, 33702
  SMARTBUFF_BERSERKING          = 26297; -- Berserking
  SMARTBUFF_WOTFORSAKEN         = 7744;  -- Will of the Forsaken
  SMARTBUFF_WarStomp            = 20549; -- War Stomp

  -- Food
  SMARTBUFF_FOOD_AURA           = 46899; -- Well Fed
  SMARTBUFF_FOOD_SPELL          = 433;   -- Food
  SMARTBUFF_DRINK_SPELL         = 430;   -- Drink

  -- Misc
  --SMARTBUFF_KIRUSSOV            = 46302; -- K'iru's Song of Victory
  SMARTBUFF_FISHING             = 7620 or 111541; -- Fishing

  -- Scroll
  SMARTBUFF_SBAGILITY           = 8115;   -- Scroll buff: Agility
  SMARTBUFF_SBINTELLECT         = 8096;   -- Scroll buff: Intellect
  SMARTBUFF_SBSTAMINA           = 8099;   -- Scroll buff: Stamina
  SMARTBUFF_SBSPIRIT            = 8112;   -- Scroll buff: Spirit
  SMARTBUFF_SBSTRENGHT          = 8118;   -- Scroll buff: Strength
  SMARTBUFF_SBPROTECTION        = 89344;  -- Scroll buff: Armor
  SMARTBUFF_BMiscItem1          = 326396; -- WoW's 16th Anniversary
  SMARTBUFF_BMiscItem2          = 62574;  -- Warts-B-Gone Lip Balm
  SMARTBUFF_BMiscItem3          = 98444;  -- Vrykul Drinking Horn
  SMARTBUFF_BMiscItem4          = 127230; -- Visions of Insanity
  SMARTBUFF_BMiscItem5          = 124036; -- Anglers Fishing Raft
  SMARTBUFF_BMiscItem6          = 125167; -- Ancient Pandaren Fishing Charm
  SMARTBUFF_BMiscItem7          = 138927; -- Burning Essence
  SMARTBUFF_BMiscItem8          = 160331; -- Blood Elf Illusion
  SMARTBUFF_BMiscItem9          = 158486; -- Safari Hat
  SMARTBUFF_BMiscItem10         = 158474; -- Savage Safari Hat
  SMARTBUFF_BMiscItem11         = 176151; -- Whispers of Insanity
  SMARTBUFF_BMiscItem12         = 193456; -- Gaze of the Legion
  SMARTBUFF_BMiscItem13         = 193547; -- Fel Crystal Infusion
  SMARTBUFF_BMiscItem14         = 190668; -- Empower
  SMARTBUFF_BMiscItem14_1       = 175457; -- Focus Augmentation
  SMARTBUFF_BMiscItem14_2       = 175456; -- Hyper Augmentation
  SMARTBUFF_BMiscItem14_3       = 175439; -- Stout Augmentation
  SMARTBUFF_BMiscItem16         = 181642; -- Bodyguard Miniaturization Device
  SMARTBUFF_BMiscItem17         = 242551; -- Fel Focus
  -- Shadowlands
  SMARTBUFF_BAugmentRune        = 367405; -- Eternal Augmentation from Eternal Augment Rune
  SMARTBUFF_BVieledAugment      = 347901; -- Veiled Augmentation from Veiled Augment Rune
  -- Dragonflight
  SMARTBUFF_BDraconicRune       = 393438; -- Draconic Augmentation from Draconic Augment Rune
  SMARTBUFF_BVantusRune_VotI_q1 = 384154; -- Vantus Rune: Vault of the Incarnates (Quality 1)
  SMARTBUFF_BVantusRune_VotI_q2 = 384248; -- Vantus Rune: Vault of the Incarnates (Quality 2)
  SMARTBUFF_BVantusRune_VotI_q3 = 384306; -- Vantus Rune: Vault of the Incarnates (Quality 3)

  S.LinkSafariHat               = { SMARTBUFF_BMiscItem9, SMARTBUFF_BMiscItem10 };
  S.LinkAugment                 = { SMARTBUFF_BMiscItem14, SMARTBUFF_BMiscItem14_1,
                                    SMARTBUFF_BMiscItem14_2, SMARTBUFF_BMiscItem14_3,
                                    SMARTBUFF_BAugmentRune,  SMARTBUFF_BVieledAugment,
                                    SMARTBUFF_BDraconicRune
                                  };

  -- Flasks & Elixirs
  SMARTBUFF_BFLASKTBC1          = 28520;  -- Flask of Relentless Assault
  SMARTBUFF_BFLASKTBC2          = 28540;  -- Flask of Pure Death
  SMARTBUFF_BFLASKTBC3          = 28518;  -- Flask of Fortification
  SMARTBUFF_BFLASKTBC4          = 28521;  -- Flask of Blinding Light
  SMARTBUFF_BFLASKTBC5          = 28519;  -- Flask of Mighty Versatility
  SMARTBUFF_BFLASK1             = 53760;  -- Flask of Endless Rage
  SMARTBUFF_BFLASK2             = 53755;  -- Flask of the Frost Wyrm
  SMARTBUFF_BFLASK3             = 53758;  -- Flask of Stoneblood
  SMARTBUFF_BFLASK4             = 54212;  -- Flask of Pure Mojo
  SMARTBUFF_BFLASKCT1           = 79471;  -- Flask of the Winds
  SMARTBUFF_BFLASKCT2           = 79472;  -- Flask of Titanic Strength
  SMARTBUFF_BFLASKCT3           = 79470;  -- Flask of the Draconic Mind
  SMARTBUFF_BFLASKCT4           = 79469;  -- Flask of Steelskin
  SMARTBUFF_BFLASKCT5           = 94160;  -- Flask of Flowing Water
  SMARTBUFF_BFLASKCT7           = 92679;  -- Flask of Battle
  SMARTBUFF_BFLASKMOP1          = 105617; -- Alchemist's Flask
  SMARTBUFF_BFLASKMOP2          = 105694; -- Flask of the Earth
  SMARTBUFF_BFLASKMOP3          = 105693; -- Flask of Falling Leaves
  SMARTBUFF_BFLASKMOP4          = 105689; -- Flask of Spring Blossoms
  SMARTBUFF_BFLASKMOP5          = 105691; -- Flask of the Warm Sun
  SMARTBUFF_BFLASKMOP6          = 105696; -- Flask of Winter's Bite
  SMARTBUFF_BFLASKCT61          = 79640;  -- Enhanced Intellect
  SMARTBUFF_BFLASKCT62          = 79639;  -- Enhanced Agility
  SMARTBUFF_BFLASKCT63          = 79638;  -- Enhanced Strength
  SMARTBUFF_BFLASKWOD1          = 156077; -- Draenic Stamina Flask
  SMARTBUFF_BFLASKWOD2          = 156071; -- Draenic Strength Flask
  SMARTBUFF_BFLASKWOD3          = 156070; -- Draenic Intellect Flask
  SMARTBUFF_BFLASKWOD4          = 156073; -- Draenic Agility Flask
  SMARTBUFF_BGRFLASKWOD1        = 156084; -- Greater Draenic Stamina Flask
  SMARTBUFF_BGRFLASKWOD2        = 156080; -- Greater Draenic Strength Flask
  SMARTBUFF_BGRFLASKWOD3        = 156079; -- Greater Draenic Intellect Flask
  SMARTBUFF_BGRFLASKWOD4        = 156064; -- Greater Draenic Agility Flask"
  SMARTBUFF_BFLASKLEG1          = 188035; -- Flask of Ten Thousand Scars
  SMARTBUFF_BFLASKLEG2          = 188034; -- Flask of the Countless Armies
  SMARTBUFF_BFLASKLEG3          = 188031; -- Flask of the Whispered Pact
  SMARTBUFF_BFLASKLEG4          = 188033; -- Flask of the Seventh Demon
  SMARTBUFF_BFLASKBFA1          = 251837; -- Flask of Endless Fathoms
  SMARTBUFF_BFLASKBFA2          = 251836; -- Flask of the Currents
  SMARTBUFF_BFLASKBFA3          = 251839; -- Flask of the Undertow
  SMARTBUFF_BFLASKBFA4          = 251838; -- Flask of the Vast Horizon
  SMARTBUFF_BGRFLASKBFA1        = 298837; -- Greather Flask of Endless Fathoms
  SMARTBUFF_BGRFLASKBFA2        = 298836; -- Greater Flask of the Currents
  SMARTBUFF_BGRFLASKBFA3        = 298841; -- Greather Flask of teh Untertow
  SMARTBUFF_BGRFLASKBFA4        = 298839; -- Greater Flask of the Vast Horizon
  SMARTBUFF_BFLASKSL1           = 307185; -- Spectral Flask of Power
  SMARTBUFF_BFLASKSL2           = 307187; -- Spectral Flask of Stamina
  -- Dragonflight
  SMARTBUFF_BFlaskDF1           = 370438; -- Phial of the Eye in the Storm
  SMARTBUFF_BFlaskDF2           = 371204; -- Phial of Still Air
  SMARTBUFF_BFlaskDF3           = 371036; -- Phial of Icy Preservation
  SMARTBUFF_BFlaskDF4           = 374000; -- Iced Phial of Corrupting Rage
  SMARTBUFF_BFlaskDF5           = 371386; -- Phial of Charged Isolation
  SMARTBUFF_BFlaskDF6           = 373257; -- Phial of Glacial Fury
  SMARTBUFF_BFlaskDF7           = 370652; -- Phial of Static Empowerment
  SMARTBUFF_BFlaskDF8           = 371172; -- Phial of Tepid Versatility
  SMARTBUFF_BFlaskDF9           = 393700; -- Aerated Phial of Deftness
  SMARTBUFF_BFlaskDF10          = 393717; -- Steaming Phial of Finesse
  SMARTBUFF_BFlaskDF11          = 371186; -- Charged Phial of Alacrity
  SMARTBUFF_BFlaskDF12          = 393714; -- Crystalline Phial of Perception
  -- the Phial of Elemental     Chaos gives 1 the following 4 random buffs every 60 seconds
  SMARTBUFF_BFlaskDF13_1        = 371348; -- Elemental Chaos: Fire
  SMARTBUFF_BFlaskDF13_2        = 371350; -- Elemental Chaos: Air
  SMARTBUFF_BFlaskDF13_3        = 371351; -- Elemental Chaos: Earth
  SMARTBUFF_BFlaskDF13_4        = 371353; -- Elemental Chaos: Frost
  SMARTBUFF_BFlaskDF14          = 393665; -- Aerated Phial of Quick Hands

  S.LinkFlaskTBC                = { SMARTBUFF_BFLASKTBC1, SMARTBUFF_BFLASKTBC2,
                                    SMARTBUFF_BFLASKTBC3, SMARTBUFF_BFLASKTBC4,
                                    SMARTBUFF_BFLASKTBC5
                                  };
  S.LinkFlaskCT7                = { SMARTBUFF_BFLASKCT1, SMARTBUFF_BFLASKCT2,
                                    SMARTBUFF_BFLASKCT3, SMARTBUFF_BFLASKCT4,
                                    SMARTBUFF_BFLASKCT5
                                  };
  S.LinkFlaskMoP                = { SMARTBUFF_BFLASKCT61, SMARTBUFF_BFLASKCT62,
                                    SMARTBUFF_BFLASKCT63, SMARTBUFF_BFLASKMOP2,
                                    SMARTBUFF_BFLASKMOP3, SMARTBUFF_BFLASKMOP4,
                                    SMARTBUFF_BFLASKMOP5, SMARTBUFF_BFLASKMOP6
                                  };
  S.LinkFlaskWoD                = { SMARTBUFF_BFLASKWOD1, SMARTBUFF_BFLASKWOD2,
                                    SMARTBUFF_BFLASKWOD3, SMARTBUFF_BFLASKWOD4,
                                    SMARTBUFF_BGRFLASKWOD1, SMARTBUFF_BGRFLASKWOD2,
                                    SMARTBUFF_BGRFLASKWOD3, SMARTBUFF_BGRFLASKWOD4
                                  };
  S.LinkFlaskLeg                = { SMARTBUFF_BFLASKLEG1, SMARTBUFF_BFLASKLEG2,
                                    SMARTBUFF_BFLASKLEG3, SMARTBUFF_BFLASKLEG4
                                  };
  S.LinkFlaskBfA                = { SMARTBUFF_BFLASKBFA1, SMARTBUFF_BFLASKBFA2,
                                    SMARTBUFF_BFLASKBFA3, SMARTBUFF_BFLASKBFA4,
                                    SMARTBUFF_BGRFLASKBFA1, SMARTBUFF_BGRFLASKBFA2,
                                    SMARTBUFF_BGRFLASKBFA3, SMARTBUFF_BGRFLASKBFA4
                                  };
  S.LinkFlaskSL                 = { SMARTBUFF_BFLASKSL1, SMARTBUFF_BFLASKSL2 };
  S.LinkFlaskDF                 = { SMARTBUFF_BFlaskDF1, SMARTBUFF_BFlaskDF2,
                                    SMARTBUFF_BFlaskDF3, SMARTBUFF_BFlaskDF4,
                                    SMARTBUFF_BFlaskDF5, SMARTBUFF_BFlaskDF6,
                                    SMARTBUFF_BFlaskDF7, SMARTBUFF_BFlaskDF8,
                                    SMARTBUFF_BFlaskDF9, SMARTBUFF_BFlaskDF10,
                                    SMARTBUFF_BFlaskDF11, SMARTBUFF_BFlaskDF12,
                                    SMARTBUFF_BFlaskDF13_1, SMARTBUFF_BFlaskDF13_2,
                                    SMARTBUFF_BFlaskDF13_3, SMARTBUFF_BFlaskDF13_4,
                                    SMARTBUFF_BFlaskDF14
                                  };

  SMARTBUFF_BELIXIRTBC1         = 54494;  -- Major Agility" B
  SMARTBUFF_BELIXIRTBC2         = 33726;  -- Mastery" B
  SMARTBUFF_BELIXIRTBC3         = 28491;  -- Healing Power" B
  SMARTBUFF_BELIXIRTBC4         = 28502;  -- Major Defense" G
  SMARTBUFF_BELIXIRTBC5         = 28490;  -- Major Strength" B
  SMARTBUFF_BELIXIRTBC6         = 39625;  -- Major Fortitude" G
  SMARTBUFF_BELIXIRTBC7         = 28509;  -- Major Mageblood" B
  SMARTBUFF_BELIXIRTBC8         = 39627;  -- Draenic Wisdom" B
  SMARTBUFF_BELIXIRTBC9         = 54452;  -- Adept's Elixir" B
  SMARTBUFF_BELIXIRTBC10        = 134870; -- Empowerment" B
  SMARTBUFF_BELIXIRTBC11        = 33720;  -- Onslaught Elixir" B
  SMARTBUFF_BELIXIRTBC12        = 28503;  -- Major Shadow Power" B
  SMARTBUFF_BELIXIRTBC13        = 39628;  -- Ironskin" G
  SMARTBUFF_BELIXIRTBC14        = 39626;  -- Earthen Elixir" G
  SMARTBUFF_BELIXIRTBC15        = 28493;  -- Major Frost Power" B
  SMARTBUFF_BELIXIRTBC16        = 38954;  -- Fel Strength Elixir" B
  SMARTBUFF_BELIXIRTBC17        = 28501;  -- Major Firepower" B
  SMARTBUFF_BELIXIR1            = 28497;  -- Mighty Agility" B
  SMARTBUFF_BELIXIR2            = 60347;  -- Mighty Thoughts" G
  SMARTBUFF_BELIXIR3            = 53751;  -- Elixir of Mighty Fortitude" G
  SMARTBUFF_BELIXIR4            = 53748;  -- Mighty Strength" B
  SMARTBUFF_BELIXIR5            = 53747;  -- Elixir of Spirit" B
  SMARTBUFF_BELIXIR6            = 53763;  -- Protection" G
  SMARTBUFF_BELIXIR7            = 60343;  -- Mighty Defense" G
  SMARTBUFF_BELIXIR8            = 60346;  -- Lightning Speed" B
  SMARTBUFF_BELIXIR9            = 60344;  -- Expertise" B
  SMARTBUFF_BELIXIR10           = 60341;  -- Deadly Strikes" B
  SMARTBUFF_BELIXIR11           = 80532;  -- Armor Piercing
  SMARTBUFF_BELIXIR12           = 60340;  -- Accuracy" B
  SMARTBUFF_BELIXIR13           = 53749;  -- Guru's Elixir" B
  SMARTBUFF_BELIXIR14           = 11334;  -- Elixir of Greater Agility" B
  SMARTBUFF_BELIXIR15           = 54452;  -- Adept's Elixir" B
  SMARTBUFF_BELIXIR16           = 33721;  -- Spellpower Elixir" B
  SMARTBUFF_BELIXIRCT1          = 79635;  -- Elixir of the Master" B
  SMARTBUFF_BELIXIRCT2          = 79632;  -- Elixir of Mighty Speed" B
  SMARTBUFF_BELIXIRCT3          = 79481;  -- Elixir of Impossible Accuracy" B
  SMARTBUFF_BELIXIRCT4          = 79631;  -- Prismatic Elixir" G
  SMARTBUFF_BELIXIRCT5          = 79480;  -- Elixir of Deep Earth" G
  SMARTBUFF_BELIXIRCT6          = 79477;  -- Elixir of the Cobra" B
  SMARTBUFF_BELIXIRCT7          = 79474;  -- Elixir of the Naga" B
  SMARTBUFF_BELIXIRCT8          = 79468;  -- Ghost Elixir" B
  SMARTBUFF_BELIXIRMOP1         = 105687; -- Elixir of Mirrors" G
  SMARTBUFF_BELIXIRMOP2         = 105685; -- Elixir of Peace" B
  SMARTBUFF_BELIXIRMOP3         = 105686; -- Elixir of Perfection" B
  SMARTBUFF_BELIXIRMOP4         = 105684; -- Elixir of the Rapids" B
  SMARTBUFF_BELIXIRMOP5         = 105683; -- Elixir of Weaponry" B
  SMARTBUFF_BELIXIRMOP6         = 105682; -- Mad Hozen Elixir" B
  SMARTBUFF_BELIXIRMOP7         = 105681; -- Mantid Elixir" G
  SMARTBUFF_BELIXIRMOP8         = 105688; -- Monk's Elixir" B
  SMARTBUFF_BEXP_POTION         = 289982; --Draught of Ten Lands

  --if (SMARTBUFF_GOTW) then
  --  SMARTBUFF_AddMsgD(SMARTBUFF_GOTW.." found");
  --end

  -- Buff map
  S.LinkStats                     = { SMARTBUFF_BOK, SMARTBUFF_MOTW, --[[ SMARTBUFF_LOTE,
                                    SMARTBUFF_LOTWT, ]]
                                    159988, -- Bark of the Wild
                                    203538, -- Greater Blessing of Kings
                                    90363,  -- Embrace of the Shale Spider
                                    160077  -- Strength of the Earth
                                  };

  S.LinkSta                     = { SMARTBUFF_POWERWORDFORTITUDE, SMARTBUFF_COMMANDINGSHOUT,
                                    --[[ SMARTBUFF_BLOODPACT, ]]
                                    50256,  -- Invigorating Roar
                                    90364,  -- Qiraji Fortitude
                                    160014, -- Sturdiness
                                    160003  -- Savage Vigor
                                  };

  S.LinkAp                      = { SMARTBUFF_HORNOFWINTER, SMARTBUFF_BATTLESHOUT
                                  };

  S.LinkMa                      = { SMARTBUFF_BOM, --[[ SMARTBUFF_DRUID_MKAURA,
                                    SMARTBUFF_GRACEOFAIR, SMARTBUFF_POTGRAVE, ]]
                                    93435,  -- Roar of Courage
                                    160039, -- Keen Senses
                                    128997, -- Spirit Beast Blessing
                                    160073  -- Plainswalking
                                  };

  S.LinkInt                     = { SMARTBUFF_BOW, SMARTBUFF_ARCANEINTELLECT, SMARTBUFF_DALARANBRILLIANCE };

  -- S.LinkSp                      = { SMARTBUFF_DARKINTENT, SMARTBUFF_AB,
  --                                  SMARTBUFF_DALARANB, SMARTBUFF_STILLWATER
  --                                 };

  SMARTBUFF_AddMsgD("Item IDs initialized");
end

function SMARTBUFF_InitSpellList()
  if (SMARTBUFF_PLAYERCLASS == nil) then return; end

  --if (SMARTBUFF_GOTW) then
  --  SMARTBUFF_AddMsgD(SMARTBUFF_GOTW.." found");
  --end

  -- Druid
  if (SMARTBUFF_PLAYERCLASS == "DRUID") then
    ---@type table[]
    SMARTBUFF_CLASSBUFFS = {
      {SMARTBUFF_DRUID_MOONKIN, -1, SMARTBUFF_CONST_SELF},
      {SMARTBUFF_DRUID_TREANT, -1, SMARTBUFF_CONST_SELF},
      {SMARTBUFF_DRUID_BEAR, -1, SMARTBUFF_CONST_SELF},
      {SMARTBUFF_DRUID_CAT, -1, SMARTBUFF_CONST_SELF},
      {SMARTBUFF_DRUID_TREE, 0.5, SMARTBUFF_CONST_SELF},
      {SMARTBUFF_MOTW, 60, SMARTBUFF_CONST_GROUP, {1,10,20,30,40,50,60,70,80}, "WPET;DKPET"},
      {SMARTBUFF_CENARIONWARD, 0.5, SMARTBUFF_CONST_GROUP, {1}, "WARRIOR;DRUID;SHAMAN;HUNTER;ROGUE;MAGE;PRIEST;PALADIN;WARLOCK;DEATHKNIGHT;MONK;DEMONHUNTER;EVOKER"},
      {SMARTBUFF_MOTW, 0.5, SMARTBUFF_CONST_GROUP, {1}, "HPET;WPET;DKPET"},
      {SMARTBUFF_BARKSKIN, 0.25, SMARTBUFF_CONST_FORCESELF},
      {SMARTBUFF_TIGERSFURY, 0.1, SMARTBUFF_CONST_SELF, nil, SMARTBUFF_DRUID_CAT},
      {SMARTBUFF_SAVAGEROAR, 0.15, SMARTBUFF_CONST_SELF, nil, SMARTBUFF_DRUID_CAT}
    };
  end

  -- Priest
  if (SMARTBUFF_PLAYERCLASS == "PRIEST") then
    ---@type table[]
    SMARTBUFF_CLASSBUFFS = {
      {SMARTBUFF_SHADOWFORM, -1, SMARTBUFF_CONST_SELF},
      {SMARTBUFF_VAMPIRICEMBRACE, 30, SMARTBUFF_CONST_SELF},
      {SMARTBUFF_POWERWORDFORTITUDE, 60, SMARTBUFF_CONST_GROUP, {14}, "HPET;WPET;DKPET", S.LinkSta},
      {SMARTBUFF_POWERWORDSHIELD, 0.5, SMARTBUFF_CONST_GROUP, {6}, "MAGE;WARLOCK;ROGUE;PALADIN;WARRIOR;DRUID;HUNTER;SHAMAN;DEATHKNIGHT;MONK;DEMONHUNTER;EVOKER;HPET;WPET;DKPET"},
      {SMARTBUFF_FEARWARD, 3, SMARTBUFF_CONST_GROUP, {54}, "HPET;WPET;DKPET"},
      {SMARTBUFF_LEVITATE, 2, SMARTBUFF_CONST_GROUP, {34}, "HPET;WPET;DKPET"},
      -- {SMARTBUFF_CHAKRA1, 0.5, SMARTBUFF_CONST_SELF, nil, nil, S.LinkPriestChakra},
      -- {SMARTBUFF_CHAKRA2, 0.5, SMARTBUFF_CONST_SELF, nil, nil, S.LinkPriestChakra},
      -- {SMARTBUFF_CHAKRA3, 0.5, SMARTBUFF_CONST_SELF, nil, nil, S.LinkPriestChakra},
      -- {SMARTBUFF_LIGHTWELL, 3, SMARTBUFF_CONST_SELF}
    };
  end
  -- Mage
  if (SMARTBUFF_PLAYERCLASS == "MAGE") then
    ---@type table[]
    SMARTBUFF_CLASSBUFFS = {
      {SMARTBUFF_ARCANEINTELLECT, 60, SMARTBUFF_CONST_GROUP, {1,14,28,42,56,70,80}, nil, S.LinkInt, S.LinkInt},
      {SMARTBUFF_DALARANBRILLIANCE, 60, SMARTBUFF_CONST_GROUP, {80,80,80,80,80,80,80}, nil, S.LinkInt, S.LinkInt},
      {SMARTBUFF_TEMPSHIELD, 0.067, SMARTBUFF_CONST_SELF},
      -- {SMARTBUFF_AMPMAGIC, 0.1, SMARTBUFF_CONST_SELF},
      {SMARTBUFF_SUMMONWATERELE, -1, SMARTBUFF_CONST_SELF, nil, S.CheckPet},
      {SMARTBUFF_FROSTARMOR, -1, SMARTBUFF_CONST_SELF, nil, nil, nil, S.ChainMageArmor},
      {SMARTBUFF_MAGEARMOR, -1, SMARTBUFF_CONST_SELF, nil, nil, nil, S.ChainMageArmor},
      {SMARTBUFF_MOLTENARMOR, -1, SMARTBUFF_CONST_SELF, nil, nil, nil, S.ChainMageArmor},
      {SMARTBUFF_SLOWFALL, 0.5, SMARTBUFF_CONST_GROUP, {32}, "HPET;WPET;DKPET"},
      {SMARTBUFF_MANASHIELD, 0.5, SMARTBUFF_CONST_SELF},
      -- {SMARTBUFF_ICEWARD, 0.5, SMARTBUFF_CONST_GROUP, {45}, "HPET;WPET;DKPET"},
      {SMARTBUFF_ICEBARRIER, 1, SMARTBUFF_CONST_SELF},
      {SMARTBUFF_COMBUSTION, -1, SMARTBUFF_CONST_SELF},
      {SMARTBUFF_ICYVEINS, 0.333, SMARTBUFF_CONST_SELF},
      {SMARTBUFF_ARCANEFAMILIAR, 60, SMARTBUFF_CONST_SELF},
      {SMARTBUFF_ARCANEPOWER, 0.25, SMARTBUFF_CONST_SELF},
      {SMARTBUFF_PRESENCEOFMIND, 0.165, SMARTBUFF_CONST_SELF},
      {SMARTBUFF_PRISBARRIER, 1, SMARTBUFF_CONST_SELF},
      {SMARTBUFF_IMPPRISBARRIER, 1, SMARTBUFF_CONST_SELF},
      {SMARTBUFF_BLAZBARRIER, 1, SMARTBUFF_CONST_SELF},
      {SMARTBUFF_REFRESHMENT, 0.03, SMARTBUFF_CONST_CONJURE, nil, SMARTBUFF_CONJUREDMANA, nil, S.FoodMage},
      {SMARTBUFF_CREATEMG, 0.03, SMARTBUFF_CONST_CONJURE, nil, SMARTBUFF_MANAGEM},
--    {SMARTBUFF_ARCANEINTELLECT, 60, SMARTBUFF_CONST_GROUP, {32}, "HPET;WPET;DKPET"}
    };
  end

  -- Warlock
  if (SMARTBUFF_PLAYERCLASS == "WARLOCK") then
    ---@type table[]
    SMARTBUFF_CLASSBUFFS = {
      {SMARTBUFF_DEMONARMOR, -1, SMARTBUFF_CONST_SELF},
      {SMARTBUFF_AMPLIFYCURSE, 1, SMARTBUFF_CONST_SELF},
      {SMARTBUFF_DARKINTENT, 60, SMARTBUFF_CONST_GROUP, nil, "WARRIOR;HUNTER;ROGUE"},
      {SMARTBUFF_SOULLINK, -1, SMARTBUFF_CONST_SELF, nil, S.CheckPetNeeded},
      {SMARTBUFF_UNENDINGBREATH, 10, SMARTBUFF_CONST_GROUP, {16}, "HPET;WPET;DKPET"},
      {SMARTBUFF_LIFETAP, 0.025, SMARTBUFF_CONST_SELF},
      {SMARTBUFF_GOSACRIFICE, 60, SMARTBUFF_CONST_SELF, nil, S.CheckPetNeeded},
      -- {SMARTBUFF_BLOODHORROR, 1, SMARTBUFF_CONST_SELF},
      {SMARTBUFF_SOULSTONE, 15, SMARTBUFF_CONST_GROUP, {18}, "WARRIOR;DRUID;SHAMAN;HUNTER;ROGUE;MAGE;PRIEST;PALADIN;WARLOCK;DEATHKNIGHT;EVOKER;MONK;DEMONHUNTER;HPET;WPET;DKPET"},
      {SMARTBUFF_CREATEHS, 0.03, SMARTBUFF_CONST_CONJURE, nil, SMARTBUFF_HEALTHSTONE},
      {SMARTBUFF_SUMMONIMP, -1, SMARTBUFF_CONST_SELF, nil, S.CheckPet},
      {SMARTBUFF_SUMMONFELHUNTER, -1, SMARTBUFF_CONST_SELF, nil, S.CheckPet},
      {SMARTBUFF_SUMMONVOIDWALKER, -1, SMARTBUFF_CONST_SELF, nil, S.CheckPet},
      {SMARTBUFF_SUMMONSUCCUBUS, -1, SMARTBUFF_CONST_SELF, nil, S.CheckPet},
      {SMARTBUFF_SUMMONINFERNAL, -1, SMARTBUFF_CONST_SELF, nil, S.CheckPet},
      {SMARTBUFF_SUMMONDOOMGUARD, -1, SMARTBUFF_CONST_SELF, nil, S.CheckPet},
      {SMARTBUFF_SUMMONFELGUARD, -1, SMARTBUFF_CONST_SELF, nil, S.CheckPet},
      {SMARTBUFF_SUMMONFELIMP, -1, SMARTBUFF_CONST_SELF, nil, S.CheckPet},
      {SMARTBUFF_SUMMONVOIDLORD, -1, SMARTBUFF_CONST_SELF, nil, S.CheckPet},
      {SMARTBUFF_SUMMONSHIVARRA, -1, SMARTBUFF_CONST_SELF, nil, S.CheckPet},
      {SMARTBUFF_SUMMONOBSERVER, -1, SMARTBUFF_CONST_SELF, nil, S.CheckPet},
      {SMARTBUFF_SUMMONWRATHGUARD, -1, SMARTBUFF_CONST_SELF, nil, S.CheckPet},
    };
  end

  -- Hunter
  if (SMARTBUFF_PLAYERCLASS == "HUNTER") then
    ---@type table[]
    SMARTBUFF_CLASSBUFFS = {
      {SMARTBUFF_RAPIDFIRE, 0.2, SMARTBUFF_CONST_SELF},
      --{SMARTBUFF_FOCUSFIRE, 0.25, SMARTBUFF_CONST_SELF},
      --{SMARTBUFF_TRAPLAUNCHER, -1, SMARTBUFF_CONST_SELF},
      {SMARTBUFF_VOLLEY, -1, SMARTBUFF_CONST_SELF},
      {SMARTBUFF_CAMOUFLAGE, 1, SMARTBUFF_CONST_SELF},
      {SMARTBUFF_ASPECTOFTHECHEETAH, -1, SMARTBUFF_CONST_SELF, nil, nil, S.LinkAspects},
      {SMARTBUFF_ASPECTOFTHEWILD, -1, SMARTBUFF_CONST_SELF, nil, nil, S.LinkAspects},
      {SMARTBUFF_CALL_PET_1, -1, SMARTBUFF_CONST_SELF, nil, S.CheckPet},
      {SMARTBUFF_CALL_PET_2, -1, SMARTBUFF_CONST_SELF, nil, S.CheckPet},
      {SMARTBUFF_CALL_PET_3, -1, SMARTBUFF_CONST_SELF, nil, S.CheckPet},
      {SMARTBUFF_CALL_PET_4, -1, SMARTBUFF_CONST_SELF, nil, S.CheckPet},
      {SMARTBUFF_CALL_PET_5, -1, SMARTBUFF_CONST_SELF, nil, S.CheckPet},
    };
  end

  -- Shaman
  if (SMARTBUFF_PLAYERCLASS == "SHAMAN") then
    ---@type table[]
    SMARTBUFF_CLASSBUFFS = {
      {SMARTBUFF_LIGHTNINGSHIELD, 60, SMARTBUFF_CONST_SELF, nil, nil, nil, S.ChainShamanShield},
      {SMARTBUFF_WATERSHIELD, 60, SMARTBUFF_CONST_SELF, nil, nil, nil, S.ChainShamanShield},
      {SMARTBUFF_WINDFURYW, 60, SMARTBUFF_CONST_WEAPON},
      {SMARTBUFF_FLAMETONGUEW, 60, SMARTBUFF_CONST_WEAPON},
      {SMARTBUFF_EVERLIVINGW, 60, SMARTBUFF_CONST_WEAPON},
      {SMARTBUFF_EARTHSHIELD, 10, SMARTBUFF_CONST_GROUP, {50,60,70,75,80}, "WARRIOR;DEATHKNIGHT;DRUID;SHAMAN;HUNTER;ROGUE;MAGE;PRIEST;PALADIN;WARLOCK;MONK;DEMONHUNTER;EVOKER;HPET;WPET;DKPET"},
      -- {SMARTBUFF_UNLEASHFLAME, 0.333, SMARTBUFF_CONST_SELF},
      {SMARTBUFF_ASCENDANCE_ELE, 0.25, SMARTBUFF_CONST_SELF},
      {SMARTBUFF_ASCENDANCE_ENH, 0.25, SMARTBUFF_CONST_SELF},
      {SMARTBUFF_ASCENDANCE_RES, 0.25, SMARTBUFF_CONST_SELF},
      {SMARTBUFF_EMASTERY, 0.5, SMARTBUFF_CONST_SELF},
      {SMARTBUFF_WATERWALKING, 10, SMARTBUFF_CONST_GROUP, {28}}
    };
  end

  -- Warrior
  if (SMARTBUFF_PLAYERCLASS == "WARRIOR") then
    ---@type table[]
    SMARTBUFF_CLASSBUFFS = {
      {SMARTBUFF_BATTLESHOUT, 60, SMARTBUFF_CONST_SELF, nil, nil, S.LinkAp, S.ChainWarriorShout},
      {SMARTBUFF_COMMANDINGSHOUT, 60, SMARTBUFF_CONST_SELF, nil, nil, S.LinkSta, S.ChainWarriorShout},
      {SMARTBUFF_BERSERKERRAGE, 0.165, SMARTBUFF_CONST_SELF},
      {SMARTBUFF_SHIELDBLOCK, 0.1666, SMARTBUFF_CONST_SELF},
      {SMARTBUFF_BATSTANCE, -1, SMARTBUFF_CONST_STANCE, nil, nil, nil, S.ChainWarriorStance},
      {SMARTBUFF_DEFSTANCE, -1, SMARTBUFF_CONST_STANCE, nil, nil, nil, S.ChainWarriorStance},
      {SMARTBUFF_GLADSTANCE, -1, SMARTBUFF_CONST_STANCE, nil, nil, nil, S.ChainWarriorStance}
    };
  end

  -- Rogue
  if (SMARTBUFF_PLAYERCLASS == "ROGUE") then
    ---@type table[]
    SMARTBUFF_CLASSBUFFS = {
      {SMARTBUFF_STEALTH, -1, SMARTBUFF_CONST_SELF},
      {SMARTBUFF_BLADEFLURRY, -1, SMARTBUFF_CONST_SELF},
      {SMARTBUFF_SAD, 0.2, SMARTBUFF_CONST_SELF},
      {SMARTBUFF_TRICKS, 0.5, SMARTBUFF_CONST_GROUP, {75}, "WARRIOR;DEATHKNIGHT;DRUID;SHAMAN;HUNTER;ROGUE;MAGE;PRIEST;PALADIN;WARLOCK;MONK;DEMONHUNTER;EVOKER;HPET;WPET;DKPET"},
      {SMARTBUFF_HUNGERFORBLOOD, 0.5, SMARTBUFF_CONST_SELF},
      {SMARTBUFF_RECUPERATE, 0.5, SMARTBUFF_CONST_SELF},
      {SMARTBUFF_EVASION, 0.2, SMARTBUFF_CONST_SELF},
      {SMARTBUFF_INSTANTPOISON, 60, SMARTBUFF_CONST_SELF, nil, S.CheckFishingPole, nil, S.ChainRoguePoisonsLethal},
      {SMARTBUFF_DEADLYPOISON, 60, SMARTBUFF_CONST_SELF, nil, S.CheckFishingPole, nil, S.ChainRoguePoisonsLethal},
      {SMARTBUFF_WOUNDPOISON, 60, SMARTBUFF_CONST_SELF, nil, S.CheckFishingPole, nil, S.ChainRoguePoisonsLethal},
      -- {SMARTBUFF_AGONIZINGPOISON, 60, SMARTBUFF_CONST_SELF, nil, S.CheckFishingPole, nil, S.ChainRoguePoisonsLethal},
      {SMARTBUFF_LEECHINGPOISON, 60, SMARTBUFF_CONST_SELF, nil, S.CheckFishingPole, nil, S.ChainRoguePoisonsNonLethal},
      {SMARTBUFF_NUMBINGPOISON, 60, SMARTBUFF_CONST_SELF, nil, S.CheckFishingPole, nil, S.ChainRoguePoisonsNonLethal},
      {SMARTBUFF_CRIPPLINGPOISON, 60, SMARTBUFF_CONST_SELF, nil, S.CheckFishingPole, nil, S.ChainRoguePoisonsNonLethal},
      {SMARTBUFF_AMPLIFYPOISON, 60, SMARTBUFF_CONST_SELF, nil, S.CheckFishingPole, nil, S.ChainRoguePoisonsNonLethal},
      {SMARTBUFF_ATROPHICPOISON, 60, SMARTBUFF_CONST_SELF, nil, S.CheckFishingPole, nil, S.ChainRoguePoisonsNonLethal}
    };
  end

  -- Paladin
  if (SMARTBUFF_PLAYERCLASS == "PALADIN") then
    ---@type table[]
    SMARTBUFF_CLASSBUFFS = {
      {SMARTBUFF_RIGHTEOUSFURY, 30, SMARTBUFF_CONST_SELF},
      {SMARTBUFF_HOLYSHIELD, 0.166, SMARTBUFF_CONST_SELF},
      {SMARTBUFF_AVENGINGWARTH, 0.333, SMARTBUFF_CONST_SELF},
      {SMARTBUFF_BOK, 60, SMARTBUFF_CONST_GROUP, {20}, nil, S.LinkStats},
      {SMARTBUFF_BOM, 60, SMARTBUFF_CONST_GROUP, {20}, nil, S.LinkMa},
      {SMARTBUFF_BOW, 60, SMARTBUFF_CONST_GROUP, {20}, nil, S.LinkInt},
      {SMARTBUFF_HOF, 0.1, SMARTBUFF_CONST_GROUP, {52}, "WARRIOR;DEATHKNIGHT;DRUID;SHAMAN;HUNTER;ROGUE;MAGE;PRIEST;PALADIN;WARLOCK;MONK;DEMONHUNTER;EVOKER;HPET;WPET;DKPET"},
      {SMARTBUFF_HOSAL, 0.1, SMARTBUFF_CONST_GROUP, {66}, "WARRIOR;DEATHKNIGHT;DRUID;SHAMAN;HUNTER;ROGUE;MAGE;PRIEST;PALADIN;WARLOCK;MONK;DEMONHUNTER;EVOKER;HPET;WPET;DKPET"},
      {SMARTBUFF_BEACONOFLIGHT, 5, SMARTBUFF_CONST_GROUP, {39}, "WARRIOR;DRUID;SHAMAN;HUNTER;ROGUE;MAGE;PRIEST;PALADIN;WARLOCK;DEATHKNIGHT;MONK;DEMONHUNTER;EVOKER;HPET;WPET;DKPET"},
      {SMARTBUFF_BEACONOFAITH, 5, SMARTBUFF_CONST_GROUP, {39}, "WARRIOR;DRUID;SHAMAN;HUNTER;ROGUE;MAGE;PRIEST;PALADIN;WARLOCK;DEATHKNIGHT;MONK;DEMONHUNTER;EVOKER;HPET;WPET;DKPET"},
      {SMARTBUFF_CRUSADERAURA, -1, SMARTBUFF_CONST_SELF},
      {SMARTBUFF_DEVOTIONAURA, -1, SMARTBUFF_CONST_SELF, nil, nil, nil, S.ChainPaladinAura},
      {SMARTBUFF_RETRIBUTIONAURA, -1, SMARTBUFF_CONST_SELF, nil, nil, nil, S.ChainPaladinAura},
      --{SMARTBUFF_SOTRUTH, -1, SMARTBUFF_CONST_STANCE, nil, nil, nil, S.ChainPaladinSeal},
      {SMARTBUFF_SORIGHTEOUSNESS, -1, SMARTBUFF_CONST_STANCE, nil, nil, nil, S.ChainPaladinSeal},
      {SMARTBUFF_SOJUSTICE, -1, SMARTBUFF_CONST_STANCE, nil, nil, nil, S.ChainPaladinSeal},
      --{SMARTBUFF_SOINSIGHT, -1, SMARTBUFF_CONST_STANCE, nil, nil, nil, S.ChainPaladinSeal},
      {SMARTBUFF_SOCOMMAND, -1, SMARTBUFF_CONST_STANCE, nil, nil, nil, S.ChainPaladinSeal}
    };
  end

  -- Deathknight
  if (SMARTBUFF_PLAYERCLASS == "DEATHKNIGHT") then
    ---@type table[]
    SMARTBUFF_CLASSBUFFS = {
      {SMARTBUFF_DANCINGRW, 0.2, SMARTBUFF_CONST_SELF},
      --{SMARTBUFF_BLOODPRESENCE, -1, SMARTBUFF_CONST_STANCE, nil, nil, nil, S.ChainDKPresence},
      --{SMARTBUFF_FROSTPRESENCE, -1, SMARTBUFF_CONST_STANCE, nil, nil, nil, S.ChainDKPresence},
      --{SMARTBUFF_UNHOLYPRESENCE, -1, SMARTBUFF_CONST_STANCE, nil, nil, nil, S.ChainDKPresence},
      {SMARTBUFF_HORNOFWINTER, 60, SMARTBUFF_CONST_SELF, nil, nil, S.LinkAp},
      -- {SMARTBUFF_BONESHIELD, 5, SMARTBUFF_CONST_SELF},
      {SMARTBUFF_RAISEDEAD, 1, SMARTBUFF_CONST_SELF, nil, S.CheckPet},
      {SMARTBUFF_PATHOFFROST, -1, SMARTBUFF_CONST_SELF}
    };
  end

  -- Monk
  if (SMARTBUFF_PLAYERCLASS == "MONK") then
    ---@type table[]
    SMARTBUFF_CLASSBUFFS = {
      --{SMARTBUFF_LOTWT, 60, SMARTBUFF_CONST_GROUP, {81}},
      --{SMARTBUFF_LOTE, 60, SMARTBUFF_CONST_GROUP, {22}, nil, S.LinkStats},
      {SMARTBUFF_SOTFIERCETIGER, -1, SMARTBUFF_CONST_STANCE, nil, nil, nil, S.ChainMonkStance},
      {SMARTBUFF_SOTSTURDYOX, -1, SMARTBUFF_CONST_STANCE, nil, nil, nil, S.ChainMonkStance},
      --{SMARTBUFF_SOTWISESERPENT, -1, SMARTBUFF_CONST_STANCE, nil, nil, nil, S.ChainMonkStance},
      --{SMARTBUFF_SOTPIRITEDCRANE, -1, SMARTBUFF_CONST_STANCE, nil, nil, nil, S.ChainMonkStance},
      {SMARTBUFF_BLACKOX, 15, SMARTBUFF_CONST_SELF, nil, nil, nil, S.ChainMonkStatue},
      { SMARTBUFF_JADESERPENT, 15, SMARTBUFF_CONST_SELF, nil, nil, nil, S.ChainMonkStatue}
    };
  end

  -- Demon Hunter
  if (SMARTBUFF_PLAYERCLASS == "DEMONHUNTER") then
    ---@type table[]
    SMARTBUFF_CLASSBUFFS = {
    };
  end

  -- Evoker
  if (SMARTBUFF_PLAYERCLASS == "EVOKER") then
    ---@type table[]
    SMARTBUFF_CLASSBUFFS = {
      {SMARTBUFF_BRONZEBLESSING, 60, SMARTBUFF_CONST_SELF},
    };
  end

  -- Stones and oils
  ---@type table[]
  SMARTBUFF_WEAPON = {
    {SMARTBUFF_SSROUGH, 60, SMARTBUFF_CONST_INV},
    {SMARTBUFF_SSCOARSE, 60, SMARTBUFF_CONST_INV},
    {SMARTBUFF_SSHEAVY, 60, SMARTBUFF_CONST_INV},
    {SMARTBUFF_SSSOLID, 60, SMARTBUFF_CONST_INV},
    {SMARTBUFF_SSDENSE, 60, SMARTBUFF_CONST_INV},
    {SMARTBUFF_SSELEMENTAL, 60, SMARTBUFF_CONST_INV},
    {SMARTBUFF_SSFEL, 60, SMARTBUFF_CONST_INV},
    {SMARTBUFF_SSADAMANTITE, 60, SMARTBUFF_CONST_INV},
    {SMARTBUFF_WSROUGH, 60, SMARTBUFF_CONST_INV},
    {SMARTBUFF_WSCOARSE, 60, SMARTBUFF_CONST_INV},
    {SMARTBUFF_WSHEAVY, 60, SMARTBUFF_CONST_INV},
    {SMARTBUFF_WSSOLID, 60, SMARTBUFF_CONST_INV},
    {SMARTBUFF_WSDENSE, 60, SMARTBUFF_CONST_INV},
    {SMARTBUFF_WSFEL, 60, SMARTBUFF_CONST_INV},
    {SMARTBUFF_WSADAMANTITE, 60, SMARTBUFF_CONST_INV},
    {SMARTBUFF_SHADOWOIL, 60, SMARTBUFF_CONST_INV},
    {SMARTBUFF_FROSTOIL, 60, SMARTBUFF_CONST_INV},
    {SMARTBUFF_MANAOIL4, 60, SMARTBUFF_CONST_INV},
    {SMARTBUFF_MANAOIL3, 60, SMARTBUFF_CONST_INV},
    {SMARTBUFF_MANAOIL2, 60, SMARTBUFF_CONST_INV},
    {SMARTBUFF_MANAOIL1, 60, SMARTBUFF_CONST_INV},
    {SMARTBUFF_WIZARDOIL5, 60, SMARTBUFF_CONST_INV},
    {SMARTBUFF_WIZARDOIL4, 60, SMARTBUFF_CONST_INV},
    {SMARTBUFF_WIZARDOIL3, 60, SMARTBUFF_CONST_INV},
    {SMARTBUFF_WIZARDOIL2, 60, SMARTBUFF_CONST_INV},
    {SMARTBUFF_WIZARDOIL1, 60, SMARTBUFF_CONST_INV},
    -- Shadowlands
    {SMARTBUFF_SHADOWCOREOIL, 60, SMARTBUFF_CONST_INV},
    {SMARTBUFF_EMBALMERSOIL, 60, SMARTBUFF_CONST_INV},
    -- Dragonflight
    {SMARTBUFF_SafeRockets_q1, 60, SMARTBUFF_CONST_INV},
    {SMARTBUFF_SafeRockets_q2, 60, SMARTBUFF_CONST_INV},
    {SMARTBUFF_SafeRockets_q3, 60, SMARTBUFF_CONST_INV},
    {SMARTBUFF_BuzzingRune_q1, 120, SMARTBUFF_CONST_INV},
    {SMARTBUFF_BuzzingRune_q2, 120, SMARTBUFF_CONST_INV},
    {SMARTBUFF_BuzzingRune_q3, 120, SMARTBUFF_CONST_INV},
    {SMARTBUFF_ChirpingRune_q1, 120, SMARTBUFF_CONST_INV},
    {SMARTBUFF_ChirpingRune_q2, 120, SMARTBUFF_CONST_INV},
    {SMARTBUFF_ChirpingRune_q3, 120, SMARTBUFF_CONST_INV},
    {SMARTBUFF_HowlingRune_q1, 120, SMARTBUFF_CONST_INV},
    {SMARTBUFF_HowlingRune_q2, 120, SMARTBUFF_CONST_INV},
    {SMARTBUFF_HowlingRune_q3, 120, SMARTBUFF_CONST_INV},
    {SMARTBUFF_PrimalWeighstone_q1, 120, SMARTBUFF_CONST_INV},
    {SMARTBUFF_PrimalWeighstone_q2, 120, SMARTBUFF_CONST_INV},
    {SMARTBUFF_PrimalWeighstone_q3, 120, SMARTBUFF_CONST_INV},
    {SMARTBUFF_PrimalWhetstone_q1, 120, SMARTBUFF_CONST_INV},
    {SMARTBUFF_PrimalWhetstone_q2, 120, SMARTBUFF_CONST_INV},
    {SMARTBUFF_PrimalWhetstone_q3, 120, SMARTBUFF_CONST_INV},
  };

  -- Tracking
  ---@type table[]
  SMARTBUFF_TRACKING = {
    {SMARTBUFF_FINDMINERALS, -1, SMARTBUFF_CONST_TRACK},
    {SMARTBUFF_FINDHERBS, -1, SMARTBUFF_CONST_TRACK},
    {SMARTBUFF_FINDTREASURE, -1, SMARTBUFF_CONST_TRACK},
    {SMARTBUFF_TRACKHUMANOIDS, -1, SMARTBUFF_CONST_TRACK},
    {SMARTBUFF_TRACKBEASTS, -1, SMARTBUFF_CONST_TRACK},
    {SMARTBUFF_TRACKUNDEAD, -1, SMARTBUFF_CONST_TRACK},
    {SMARTBUFF_TRACKHIDDEN, -1, SMARTBUFF_CONST_TRACK},
    {SMARTBUFF_TRACKELEMENTALS, -1, SMARTBUFF_CONST_TRACK},
    {SMARTBUFF_TRACKDEMONS, -1, SMARTBUFF_CONST_TRACK},
    {SMARTBUFF_TRACKGIANTS, -1, SMARTBUFF_CONST_TRACK},
    {SMARTBUFF_TRACKDRAGONKIN, -1, SMARTBUFF_CONST_TRACK}
  };

  -- Racial
  ---@type table[]
  SMARTBUFF_RACIAL = {
    {SMARTBUFF_STONEFORM, 0.133, SMARTBUFF_CONST_SELF},  -- Dwarv
    --{SMARTBUFF_PRECEPTION, 0.333, SMARTBUFF_CONST_SELF}, -- Human
    {SMARTBUFF_BLOODFURY, 0.416, SMARTBUFF_CONST_SELF},  -- Orc
    {SMARTBUFF_BERSERKING, 0.166, SMARTBUFF_CONST_SELF}, -- Troll
    {SMARTBUFF_WOTFORSAKEN, 0.083, SMARTBUFF_CONST_SELF}, -- Undead
    {SMARTBUFF_WarStomp, 0.033, SMARTBUFF_CONST_SELF} -- Tauer
  };

  -- FOOD
    SMARTBUFF_FOOD = {
    {SMARTBUFF_ABYSSALFRIEDRISSOLE, 60, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_BAKEDPORTTATO, 60, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_BANANABEEFPUDDING, 60, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_BARRACUDAMRGLGAGH, 60, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_BATBITES,  15, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_BEARTARTARE, 60, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_BILTONG, 60, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_BIGMECH, 60, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_BLACKENEDBASILISK, 30, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_BLACKENEDSPOREFISH, 30, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_BROILEDBLOODFIN, 30, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_BUTTERSCOTCHRIBS, 60, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_BUZZARDBITES, 30, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_CHARREDBEARKABOBS, 15, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_CINNAMONBONEFISH, 60, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_CLAMBAR, 30, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_CRUNCHYSERPENT, 30, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_CRUNCHYSPIDER, 15, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_DEEPFRIEDMOSSGILL, 60, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_DROGBARSTYLESALMON, 60, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_EXTRALEMONYFILET, 20, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_FARONAARFIZZ, 60, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_FELTAILDELIGHT, 30, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_FIGHTERCHOW, 60, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_FRAGRANTKAKAVIA, 60, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_FRIEDBONEFISH, 60, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_GOLDENFISHSTICKS, 30, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_GRILLEDCATFISH, 60, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_GRILLEDMUDFISH, 30, SMARTBUFF_CONST_FOOD},
    --{SMARTBUFF_HEARTSBANEHEXWURST, 5, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_HONEYHAUNCHES, 60, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_IRIDESCENTRAVIOLI, 60, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_JUICYBEARBURGER, 15, SMARTBUFF_CONST_FOOD},
    --{SMARTBUFF_KIBLERSBITS, 20, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_KULTIRAMISU, 60, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_LEGIONCHILI, 60, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_LOALOAF, 60, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_LYNXSTEAK, 15, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_MEATYAPPLEDUMPLINGS, 60, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_MOKNATHALSHORTRIBS, 30, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_MONDAZI, 60, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_PICKLEDMEATSMOOTHIE, 60, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_PICKLEDSTORMRAY, 60, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_POACHEDBLUEFISH, 30, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_RAVAGERDOG, 30, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_RAVENBERRYTARTS, 60, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_ROASTEDCLEFTHOOF, 30, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_ROASTEDMOONGRAZE,  15, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_SAGEFISHDELIGHT, 15, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_SAILORSPIE, 60, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_SALTPEPPERSHANK, 60, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_SEASONEDLOINS, 60, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_SERAPHTENDERS, 60, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_SKULLFISHSOUP, 30, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_SPICEDSNAPPER, 60, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_SPICYCRAWDAD, 30, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_SPICYHOTTALBUK, 30, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_SPINEFISHSOUFFLE, 60, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_STEAKALAMODE, 60, SMARTBUFF_CONST_FOOD},
    --{SMARTBUFF_STORMCHOPS,  30, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_SWAMPFISHNCHIPS, 60, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_SWEETSILVERGILL, 60, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_TALBUKSTEAK, 30, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_TENEBROUSCROWNROAST, 60, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_WARPBURGER, 30, SMARTBUFF_CONST_FOOD},
    -- Dragonflight
    {SMARTBUFF_TimelyDemise, 60, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_FiletOfFangs, 60, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_SeamothSurprise, 60, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_SaltBakedFishcake, 60, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_FeistyFishSticks, 60, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_SeafoodPlatter, 60, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_SeafoodMedley, 60, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_RevengeServedCold, 60, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_Tongueslicer, 60, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_GreatCeruleanSea, 60, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_FatedFortuneCookie, 60, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_KaluakBanquet, 60, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_HoardOfDelicacies, 60, SMARTBUFF_CONST_FOOD}
  };

  for n, id in pairs(S.FoodItems) do
    if (id) then
      table.insert(SMARTBUFF_FOOD, 1, {id, 60, SMARTBUFF_CONST_FOOD});
    end
  end

  -- Scrolls
  ---@type table[]
  SMARTBUFF_SCROLL = {
    {SMARTBUFF_MiscItem17, 60, SMARTBUFF_CONST_SCROLL, nil, SMARTBUFF_BMiscItem17, S.LinkFlaskLeg},
--    {SMARTBUFF_MiscItem16, 60, SMARTBUFF_CONST_SCROLL, nil, SMARTBUFF_BMiscItem16},
    {SMARTBUFF_MiscItem15, 60, SMARTBUFF_CONST_SCROLL, nil, SMARTBUFF_BMiscItem14, S.LinkAugment},
    {SMARTBUFF_MiscItem14, 60, SMARTBUFF_CONST_SCROLL, nil, SMARTBUFF_BMiscItem14, S.LinkAugment},
    {SMARTBUFF_MiscItem13, 10, SMARTBUFF_CONST_SCROLL, nil, SMARTBUFF_BMiscItem13},
    {SMARTBUFF_MiscItem12, 60, SMARTBUFF_CONST_SCROLL, nil, SMARTBUFF_BMiscItem12},
    {SMARTBUFF_MiscItem11, 60, SMARTBUFF_CONST_SCROLL, nil, SMARTBUFF_BMiscItem11, S.LinkFlaskWoD},
    {SMARTBUFF_MiscItem10, -1, SMARTBUFF_CONST_SCROLL, nil, SMARTBUFF_BMiscItem10, S.LinkSafariHat},
    {SMARTBUFF_MiscItem9, -1, SMARTBUFF_CONST_SCROLL, nil, SMARTBUFF_BMiscItem9, S.LinkSafariHat},
    {SMARTBUFF_MiscItem1, -1, SMARTBUFF_CONST_SCROLL, nil, SMARTBUFF_BMiscItem1},
    {SMARTBUFF_MiscItem2, -1, SMARTBUFF_CONST_SCROLL, nil, SMARTBUFF_BMiscItem2},
    {SMARTBUFF_MiscItem3, 10, SMARTBUFF_CONST_SCROLL, nil, SMARTBUFF_BMiscItem3},
    {SMARTBUFF_MiscItem4, 60, SMARTBUFF_CONST_SCROLL, nil, SMARTBUFF_BMiscItem4, S.LinkFlaskMoP},
    {SMARTBUFF_MiscItem5, 10, SMARTBUFF_CONST_SCROLL, nil, SMARTBUFF_BMiscItem5},
    {SMARTBUFF_MiscItem6, 60, SMARTBUFF_CONST_SCROLL, nil, SMARTBUFF_BMiscItem6},
    {SMARTBUFF_MiscItem7, 60, SMARTBUFF_CONST_SCROLL, nil, SMARTBUFF_BMiscItem7},
    --{SMARTBUFF_MiscItem8, 5, SMARTBUFF_CONST_SCROLL, nil, SMARTBUFF_BMiscItem8},
    {SMARTBUFF_AugmentRune, 60, SMARTBUFF_CONST_SCROLL, nil, SMARTBUFF_BAugmentRune, S.LinkAugment},
    {SMARTBUFF_VieledAugment, 60, SMARTBUFF_CONST_SCROLL, nil, SMARTBUFF_BVieledAugment, S.LinkAugment},

    {SMARTBUFF_SOAGILITY9, 30, SMARTBUFF_CONST_SCROLL, nil, SMARTBUFF_SBAGILITY},
    {SMARTBUFF_SOAGILITY8, 30, SMARTBUFF_CONST_SCROLL, nil, SMARTBUFF_SBAGILITY},
    {SMARTBUFF_SOAGILITY7, 30, SMARTBUFF_CONST_SCROLL, nil, SMARTBUFF_SBAGILITY},
    {SMARTBUFF_SOAGILITY6, 30, SMARTBUFF_CONST_SCROLL, nil, SMARTBUFF_SBAGILITY},
    {SMARTBUFF_SOAGILITY5, 30, SMARTBUFF_CONST_SCROLL, nil, SMARTBUFF_SBAGILITY},
    {SMARTBUFF_SOAGILITY4, 30, SMARTBUFF_CONST_SCROLL, nil, SMARTBUFF_SBAGILITY},
    {SMARTBUFF_SOAGILITY3, 30, SMARTBUFF_CONST_SCROLL, nil, SMARTBUFF_SBAGILITY},
    {SMARTBUFF_SOAGILITY2, 30, SMARTBUFF_CONST_SCROLL, nil, SMARTBUFF_SBAGILITY},
    {SMARTBUFF_SOAGILITY1, 30, SMARTBUFF_CONST_SCROLL, nil, SMARTBUFF_SBAGILITY},
    {SMARTBUFF_SOINTELLECT9, 30, SMARTBUFF_CONST_SCROLL, nil, SMARTBUFF_SBINTELLECT},
    {SMARTBUFF_SOINTELLECT8, 30, SMARTBUFF_CONST_SCROLL, nil, SMARTBUFF_SBINTELLECT},
    {SMARTBUFF_SOINTELLECT7, 30, SMARTBUFF_CONST_SCROLL, nil, SMARTBUFF_SBINTELLECT},
    {SMARTBUFF_SOINTELLECT6, 30, SMARTBUFF_CONST_SCROLL, nil, SMARTBUFF_SBINTELLECT},
    {SMARTBUFF_SOINTELLECT5, 30, SMARTBUFF_CONST_SCROLL, nil, SMARTBUFF_SBINTELLECT},
    {SMARTBUFF_SOINTELLECT4, 30, SMARTBUFF_CONST_SCROLL, nil, SMARTBUFF_SBINTELLECT},
    {SMARTBUFF_SOINTELLECT3, 30, SMARTBUFF_CONST_SCROLL, nil, SMARTBUFF_SBINTELLECT},
    {SMARTBUFF_SOINTELLECT2, 30, SMARTBUFF_CONST_SCROLL, nil, SMARTBUFF_SBINTELLECT},
    {SMARTBUFF_SOINTELLECT1, 30, SMARTBUFF_CONST_SCROLL, nil, SMARTBUFF_SBINTELLECT},
    {SMARTBUFF_SOSTAMINA9, 30, SMARTBUFF_CONST_SCROLL, nil, SMARTBUFF_SBSTAMINA},
    {SMARTBUFF_SOSTAMINA8, 30, SMARTBUFF_CONST_SCROLL, nil, SMARTBUFF_SBSTAMINA},
    {SMARTBUFF_SOSTAMINA7, 30, SMARTBUFF_CONST_SCROLL, nil, SMARTBUFF_SBSTAMINA},
    {SMARTBUFF_SOSTAMINA6, 30, SMARTBUFF_CONST_SCROLL, nil, SMARTBUFF_SBSTAMINA},
    {SMARTBUFF_SOSTAMINA5, 30, SMARTBUFF_CONST_SCROLL, nil, SMARTBUFF_SBSTAMINA},
    {SMARTBUFF_SOSTAMINA4, 30, SMARTBUFF_CONST_SCROLL, nil, SMARTBUFF_SBSTAMINA},
    {SMARTBUFF_SOSTAMINA3, 30, SMARTBUFF_CONST_SCROLL, nil, SMARTBUFF_SBSTAMINA},
    {SMARTBUFF_SOSTAMINA2, 30, SMARTBUFF_CONST_SCROLL, nil, SMARTBUFF_SBSTAMINA},
    {SMARTBUFF_SOSTAMINA1, 30, SMARTBUFF_CONST_SCROLL, nil, SMARTBUFF_SBSTAMINA},
    {SMARTBUFF_SOSPIRIT9, 30, SMARTBUFF_CONST_SCROLL, nil, SMARTBUFF_SBSPIRIT},
    {SMARTBUFF_SOSPIRIT8, 30, SMARTBUFF_CONST_SCROLL, nil, SMARTBUFF_SBSPIRIT},
    {SMARTBUFF_SOSPIRIT7, 30, SMARTBUFF_CONST_SCROLL, nil, SMARTBUFF_SBSPIRIT},
    {SMARTBUFF_SOSPIRIT6, 30, SMARTBUFF_CONST_SCROLL, nil, SMARTBUFF_SBSPIRIT},
    {SMARTBUFF_SOSPIRIT5, 30, SMARTBUFF_CONST_SCROLL, nil, SMARTBUFF_SBSPIRIT},
    {SMARTBUFF_SOSPIRIT4, 30, SMARTBUFF_CONST_SCROLL, nil, SMARTBUFF_SBSPIRIT},
    {SMARTBUFF_SOSPIRIT3, 30, SMARTBUFF_CONST_SCROLL, nil, SMARTBUFF_SBSPIRIT},
    {SMARTBUFF_SOSPIRIT2, 30, SMARTBUFF_CONST_SCROLL, nil, SMARTBUFF_SBSPIRIT},
    {SMARTBUFF_SOSPIRIT1, 30, SMARTBUFF_CONST_SCROLL, nil, SMARTBUFF_SBSPIRIT},
    {SMARTBUFF_SOSTRENGHT9, 30, SMARTBUFF_CONST_SCROLL, nil, SMARTBUFF_SBSTRENGHT},
    {SMARTBUFF_SOSTRENGHT8, 30, SMARTBUFF_CONST_SCROLL, nil, SMARTBUFF_SBSTRENGHT},
    {SMARTBUFF_SOSTRENGHT7, 30, SMARTBUFF_CONST_SCROLL, nil, SMARTBUFF_SBSTRENGHT},
    {SMARTBUFF_SOSTRENGHT6, 30, SMARTBUFF_CONST_SCROLL, nil, SMARTBUFF_SBSTRENGHT},
    {SMARTBUFF_SOSTRENGHT5, 30, SMARTBUFF_CONST_SCROLL, nil, SMARTBUFF_SBSTRENGHT},
    {SMARTBUFF_SOSTRENGHT4, 30, SMARTBUFF_CONST_SCROLL, nil, SMARTBUFF_SBSTRENGHT},
    {SMARTBUFF_SOSTRENGHT3, 30, SMARTBUFF_CONST_SCROLL, nil, SMARTBUFF_SBSTRENGHT},
    {SMARTBUFF_SOSTRENGHT2, 30, SMARTBUFF_CONST_SCROLL, nil, SMARTBUFF_SBSTRENGHT},
    {SMARTBUFF_SOSTRENGHT1, 30, SMARTBUFF_CONST_SCROLL, nil, SMARTBUFF_SBSTRENGHT},
    {SMARTBUFF_SOPROTECTION9, 30, SMARTBUFF_CONST_SCROLL, nil, SMARTBUFF_SBPROTECTION},

    -- Dragonflight
    {SMARTBUFF_DraconicRune, 60, SMARTBUFF_CONST_SCROLL, nil, SMARTBUFF_BDraconicRune, S.LinkAugment},
    {SMARTBUFF_VantusRune_VotI_q1, 60, SMARTBUFF_CONST_SCROLL, nil, SMARTBUFF_BVantusRune_VotI_q1},
    {SMARTBUFF_VantusRune_VotI_q2, 60, SMARTBUFF_CONST_SCROLL, nil, SMARTBUFF_BVantusRune_VotI_q2},
    {SMARTBUFF_VantusRune_VotI_q3, 60, SMARTBUFF_CONST_SCROLL, nil, SMARTBUFF_BVantusRune_VotI_q3},
  };

  --      ItemID, SpellID, Duration [min]
  AddItemScroll(174906, 270058,  60); -- Lightning-Forged Augment Rune
  AddItemScroll(153023, 224001,  60); -- Lightforged Augment Rune
  AddItemScroll(160053, 270058,  60); -- Battle-Scarred Augment Rune
  AddItemScroll(164375, 281303,  10); -- Bad Mojo Banana
  AddItemScroll(129165, 193345,  10); -- Barnacle-Encrusted Gem
  AddItemScroll(116115, 170869,  60); -- Blazing Wings
  AddItemScroll(133997, 203533,   0); -- Black Ice
  AddItemScroll(122298, 181642,  60); -- Bodyguard Miniaturization Device
  AddItemScroll(163713, 279934,  30); -- Brazier Cap
  AddItemScroll(128310, 189363,  10); -- Burning Blade
  AddItemScroll(116440, 171554,  20); -- Burning Defender's Medallion
  AddItemScroll(128807, 192225,  60); -- Coin of Many Faces
  AddItemScroll(138878, 217668,   5); -- Copy of Daglop's Contract
  AddItemScroll(143662, 232613,  60); -- Crate of Bobbers: Pepe
  AddItemScroll(142529, 231319,  60); -- Crate of Bobbers: Cat Head
  AddItemScroll(142530, 231338,  60); -- Crate of Bobbers: Tugboat
  AddItemScroll(142528, 231291,  60); -- Crate of Bobbers: Can of Worms
  AddItemScroll(142532, 231349,  60); -- Crate of Bobbers: Murloc Head
  AddItemScroll(147308, 240800,  60); -- Crate of Bobbers: Enchanted Bobber
  AddItemScroll(142531, 231341,  60); -- Crate of Bobbers: Squeaky Duck
  AddItemScroll(147312, 240801,  60); -- Crate of Bobbers: Demon Noggin
  AddItemScroll(147307, 240803,  60); -- Crate of Bobbers: Carved Wooden Helm
  AddItemScroll(147309, 240806,  60); -- Crate of Bobbers: Face of the Forest
  AddItemScroll(147310, 240802,  60); -- Crate of Bobbers: Floating Totem
  AddItemScroll(147311, 240804,  60); -- Crate of Bobbers: Replica Gondola
  AddItemScroll(122117, 179872,  15); -- Cursed Feather of Ikzan
  AddItemScroll( 54653,  75532,  30); -- Darkspear Pride
  AddItemScroll(108743, 160688,  10); -- Deceptia's Smoldering Boots
  AddItemScroll(129149, 193333,  30); -- Death's Door Charm
  AddItemScroll(159753, 279366,   5); -- Desert Flute
  AddItemScroll(164373, 281298,  10); -- Enchanted Soup Stone
  AddItemScroll(140780, 224992,   5); -- Fal'dorei Egg
  AddItemScroll(122304, 138927,  10); -- Fandral's Seed Pouch
  AddItemScroll(102463, 148429,  10); -- Fire-Watcher's Oath
  AddItemScroll(128471, 190655,  30); -- Frostwolf Grunt's Battlegear
  AddItemScroll(128462, 190653,  30); -- Karabor Councilor's Attire
  AddItemScroll(161342, 275089,  30); -- Gem of Acquiescence
  AddItemScroll(127659, 188228,  60); -- Ghostly Iron Buccaneer's Hat
  AddItemScroll( 54651,  75531,  30); -- Gnomeregan Pride
  AddItemScroll(118716, 175832,   5); -- Goren Garb
  AddItemScroll(138900, 217708,  10); -- Gravil Goldbraid's Famous Sausage Hat
  AddItemScroll(159749, 277572,   5); -- Haw'li's Hot & Spicy Chili
  AddItemScroll(163742, 279997,  60); -- Heartsbane Grimoire
  AddItemScroll(140325, 223446,  10); -- Home Made Party Mask
  AddItemScroll(136855, 210642,0.25); -- Hunter's Call
  AddItemScroll( 43499,  58501,  10); -- Iron Boot Flask
  AddItemScroll(118244, 173956,  60); -- Iron Buccaneer's Hat
  AddItemScroll(170380, 304369, 120); -- Jar of Sunwarmed Sand
  AddItemScroll(127668, 187174,   5); -- Jewel of Hellfire
  AddItemScroll( 26571, 127261,  10); -- Kang's Bindstone
  AddItemScroll( 68806,  96312,  30); -- Kalytha's Haunted Locket
  AddItemScroll(163750, 280121,  10); -- Kovork Kostume
  AddItemScroll(164347, 281302,  10); -- Magic Monkey Banana
  AddItemScroll(118938, 176180,  10); -- Manastorm's Duplicator
  AddItemScroll(163775, 280133,  10); -- Molok Morion
  AddItemScroll(101571, 144787,   0); -- Moonfang Shroud
  AddItemScroll(105898, 145255,  10); -- Moonfang's Paw
  AddItemScroll( 52201,  73320,  10); -- Muradin's Favor
  AddItemScroll(138873, 217597,   5); -- Mystical Frosh Hat
  AddItemScroll(163795, 280308,  10); -- Oomgut Ritual Drum
  AddItemScroll(  1973,  16739,   5); -- Orb of Deception
  AddItemScroll( 35275, 160331,  30); -- Orb of the Sin'dorei
  AddItemScroll(158149, 264091,  30); -- Overtuned Corgi Goggles
  AddItemScroll(130158, 195949,   5); -- Path of Elothir
  AddItemScroll(127864, 188172,  60); -- Personal Spotlight
  AddItemScroll(127394, 186842,   5); -- Podling Camouflage
  AddItemScroll(108739, 162402,   5); -- Pretty Draenor Pearl
  AddItemScroll(129093, 129999,  10); -- Ravenbear Disguise
  AddItemScroll(153179, 254485,   5); -- Blue Conservatory Scroll
  AddItemScroll(153180, 254486,   5); -- Yellow Conservatory Scroll
  AddItemScroll(153181, 254487,   5); -- Red Conservatory Scroll
  AddItemScroll(104294, 148529,  15); -- Rime of the Time-Lost Mariner
  AddItemScroll(119215, 176898,  10); -- Robo-Gnomebobulator
  AddItemScroll(119134, 176569,  30); -- Sargerei Disguise
  AddItemScroll(129055,  62089,  60); -- Shoe Shine Kit
  AddItemScroll(163436, 279977,  30); -- Spectral Visage
  AddItemScroll(156871, 261981,  60); -- Spitzy
  AddItemScroll( 66888,   6405,   3); -- Stave of Fur and Claw
  AddItemScroll(111476, 169291,   5); -- Stolen Breath
  AddItemScroll(140160, 222630,  10); -- Stormforged Vrykul Horn
  AddItemScroll(163738, 279983,  30); -- Syndicate Mask
  AddItemScroll(130147, 195509,   5); -- Thistleleaf Branch
  AddItemScroll(113375, 166592,   5); -- Vindicator's Armor Polish Kit
  AddItemScroll(163565, 279407,   5); -- Vulpera Scrapper's Armor
  AddItemScroll(163924, 280632,  30); -- Whiskerwax Candle
  AddItemScroll( 97919, 141917,   3); -- Whole-Body Shrinka'
  AddItemScroll(167698, 293671,  60); -- Secret Fish Goggles
  AddItemScroll(169109, 299445,  60); -- Beeholder's Goggles
  -- Dragonflight
  AddItemScroll(199902, 388275,  30); -- Wayfarer's Compass
  AddItemScroll(202019, 396172,  30); -- Golden Dragon Goblet
  AddItemScroll(198857, 385941,  30); -- Lucky Duck


  -- Potions
  ---@type table[]
  SMARTBUFF_POTION = {
    {SMARTBUFF_ELIXIRTBC1, 60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BELIXIRTBC1},
    {SMARTBUFF_ELIXIRTBC2, 60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BELIXIRTBC2},
    {SMARTBUFF_ELIXIRTBC3, 60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BELIXIRTBC3},
    {SMARTBUFF_ELIXIRTBC4, 60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BELIXIRTBC4},
    {SMARTBUFF_ELIXIRTBC5, 60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BELIXIRTBC5},
    {SMARTBUFF_ELIXIRTBC6, 60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BELIXIRTBC6},
    {SMARTBUFF_ELIXIRTBC7, 60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BELIXIRTBC7},
    {SMARTBUFF_ELIXIRTBC8, 60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BELIXIRTBC8},
    {SMARTBUFF_ELIXIRTBC9, 60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BELIXIRTBC9},
    {SMARTBUFF_ELIXIRTBC10, 60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BELIXIRTBC10},
    {SMARTBUFF_ELIXIRTBC11, 60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BELIXIRTBC11},
    {SMARTBUFF_ELIXIRTBC12, 60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BELIXIRTBC12},
    {SMARTBUFF_ELIXIRTBC13, 60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BELIXIRTBC13},
    {SMARTBUFF_ELIXIRTBC14, 60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BELIXIRTBC14},
    {SMARTBUFF_ELIXIRTBC15, 60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BELIXIRTBC15},
    {SMARTBUFF_ELIXIRTBC16, 60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BELIXIRTBC16},
    {SMARTBUFF_ELIXIRTBC17, 60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BELIXIRTBC17},
    {SMARTBUFF_FLASKTBC1, 60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BFLASKTBC1}, --, S.LinkFlaskTBC},
    {SMARTBUFF_FLASKTBC2, 60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BFLASKTBC2},
    {SMARTBUFF_FLASKTBC3, 60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BFLASKTBC3},
    {SMARTBUFF_FLASKTBC4, 60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BFLASKTBC4},
    {SMARTBUFF_FLASKTBC5, 60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BFLASKTBC5},
    {SMARTBUFF_FLASKLEG1, 60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BFLASKLEG1, S.LinkFlaskLeg},
    {SMARTBUFF_FLASKLEG2, 60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BFLASKLEG2},
    {SMARTBUFF_FLASKLEG3, 60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BFLASKLEG3},
    {SMARTBUFF_FLASKLEG4, 60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BFLASKLEG4},
    {SMARTBUFF_FLASKWOD1, 60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BFLASKWOD1, S.LinkFlaskWoD},
    {SMARTBUFF_FLASKWOD2, 60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BFLASKWOD2},
    {SMARTBUFF_FLASKWOD3, 60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BFLASKWOD3},
    {SMARTBUFF_FLASKWOD4, 60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BFLASKWOD4},
    {SMARTBUFF_GRFLASKWOD1, 60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BGRFLASKWOD1},
    {SMARTBUFF_GRFLASKWOD2, 60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BGRFLASKWOD2},
    {SMARTBUFF_GRFLASKWOD3, 60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BGRFLASKWOD3},
    {SMARTBUFF_GRFLASKWOD4, 60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BGRFLASKWOD4},
    {SMARTBUFF_FLASKMOP1, 60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BFLASKMOP1, S.LinkFlaskMoP},
    {SMARTBUFF_FLASKMOP2, 60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BFLASKMOP2},
    {SMARTBUFF_FLASKMOP3, 60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BFLASKMOP3},
    {SMARTBUFF_FLASKMOP4, 60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BFLASKMOP4},
    {SMARTBUFF_FLASKMOP5, 60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BFLASKMOP5},
    {SMARTBUFF_FLASKMOP6, 60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BFLASKMOP6},
    {SMARTBUFF_ELIXIRMOP1, 60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BELIXIRMOP1},
    {SMARTBUFF_ELIXIRMOP2, 60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BELIXIRMOP2},
    {SMARTBUFF_ELIXIRMOP3, 60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BELIXIRMOP3},
    {SMARTBUFF_ELIXIRMOP4, 60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BELIXIRMOP4},
    {SMARTBUFF_ELIXIRMOP5, 60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BELIXIRMOP5},
    {SMARTBUFF_ELIXIRMOP6, 60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BELIXIRMOP6},
    {SMARTBUFF_ELIXIRMOP7, 60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BELIXIRMOP7},
    {SMARTBUFF_ELIXIRMOP8, 60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BELIXIRMOP8},
    {SMARTBUFF_EXP_POTION, 60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BEXP_POTION},
    {SMARTBUFF_FLASKCT1, 60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BFLASKCT1},
    {SMARTBUFF_FLASKCT2, 60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BFLASKCT2},
    {SMARTBUFF_FLASKCT3, 60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BFLASKCT3},
    {SMARTBUFF_FLASKCT4, 60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BFLASKCT4},
    {SMARTBUFF_FLASKCT5, 60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BFLASKCT5},
    {SMARTBUFF_FLASKCT7, 60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BFLASKCT7, S.LinkFlaskCT7},
    {SMARTBUFF_ELIXIRCT1, 60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BELIXIRCT1},
    {SMARTBUFF_ELIXIRCT2, 60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BELIXIRCT2},
    {SMARTBUFF_ELIXIRCT3, 60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BELIXIRCT3},
    {SMARTBUFF_ELIXIRCT4, 60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BELIXIRCT4},
    {SMARTBUFF_ELIXIRCT5, 60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BELIXIRCT5},
    {SMARTBUFF_ELIXIRCT6, 60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BELIXIRCT6},
    {SMARTBUFF_ELIXIRCT7, 60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BELIXIRCT7},
    {SMARTBUFF_ELIXIRCT8, 60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BELIXIRCT8},
    {SMARTBUFF_FLASK1, 60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BFLASK1},
    {SMARTBUFF_FLASK2, 60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BFLASK2},
    {SMARTBUFF_FLASK3, 60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BFLASK3},
    {SMARTBUFF_FLASK4, 60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BFLASK4},
    {SMARTBUFF_ELIXIR1,  60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BELIXIR1},
    {SMARTBUFF_ELIXIR2,  60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BELIXIR2},
    {SMARTBUFF_ELIXIR3,  60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BELIXIR3},
    {SMARTBUFF_ELIXIR4,  60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BELIXIR4},
    {SMARTBUFF_ELIXIR5,  60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BELIXIR5},
    {SMARTBUFF_ELIXIR6,  60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BELIXIR6},
    {SMARTBUFF_ELIXIR7,  60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BELIXIR7},
    {SMARTBUFF_ELIXIR8,  60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BELIXIR8},
    {SMARTBUFF_ELIXIR9,  60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BELIXIR9},
    {SMARTBUFF_ELIXIR10, 60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BELIXIR10},
    {SMARTBUFF_ELIXIR11, 60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BELIXIR11},
    {SMARTBUFF_ELIXIR12, 60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BELIXIR12},
    {SMARTBUFF_ELIXIR13, 60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BELIXIR13},
    {SMARTBUFF_ELIXIR14, 60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BELIXIR14},
    -- {SMARTBUFF_ELIXIR15, 60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BELIXIR15},
    {SMARTBUFF_ELIXIR16, 60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BELIXIR16},
    {SMARTBUFF_FLASKBFA1, 60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BFLASKBFA1, S.LinkFlaskBfA},
    {SMARTBUFF_FLASKBFA2, 60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BFLASKBFA2},
    {SMARTBUFF_FLASKBFA3, 60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BFLASKBFA3},
    {SMARTBUFF_FLASKBFA4, 60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BFLASKBFA4},
    {SMARTBUFF_GRFLASKBFA1, 60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BGRFLASKBFA1},
    {SMARTBUFF_GRFLASKBFA2, 60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BGRFLASKBFA2},
    {SMARTBUFF_GRFLASKBFA3, 60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BGRFLASKBFA3},
    {SMARTBUFF_GRFLASKBFA4, 60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BGRFLASKBFA4},
    {SMARTBUFF_FLASKSL1, 60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BFLASKSL1, S.LinkFlaskSL},
    {SMARTBUFF_FLASKSL2, 60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BFLASKSL2},
    -- Dragonflight
    -- consuming an identical phial will add another 30 min
    -- alchemist's flasks last twice as long
    {SMARTBUFF_FlaskDF1_q1, 30, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BFlaskDF1, S.LinkFlaskDF},
    {SMARTBUFF_FlaskDF1_q2, 30, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BFlaskDF1, S.LinkFlaskDF},
    {SMARTBUFF_FlaskDF1_q3, 30, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BFlaskDF1, S.LinkFlaskDF},

    {SMARTBUFF_FlaskDF2_q1, 30, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BFlaskDF2, S.LinkFlaskDF},
    {SMARTBUFF_FlaskDF2_q2, 30, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BFlaskDF2, S.LinkFlaskDF},
    {SMARTBUFF_FlaskDF2_q3, 30, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BFlaskDF2, S.LinkFlaskDF},

    {SMARTBUFF_FlaskDF3_q1, 30, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BFlaskDF3, S.LinkFlaskDF},
    {SMARTBUFF_FlaskDF3_q2, 30, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BFlaskDF3, S.LinkFlaskDF},
    {SMARTBUFF_FlaskDF3_q3, 30, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BFlaskDF3, S.LinkFlaskDF},

    {SMARTBUFF_FlaskDF4_q1, 30, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BFlaskDF4, S.LinkFlaskDF},
    {SMARTBUFF_FlaskDF4_q2, 30, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BFlaskDF4, S.LinkFlaskDF},
    {SMARTBUFF_FlaskDF4_q3, 30, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BFlaskDF4, S.LinkFlaskDF},


    {SMARTBUFF_FlaskDF5_q1, 30, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BFlaskDF5, S.LinkFlaskDF},
    {SMARTBUFF_FlaskDF5_q2, 30, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BFlaskDF5, S.LinkFlaskDF},
    {SMARTBUFF_FlaskDF5_q3, 30, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BFlaskDF5, S.LinkFlaskDF},

    {SMARTBUFF_FlaskDF6_q1, 30, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BFlaskDF6, S.LinkFlaskDF},
    {SMARTBUFF_FlaskDF6_q2, 30, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BFlaskDF6, S.LinkFlaskDF},
    {SMARTBUFF_FlaskDF6_q3, 30, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BFlaskDF6, S.LinkFlaskDF},

    {SMARTBUFF_FlaskDF7_q1, 30, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BFlaskDF7, S.LinkFlaskDF},
    {SMARTBUFF_FlaskDF7_q2, 30, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BFlaskDF7, S.LinkFlaskDF},
    {SMARTBUFF_FlaskDF7_q3, 30, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BFlaskDF7, S.LinkFlaskDF},

    {SMARTBUFF_FlaskDF8_q1, 30, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BFlaskDF8, S.LinkFlaskDF},
    {SMARTBUFF_FlaskDF8_q2, 30, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BFlaskDF8, S.LinkFlaskDF},
    {SMARTBUFF_FlaskDF8_q3, 30, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BFlaskDF8, S.LinkFlaskDF},

    {SMARTBUFF_FlaskDF9_q1, 30, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BFlaskDF9, S.LinkFlaskDF},
    {SMARTBUFF_FlaskDF9_q2, 30, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BFlaskDF9, S.LinkFlaskDF},
    {SMARTBUFF_FlaskDF9_q3, 30, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BFlaskDF9, S.LinkFlaskDF},

    {SMARTBUFF_FlaskDF10_q1, 30, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BFlaskDF10, S.LinkFlaskDF},
    {SMARTBUFF_FlaskDF10_q2, 30, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BFlaskDF10, S.LinkFlaskDF},
    {SMARTBUFF_FlaskDF10_q3, 30, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BFlaskDF10, S.LinkFlaskDF},

    {SMARTBUFF_FlaskDF11_q1, 30, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BFlaskDF11, S.LinkFlaskDF},
    {SMARTBUFF_FlaskDF11_q2, 30, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BFlaskDF11, S.LinkFlaskDF},
    {SMARTBUFF_FlaskDF11_q3, 30, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BFlaskDF11, S.LinkFlaskDF},

    {SMARTBUFF_FlaskDF12_q1, 30, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BFlaskDF12, S.LinkFlaskDF},
    {SMARTBUFF_FlaskDF12_q2, 30, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BFlaskDF12, S.LinkFlaskDF},
    {SMARTBUFF_FlaskDF12_q3, 30, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BFlaskDF12, S.LinkFlaskDF},

    -- the Elemental Chaos flask has 4 random effects changing every 60 seconds
    {SMARTBUFF_FlaskDF13_q1, 60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BFlaskDF13_1, S.LinkFlaskDF},
    {SMARTBUFF_FlaskDF13_q2, 60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BFlaskDF13_1, S.LinkFlaskDF},
    {SMARTBUFF_FlaskDF13_q3, 60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BFlaskDF13_1, S.LinkFlaskDF},

    {SMARTBUFF_FlaskDF14_q1, 30, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BFlaskDF14, S.LinkFlaskDF},
    {SMARTBUFF_FlaskDF14_q2, 30, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BFlaskDF14, S.LinkFlaskDF},
    {SMARTBUFF_FlaskDF14_q3, 30, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BFlaskDF14, S.LinkFlaskDF},

  }
  SMARTBUFF_AddMsgD("Spell list initialized");

--  LoadToys();

end
