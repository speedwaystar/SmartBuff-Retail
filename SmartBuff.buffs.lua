local _;
local S = SMARTBUFF_GLOBALS;

SMARTBUFF_PLAYERCLASS = nil;
SMARTBUFF_BUFFLIST = nil;

-- Buff types
SMARTBUFF_CONST_ALL       = "ALL";
SMARTBUFF_CONST_GROUP     = "GROUP";
SMARTBUFF_CONST_GROUPALL  = "GROUPALL";
SMARTBUFF_CONST_SELF      = "SELF";
SMARTBUFF_CONST_FORCESELF = "FORCESELF";
SMARTBUFF_CONST_TRACK     = "TRACK";
SMARTBUFF_CONST_WEAPON    = "WEAPON";
SMARTBUFF_CONST_INV       = "INVENTORY";
SMARTBUFF_CONST_FOOD      = "FOOD";
SMARTBUFF_CONST_SCROLL    = "SCROLL";
SMARTBUFF_CONST_POTION    = "POTION";
SMARTBUFF_CONST_STANCE    = "STANCE";
SMARTBUFF_CONST_ITEM      = "ITEM";
SMARTBUFF_CONST_ITEMGROUP = "ITEMGROUP";
SMARTBUFF_CONST_TOY       = "TOY";

S.CheckPet = "CHECKPET";
S.CheckPetNeeded = "CHECKPETNEEDED";
S.CheckFishingPole = "CHECKFISHINGPOLE";
S.NIL = "x";
S.Toybox = { };

local function GetItems(items)
  local t = { };
  for _, id in pairs(items) do
    local _,name = GetItemInfo(id);
    if (name) then
      --print("Item found: "..id..", "..name);
      tinsert(t, name);
    end
  end
  return t;
end

local function InsertItem(t, type, itemId, spellId, duration, link)
  local _,item = GetItemInfo(itemId); -- item link
  local spell = GetSpellInfo(spellId);
  if (item and spell) then
    --print("Item found: "..item..", "..spell);
    tinsert(t, {item, duration, type, nil, spell, link});
  end
end

local function AddItem(itemId, spellId, duration, link)
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

  SMARTBUFF_AddMsgD("Toys initialized");
end

function SMARTBUFF_InitItemList()
  -- Stones and oils
  _,SMARTBUFF_HEALTHSTONE         = GetItemInfo(5512);  --"Healthstone"
  _,SMARTBUFF_MANAGEM             = GetItemInfo(36799); --"Mana Gem"
  _,SMARTBUFF_BRILLIANTMANAGEM    = GetItemInfo(81901); --"Brilliant Mana Gem"
  _,SMARTBUFF_SSROUGH             = GetItemInfo(2862);  --"Rough Sharpening Stone"
  _,SMARTBUFF_SSCOARSE            = GetItemInfo(2863);  --"Coarse Sharpening Stone"
  _,SMARTBUFF_SSHEAVY             = GetItemInfo(2871);  --"Heavy Sharpening Stone"
  _,SMARTBUFF_SSSOLID             = GetItemInfo(7964);  --"Solid Sharpening Stone"
  _,SMARTBUFF_SSDENSE             = GetItemInfo(12404); --"Dense Sharpening Stone"
  _,SMARTBUFF_SSELEMENTAL         = GetItemInfo(18262); --"Elemental Sharpening Stone"
  _,SMARTBUFF_SSFEL               = GetItemInfo(23528); --"Fel Sharpening Stone"
  _,SMARTBUFF_SSADAMANTITE        = GetItemInfo(23529); --"Adamantite Sharpening Stone"
  _,SMARTBUFF_WSROUGH             = GetItemInfo(3239);  --"Rough Weightstone"
  _,SMARTBUFF_WSCOARSE            = GetItemInfo(3240);  --"Coarse Weightstone"
  _,SMARTBUFF_WSHEAVY             = GetItemInfo(3241);  --"Heavy Weightstone"
  _,SMARTBUFF_WSSOLID             = GetItemInfo(7965);  --"Solid Weightstone"
  _,SMARTBUFF_WSDENSE             = GetItemInfo(12643); --"Dense Weightstone"
  _,SMARTBUFF_WSFEL               = GetItemInfo(28420); --"Fel Weightstone"
  _,SMARTBUFF_WSADAMANTITE        = GetItemInfo(28421); --"Adamantite Weightstone"
  _,SMARTBUFF_SHADOWOIL           = GetItemInfo(3824);  --"Shadow Oil"
  _,SMARTBUFF_FROSTOIL            = GetItemInfo(3829);  --"Frost Oil"
  _,SMARTBUFF_MANAOIL1            = GetItemInfo(20745); --"Minor Mana Oil"
  _,SMARTBUFF_MANAOIL2            = GetItemInfo(20747); --"Lesser Mana Oil"
  _,SMARTBUFF_MANAOIL3            = GetItemInfo(20748); --"Brilliant Mana Oil"
  _,SMARTBUFF_MANAOIL4            = GetItemInfo(22521); --"Superior Mana Oil"
  _,SMARTBUFF_WIZARDOIL1          = GetItemInfo(20744); --"Minor Wizard Oil"
  _,SMARTBUFF_WIZARDOIL2          = GetItemInfo(20746); --"Lesser Wizard Oil"
  _,SMARTBUFF_WIZARDOIL3          = GetItemInfo(20750); --"Wizard Oil"
  _,SMARTBUFF_WIZARDOIL4          = GetItemInfo(20749); --"Brilliant Wizard Oil"
  _,SMARTBUFF_WIZARDOIL5          = GetItemInfo(22522); --"Superior Wizard Oil"
  _,SMARTBUFF_SHADOWCOREOIL       = GetItemInfo(171285); --"Shadowcore Oil"
  _,SMARTBUFF_EMBALMERSOIL        = GetItemInfo(171286); --"Embalmer's Oil"
  -- Dragonflight
  _,SMARTBUFF_SafeRockets_q1      = GetItemInfo(198160); -- Completely Safe Rockets (Quality 1)
  _,SMARTBUFF_SafeRockets_q2      = GetItemInfo(198161); -- Completely Safe Rockets (Quality 2)
  _,SMARTBUFF_SafeRockets_q3      = GetItemInfo(198162); -- Completely Safe Rockets (Quality 3)
  _,SMARTBUFF_BuzzingRune_q1      = GetItemInfo(194821); -- Buzzing Rune (Quality 1)
  _,SMARTBUFF_BuzzingRune_q2      = GetItemInfo(194822); -- Buzzing Rune (Quality 2)
  _,SMARTBUFF_BuzzingRune_q3      = GetItemInfo(194823); -- Buzzing Rune (Quality 3)
  _,SMARTBUFF_ChirpingRune_q1     = GetItemInfo(194824); -- Buzzing Rune (Quality 1)
  _,SMARTBUFF_ChirpingRune_q2     = GetItemInfo(194825); -- Buzzing Rune (Quality 2)
  _,SMARTBUFF_ChirpingRune_q3     = GetItemInfo(194826); -- Buzzing Rune (Quality 3)
  _,SMARTBUFF_HowlingRune_q1      = GetItemInfo(194821); -- Buzzing Rune (Quality 1)
  _,SMARTBUFF_HowlingRune_q2      = GetItemInfo(194822); -- Buzzing Rune (Quality 2)
  _,SMARTBUFF_HowlingRune_q3      = GetItemInfo(194820); -- Buzzing Rune (Quality 3)
  _,SMARTBUFF_PrimalWeighstone_q1 = GetItemInfo(191943); -- Primal Weighstone (Quality 1)
  _,SMARTBUFF_PrimalWeighstone_q2 = GetItemInfo(191944); -- Primal Weighstone (Quality 2)
  _,SMARTBUFF_PrimalWeighstone_q3 = GetItemInfo(191945); -- Primal Weighstone (Quality 3)
  _,SMARTBUFF_PrimalWhetstone_q1  = GetItemInfo(191933); -- Primal Whestone (Quality 1)
  _,SMARTBUFF_PrimalWhetstone_q2  = GetItemInfo(191939); -- Primal Whestone (Quality 2)
  _,SMARTBUFF_PrimalWhetstone_q3  = GetItemInfo(191940); -- Primal Whestone (Quality 3)

  -- Food
--  SMARTBUFF_KIBLERSBITS         = GetItemInfo(33874); --"Kibler's Bits"
--  SMARTBUFF_STORMCHOPS          = GetItemInfo(33866); --"Stormchops"
  _,SMARTBUFF_JUICYBEARBURGER     = GetItemInfo(35565); --"Juicy Bear Burger"
  _,SMARTBUFF_CRUNCHYSPIDER       = GetItemInfo(22645); --"Crunchy Spider Surprise"
  _,SMARTBUFF_LYNXSTEAK           = GetItemInfo(27635); --"Lynx Steak"
  _,SMARTBUFF_CHARREDBEARKABOBS   = GetItemInfo(35563); --"Charred Bear Kabobs"
  _,SMARTBUFF_BATBITES            = GetItemInfo(27636); --"Bat Bites"
  _,SMARTBUFF_ROASTEDMOONGRAZE    = GetItemInfo(24105); --"Roasted Moongraze Tenderloin"
  _,SMARTBUFF_MOKNATHALSHORTRIBS  = GetItemInfo(31672); --"Mok'Nathal Shortribs"
  _,SMARTBUFF_CRUNCHYSERPENT      = GetItemInfo(31673); --"Crunchy Serpent"
  _,SMARTBUFF_ROASTEDCLEFTHOOF    = GetItemInfo(27658); --"Roasted Clefthoof"
  _,SMARTBUFF_FISHERMANSFEAST     = GetItemInfo(33052); --"Fisherman's Feast"
  _,SMARTBUFF_WARPBURGER          = GetItemInfo(27659); --"Warp Burger"
  _,SMARTBUFF_RAVAGERDOG          = GetItemInfo(27655); --"Ravager Dog"
  _,SMARTBUFF_SKULLFISHSOUP       = GetItemInfo(33825); --"Skullfish Soup"
  _,SMARTBUFF_BUZZARDBITES        = GetItemInfo(27651); --"Buzzard Bites"
  _,SMARTBUFF_TALBUKSTEAK         = GetItemInfo(27660); --"Talbuk Steak"
  _,SMARTBUFF_GOLDENFISHSTICKS    = GetItemInfo(27666); --"Golden Fish Sticks"
  _,SMARTBUFF_SPICYHOTTALBUK      = GetItemInfo(33872); --"Spicy Hot Talbuk"
  _,SMARTBUFF_FELTAILDELIGHT      = GetItemInfo(27662); --"Feltail Delight"
  _,SMARTBUFF_BLACKENEDSPOREFISH  = GetItemInfo(27663); --"Blackened Sporefish"
  _,SMARTBUFF_HOTAPPLECIDER       = GetItemInfo(34411); --"Hot Apple Cider"
  _,SMARTBUFF_BROILEDBLOODFIN     = GetItemInfo(33867); --"Broiled Bloodfin"
  _,SMARTBUFF_SPICYCRAWDAD        = GetItemInfo(27667); --"Spicy Crawdad"
  _,SMARTBUFF_POACHEDBLUEFISH     = GetItemInfo(27665); --"Poached Bluefish"
  _,SMARTBUFF_BLACKENEDBASILISK   = GetItemInfo(27657); --"Blackened Basilisk"
  _,SMARTBUFF_GRILLEDMUDFISH      = GetItemInfo(27664); --"Grilled Mudfish"
  _,SMARTBUFF_CLAMBAR             = GetItemInfo(30155); --"Clam Bar"
  _,SMARTBUFF_SAGEFISHDELIGHT     = GetItemInfo(21217); --"Sagefish Delight"
  _,SMARTBUFF_SALTPEPPERSHANK     = GetItemInfo(133557); --"Salt & Pepper Shank"
  _,SMARTBUFF_PICKLEDSTORMRAY     = GetItemInfo(133562); --"Pickled Stormray"
  _,SMARTBUFF_DROGBARSTYLESALMON  = GetItemInfo(133569); --"Drogbar-Style Salmon"
  _,SMARTBUFF_BARRACUDAMRGLGAGH   = GetItemInfo(133567); --"Barracuda Mrglgagh"
  _,SMARTBUFF_FIGHTERCHOW         = GetItemInfo(133577); --"Fighter Chow"
  _,SMARTBUFF_FARONAARFIZZ        = GetItemInfo(133563); --"Faronaar Fizz"
  _,SMARTBUFF_BEARTARTARE         = GetItemInfo(133576); --"Bear Tartare"
  _,SMARTBUFF_LEGIONCHILI         = GetItemInfo(118428); --"Legion Chili"
  _,SMARTBUFF_DEEPFRIEDMOSSGILL   = GetItemInfo(133561); --"Deep-Fried Mossgill"
  _,SMARTBUFF_MONDAZI             = GetItemInfo(154885); --"Mon'Dazi"
  _,SMARTBUFF_KULTIRAMISU         = GetItemInfo(154881); --"Kul Tiramisu"
  _,SMARTBUFF_GRILLEDCATFISH      = GetItemInfo(154889); --"Grilled Catfish"
  _,SMARTBUFF_LOALOAF             = GetItemInfo(154887); --"Loa Loaf"
  _,SMARTBUFF_HONEYHAUNCHES       = GetItemInfo(154882); --"Honey-Glazed Haunches"
  _,SMARTBUFF_RAVENBERRYTARTS     = GetItemInfo(154883); --"Ravenberry Tarts"
  _,SMARTBUFF_SWAMPFISHNCHIPS     = GetItemInfo(154884); --"Swamp Fish 'n Chips"
  _,SMARTBUFF_SEASONEDLOINS       = GetItemInfo(154891); --"Seasoned Loins"
  _,SMARTBUFF_SAILORSPIE          = GetItemInfo(154888); --"Sailor's Pie"
  _,SMARTBUFF_SPICEDSNAPPER       = GetItemInfo(154886); --"Spiced Snapper"
  --_,SMARTBUFF_HEARTSBANEHEXWURST = GetItemInfo(163781); --"Heartsbane Hexwurst"
  _,SMARTBUFF_ABYSSALFRIEDRISSOLE = GetItemInfo(168311); --"Abyssal-Fried Rissole"
  _,SMARTBUFF_BAKEDPORTTATO       = GetItemInfo(168313); --"Baked Port Tato"
  _,SMARTBUFF_BILTONG             = GetItemInfo(168314); --"Bil'Tong"
  _,SMARTBUFF_BIGMECH             = GetItemInfo(168310); --"Mech-Dowel's 'Big Mech'"
  _,SMARTBUFF_FRAGRANTKAKAVIA     = GetItemInfo(168312); --"Fragrant Kakavia"
  _,SMARTBUFF_BANANABEEFPUDDING   = GetItemInfo(172069); --"Banana Beef Pudding"
  _,SMARTBUFF_BUTTERSCOTCHRIBS    = GetItemInfo(172040); --"Butterscotch Marinated Ribs"
  _,SMARTBUFF_CINNAMONBONEFISH    = GetItemInfo(172044); --"Cinnamon Bonefish Stew"
  _,SMARTBUFF_EXTRALEMONYFILET    = GetItemInfo(184682); --"Extra Lemony Herb Filet"
  _,SMARTBUFF_FRIEDBONEFISH       = GetItemInfo(172063); --"Friedn Bonefish"
  _,SMARTBUFF_IRIDESCENTRAVIOLI   = GetItemInfo(172049); --"Iridescent Ravioli with Apple Sauce"
  _,SMARTBUFF_MEATYAPPLEDUMPLINGS = GetItemInfo(172048); --"Meaty Apple Dumplings"
  _,SMARTBUFF_PICKLEDMEATSMOOTHIE = GetItemInfo(172068); --"Pickled Meat Smoothie"
  _,SMARTBUFF_SERAPHTENDERS       = GetItemInfo(172061); --"Seraph Tenders"
  _,SMARTBUFF_SPINEFISHSOUFFLE    = GetItemInfo(172041); --"Spinefish Souffle and Fries"
  _,SMARTBUFF_STEAKALAMODE        = GetItemInfo(172051); --"Steak ala Mode"
  _,SMARTBUFF_SWEETSILVERGILL     = GetItemInfo(172050); --"Sweet Silvergill Sausages"
  _,SMARTBUFF_TENEBROUSCROWNROAST = GetItemInfo(172045); --"Tenebrous Crown Roast Aspic"
  -- Dragonflight
  _,SMARTBUFF_TimelyDemise        = GetItemInfo(197778); -- Timely Demise (70 Haste)
  _,SMARTBUFF_FiletOfFangs        = GetItemInfo(197779); -- Filet of Fangs (70 Crit)
  _,SMARTBUFF_SeamothSurprise     = GetItemInfo(197780); -- Seamoth Surprise (70 Vers)
  _,SMARTBUFF_SaltBakedFishcake   = GetItemInfo(197781); -- Salt-Baked Fishcake (70 Mastery)
  _,SMARTBUFF_FeistyFishSticks    = GetItemInfo(197782); -- Feisty Fish Sticks (45 Haste/Crit)
  _,SMARTBUFF_SeafoodPlatter      = GetItemInfo(197783); -- Aromatic Seafood Platter (45 Haste/Vers)
  _,SMARTBUFF_SeafoodMedley       = GetItemInfo(197784); -- Sizzling Seafood Medley (45 Haste/Mastery)
  _,SMARTBUFF_RevengeServedCold   = GetItemInfo(197785); -- Revenge, Served Cold (45 Crit/Verst)
  _,SMARTBUFF_Tongueslicer        = GetItemInfo(197786); -- Thousandbone Tongueslicer (45 Crit/Mastery)
  _,SMARTBUFF_GreatCeruleanSea    = GetItemInfo(197787); -- Great Cerulean Sea (45 Vers/Mastery)
  _,SMARTBUFF_FatedFortuneCookie  = GetItemInfo(197792); -- Fated Fortune Cookie (76 primary stat)
  _,SMARTBUFF_KaluakBanquet       = GetItemInfo(197794); -- Feast: Grand Banquet of the Kalu'ak (76 primary stat)
  _,SMARTBUFF_HoardOfDelicacies   = GetItemInfo(197795); -- Feast: Hoard of Draconic Delicacies (76 primary stat)
  _,SMARTBUFF_DeviouslyDeviledEgg = GetItemInfo(204072); -- Deviously Deviled Eggs

  -- Food item IDs
  S.FoodItems = GetItems({
    -- WotLK
    39691, 34125, 42779, 42997, 42998, 42999, 43000, 34767, 42995, 34769, 34754, 34758, 34766, 42994, 42996, 34756, 34768, 42993, 34755, 43001, 34757, 34752, 34751, 34750, 34749, 34764, 34765, 34763, 34762, 42942, 43268, 34748,
    -- CT
    62651, 62652, 62653, 62654, 62655, 62656, 62657, 62658, 62659, 62660, 62661, 62662, 62663, 62664, 62665, 62666, 62667, 62668, 62669, 62670, 62671, 62649,
    -- MoP
    74645, 74646, 74647, 74648, 74649, 74650, 74652, 74653, 74655, 74656, 86069, 86070, 86073, 86074, 81400, 81401, 81402, 81403, 81404, 81405, 81406, 81408, 81409, 81410, 81411, 81412, 81413, 81414,
 	-- WoD
 	111431, 111432, 111433, 111434, 111435, 111436, 111437, 111438, 111439, 111440, 11441, 111442, 111443, 111444, 111445, 111446, 111447, 111448, 111449, 111450, 111451, 111452, 111453, 111454,127991, 111457, 111458, 118576,
  });

  -- Conjured mage food IDs
  SMARTBUFF_CONJUREDMANA        = GetItemInfo(113509); --"Conjured Mana Buns"
  S.FoodMage = GetItems({113509, 80618, 80610, 65499, 43523, 43518, 34062, 65517, 65516, 65515, 65500, 42955});

  --_,SMARTBUFF_BCPETFOOD1          = GetItemInfo(33874); --"Kibler's Bits (Pet food)"
  --_,SMARTBUFF_WOTLKPETFOOD1       = GetItemInfo(43005); --"Spiced Mammoth Treats (Pet food)"

  -- Scrolls
  _,SMARTBUFF_SOAGILITY1          = GetItemInfo(3012);  --"Scroll of Agility I"
  _,SMARTBUFF_SOAGILITY2          = GetItemInfo(1477);  --"Scroll of Agility II"
  _,SMARTBUFF_SOAGILITY3          = GetItemInfo(4425);  --"Scroll of Agility III"
  _,SMARTBUFF_SOAGILITY4          = GetItemInfo(10309); --"Scroll of Agility IV"
  _,SMARTBUFF_SOAGILITY5          = GetItemInfo(27498); --"Scroll of Agility V"
  _,SMARTBUFF_SOAGILITY6          = GetItemInfo(33457); --"Scroll of Agility VI"
  _,SMARTBUFF_SOAGILITY7          = GetItemInfo(43463); --"Scroll of Agility VII"
  _,SMARTBUFF_SOAGILITY8          = GetItemInfo(43464); --"Scroll of Agility VIII"
  _,SMARTBUFF_SOAGILITY9          = GetItemInfo(63303); --"Scroll of Agility IX"
  _,SMARTBUFF_SOINTELLECT1        = GetItemInfo(955);   --"Scroll of Intellect I"
  _,SMARTBUFF_SOINTELLECT2        = GetItemInfo(2290);  --"Scroll of Intellect II"
  _,SMARTBUFF_SOINTELLECT3        = GetItemInfo(4419);  --"Scroll of Intellect III"
  _,SMARTBUFF_SOINTELLECT4        = GetItemInfo(10308); --"Scroll of Intellect IV"
  _,SMARTBUFF_SOINTELLECT5        = GetItemInfo(27499); --"Scroll of Intellect V"
  _,SMARTBUFF_SOINTELLECT6        = GetItemInfo(33458); --"Scroll of Intellect VI"
  _,SMARTBUFF_SOINTELLECT7        = GetItemInfo(37091); --"Scroll of Intellect VII"
  _,SMARTBUFF_SOINTELLECT8        = GetItemInfo(37092); --"Scroll of Intellect VIII"
  _,SMARTBUFF_SOINTELLECT9        = GetItemInfo(63305); --"Scroll of Intellect IX"
  _,SMARTBUFF_SOSTAMINA1          = GetItemInfo(1180);  --"Scroll of Stamina I"
  _,SMARTBUFF_SOSTAMINA2          = GetItemInfo(1711);  --"Scroll of Stamina II"
  _,SMARTBUFF_SOSTAMINA3          = GetItemInfo(4422);  --"Scroll of Stamina III"
  _,SMARTBUFF_SOSTAMINA4          = GetItemInfo(10307); --"Scroll of Stamina IV"
  _,SMARTBUFF_SOSTAMINA5          = GetItemInfo(27502); --"Scroll of Stamina V"
  _,SMARTBUFF_SOSTAMINA6          = GetItemInfo(33461); --"Scroll of Stamina VI"
  _,SMARTBUFF_SOSTAMINA7          = GetItemInfo(37093); --"Scroll of Stamina VII"
  _,SMARTBUFF_SOSTAMINA8          = GetItemInfo(37094); --"Scroll of Stamina VIII"
  _,SMARTBUFF_SOSTAMINA9          = GetItemInfo(63306); --"Scroll of Stamina IX"
  _,SMARTBUFF_SOSPIRIT1           = GetItemInfo(1181);  --"Scroll of Spirit I"
  _,SMARTBUFF_SOSPIRIT2           = GetItemInfo(1712);  --"Scroll of Spirit II"
  _,SMARTBUFF_SOSPIRIT3           = GetItemInfo(4424);  --"Scroll of Spirit III"
  _,SMARTBUFF_SOSPIRIT4           = GetItemInfo(10306); --"Scroll of Spirit IV"
  _,SMARTBUFF_SOSPIRIT5           = GetItemInfo(27501); --"Scroll of Spirit V"
  _,SMARTBUFF_SOSPIRIT6           = GetItemInfo(33460); --"Scroll of Spirit VI"
  _,SMARTBUFF_SOSPIRIT7           = GetItemInfo(37097); --"Scroll of Spirit VII"
  _,SMARTBUFF_SOSPIRIT8           = GetItemInfo(37098); --"Scroll of Spirit VIII"
  _,SMARTBUFF_SOSPIRIT9           = GetItemInfo(63307); --"Scroll of Spirit IX"
  _,SMARTBUFF_SOSTRENGHT1         = GetItemInfo(954);   --"Scroll of Strength I"
  _,SMARTBUFF_SOSTRENGHT2         = GetItemInfo(2289);  --"Scroll of Strength II"
  _,SMARTBUFF_SOSTRENGHT3         = GetItemInfo(4426);  --"Scroll of Strength III"
  _,SMARTBUFF_SOSTRENGHT4         = GetItemInfo(10310); --"Scroll of Strength IV"
  _,SMARTBUFF_SOSTRENGHT5         = GetItemInfo(27503); --"Scroll of Strength V"
  _,SMARTBUFF_SOSTRENGHT6         = GetItemInfo(33462); --"Scroll of Strength VI"
  _,SMARTBUFF_SOSTRENGHT7         = GetItemInfo(43465); --"Scroll of Strength VII"
  _,SMARTBUFF_SOSTRENGHT8         = GetItemInfo(43466); --"Scroll of Strength VIII"
  _,SMARTBUFF_SOSTRENGHT9         = GetItemInfo(63304); --"Scroll of Strength IX"
  _,SMARTBUFF_SOPROTECTION9       = GetItemInfo(63308); --"Scroll of Protection IX"

  _,SMARTBUFF_MiscItem1           = GetItemInfo(178512);  --"Celebration Package"
  _,SMARTBUFF_MiscItem2           = GetItemInfo(44986);  --"Warts-B-Gone Lip Balm"
  _,SMARTBUFF_MiscItem3           = GetItemInfo(69775);  --"Vrykul Drinking Horn"
  _,SMARTBUFF_MiscItem4           = GetItemInfo(86569);  --"Crystal of Insanity"
  _,SMARTBUFF_MiscItem5           = GetItemInfo(85500);  --"Anglers Fishing Raft"
  _,SMARTBUFF_MiscItem6           = GetItemInfo(85973);  --"Ancient Pandaren Fishing Charm"
  _,SMARTBUFF_MiscItem7           = GetItemInfo(94604);  --"Burning Seed"
  _,SMARTBUFF_MiscItem9           = GetItemInfo(92738);  --"Safari Hat"
  _,SMARTBUFF_MiscItem10          = GetItemInfo(110424); --"Savage Safari Hat"
  _,SMARTBUFF_MiscItem11          = GetItemInfo(118922); --"Oralius' Whispering Crystal"
  _,SMARTBUFF_MiscItem12          = GetItemInfo(129192); --"Inquisitor's Menacing Eye"
  _,SMARTBUFF_MiscItem13          = GetItemInfo(129210); --"Fel Crystal Fragments"
  _,SMARTBUFF_MiscItem14          = GetItemInfo(128475); --"Empowered Augment Rune"
  _,SMARTBUFF_MiscItem15          = GetItemInfo(128482); --"Empowered Augment Rune"
  _,SMARTBUFF_MiscItem17          = GetItemInfo(147707); --"Repurposed Fel Focuser"
  --Shadowlands
  _,SMARTBUFF_AugmentRune         = GetItemInfo(190384); --"Eternal Augment Rune"
  _,SMARTBUFF_VieledAugment       = GetItemInfo(181468); --"Veiled Augment Rune"
  --Dragonflight
  _,SMARTBUFF_DraconicRune        = GetItemInfo(201325); -- Draconic Augment Rune
  _,SMARTBUFF_VantusRune_VotI_q1  = GetItemInfo(198491); -- Vantus Rune: Vault of the Incarnates (Quality 1)
  _,SMARTBUFF_VantusRune_VotI_q2  = GetItemInfo(198492); -- Vantus Rune: Vault of the Incarnates (Quality 2)
  _,SMARTBUFF_VantusRune_VotI_q3  = GetItemInfo(198493); -- Vantus Rune: Vault of the Incarnates (Quality 3)

  _,SMARTBUFF_FLASKTBC1           = GetItemInfo(22854);  --"Flask of Relentless Assault"
  _,SMARTBUFF_FLASKTBC2           = GetItemInfo(22866);  --"Flask of Pure Death"
  _,SMARTBUFF_FLASKTBC3           = GetItemInfo(22851);  --"Flask of Fortification"
  _,SMARTBUFF_FLASKTBC4           = GetItemInfo(22861);  --"Flask of Blinding Light"
  _,SMARTBUFF_FLASKTBC5           = GetItemInfo(22853);  --"Flask of Mighty Versatility"
  _,SMARTBUFF_FLASK1              = GetItemInfo(46377);  --"Flask of Endless Rage"
  _,SMARTBUFF_FLASK2              = GetItemInfo(46376);  --"Flask of the Frost Wyrm"
  _,SMARTBUFF_FLASK3              = GetItemInfo(46379);  --"Flask of Stoneblood"
  _,SMARTBUFF_FLASK4              = GetItemInfo(46378);  --"Flask of Pure Mojo"
  _,SMARTBUFF_FLASKCT1            = GetItemInfo(58087);  --"Flask of the Winds"
  _,SMARTBUFF_FLASKCT2            = GetItemInfo(58088);  --"Flask of Titanic Strength"
  _,SMARTBUFF_FLASKCT3            = GetItemInfo(58086);  --"Flask of the Draconic Mind"
  _,SMARTBUFF_FLASKCT4            = GetItemInfo(58085);  --"Flask of Steelskin"
  _,SMARTBUFF_FLASKCT5            = GetItemInfo(67438);  --"Flask of Flowing Water"
  _,SMARTBUFF_FLASKCT7            = GetItemInfo(65455);  --"Flask of Battle"
  _,SMARTBUFF_FLASKMOP1           = GetItemInfo(75525);  --"Alchemist's Flask"
  _,SMARTBUFF_FLASKMOP2           = GetItemInfo(76087);  --"Flask of the Earth"
  _,SMARTBUFF_FLASKMOP3           = GetItemInfo(76086);  --"Flask of Falling Leaves"
  _,SMARTBUFF_FLASKMOP4           = GetItemInfo(76084);  --"Flask of Spring Blossoms"
  _,SMARTBUFF_FLASKMOP5           = GetItemInfo(76085);  --"Flask of the Warm Sun"
  _,SMARTBUFF_FLASKMOP6           = GetItemInfo(76088);  --"Flask of Winter's Bite"
  _,SMARTBUFF_FLASKWOD1           = GetItemInfo(109152); --"Draenic Stamina Flask"
  _,SMARTBUFF_FLASKWOD2           = GetItemInfo(109148); --"Draenic Strength Flask"
  _,SMARTBUFF_FLASKWOD3           = GetItemInfo(109147); --"Draenic Intellect Flask"
  _,SMARTBUFF_FLASKWOD4           = GetItemInfo(109145); --"Draenic Agility Flask"
  _,SMARTBUFF_GRFLASKWOD1         = GetItemInfo(109160); --"Greater Draenic Stamina Flask"
  _,SMARTBUFF_GRFLASKWOD2         = GetItemInfo(109156); --"Greater Draenic Strength Flask"
  _,SMARTBUFF_GRFLASKWOD3         = GetItemInfo(109155); --"Greater Draenic Intellect Flask"
  _,SMARTBUFF_GRFLASKWOD4         = GetItemInfo(109153); --"Greater Draenic Agility Flask"
  _,SMARTBUFF_FLASKLEG1           = GetItemInfo(127850); --"Flask of Ten Thousand Scars"
  _,SMARTBUFF_FLASKLEG2           = GetItemInfo(127849); --"Flask of the Countless Armies"
  _,SMARTBUFF_FLASKLEG3           = GetItemInfo(127847); --"Flask of the Whispered Pact"
  _,SMARTBUFF_FLASKLEG4           = GetItemInfo(127848); --"Flask of the Seventh Demon"
  _,SMARTBUFF_FLASKBFA1           = GetItemInfo(152639); --"Flask of Endless Fathoms"
  _,SMARTBUFF_FLASKBFA2           = GetItemInfo(152638); --"Flask of the Currents"
  _,SMARTBUFF_FLASKBFA3           = GetItemInfo(152641); --"Flask of the Undertow"
  _,SMARTBUFF_FLASKBFA4           = GetItemInfo(152640); --"Flask of the Vast Horizon"
  _,SMARTBUFF_GRFLASKBFA1         = GetItemInfo(168652); --"Greather Flask of Endless Fathoms"
  _,SMARTBUFF_GRFLASKBFA2         = GetItemInfo(168651); --"Greater Flask of the Currents"
  _,SMARTBUFF_GRFLASKBFA3         = GetItemInfo(168654); --"Greather Flask of teh Untertow"
  _,SMARTBUFF_GRFLASKBFA4         = GetItemInfo(168653); --"Greater Flask of the Vast Horizon"
  _,SMARTBUFF_FLASKSL1            = GetItemInfo(171276); --"Spectral Flask of Power"
  _,SMARTBUFF_FLASKSL2            = GetItemInfo(171278); --"Spectral Flask of Stamina"

  _,SMARTBUFF_FlaskDF1_q1        = GetItemInfo(191318); -- Phial of the Eye in the Storm (Quality 1)
  _,SMARTBUFF_FlaskDF1_q2        = GetItemInfo(191319); -- Phial of the Eye in the Storm (Quality 2)
  _,SMARTBUFF_FlaskDF1_q3        = GetItemInfo(191320); -- Phial of the Eye in the Storm (Quality 3)

  _,SMARTBUFF_FlaskDF2_q1        = GetItemInfo(191321); -- Phial of Still Air (Quality 1)
  _,SMARTBUFF_FlaskDF2_q2        = GetItemInfo(191322); -- Phial of Still Air (Quality 2)
  _,SMARTBUFF_FlaskDF2_q3        = GetItemInfo(191323); -- Phial of Still Air (Quality 3)

  _,SMARTBUFF_FlaskDF3_q1        = GetItemInfo(191324); -- Phial of Icy Preservation (Quality 1)
  _,SMARTBUFF_FlaskDF3_q2        = GetItemInfo(191325); -- Phial of Icy Preservation (Quality 2)
  _,SMARTBUFF_FlaskDF3_q3        = GetItemInfo(191326); -- Phial of Icy Preservation (Quality 3)

  _,SMARTBUFF_FlaskDF4_q1        = GetItemInfo(191327); -- Iced Phial of Corrupting Rage (Quality 1)
  _,SMARTBUFF_FlaskDF4_q2        = GetItemInfo(191328); -- Iced Phial of Corrupting Rage (Quality 2)
  _,SMARTBUFF_FlaskDF4_q3        = GetItemInfo(191329); -- Iced Phial of Corrupting Rage (Quality 3)

  _,SMARTBUFF_FlaskDF5_q1        = GetItemInfo(191330); -- Phial of Charged Isolation (Quality 1)
  _,SMARTBUFF_FlaskDF5_q2        = GetItemInfo(191331); -- Phial of Charged Isolation (Quality 2)
  _,SMARTBUFF_FlaskDF5_q3        = GetItemInfo(191332); -- Phial of Charged Isolation (Quality 3)

  _,SMARTBUFF_FlaskDF6_q1        = GetItemInfo(191333); -- Phial of Glacial Fury (Quality 1)
  _,SMARTBUFF_FlaskDF6_q2        = GetItemInfo(191334); -- Phial of Glacial Fury (Quality 2)
  _,SMARTBUFF_FlaskDF6_q3        = GetItemInfo(191335); -- Phial of Glacial Fury (Quality 3)

  _,SMARTBUFF_FlaskDF7_q1        = GetItemInfo(191336); -- Phial of Static Empowerment (Quality 1)
  _,SMARTBUFF_FlaskDF7_q2        = GetItemInfo(191337); -- Phial of Static Empowerment (Quality 2)
  _,SMARTBUFF_FlaskDF7_q3        = GetItemInfo(191338); -- Phial of Static Empowerment (Quality 3)

  _,SMARTBUFF_FlaskDF8_q1        = GetItemInfo(191339); -- Phial of Tepid Versatility (Quality 1)
  _,SMARTBUFF_FlaskDF8_q2        = GetItemInfo(191340); -- Phial of Tepid Versatility (Quality 2)
  _,SMARTBUFF_FlaskDF8_q3        = GetItemInfo(191341); -- Phial of Tepid Versatility (Quality 3)

  _,SMARTBUFF_FlaskDF9_q1        = GetItemInfo(191342); -- Aerated Phial of Deftness (Quality 1)
  _,SMARTBUFF_FlaskDF9_q3        = GetItemInfo(191343); -- Aerated Phial of Deftness (Quality 2)
  _,SMARTBUFF_FlaskDF9_q3        = GetItemInfo(191344); -- Aerated Phial of Deftness (Quality 3)

  _,SMARTBUFF_FlaskDF10_q1       = GetItemInfo(191345); -- Steaming Phial of Finesse (Quality 1)
  _,SMARTBUFF_FlaskDF10_q2       = GetItemInfo(191346); -- Steaming Phial of Finesse (Quality 1)
  _,SMARTBUFF_FlaskDF10_q3       = GetItemInfo(191347); -- Steaming Phial of Finesse (Quality 1)

  _,SMARTBUFF_FlaskDF11_q1       = GetItemInfo(191348); -- Charged Phial of Alacrity (Quality 1)
  _,SMARTBUFF_FlaskDF11_q2       = GetItemInfo(191349); -- Charged Phial of Alacrity (Quality 2)
  _,SMARTBUFF_FlaskDF11_q3       = GetItemInfo(191350); -- Charged Phial of Alacrity (Quality 3)

  _,SMARTBUFF_FlaskDF12_q1       = GetItemInfo(191354); -- Crystalline Phial of Perception (Quality 1)
  _,SMARTBUFF_FlaskDF12_q2       = GetItemInfo(191355); -- Crystalline Phial of Perception (Quality 2)
  _,SMARTBUFF_FlaskDF12_q3       = GetItemInfo(191356); -- Crystalline Phial of Perception (Quality 3)

  _,SMARTBUFF_FlaskDF13_q1       = GetItemInfo(191357); -- Phial of Elemental Chaos (Quality 1)
  _,SMARTBUFF_FlaskDF13_q2       = GetItemInfo(191358); -- Phial of Elemental Chaos (Quality 2)
  _,SMARTBUFF_FlaskDF13_q3       = GetItemInfo(191359); -- Phial of Elemental Chaos (Quality 3)

  _,SMARTBUFF_FlaskDF14_q1       = GetItemInfo(197720); -- Aerated Phial of Quick Hands (Quality 1)
  _,SMARTBUFF_FlaskDF14_q2       = GetItemInfo(197721); -- Aerated Phial of Quick Hands (Quality 2)
  _,SMARTBUFF_FlaskDF14_q3       = GetItemInfo(197722); -- Aerated Phial of Quick Hands (Quality 3)

  _,SMARTBUFF_ELIXIRTBC1          = GetItemInfo(22831);  --"Elixir of Major Agility"
  _,SMARTBUFF_ELIXIRTBC2          = GetItemInfo(28104);  --"Elixir of Mastery"
  _,SMARTBUFF_ELIXIRTBC3          = GetItemInfo(22825);  --"Elixir of Healing Power"
  _,SMARTBUFF_ELIXIRTBC4          = GetItemInfo(22834);  --"Elixir of Major Defense"
  _,SMARTBUFF_ELIXIRTBC5          = GetItemInfo(22824);  --"Elixir of Major Strangth"
  _,SMARTBUFF_ELIXIRTBC6          = GetItemInfo(32062);  --"Elixir of Major Fortitude"
  _,SMARTBUFF_ELIXIRTBC7          = GetItemInfo(22840);  --"Elixir of Major Mageblood"
  _,SMARTBUFF_ELIXIRTBC8          = GetItemInfo(32067);  --"Elixir of Draenic Wisdom"
  _,SMARTBUFF_ELIXIRTBC9          = GetItemInfo(28103);  --"Adept's Elixir"
  _,SMARTBUFF_ELIXIRTBC10         = GetItemInfo(22848);  --"Elixir of Empowerment"
  _,SMARTBUFF_ELIXIRTBC11         = GetItemInfo(28102);  --"Onslaught Elixir"
  _,SMARTBUFF_ELIXIRTBC12         = GetItemInfo(22835);  --"Elixir of Major Shadow Power"
  _,SMARTBUFF_ELIXIRTBC13         = GetItemInfo(32068);  --"Elixir of Ironskin"
  _,SMARTBUFF_ELIXIRTBC14         = GetItemInfo(32063);  --"Earthen Elixir"
  _,SMARTBUFF_ELIXIRTBC15         = GetItemInfo(22827);  --"Elixir of Major Frost Power"
  _,SMARTBUFF_ELIXIRTBC16         = GetItemInfo(31679);  --"Fel Strength Elixir"
  _,SMARTBUFF_ELIXIRTBC17         = GetItemInfo(22833);  --"Elixir of Major Firepower"
  _,SMARTBUFF_ELIXIR1             = GetItemInfo(39666);  --"Elixir of Mighty Agility"
  _,SMARTBUFF_ELIXIR2             = GetItemInfo(44332);  --"Elixir of Mighty Thoughts"
  _,SMARTBUFF_ELIXIR3             = GetItemInfo(40078);  --"Elixir of Mighty Fortitude"
  _,SMARTBUFF_ELIXIR4             = GetItemInfo(40073);  --"Elixir of Mighty Strength"
  _,SMARTBUFF_ELIXIR5             = GetItemInfo(40072);  --"Elixir of Spirit"
  _,SMARTBUFF_ELIXIR6             = GetItemInfo(40097);  --"Elixir of Protection"
  _,SMARTBUFF_ELIXIR7             = GetItemInfo(44328);  --"Elixir of Mighty Defense"
  _,SMARTBUFF_ELIXIR8             = GetItemInfo(44331);  --"Elixir of Lightning Speed"
  _,SMARTBUFF_ELIXIR9             = GetItemInfo(44329);  --"Elixir of Expertise"
  _,SMARTBUFF_ELIXIR10            = GetItemInfo(44327);  --"Elixir of Deadly Strikes"
  _,SMARTBUFF_ELIXIR11            = GetItemInfo(44330);  --"Elixir of Armor Piercing"
  _,SMARTBUFF_ELIXIR12            = GetItemInfo(44325);  --"Elixir of Accuracy"
  _,SMARTBUFF_ELIXIR13            = GetItemInfo(40076);  --"Guru's Elixir"
  _,SMARTBUFF_ELIXIR14            = GetItemInfo(9187);   --"Elixir of Greater Agility"
  _,SMARTBUFF_ELIXIR15            = GetItemInfo(28103);  --"Adept's Elixir"
  _,SMARTBUFF_ELIXIR16            = GetItemInfo(40070);  --"Spellpower Elixir"
  _,SMARTBUFF_ELIXIRCT1           = GetItemInfo(58148);  --"Elixir of the Master"
  _,SMARTBUFF_ELIXIRCT2           = GetItemInfo(58144);  --"Elixir of Mighty Speed"
  _,SMARTBUFF_ELIXIRCT3           = GetItemInfo(58094);  --"Elixir of Impossible Accuracy"
  _,SMARTBUFF_ELIXIRCT4           = GetItemInfo(58143);  --"Prismatic Elixir"
  _,SMARTBUFF_ELIXIRCT5           = GetItemInfo(58093);  --"Elixir of Deep Earth"
  _,SMARTBUFF_ELIXIRCT6           = GetItemInfo(58092);  --"Elixir of the Cobra"
  _,SMARTBUFF_ELIXIRCT7           = GetItemInfo(58089);  --"Elixir of the Naga"
  _,SMARTBUFF_ELIXIRCT8           = GetItemInfo(58084);  --"Ghost Elixir"
  _,SMARTBUFF_ELIXIRMOP1          = GetItemInfo(76081);  --"Elixir of Mirrors"
  _,SMARTBUFF_ELIXIRMOP2          = GetItemInfo(76079);  --"Elixir of Peace"
  _,SMARTBUFF_ELIXIRMOP3          = GetItemInfo(76080);  --"Elixir of Perfection"
  _,SMARTBUFF_ELIXIRMOP4          = GetItemInfo(76078);  --"Elixir of the Rapids"
  _,SMARTBUFF_ELIXIRMOP5          = GetItemInfo(76077);  --"Elixir of Weaponry"
  _,SMARTBUFF_ELIXIRMOP6          = GetItemInfo(76076);  --"Mad Hozen Elixir"
  _,SMARTBUFF_ELIXIRMOP7          = GetItemInfo(76075);  --"Mantid Elixir"
  _,SMARTBUFF_ELIXIRMOP8          = GetItemInfo(76083);  --"Monk's Elixir"

  -- Draught of Ten Lands
  _,SMARTBUFF_EXP_POTION          = GetItemInfo(166750); --"Draught of Ten Lands"

  -- fishing pole
  _, _, _, _, _, _, S.FishingPole = GetItemInfo(6256);  --"Fishing Pole"

  SMARTBUFF_AddMsgD("Item list initialized");
  -- i still want to load them regardless of the option to turn them off/hide them
  -- so that my settings are preserved and loaded should i turn it back on.
  LoadToys();
end


function SMARTBUFF_InitSpellIDs()
  SMARTBUFF_TESTSPELL       = GetSpellInfo(774);

  -- Druid
  SMARTBUFF_DRUID_CAT       = GetSpellInfo(768);   --"Cat Form"
  SMARTBUFF_DRUID_TREE      = GetSpellInfo(33891); --"Incarnation: Tree of Life"
  SMARTBUFF_DRUID_TREANT    = GetSpellInfo(114282);--"Treant Form"
  SMARTBUFF_DRUID_MOONKIN   = GetSpellInfo(24858); --"Moonkin Form"
  --SMARTBUFF_DRUID_MKAURA    = GetSpellInfo(24907); --"Moonkin Aura"
  SMARTBUFF_DRUID_TRACK     = GetSpellInfo(5225);  --"Track Humanoids"
  SMARTBUFF_MOTW            = GetSpellInfo(1126);  --"Mark of the Wild"
  SMARTBUFF_BARKSKIN        = GetSpellInfo(22812); --"Barkskin"
  SMARTBUFF_TIGERSFURY      = GetSpellInfo(5217);  --"Tiger's Fury"
  SMARTBUFF_SAVAGEROAR      = GetSpellInfo(52610); --"Savage Roar"
  SMARTBUFF_CENARIONWARD    = GetSpellInfo(102351);--"Cenarion Ward"
  SMARTBUFF_DRUID_BEAR      = GetSpellInfo(5487);  --"Bear Form"

  -- Priest
  SMARTBUFF_PWF             = GetSpellInfo(21562); --"Power Word: Fortitude"
  SMARTBUFF_PWS             = GetSpellInfo(17);    --"Power Word: Shield"
  --SMARTBUFF_FEARWARD        = GetSpellInfo(6346);  --"Fear Ward"
  SMARTBUFF_RENEW           = GetSpellInfo(139);   --"Renew"
  SMARTBUFF_LEVITATE        = GetSpellInfo(1706);  --"Levitate"
  SMARTBUFF_SHADOWFORM      = GetSpellInfo(232698); --"Shadowform"
  SMARTBUFF_VAMPIRICEMBRACE = GetSpellInfo(15286); --"Vampiric Embrace"
  --SMARTBUFF_LIGHTWELL       = GetSpellInfo(724);   --"Lightwell"
  --SMARTBUFF_CHAKRA1         = GetSpellInfo(81206)  --"Chakra Sanctuary"
  --SMARTBUFF_CHAKRA2         = GetSpellInfo(81208)  --"Chakra Serenity"
  --SMARTBUFF_CHAKRA3         = GetSpellInfo(81209)  --"Chakra Chastise"
  -- Priest buff links
  S.LinkPriestChakra        = { SMARTBUFF_CHAKRA1, SMARTBUFF_CHAKRA2, SMARTBUFF_CHAKRA3 };

  -- Mage
  SMARTBUFF_AB              = GetSpellInfo(1459);  --"Arcane Intellect"
  SMARTBUFF_DALARANB        = GetSpellInfo(61316); --"Dalaran Brilliance"
  SMARTBUFF_FROSTARMOR      = GetSpellInfo(7302);  --"Frost Armor"
  SMARTBUFF_MAGEARMOR       = GetSpellInfo(6117);  --"Mage Armor"
  --SMARTBUFF_MOLTENARMOR     = GetSpellInfo(30482); --"Molten Armor"
  SMARTBUFF_MANASHIELD      = GetSpellInfo(35064); --"Mana Shield"
  --SMARTBUFF_ICEWARD         = GetSpellInfo(111264);--"Ice Ward"
  SMARTBUFF_ICEBARRIER      = GetSpellInfo(11426); --"Ice Barrier"
  --SMARTBUFF_COMBUSTION      = GetSpellInfo(11129); --"Combustion"
  SMARTBUFF_ARCANEPOWER     = GetSpellInfo(12042); --"Arcane Power"
  SMARTBUFF_PRESENCEOFMIND  = GetSpellInfo(205025); --"Presence of Mind"
  SMARTBUFF_ICYVEINS        = GetSpellInfo(12472); --"Icy Veins"
  SMARTBUFF_SUMMONWATERELE  = GetSpellInfo(31687); --"Summon Water Elemental"
  SMARTBUFF_SLOWFALL        = GetSpellInfo(130);   --"Slow Fall"
  SMARTBUFF_REFRESHMENT     = GetSpellInfo(42955); --"Conjure Refreshment"
  SMARTBUFF_TEMPSHIELD      = GetSpellInfo(198111);--"Temporal Shield"
  --SMARTBUFF_AMPMAGIC        = GetSpellInfo(159916);--"Amplify Magic"

  SMARTBUFF_PRISBARRIER     = GetSpellInfo(235450);--"Prismatic Barrier"
  SMARTBUFF_IMPPRISBARRIER     = GetSpellInfo(321745);--"Improved Prismatic Barrier"

  SMARTBUFF_BLAZBARRIER     = GetSpellInfo(235313);--"Blazing Barrier"
  SMARTBUFF_ARCANEFAMILIAR  = GetSpellInfo(205022);--"Arcane Familiar"
  SMARTBUFF_CREATEMG		= GetSpellInfo(759);   --"Conjure Mana Gem"

  -- Mage buff links
  S.ChainMageArmor = { SMARTBUFF_FROSTARMOR, SMARTBUFF_MAGEARMOR, SMARTBUFF_MOLTENARMOR };

  -- Warlock
  SMARTBUFF_AMPLIFYCURSE    = GetSpellInfo(328774);--"Amplify Curse"
  SMARTBUFF_DEMONARMOR      = GetSpellInfo(285933);--"Demon ARmor"
  SMARTBUFF_DARKINTENT      = GetSpellInfo(183582);--"Dark Intent"
  SMARTBUFF_UNENDINGBREATH  = GetSpellInfo(5697);  --"Unending Breath"
  SMARTBUFF_SOULLINK        = GetSpellInfo(108447);--"Soul Link"
  SMARTBUFF_LIFETAP         = GetSpellInfo(1454);  --"Life Tap"
  SMARTBUFF_CREATEHS        = GetSpellInfo(6201);  --"Create Healthstone"
  SMARTBUFF_SOULSTONE       = GetSpellInfo(20707); --"Soulstone"
  SMARTBUFF_GOSACRIFICE     = GetSpellInfo(108503);--"Grimoire of Sacrifice"
  SMARTBUFF_INQUISITORGAZE  = GetSpellInfo(386344);--"Inquisitor's Gaze"

  -- Warlock pets
  SMARTBUFF_SUMMONIMP		= GetSpellInfo(688);    --"Summon Imp"
  SMARTBUFF_SUMMONFELHUNTER	= GetSpellInfo(691);    --"Summon Fellhunter"
  SMARTBUFF_SUMMONVOIDWALKER= GetSpellInfo(697);    --"Summon Voidwalker"
  SMARTBUFF_SUMMONSUCCUBUS	= GetSpellInfo(712);    --"Summon Succubus"
  SMARTBUFF_SUMMONINFERNAL	= GetSpellInfo(1122);   --"Summon Infernal"
  SMARTBUFF_SUMMONDOOMGUARD	= GetSpellInfo(18540);  --"Summon Doomguard"
  SMARTBUFF_SUMMONFELGUARD  = GetSpellInfo(30146);  --"Summon Felguard"
  SMARTBUFF_SUMMONFELIMP	= GetSpellInfo(112866); --"Summon Fel Imp"
  SMARTBUFF_SUMMONVOIDLORD	= GetSpellInfo(112867); --"Summon Voidlord"
  SMARTBUFF_SUMMONSHIVARRA	= GetSpellInfo(112868); --"Summon Shivarra"
  SMARTBUFF_SUMMONOBSERVER	= GetSpellInfo(112869); --"Summon Observer"
  SMARTBUFF_SUMMONWRATHGUARD= GetSpellInfo(112870); --"Summon Wrathguard"

  -- Hunter
  SMARTBUFF_TRUESHOTAURA    = GetSpellInfo(193526); --"Trueshot Aura" (P)
  SMARTBUFF_VOLLEY          = GetSpellInfo(194386); --"Volley"
  SMARTBUFF_RAPIDFIRE       = GetSpellInfo(3045);  --"Rapid Fire"
  SMARTBUFF_FOCUSFIRE       = GetSpellInfo(82692); --"Focus Fire"
  --SMARTBUFF_TRAPLAUNCHER    = GetSpellInfo(77769); --"Trap Launcher"
  --SMARTBUFF_CAMOFLAUGE      = GetSpellInfo(51753); --"Camoflauge"
  SMARTBUFF_AOTC            = GetSpellInfo(186257);  --"Aspect of the Cheetah"
  --SMARTBUFF_AOTP            = GetSpellInfo(13159); --"Aspect of the Pack"
  --SMARTBUFF_AOTF            = GetSpellInfo(172106); --"Aspect of the Fox"
  SMARTBUFF_AOTW			= GetSpellInfo(193530);	--"Aspect of the Wild"
  SMARTBUFF_AMMOI           = GetSpellInfo(162536); --"Incendiary Ammo"
  SMARTBUFF_AMMOP           = GetSpellInfo(162537); --"Poisoned Ammo"
  SMARTBUFF_AMMOF           = GetSpellInfo(162539); --"Frozen Ammo"
  --SMARTBUFF_LW1             = GetSpellInfo(160200); --"Lone Wolf: Ferocity of the Raptor"
  --SMARTBUFF_LW2             = GetSpellInfo(160203); --"Lone Wolf: Haste of the Hyena"
  --SMARTBUFF_LW3             = GetSpellInfo(160198); --"Lone Wolf: Grace of the Cat"
  --SMARTBUFF_LW4             = GetSpellInfo(160206); --"Lone Wolf: Power of the Primates"
  --SMARTBUFF_LW5             = GetSpellInfo(160199); --"Lone Wolf: Fortitude of the Bear"
  --SMARTBUFF_LW6             = GetSpellInfo(160205); --"Lone Wolf: Wisdom of the Serpent"
  --SMARTBUFF_LW7             = GetSpellInfo(172967); --"Lone Wolf: Versatility of the Ravager"
  --SMARTBUFF_LW8             = GetSpellInfo(172968); --"Lone Wolf: Quickness of the Dragonhawk"
  -- Hunter pets
  SMARTBUFF_CALL_PET_1      = GetSpellInfo(883  ); -- "Call Pet 1"
  SMARTBUFF_CALL_PET_2      = GetSpellInfo(83242); -- "Call Pet 2"
  SMARTBUFF_CALL_PET_3      = GetSpellInfo(83243); -- "Call Pet 3"
  SMARTBUFF_CALL_PET_4      = GetSpellInfo(83244); -- "Call Pet 4"
  SMARTBUFF_CALL_PET_5      = GetSpellInfo(83245); -- "Call Pet 5"
  -- Hunter buff links
  S.LinkAspects  = { SMARTBUFF_AOTF, SMARTBUFF_AOTC, SMARTBUFF_AOTP, SMARTBUFF_AOTW };
  S.LinkAmmo     = { SMARTBUFF_AMMOI, SMARTBUFF_AMMOP, SMARTBUFF_AMMOF };
  S.LinkLoneWolf = { SMARTBUFF_LW1, SMARTBUFF_LW2, SMARTBUFF_LW3, SMARTBUFF_LW4, SMARTBUFF_LW5, SMARTBUFF_LW6, SMARTBUFF_LW7, SMARTBUFF_LW8 };

  -- Shaman
  SMARTBUFF_LIGHTNINGSHIELD = GetSpellInfo(192106); --"Lightning Shield"
  SMARTBUFF_WATERSHIELD     = GetSpellInfo(52127);  --"Water Shield"
  SMARTBUFF_EARTHSHIELD     = GetSpellInfo(974);    --"Earth Shield"
  SMARTBUFF_WATERWALKING    = GetSpellInfo(546);    --"Water Walking"
  SMARTBUFF_EMASTERY        = GetSpellInfo(16166);  --"Elemental Mastery"
  SMARTBUFF_ASCENDANCE_ELE  = GetSpellInfo(114050); --"Ascendance (Elemental)"
  SMARTBUFF_ASCENDANCE_ENH  = GetSpellInfo(114051); --"Ascendance (Enhancement)"
  SMARTBUFF_ASCENDANCE_RES  = GetSpellInfo(114052); --"Ascendance (Restoration)"
  SMARTBUFF_WINDFURYW       = GetSpellInfo(33757);  --"Windfury Weapon"
  SMARTBUFF_FLAMETONGUEW    = GetSpellInfo(318038); --"Flametongue Weapon"
  SMARTBUFF_EVERLIVINGW     = GetSpellInfo(382021); --"Everliving Weapon"

  -- Shaman buff links
  S.ChainShamanShield = { SMARTBUFF_LIGHTNINGSHIELD, SMARTBUFF_WATERSHIELD, SMARTBUFF_EARTHSHIELD };

  -- Warrior
  SMARTBUFF_BATTLESHOUT     = GetSpellInfo(6673);   --"Battle Shout"
  --SMARTBUFF_COMMANDINGSHOUT = GetSpellInfo(97462);    --"Reallying Cry"
  SMARTBUFF_BERSERKERRAGE   = GetSpellInfo(18499);  --"Berserker Rage"
  SMARTBUFF_BATSTANCE       = GetSpellInfo(386164); --"Battle Stance"
  SMARTBUFF_DEFSTANCE       = GetSpellInfo(197690); --"Defensive Stance"
  SMARTBUFF_GLADSTANCE      = GetSpellInfo(156291); --"Gladiator Stance"
  SMARTBUFF_SHIELDBLOCK     = GetSpellInfo(2565);   --"Shield Block"

  -- Warrior buff links
  S.ChainWarriorStance = { SMARTBUFF_BATSTANCE, SMARTBUFF_DEFSTANCE, SMARTBUFF_GLADSTANCE };
  S.ChainWarriorShout  = { SMARTBUFF_BATTLESHOUT, SMARTBUFF_COMMANDINGSHOUT };

  -- Rogue
  SMARTBUFF_STEALTH         = GetSpellInfo(1784);  --"Stealth"
  SMARTBUFF_BLADEFLURRY     = GetSpellInfo(13877); --"Blade Flurry"
  SMARTBUFF_SAD             = GetSpellInfo(5171);  --"Slice and Dice"
  SMARTBUFF_EVASION         = GetSpellInfo(5277);  --"Evasion"
  SMARTBUFF_HUNGERFORBLOOD  = GetSpellInfo(60177); --"Hunger For Blood"
  SMARTBUFF_TRICKS          = GetSpellInfo(57934); --"Tricks of the Trade"
  SMARTBUFF_RECUPERATE      = GetSpellInfo(185311); --"Crimson Vial
  -- Poisons
  SMARTBUFF_WOUNDPOISON         = GetSpellInfo(8679);   --"Wound Poison"
  SMARTBUFF_CRIPPLINGPOISON     = GetSpellInfo(3408);   --"Crippling Poison"
  SMARTBUFF_DEADLYPOISON        = GetSpellInfo(2823);   --"Deadly Poison"
  SMARTBUFF_LEECHINGPOISON      = GetSpellInfo(108211); --"Leeching Poison"
  SMARTBUFF_INSTANTPOISON       = GetSpellInfo(315584); --"Instant Poison"
  SMARTBUFF_NUMBINGPOISON       = GetSpellInfo(5761);   --"Numbing Poison"
  SMARTBUFF_AMPLIFYPOISON       = GetSpellInfo(381664); --"Amplifying Poison"
  SMARTBUFF_ATROPHICPOISON      = GetSpellInfo(381637);   --"Atrophic Poison"

  -- Rogue buff links
  S.ChainRoguePoisonsLethal     = { SMARTBUFF_DEADLYPOISON, SMARTBUFF_WOUNDPOISON, SMARTBUFF_INSTANTPOISON, SMARTBUFF_AGONIZINGPOISON, SMARTBUFF_AMPLIFYPOISON };
  S.ChainRoguePoisonsNonLethal  = { SMARTBUFF_CRIPPLINGPOISON, SMARTBUFF_LEECHINGPOISON, SMARTBUFF_NUMBINGPOISON, SMARTBUFF_ATROPHICPOISON };

  -- Paladin
  SMARTBUFF_RIGHTEOUSFURY         = GetSpellInfo(25780);  --"Righteous Fury"
--  SMARTBUFF_HOLYSHIELD            = GetSpellInfo(20925);  --"Sacred Shield"
  SMARTBUFF_BOK                   = GetSpellInfo(203538); --"Greater Blessing of Kings"
--  SMARTBUFF_BOM                   = GetSpellInfo(203528); --"Greater Blessing of Might"
  SMARTBUFF_BOW                   = GetSpellInfo(203539); --"Greater Blessing of Wisdom"
  SMARTBUFF_HOF                   = GetSpellInfo(1044);   --"Blessing of Freedom"
  SMARTBUFF_HOP                   = GetSpellInfo(1022);   --"Blessing of Protection"
  SMARTBUFF_HOSAL                 = GetSpellInfo(204013); --"Blessing of Salvation"
--  SMARTBUFF_SOJUSTICE             = GetSpellInfo(20164);  --"Seal of Justice"
--  SMARTBUFF_SOINSIGHT             = GetSpellInfo(20165);  --"Seal of Insight"
--  SMARTBUFF_SORIGHTEOUSNESS       = GetSpellInfo(20154);  --"Seal of Righteousness"
--  SMARTBUFF_SOTRUTH               = GetSpellInfo(31801);  --"Seal of Truth"
--  SMARTBUFF_SOCOMMAND             = GetSpellInfo(105361); --"Seal of Command"
  SMARTBUFF_AVENGINGWARTH         = GetSpellInfo(31884);  --"Avenging Wrath"
  SMARTBUFF_BEACONOFLIGHT         = GetSpellInfo(53563);  --"Beacon of Light"
  SMARTBUFF_BEACONOFAITH          = GetSpellInfo(156910); --"Beacon of Faith"
  SMARTBUFF_CRUSADERAURA          = GetSpellInfo(32223); --"Crusader Aura"
  SMARTBUFF_DEVOTIONAURA          = GetSpellInfo(465); --"Devotion Aura"
  SMARTBUFF_RETRIBUTIONAURA       = GetSpellInfo(183435); --"Retribution Aura"
  -- Paladin buff links
  S.ChainPaladinAura     = { SMARTBUFF_DEVOTIONAURA, SMARTBUFF_RETRIBUTIONAURA };
  S.ChainPaladinSeal     = { SMARTBUFF_SOCOMMAND, SMARTBUFF_SOTRUTH, SMARTBUFF_SOJUSTICE, SMARTBUFF_SOINSIGHT, SMARTBUFF_SORIGHTEOUSNESS };
  S.ChainPaladinBlessing = { SMARTBUFF_BOK, SMARTBUFF_BOM, SMARTBUFF_BOW};

  -- Death Knight
  SMARTBUFF_DANCINGRW         = GetSpellInfo(49028); --"Dancing Rune Weapon"
--  SMARTBUFF_BLOODPRESENCE     = GetSpellInfo(48263); --"Blood Presence"
--  SMARTBUFF_FROSTPRESENCE     = GetSpellInfo(48266); --"Frost Presence"
--  SMARTBUFF_UNHOLYPRESENCE    = GetSpellInfo(48265); --"Unholy Presence"
  SMARTBUFF_PATHOFFROST       = GetSpellInfo(3714);  --"Path of Frost"
--  SMARTBUFF_BONESHIELD        = GetSpellInfo(49222); --"Bone Shield"
  SMARTBUFF_HORNOFWINTER      = GetSpellInfo(57330); --"Horn of Winter"
  SMARTBUFF_RAISEDEAD         = GetSpellInfo(46584); --"Raise Dead"
--  SMARTBUFF_POTGRAVE          = GetSpellInfo(155522); --"Power of the Grave" (P)
  -- Death Knight buff links
  S.ChainDKPresence = { SMARTBUFF_BLOODPRESENCE, SMARTBUFF_FROSTPRESENCE, SMARTBUFF_UNHOLYPRESENCE };

  -- Monk
--  SMARTBUFF_LOTWT           = GetSpellInfo(116781); --"Legacy of the White Tiger"
--  SMARTBUFF_LOTE            = GetSpellInfo(115921); --"Legacy of the Emperor"
  SMARTBUFF_BLACKOX         = GetSpellInfo(115315); --"Summon Black Ox Statue"
  SMARTBUFF_JADESERPENT     = GetSpellInfo(115313); --"Summon Jade Serpent Statue"
  SMARTBUFF_SOTFIERCETIGER  = GetSpellInfo(103985); --"Stance of the Fierce Tiger"
  SMARTBUFF_SOTSTURDYOX     = GetSpellInfo(115069); --"Stagger"
--  SMARTBUFF_SOTWISESERPENT  = GetSpellInfo(115070); --"Stance of the Wise Serpent"
--  SMARTBUFF_SOTSPIRITEDCRANE= GetSpellInfo(154436); --"Stance of the Spirited Crane"

  -- Monk buff links
  S.ChainMonkStatue = { SMARTBUFF_BLACKOX, SMARTBUFF_JADESERPENT };
  S.ChainMonkStance = { SMARTBUFF_SOTFIERCETIGER, SMARTBUFF_SOTSTURDYOX, SMARTBUFF_SOTWISESERPENT, SMARTBUFF_SOTSPIRITEDCRANE };

  -- Evoker
  SMARTBUFF_BRONZEBLESSING  = GetSpellInfo(364342);   --"Blessing of the Bronze"
  SMARTBUFF_Visage          = GetSpellInfo(351239);   --"Visage"

  SMARTBUFF_SourceOfMagic   = GetSpellInfo(369459);   --"Source of Magic"
  SMARTBUFF_EbonMight       = GetSpellInfo(395152);   --"Ebon Might"
  SMARTBUFF_BlisteringScale = GetSpellInfo(360827);   --"Blistering Scales"
  SMARTBUFF_Timelessness    = GetSpellInfo(412710);   --"Timelessness"

  -- Demon Hunter


  -- Tracking
  SMARTBUFF_FINDMINERALS    = GetSpellInfo(2580);  --"Find Minerals"
  SMARTBUFF_FINDHERBS       = GetSpellInfo(2383);  --"Find Herbs"
  SMARTBUFF_FINDTREASURE    = GetSpellInfo(2481);  --"Find Treasure"
  SMARTBUFF_TRACKHUMANOIDS  = GetSpellInfo(19883); --"Track Humanoids"
  SMARTBUFF_TRACKBEASTS     = GetSpellInfo(1494);  --"Track Beasts"
  SMARTBUFF_TRACKUNDEAD     = GetSpellInfo(19884); --"Track Undead"
  SMARTBUFF_TRACKHIDDEN     = GetSpellInfo(19885); --"Track Hidden"
  SMARTBUFF_TRACKELEMENTALS = GetSpellInfo(19880); --"Track Elementals"
  SMARTBUFF_TRACKDEMONS     = GetSpellInfo(19878); --"Track Demons"
  SMARTBUFF_TRACKGIANTS     = GetSpellInfo(19882); --"Track Giants"
  SMARTBUFF_TRACKDRAGONKIN  = GetSpellInfo(19879); --"Track Dragonkin"

  -- Racial
  SMARTBUFF_STONEFORM       = GetSpellInfo(20594); --"Stoneform"
  SMARTBUFF_BLOODFURY       = GetSpellInfo(20572); --"Blood Fury" 33697, 33702
  SMARTBUFF_BERSERKING      = GetSpellInfo(26297); --"Berserking"
  SMARTBUFF_WOTFORSAKEN     = GetSpellInfo(7744);  --"Will of the Forsaken"
  SMARTBUFF_WarStomp        = GetSpellInfo(20549); --"War Stomp"

  -- Food
  SMARTBUFF_FOOD_AURA       = GetSpellInfo(46899); --"Well Fed"
  SMARTBUFF_FOOD_SPELL      = GetSpellInfo(433);   --"Food"
  SMARTBUFF_DRINK_SPELL     = GetSpellInfo(430);   --"Drink"

  -- Misc
  SMARTBUFF_KIRUSSOV        = GetSpellInfo(46302); --"K'iru's Song of Victory"
  SMARTBUFF_FISHING         = GetSpellInfo(7620) or GetSpellInfo(111541); --"Fishing"

  -- Scroll
  SMARTBUFF_SBAGILITY       = GetSpellInfo(8115);   --"Scroll buff: Agility"
  SMARTBUFF_SBINTELLECT     = GetSpellInfo(8096);   --"Scroll buff: Intellect"
  SMARTBUFF_SBSTAMINA       = GetSpellInfo(8099);   --"Scroll buff: Stamina"
  SMARTBUFF_SBSPIRIT        = GetSpellInfo(8112);   --"Scroll buff: Spirit"
  SMARTBUFF_SBSTRENGHT      = GetSpellInfo(8118);   --"Scroll buff: Strength"
  SMARTBUFF_SBPROTECTION    = GetSpellInfo(89344);  --"Scroll buff: Armor"
  SMARTBUFF_BMiscItem1      = GetSpellInfo(326396); --"WoW's 16th Anniversary"
  SMARTBUFF_BMiscItem2      = GetSpellInfo(62574);  --"Warts-B-Gone Lip Balm"
  SMARTBUFF_BMiscItem3      = GetSpellInfo(98444);  --"Vrykul Drinking Horn"
  SMARTBUFF_BMiscItem4      = GetSpellInfo(127230); --"Visions of Insanity"
  SMARTBUFF_BMiscItem5      = GetSpellInfo(124036); --"Anglers Fishing Raft"
  SMARTBUFF_BMiscItem6      = GetSpellInfo(125167); --"Ancient Pandaren Fishing Charm"
  SMARTBUFF_BMiscItem7      = GetSpellInfo(138927); --"Burning Essence"
  SMARTBUFF_BMiscItem8      = GetSpellInfo(160331); --"Blood Elf Illusion"
  SMARTBUFF_BMiscItem9      = GetSpellInfo(158486); --"Safari Hat"
  SMARTBUFF_BMiscItem10     = GetSpellInfo(158474); --"Savage Safari Hat"
  SMARTBUFF_BMiscItem11     = GetSpellInfo(176151); --"Whispers of Insanity"
  SMARTBUFF_BMiscItem12     = GetSpellInfo(193456); --"Gaze of the Legion"
  SMARTBUFF_BMiscItem13     = GetSpellInfo(193547); --"Fel Crystal Infusion"
  SMARTBUFF_BMiscItem14     = GetSpellInfo(190668); --"Empower"
  SMARTBUFF_BMiscItem14_1   = GetSpellInfo(175457); --"Focus Augmentation"
  SMARTBUFF_BMiscItem14_2   = GetSpellInfo(175456); --"Hyper Augmentation"
  SMARTBUFF_BMiscItem14_3   = GetSpellInfo(175439); --"Stout Augmentation
  SMARTBUFF_BMiscItem16     = GetSpellInfo(181642); --"Bodyguard Miniaturization Device"
  SMARTBUFF_BMiscItem17     = GetSpellInfo(242551); --"Fel Focus"
  -- Shadowlands
  SMARTBUFF_BAugmentRune    = GetSpellInfo(367405); --"Eternal Augmentation from Eternal Augment Rune"
  SMARTBUFF_BVieledAugment  = GetSpellInfo(347901); --"Veiled Augmentation from Veiled Augment Rune"
  -- Dragonflight
  SMARTBUFF_BDraconicRune   = GetSpellInfo(393438); -- Draconic Augmentation from Draconic Augment Rune
  SMARTBUFF_BVantusRune_VotI_q1 = GetSpellInfo(384154); -- Vantus Rune: Vault of the Incarnates (Quality 1)
  SMARTBUFF_BVantusRune_VotI_q2 = GetSpellInfo(384248); -- Vantus Rune: Vault of the Incarnates (Quality 2)
  SMARTBUFF_BVantusRune_VotI_q3 = GetSpellInfo(384306); -- Vantus Rune: Vault of the Incarnates (Quality 3)

  S.LinkSafariHat           = { SMARTBUFF_BMiscItem9, SMARTBUFF_BMiscItem10 };
  S.LinkAugment             = { SMARTBUFF_BMiscItem14, SMARTBUFF_BMiscItem14_1, SMARTBUFF_BMiscItem14_2, SMARTBUFF_BMiscItem14_3, SMARTBUFF_BAugmentRune,  SMARTBUFF_BVieledAugment, SMARTBUFF_BDraconicRune };

  -- Flasks & Elixirs
  SMARTBUFF_BFLASKTBC1      = GetSpellInfo(28520);  --"Flask of Relentless Assault"
  SMARTBUFF_BFLASKTBC2      = GetSpellInfo(28540);  --"Flask of Pure Death"
  SMARTBUFF_BFLASKTBC3      = GetSpellInfo(28518);  --"Flask of Fortification"
  SMARTBUFF_BFLASKTBC4      = GetSpellInfo(28521);  --"Flask of Blinding Light"
  SMARTBUFF_BFLASKTBC5      = GetSpellInfo(28519);  --"Flask of Mighty Versatility"
  SMARTBUFF_BFLASK1         = GetSpellInfo(53760);  --"Flask of Endless Rage"
  SMARTBUFF_BFLASK2         = GetSpellInfo(53755);  --"Flask of the Frost Wyrm"
  SMARTBUFF_BFLASK3         = GetSpellInfo(53758);  --"Flask of Stoneblood"
  SMARTBUFF_BFLASK4         = GetSpellInfo(54212);  --"Flask of Pure Mojo"
  SMARTBUFF_BFLASKCT1       = GetSpellInfo(79471);  --"Flask of the Winds"
  SMARTBUFF_BFLASKCT2       = GetSpellInfo(79472);  --"Flask of Titanic Strength"
  SMARTBUFF_BFLASKCT3       = GetSpellInfo(79470);  --"Flask of the Draconic Mind"
  SMARTBUFF_BFLASKCT4       = GetSpellInfo(79469);  --"Flask of Steelskin"
  SMARTBUFF_BFLASKCT5       = GetSpellInfo(94160);  --"Flask of Flowing Water"
  SMARTBUFF_BFLASKCT7       = GetSpellInfo(92679);  --"Flask of Battle"
  SMARTBUFF_BFLASKMOP1      = GetSpellInfo(105617); --"Alchemist's Flask"
  SMARTBUFF_BFLASKMOP2      = GetSpellInfo(105694); --"Flask of the Earth"
  SMARTBUFF_BFLASKMOP3      = GetSpellInfo(105693); --"Flask of Falling Leaves"
  SMARTBUFF_BFLASKMOP4      = GetSpellInfo(105689); --"Flask of Spring Blossoms"
  SMARTBUFF_BFLASKMOP5      = GetSpellInfo(105691); --"Flask of the Warm Sun"
  SMARTBUFF_BFLASKMOP6      = GetSpellInfo(105696); --"Flask of Winter's Bite"
  SMARTBUFF_BFLASKCT61      = GetSpellInfo(79640);  --"Enhanced Intellect"
  SMARTBUFF_BFLASKCT62      = GetSpellInfo(79639);  --"Enhanced Agility"
  SMARTBUFF_BFLASKCT63      = GetSpellInfo(79638);  --"Enhanced Strength"
  SMARTBUFF_BFLASKWOD1      = GetSpellInfo(156077); --"Draenic Stamina Flask"
  SMARTBUFF_BFLASKWOD2      = GetSpellInfo(156071); --"Draenic Strength Flask"
  SMARTBUFF_BFLASKWOD3      = GetSpellInfo(156070); --"Draenic Intellect Flask"
  SMARTBUFF_BFLASKWOD4      = GetSpellInfo(156073); --"Draenic Agility Flask"
  SMARTBUFF_BGRFLASKWOD1    = GetSpellInfo(156084); --"Greater Draenic Stamina Flask"
  SMARTBUFF_BGRFLASKWOD2    = GetSpellInfo(156080); --"Greater Draenic Strength Flask"
  SMARTBUFF_BGRFLASKWOD3    = GetSpellInfo(156079); --"Greater Draenic Intellect Flask"
  SMARTBUFF_BGRFLASKWOD4    = GetSpellInfo(156064); --"Greater Draenic Agility Flask"
  SMARTBUFF_BFLASKLEG1      = GetSpellInfo(188035); --"Flask of Ten Thousand Scars"
  SMARTBUFF_BFLASKLEG2      = GetSpellInfo(188034); --"Flask of the Countless Armies"
  SMARTBUFF_BFLASKLEG3      = GetSpellInfo(188031); --"Flask of the Whispered Pact"
  SMARTBUFF_BFLASKLEG4      = GetSpellInfo(188033); --"Flask of the Seventh Demon"
  SMARTBUFF_BFLASKBFA1      = GetSpellInfo(251837); --"Flask of Endless Fathoms"
  SMARTBUFF_BFLASKBFA2      = GetSpellInfo(251836); --"Flask of the Currents"
  SMARTBUFF_BFLASKBFA3      = GetSpellInfo(251839); --"Flask of the Undertow"
  SMARTBUFF_BFLASKBFA4      = GetSpellInfo(251838); --"Flask of the Vast Horizon"
  SMARTBUFF_BGRFLASKBFA1    = GetSpellInfo(298837); --"Greather Flask of Endless Fathoms"
  SMARTBUFF_BGRFLASKBFA2    = GetSpellInfo(298836); --"Greater Flask of the Currents"
  SMARTBUFF_BGRFLASKBFA3    = GetSpellInfo(298841); --"Greather Flask of teh Untertow"
  SMARTBUFF_BGRFLASKBFA4    = GetSpellInfo(298839); --"Greater Flask of the Vast Horizon"
  SMARTBUFF_BFLASKSL1       = GetSpellInfo(307185); --"Spectral Flask of Power"
  SMARTBUFF_BFLASKSL2       = GetSpellInfo(307187); --"Spectral Flask of Stamina"
  -- Dragonflight
  SMARTBUFF_BFlaskDF1      = GetSpellInfo(371345); -- Phial of the Eye in the Storm
  SMARTBUFF_BFlaskDF2      = GetSpellInfo(371204); -- Phial of Still Air
  SMARTBUFF_BFlaskDF3      = GetSpellInfo(371036); -- Phial of Icy Preservation
  SMARTBUFF_BFlaskDF4      = GetSpellInfo(374000); -- Iced Phial of Corrupting Rage
  SMARTBUFF_BFlaskDF5      = GetSpellInfo(371386); -- Phial of Charged Isolation
  SMARTBUFF_BFlaskDF6      = GetSpellInfo(373257); -- Phial of Glacial Fury
  SMARTBUFF_BFlaskDF7      = GetSpellInfo(370652); -- Phial of Static Empowerment
  SMARTBUFF_BFlaskDF8      = GetSpellInfo(371172); -- Phial of Tepid Versatility
  SMARTBUFF_BFlaskDF9      = GetSpellInfo(393700); -- Aerated Phial of Deftness
  SMARTBUFF_BFlaskDF10     = GetSpellInfo(393717); -- Steaming Phial of Finesse
  SMARTBUFF_BFlaskDF11     = GetSpellInfo(371186); -- Charged Phial of Alacrity
  SMARTBUFF_BFlaskDF12     = GetSpellInfo(393714); -- Crystalline Phial of Perception
  -- the Phial of Elemental Chaos gives 1 the following 4 random buffs every 60 seconds
  SMARTBUFF_BFlaskDF13_1   = GetSpellInfo(371348); -- Elemental Chaos: Fire
  SMARTBUFF_BFlaskDF13_2   = GetSpellInfo(371350); -- Elemental Chaos: Air
  SMARTBUFF_BFlaskDF13_3   = GetSpellInfo(371351); -- Elemental Chaos: Earth
  SMARTBUFF_BFlaskDF13_4   = GetSpellInfo(371353); -- Elemental Chaos: Frost
  SMARTBUFF_BFlaskDF14     = GetSpellInfo(393665); -- Aerated Phial of Quick Hands

  S.LinkFlaskTBC            = { SMARTBUFF_BFLASKTBC1, SMARTBUFF_BFLASKTBC2, SMARTBUFF_BFLASKTBC3, SMARTBUFF_BFLASKTBC4, SMARTBUFF_BFLASKTBC5 };
  S.LinkFlaskCT7            = { SMARTBUFF_BFLASKCT1, SMARTBUFF_BFLASKCT2, SMARTBUFF_BFLASKCT3, SMARTBUFF_BFLASKCT4, SMARTBUFF_BFLASKCT5 };
  S.LinkFlaskMoP            = { SMARTBUFF_BFLASKCT61, SMARTBUFF_BFLASKCT62, SMARTBUFF_BFLASKCT63, SMARTBUFF_BFLASKMOP2, SMARTBUFF_BFLASKMOP3, SMARTBUFF_BFLASKMOP4, SMARTBUFF_BFLASKMOP5, SMARTBUFF_BFLASKMOP6 };
  S.LinkFlaskWoD            = { SMARTBUFF_BFLASKWOD1, SMARTBUFF_BFLASKWOD2, SMARTBUFF_BFLASKWOD3, SMARTBUFF_BFLASKWOD4, SMARTBUFF_BGRFLASKWOD1, SMARTBUFF_BGRFLASKWOD2, SMARTBUFF_BGRFLASKWOD3, SMARTBUFF_BGRFLASKWOD4 };
  S.LinkFlaskLeg            = { SMARTBUFF_BFLASKLEG1, SMARTBUFF_BFLASKLEG2, SMARTBUFF_BFLASKLEG3, SMARTBUFF_BFLASKLEG4 };
  S.LinkFlaskBfA            = { SMARTBUFF_BFLASKBFA1, SMARTBUFF_BFLASKBFA2, SMARTBUFF_BFLASKBFA3, SMARTBUFF_BFLASKBFA4, SMARTBUFF_BGRFLASKBFA1, SMARTBUFF_BGRFLASKBFA2, SMARTBUFF_BGRFLASKBFA3, SMARTBUFF_BGRFLASKBFA4 };
  S.LinkFlaskSL             = { SMARTBUFF_BFLASKSL1, SMARTBUFF_BFLASKSL2 };
  S.LinkFlaskDF             = { SMARTBUFF_BFlaskDF1, SMARTBUFF_BFlaskDF2, SMARTBUFF_BFlaskDF3, SMARTBUFF_BFlaskDF4, SMARTBUFF_BFlaskDF5, SMARTBUFF_BFlaskDF6, SMARTBUFF_BFlaskDF7, SMARTBUFF_BFlaskDF8, SMARTBUFF_BFlaskDF9, SMARTBUFF_BFlaskDF10, SMARTBUFF_BFlaskDF11, SMARTBUFF_BFlaskDF12, SMARTBUFF_BFlaskDF13_1, SMARTBUFF_BFlaskDF13_2, SMARTBUFF_BFlaskDF13_3, SMARTBUFF_BFlaskDF13_4, SMARTBUFF_BFlaskDF14 };

  SMARTBUFF_BELIXIRTBC1     = GetSpellInfo(54494);  --"Major Agility" B
  SMARTBUFF_BELIXIRTBC2     = GetSpellInfo(33726);  --"Mastery" B
  SMARTBUFF_BELIXIRTBC3     = GetSpellInfo(28491);  --"Healing Power" B
  SMARTBUFF_BELIXIRTBC4     = GetSpellInfo(28502);  --"Major Defense" G
  SMARTBUFF_BELIXIRTBC5     = GetSpellInfo(28490);  --"Major Strength" B
  SMARTBUFF_BELIXIRTBC6     = GetSpellInfo(39625);  --"Major Fortitude" G
  SMARTBUFF_BELIXIRTBC7     = GetSpellInfo(28509);  --"Major Mageblood" B
  SMARTBUFF_BELIXIRTBC8     = GetSpellInfo(39627);  --"Draenic Wisdom" B
  SMARTBUFF_BELIXIRTBC9     = GetSpellInfo(54452);  --"Adept's Elixir" B
  SMARTBUFF_BELIXIRTBC10    = GetSpellInfo(134870); --"Empowerment" B
  SMARTBUFF_BELIXIRTBC11    = GetSpellInfo(33720);  --"Onslaught Elixir" B
  SMARTBUFF_BELIXIRTBC12    = GetSpellInfo(28503);  --"Major Shadow Power" B
  SMARTBUFF_BELIXIRTBC13    = GetSpellInfo(39628);  --"Ironskin" G
  SMARTBUFF_BELIXIRTBC14    = GetSpellInfo(39626);  --"Earthen Elixir" G
  SMARTBUFF_BELIXIRTBC15    = GetSpellInfo(28493);  --"Major Frost Power" B
  SMARTBUFF_BELIXIRTBC16    = GetSpellInfo(38954);  --"Fel Strength Elixir" B
  SMARTBUFF_BELIXIRTBC17    = GetSpellInfo(28501);  --"Major Firepower" B
  SMARTBUFF_BELIXIR1        = GetSpellInfo(28497);  --"Mighty Agility" B
  SMARTBUFF_BELIXIR2        = GetSpellInfo(60347);  --"Mighty Thoughts" G
  SMARTBUFF_BELIXIR3        = GetSpellInfo(53751);  --"Elixir of Mighty Fortitude" G
  SMARTBUFF_BELIXIR4        = GetSpellInfo(53748);  --"Mighty Strength" B
  SMARTBUFF_BELIXIR5        = GetSpellInfo(53747);  --"Elixir of Spirit" B
  SMARTBUFF_BELIXIR6        = GetSpellInfo(53763);  --"Protection" G
  SMARTBUFF_BELIXIR7        = GetSpellInfo(60343);  --"Mighty Defense" G
  SMARTBUFF_BELIXIR8        = GetSpellInfo(60346);  --"Lightning Speed" B
  SMARTBUFF_BELIXIR9        = GetSpellInfo(60344);  --"Expertise" B
  SMARTBUFF_BELIXIR10       = GetSpellInfo(60341);  --"Deadly Strikes" B
  SMARTBUFF_BELIXIR11       = GetSpellInfo(80532);  --"Armor Piercing"
  SMARTBUFF_BELIXIR12       = GetSpellInfo(60340);  --"Accuracy" B
  SMARTBUFF_BELIXIR13       = GetSpellInfo(53749);  --"Guru's Elixir" B
  SMARTBUFF_BELIXIR14       = GetSpellInfo(11334);  --"Elixir of Greater Agility" B
  SMARTBUFF_BELIXIR15       = GetSpellInfo(54452);  --"Adept's Elixir" B
  SMARTBUFF_BELIXIR16       = GetSpellInfo(33721);  --"Spellpower Elixir" B
  SMARTBUFF_BELIXIRCT1      = GetSpellInfo(79635);  --"Elixir of the Master" B
  SMARTBUFF_BELIXIRCT2      = GetSpellInfo(79632);  --"Elixir of Mighty Speed" B
  SMARTBUFF_BELIXIRCT3      = GetSpellInfo(79481);  --"Elixir of Impossible Accuracy" B
  SMARTBUFF_BELIXIRCT4      = GetSpellInfo(79631);  --"Prismatic Elixir" G
  SMARTBUFF_BELIXIRCT5      = GetSpellInfo(79480);  --"Elixir of Deep Earth" G
  SMARTBUFF_BELIXIRCT6      = GetSpellInfo(79477);  --"Elixir of the Cobra" B
  SMARTBUFF_BELIXIRCT7      = GetSpellInfo(79474);  --"Elixir of the Naga" B
  SMARTBUFF_BELIXIRCT8      = GetSpellInfo(79468);  --"Ghost Elixir" B
  SMARTBUFF_BELIXIRMOP1     = GetSpellInfo(105687); --"Elixir of Mirrors" G
  SMARTBUFF_BELIXIRMOP2     = GetSpellInfo(105685); --"Elixir of Peace" B
  SMARTBUFF_BELIXIRMOP3     = GetSpellInfo(105686); --"Elixir of Perfection" B
  SMARTBUFF_BELIXIRMOP4     = GetSpellInfo(105684); --"Elixir of the Rapids" B
  SMARTBUFF_BELIXIRMOP5     = GetSpellInfo(105683); --"Elixir of Weaponry" B
  SMARTBUFF_BELIXIRMOP6     = GetSpellInfo(105682); --"Mad Hozen Elixir" B
  SMARTBUFF_BELIXIRMOP7     = GetSpellInfo(105681); --"Mantid Elixir" G
  SMARTBUFF_BELIXIRMOP8     = GetSpellInfo(105688); --"Monk's Elixir" B
  -- Draught of Ten Lands
  SMARTBUFF_BEXP_POTION     = GetSpellInfo(289982); --Draught of Ten Lands

  --if (SMARTBUFF_GOTW) then
  --  SMARTBUFF_AddMsgD(SMARTBUFF_GOTW.." found");
  --end

  -- Buff map
  S.LinkStats = { SMARTBUFF_BOK, SMARTBUFF_MOTW, SMARTBUFF_LOTE, SMARTBUFF_LOTWT,
                  GetSpellInfo(159988), -- Bark of the Wild
                  GetSpellInfo(203538), -- Greater Blessing of Kings
                  GetSpellInfo(90363),  -- Embrace of the Shale Spider
                  GetSpellInfo(160077)  -- Strength of the Earth
                };

  S.LinkSta   = { SMARTBUFF_PWF, SMARTBUFF_COMMANDINGSHOUT, SMARTBUFF_BLOODPACT,
                  GetSpellInfo(50256),  -- Invigorating Roar
                  GetSpellInfo(90364),  -- Qiraji Fortitude
                  GetSpellInfo(160014), -- Sturdiness
                  GetSpellInfo(160003)  -- Savage Vigor
                };

  S.LinkAp    = { SMARTBUFF_HORNOFWINTER, SMARTBUFF_BATTLESHOUT, SMARTBUFF_TRUESHOTAURA };

  S.LinkMa    = { SMARTBUFF_BOM, SMARTBUFF_DRUID_MKAURA, SMARTBUFF_GRACEOFAIR, SMARTBUFF_POTGRAVE,
                  GetSpellInfo(93435),  -- Roar of Courage
                  GetSpellInfo(160039), -- Keen Senses
                  GetSpellInfo(128997), -- Spirit Beast Blessing
                  GetSpellInfo(160073)  -- Plainswalking
                };

  S.LinkInt   = { SMARTBUFF_BOW, SMARTBUFF_AB, SMARTBUFF_DALARANB };

  --S.LinkSp    = { SMARTBUFF_DARKINTENT, SMARTBUFF_AB, SMARTBUFF_DALARANB, SMARTBUFF_STILLWATER };

  --SMARTBUFF_AddMsgD("Spell IDs initialized");
end


function SMARTBUFF_InitSpellList()
  if (SMARTBUFF_PLAYERCLASS == nil) then return; end

  --if (SMARTBUFF_GOTW) then
  --  SMARTBUFF_AddMsgD(SMARTBUFF_GOTW.." found");
  --end

  -- Druid
  if (SMARTBUFF_PLAYERCLASS == "DRUID") then
    SMARTBUFF_BUFFLIST = {
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
    SMARTBUFF_BUFFLIST = {
      {SMARTBUFF_SHADOWFORM, -1, SMARTBUFF_CONST_SELF},
      {SMARTBUFF_VAMPIRICEMBRACE, 30, SMARTBUFF_CONST_SELF},
      {SMARTBUFF_PWF, 60, SMARTBUFF_CONST_GROUP, {14}, "HPET;WPET;DKPET", S.LinkSta},
      {SMARTBUFF_PWS, 0.5, SMARTBUFF_CONST_GROUP, {6}, "MAGE;WARLOCK;ROGUE;PALADIN;WARRIOR;DRUID;HUNTER;SHAMAN;DEATHKNIGHT;MONK;DEMONHUNTER;EVOKER;HPET;WPET;DKPET"},
      {SMARTBUFF_FEARWARD, 3, SMARTBUFF_CONST_GROUP, {54}, "HPET;WPET;DKPET"},
      {SMARTBUFF_LEVITATE, 2, SMARTBUFF_CONST_GROUP, {34}, "HPET;WPET;DKPET"},
      {SMARTBUFF_CHAKRA1, 0.5, SMARTBUFF_CONST_SELF, nil, nil, S.LinkPriestChakra},
      {SMARTBUFF_CHAKRA2, 0.5, SMARTBUFF_CONST_SELF, nil, nil, S.LinkPriestChakra},
      {SMARTBUFF_CHAKRA3, 0.5, SMARTBUFF_CONST_SELF, nil, nil, S.LinkPriestChakra},
      {SMARTBUFF_LIGHTWELL, 3, SMARTBUFF_CONST_SELF}
    };
  end

  -- Mage
  if (SMARTBUFF_PLAYERCLASS == "MAGE") then
    SMARTBUFF_BUFFLIST = {
      {SMARTBUFF_AB, 60, SMARTBUFF_CONST_GROUP, {1,14,28,42,56,70,80}, nil, S.LinkInt, S.LinkInt},
      {SMARTBUFF_DALARANB, 60, SMARTBUFF_CONST_GROUP, {80,80,80,80,80,80,80}, nil, S.LinkInt, S.LinkInt},
      {SMARTBUFF_TEMPSHIELD, 0.067, SMARTBUFF_CONST_SELF},
      {SMARTBUFF_AMPMAGIC, 0.1, SMARTBUFF_CONST_SELF},
      {SMARTBUFF_SUMMONWATERELE, -1, SMARTBUFF_CONST_SELF, nil, S.CheckPet},
      {SMARTBUFF_FROSTARMOR, -1, SMARTBUFF_CONST_SELF, nil, nil, nil, S.ChainMageArmor},
      {SMARTBUFF_MAGEARMOR, -1, SMARTBUFF_CONST_SELF, nil, nil, nil, S.ChainMageArmor},
      {SMARTBUFF_MOLTENARMOR, -1, SMARTBUFF_CONST_SELF, nil, nil, nil, S.ChainMageArmor},
      {SMARTBUFF_SLOWFALL, 0.5, SMARTBUFF_CONST_GROUP, {32}, "HPET;WPET;DKPET"},
      {SMARTBUFF_MANASHIELD, 0.5, SMARTBUFF_CONST_SELF},
      {SMARTBUFF_ICEWARD, 0.5, SMARTBUFF_CONST_GROUP, {45}, "HPET;WPET;DKPET"},
      {SMARTBUFF_ICEBARRIER, 1, SMARTBUFF_CONST_SELF},
      {SMARTBUFF_COMBUSTION, -1, SMARTBUFF_CONST_SELF},
      {SMARTBUFF_ICYVEINS, 0.333, SMARTBUFF_CONST_SELF},
	  {SMARTBUFF_ARCANEFAMILIAR, 60, SMARTBUFF_CONST_SELF},
      {SMARTBUFF_ARCANEPOWER, 0.25, SMARTBUFF_CONST_SELF},
      {SMARTBUFF_PRESENCEOFMIND, 0.165, SMARTBUFF_CONST_SELF},
	  {SMARTBUFF_PRISBARRIER, 1, SMARTBUFF_CONST_SELF},
      {SMARTBUFF_IMPPRISBARRIER, 1, SMARTBUFF_CONST_SELF},
      {SMARTBUFF_BLAZBARRIER, 1, SMARTBUFF_CONST_SELF},
      {SMARTBUFF_REFRESHMENT, 0.03, SMARTBUFF_CONST_ITEM, nil, SMARTBUFF_CONJUREDMANA, nil, S.FoodMage},
	  {SMARTBUFF_CREATEMG, 0.03, SMARTBUFF_CONST_ITEM, nil, SMARTBUFF_MANAGEM},
--	  {SMARTBUFF_ARCANEINTELLECT, 60, SMARTBUFF_CONST_GROUP, {32}, "HPET;WPET;DKPET"}
    };
  end

  -- Warlock
  if (SMARTBUFF_PLAYERCLASS == "WARLOCK") then
    SMARTBUFF_BUFFLIST = {
      {SMARTBUFF_DEMONARMOR, -1, SMARTBUFF_CONST_SELF},
      {SMARTBUFF_AMPLIFYCURSE, 1, SMARTBUFF_CONST_SELF},
      {SMARTBUFF_INQUISITORGAZE, 60, SMARTBUFF_CONST_SELF},
      {SMARTBUFF_DARKINTENT, 60, SMARTBUFF_CONST_GROUP, nil, "WARRIOR;HUNTER;ROGUE"},
      {SMARTBUFF_SOULLINK, -1, SMARTBUFF_CONST_SELF, nil, S.CheckPetNeeded},
      {SMARTBUFF_UNENDINGBREATH, 10, SMARTBUFF_CONST_GROUP, {16}, "HPET;WPET;DKPET"},
      {SMARTBUFF_LIFETAP, 0.025, SMARTBUFF_CONST_SELF},
      {SMARTBUFF_GOSACRIFICE, 60, SMARTBUFF_CONST_SELF, nil, S.CheckPetNeeded},
      {SMARTBUFF_BLOODHORROR, 1, SMARTBUFF_CONST_SELF},
      {SMARTBUFF_SOULSTONE, 15, SMARTBUFF_CONST_GROUP, {18}, "WARRIOR;DRUID;SHAMAN;HUNTER;ROGUE;MAGE;PRIEST;PALADIN;WARLOCK;DEATHKNIGHT;EVOKER;MONK;DEMONHUNTER;HPET;WPET;DKPET"},
      {SMARTBUFF_CREATEHS, 0.03, SMARTBUFF_CONST_ITEM, nil, SMARTBUFF_HEALTHSTONE},
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
    SMARTBUFF_BUFFLIST = {
      {SMARTBUFF_RAPIDFIRE, 0.2, SMARTBUFF_CONST_SELF},
      {SMARTBUFF_FOCUSFIRE, 0.25, SMARTBUFF_CONST_SELF},
      {SMARTBUFF_TRAPLAUNCHER, -1, SMARTBUFF_CONST_SELF},
      {SMARTBUFF_VOLLEY, -1, SMARTBUFF_CONST_SELF},
      {SMARTBUFF_CAMOFLAUGE, 1, SMARTBUFF_CONST_SELF},
      {SMARTBUFF_AMMOI, 60, SMARTBUFF_CONST_SELF, nil, nil, S.LinkAmmo},
      {SMARTBUFF_AMMOP, 60, SMARTBUFF_CONST_SELF, nil, nil, S.LinkAmmo},
      {SMARTBUFF_AMMOF, 60, SMARTBUFF_CONST_SELF, nil, nil, S.LinkAmmo},
      {SMARTBUFF_LW1, -1, SMARTBUFF_CONST_SELF, nil, nil, S.LinkLoneWolf},
      {SMARTBUFF_LW2, -1, SMARTBUFF_CONST_SELF, nil, nil, S.LinkLoneWolf},
      {SMARTBUFF_LW3, -1, SMARTBUFF_CONST_SELF, nil, nil, S.LinkLoneWolf},
      {SMARTBUFF_LW4, -1, SMARTBUFF_CONST_SELF, nil, nil, S.LinkLoneWolf},
      {SMARTBUFF_LW5, -1, SMARTBUFF_CONST_SELF, nil, nil, S.LinkLoneWolf},
      {SMARTBUFF_LW6, -1, SMARTBUFF_CONST_SELF, nil, nil, S.LinkLoneWolf},
      {SMARTBUFF_LW7, -1, SMARTBUFF_CONST_SELF, nil, nil, S.LinkLoneWolf},
      {SMARTBUFF_LW8, -1, SMARTBUFF_CONST_SELF, nil, nil, S.LinkLoneWolf},
      {SMARTBUFF_AOTF, 0.1, SMARTBUFF_CONST_SELF, nil, nil, S.LinkAspects},
      {SMARTBUFF_AOTC, -1, SMARTBUFF_CONST_SELF, nil, nil, S.LinkAspects},
      {SMARTBUFF_AOTP, -1, SMARTBUFF_CONST_SELF, nil, nil, S.LinkAspects},
      {SMARTBUFF_AOTW, -1, SMARTBUFF_CONST_SELF, nil, nil, S.LinkAspects},
      {SMARTBUFF_CALL_PET_1, -1, SMARTBUFF_CONST_SELF, nil, S.CheckPet},
      {SMARTBUFF_CALL_PET_2, -1, SMARTBUFF_CONST_SELF, nil, S.CheckPet},
      {SMARTBUFF_CALL_PET_3, -1, SMARTBUFF_CONST_SELF, nil, S.CheckPet},
      {SMARTBUFF_CALL_PET_4, -1, SMARTBUFF_CONST_SELF, nil, S.CheckPet},
      {SMARTBUFF_CALL_PET_5, -1, SMARTBUFF_CONST_SELF, nil, S.CheckPet},
    };
  end

  -- Shaman
  if (SMARTBUFF_PLAYERCLASS == "SHAMAN") then
    SMARTBUFF_BUFFLIST = {
      {SMARTBUFF_LIGHTNINGSHIELD, 60, SMARTBUFF_CONST_SELF, nil, nil, nil, S.ChainShamanShield},
      {SMARTBUFF_WATERSHIELD, 60, SMARTBUFF_CONST_SELF, nil, nil, nil, S.ChainShamanShield},
      {SMARTBUFF_WINDFURYW, 60, SMARTBUFF_CONST_WEAPON},
      {SMARTBUFF_FLAMETONGUEW, 60, SMARTBUFF_CONST_WEAPON},
      {SMARTBUFF_EVERLIVINGW, 60, SMARTBUFF_CONST_WEAPON},
      {SMARTBUFF_EARTHSHIELD, 10, SMARTBUFF_CONST_GROUP, {50,60,70,75,80}, "WARRIOR;DEATHKNIGHT;DRUID;SHAMAN;HUNTER;ROGUE;MAGE;PRIEST;PALADIN;WARLOCK;MONK;DEMONHUNTER;EVOKER;HPET;WPET;DKPET"},
      {SMARTBUFF_UNLEASHFLAME, 0.333, SMARTBUFF_CONST_SELF},
      {SMARTBUFF_ASCENDANCE_ELE, 0.25, SMARTBUFF_CONST_SELF},
      {SMARTBUFF_ASCENDANCE_ENH, 0.25, SMARTBUFF_CONST_SELF},
      {SMARTBUFF_ASCENDANCE_RES, 0.25, SMARTBUFF_CONST_SELF},
      {SMARTBUFF_EMASTERY, 0.5, SMARTBUFF_CONST_SELF},
      {SMARTBUFF_WATERWALKING, 10, SMARTBUFF_CONST_GROUP, {28}}
    };
  end

  -- Warrior
  if (SMARTBUFF_PLAYERCLASS == "WARRIOR") then
    SMARTBUFF_BUFFLIST = {
      {SMARTBUFF_BATTLESHOUT, 60, SMARTBUFF_CONST_SELF, nil, nil, S.LinkAp, S.ChainWarriorShout},
      {SMARTBUFF_COMMANDINGSHOUT, 60, SMARTBUFF_CONST_SELF, nil, nil, S.LinkSta, S.ChainWarriorShout},
      {SMARTBUFF_BERSERKERRAGE, 0.165, SMARTBUFF_CONST_SELF},
      {SMARTBUFF_SHIELDBLOCK, 0.1666, SMARTBUFF_CONST_SELF},
      {SMARTBUFF_BATSTANCE, -1, SMARTBUFF_CONST_SELF, nil, nil, nil, S.ChainWarriorStance},
      {SMARTBUFF_DEFSTANCE, -1, SMARTBUFF_CONST_SELF, nil, nil, nil, S.ChainWarriorStance},
      {SMARTBUFF_GLADSTANCE, -1, SMARTBUFF_CONST_SELF, nil, nil, nil, S.ChainWarriorStance}
    };
  end

  -- Rogue
  if (SMARTBUFF_PLAYERCLASS == "ROGUE") then
    SMARTBUFF_BUFFLIST = {
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
      {SMARTBUFF_AGONIZINGPOISON, 60, SMARTBUFF_CONST_SELF, nil, S.CheckFishingPole, nil, S.ChainRoguePoisonsLethal},
      {SMARTBUFF_LEECHINGPOISON, 60, SMARTBUFF_CONST_SELF, nil, S.CheckFishingPole, nil, S.ChainRoguePoisonsNonLethal},
      {SMARTBUFF_NUMBINGPOISON, 60, SMARTBUFF_CONST_SELF, nil, S.CheckFishingPole, nil, S.ChainRoguePoisonsNonLethal},
      {SMARTBUFF_CRIPPLINGPOISON, 60, SMARTBUFF_CONST_SELF, nil, S.CheckFishingPole, nil, S.ChainRoguePoisonsNonLethal},
      {SMARTBUFF_AMPLIFYPOISON, 60, SMARTBUFF_CONST_SELF, nil, S.CheckFishingPole, nil, S.ChainRoguePoisonsLethal},
      {SMARTBUFF_ATROPHICPOISON, 60, SMARTBUFF_CONST_SELF, nil, S.CheckFishingPole, nil, S.ChainRoguePoisonsNonLethal}
    };
  end

  -- Paladin
  if (SMARTBUFF_PLAYERCLASS == "PALADIN") then
    SMARTBUFF_BUFFLIST = {
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
      {SMARTBUFF_SOTRUTH, -1, SMARTBUFF_CONST_STANCE, nil, nil, nil, S.ChainPaladinSeal},
      {SMARTBUFF_SORIGHTEOUSNESS, -1, SMARTBUFF_CONST_STANCE, nil, nil, nil, S.ChainPaladinSeal},
      {SMARTBUFF_SOJUSTICE, -1, SMARTBUFF_CONST_STANCE, nil, nil, nil, S.ChainPaladinSeal},
      {SMARTBUFF_SOINSIGHT, -1, SMARTBUFF_CONST_STANCE, nil, nil, nil, S.ChainPaladinSeal},
      {SMARTBUFF_SOCOMMAND, -1, SMARTBUFF_CONST_STANCE, nil, nil, nil, S.ChainPaladinSeal}
    };
  end

  -- Deathknight
  if (SMARTBUFF_PLAYERCLASS == "DEATHKNIGHT") then
    SMARTBUFF_BUFFLIST = {
      {SMARTBUFF_DANCINGRW, 0.2, SMARTBUFF_CONST_SELF},
      {SMARTBUFF_BLOODPRESENCE, -1, SMARTBUFF_CONST_STANCE, nil, nil, nil, S.ChainDKPresence},
      {SMARTBUFF_FROSTPRESENCE, -1, SMARTBUFF_CONST_STANCE, nil, nil, nil, S.ChainDKPresence},
      {SMARTBUFF_UNHOLYPRESENCE, -1, SMARTBUFF_CONST_STANCE, nil, nil, nil, S.ChainDKPresence},
      {SMARTBUFF_HORNOFWINTER, 60, SMARTBUFF_CONST_SELF, nil, nil, S.LinkAp},
      {SMARTBUFF_BONESHIELD, 5, SMARTBUFF_CONST_SELF},
      {SMARTBUFF_RAISEDEAD, 1, SMARTBUFF_CONST_SELF, nil, S.CheckPet},
      {SMARTBUFF_PATHOFFROST, -1, SMARTBUFF_CONST_SELF}
    };
  end

  -- Monk
  if (SMARTBUFF_PLAYERCLASS == "MONK") then
    SMARTBUFF_BUFFLIST = {
      {SMARTBUFF_LOTWT, 60, SMARTBUFF_CONST_GROUP, {81}},
      {SMARTBUFF_LOTE, 60, SMARTBUFF_CONST_GROUP, {22}, nil, S.LinkStats},
      {SMARTBUFF_SOTFIERCETIGER, -1, SMARTBUFF_CONST_STANCE, nil, nil, nil, S.ChainMonkStance},
      {SMARTBUFF_SOTSTURDYOX, -1, SMARTBUFF_CONST_STANCE, nil, nil, nil, S.ChainMonkStance},
      {SMARTBUFF_SOTWISESERPENT, -1, SMARTBUFF_CONST_STANCE, nil, nil, nil, S.ChainMonkStance},
      {SMARTBUFF_SOTSPIRITEDCRANE, -1, SMARTBUFF_CONST_STANCE, nil, nil, nil, S.ChainMonkStance},
      {SMARTBUFF_BLACKOX, 15, SMARTBUFF_CONST_SELF, nil, nil, nil, S.ChainMonkStatue},
      {SMARTBUFF_SMARTBUFF_JADESERPENT, 15, SMARTBUFF_CONST_SELF, nil, nil, nil, S.ChainMonkStatue}
    };
  end

  -- Demon Hunter
  if (SMARTBUFF_PLAYERCLASS == "DEMONHUNTER") then
    SMARTBUFF_BUFFLIST = {
    };
  end

  -- Evoker
  if (SMARTBUFF_PLAYERCLASS == "EVOKER") then
    SMARTBUFF_BUFFLIST = {
      {SMARTBUFF_BRONZEBLESSING, 60, SMARTBUFF_CONST_SELF},
      {SMARTBUFF_Visage, -1, SMARTBUFF_CONST_SELF},
      {SMARTBUFF_Timelessness, 30, SMARTBUFF_CONST_GROUP, {1}, "WARRIOR;DRUID;SHAMAN;HUNTER;ROGUE;MAGE;PRIEST;PALADIN;WARLOCK;DEATHKNIGHT;MONK;DEMONHUNTER;EVOKER"},
      {SMARTBUFF_BlisteringScale, -1, SMARTBUFF_CONST_GROUP, {1}, "WARRIOR;DRUID;SHAMAN;HUNTER;ROGUE;MAGE;PRIEST;PALADIN;WARLOCK;DEATHKNIGHT;MONK;DEMONHUNTER;EVOKER"},
      {SMARTBUFF_SourceOfMagic, 30, SMARTBUFF_CONST_GROUP, {1}, "SHAMAN;PRIEST;PALADIN;MONK;EVOKER"},
      {SMARTBUFF_EbonMight, -1, SMARTBUFF_CONST_SELF},
    };
  end

  -- Stones and oils
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
    {SMARTBUFF_HowlingRune_q3, 120, SMARTBUFF_CONST_INV},
    {SMARTBUFF_PrimalWeighstone_q1, 120, SMARTBUFF_CONST_INV},
    {SMARTBUFF_PrimalWeighstone_q2, 120, SMARTBUFF_CONST_INV},
    {SMARTBUFF_PrimalWeighstone_q3, 120, SMARTBUFF_CONST_INV},
    {SMARTBUFF_PrimalWhetstone_q1, 120, SMARTBUFF_CONST_INV},
    {SMARTBUFF_PrimalWhetstone_q2, 120, SMARTBUFF_CONST_INV},
    {SMARTBUFF_PrimalWhetstone_q3, 120, SMARTBUFF_CONST_INV},
  };

  -- Tracking
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
	  {SMARTBUFF_BATBITES,	15,	SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_BEARTARTARE, 60, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_BILTONG, 60, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_BIGMECH, 60, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_BLACKENEDBASILISK, 30, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_BLACKENEDSPOREFISH, 30, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_BROILEDBLOODFIN, 30, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_BUTTERSCOTCHRIBS, 60, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_BUZZARDBITES, 30, SMARTBUFF_CONST_FOOD},
	  {SMARTBUFF_CHARREDBEARKABOBS,	15,	SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_CINNAMONBONEFISH, 60, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_CLAMBAR, 30, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_CRUNCHYSERPENT, 30, SMARTBUFF_CONST_FOOD},
	  {SMARTBUFF_CRUNCHYSPIDER,	15,	SMARTBUFF_CONST_FOOD},
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
    {SMARTBUFF_HEARTSBANEHEXWURST, 5, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_HONEYHAUNCHES, 60, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_IRIDESCENTRAVIOLI, 60, SMARTBUFF_CONST_FOOD},
	  {SMARTBUFF_JUICYBEARBURGER,	15,	SMARTBUFF_CONST_FOOD},
	  {SMARTBUFF_KIBLERSBITS,	20,	SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_KULTIRAMISU, 60, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_LEGIONCHILI, 60, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_LOALOAF, 60, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_LYNXSTEAK,	15,	SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_MEATYAPPLEDUMPLINGS, 60, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_MOKNATHALSHORTRIBS, 30, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_MONDAZI, 60, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_PICKLEDMEATSMOOTHIE, 60, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_PICKLEDSTORMRAY, 60, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_POACHEDBLUEFISH, 30, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_RAVAGERDOG, 30, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_RAVENBERRYTARTS, 60, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_ROASTEDCLEFTHOOF, 30, SMARTBUFF_CONST_FOOD},
	  {SMARTBUFF_ROASTEDMOONGRAZE,	15,	SMARTBUFF_CONST_FOOD},
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
    {SMARTBUFF_STORMCHOPS,	30,	SMARTBUFF_CONST_FOOD},
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
    {SMARTBUFF_HoardOfDelicacies, 60, SMARTBUFF_CONST_FOOD},
    {SMARTBUFF_DeviouslyDeviledEgg, 60, SMARTBUFF_CONST_FOOD},
  };

  for n, name in pairs(S.FoodItems) do
    if (name) then
      --print("Adding: "..n..". "..name);
      tinsert(SMARTBUFF_FOOD, 1, {name, 60, SMARTBUFF_CONST_FOOD});
    end
  end

  --[[
  for _, v in pairs(SMARTBUFF_FOOD) do
    if (v and v[1]) then
      print("List: "..v[1]);
    end
  end
  ]]


  -- Scrolls
  SMARTBUFF_SCROLL = {
    {SMARTBUFF_MiscItem17, 60, SMARTBUFF_CONST_SCROLL, nil, SMARTBUFF_BMiscItem17, S.LinkFlaskLeg},
    {SMARTBUFF_MiscItem16, 60, SMARTBUFF_CONST_SCROLL, nil, SMARTBUFF_BMiscItem16},
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
    {SMARTBUFF_MiscItem8, 5, SMARTBUFF_CONST_SCROLL, nil, SMARTBUFF_BMiscItem8},
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

  --      ItemId, SpellId, Duration [min]
  AddItem(174906, 270058,  60); -- Lightning-Forged Augment Rune
  AddItem(153023, 224001,  60); -- Lightforged Augment Rune
  AddItem(160053, 270058,  60); --Battle-Scarred Augment Rune
  AddItem(164375, 281303,  10); --Bad Mojo Banana
  AddItem(129165, 193345,  10); --Barnacle-Encrusted Gem
  AddItem(116115, 170869,  60); -- Blazing Wings
  AddItem(133997, 203533,   0); --Black Ice
  AddItem(122298, 181642,  60); --Bodyguard Miniaturization Device
  AddItem(163713, 279934,  30); --Brazier Cap
  AddItem(128310, 189363,  10); --Burning Blade
  AddItem(116440, 171554,  20); --Burning Defender's Medallion
  AddItem(128807, 192225,  60); -- Coin of Many Faces
  AddItem(138878, 217668,   5); --Copy of Daglop's Contract
  AddItem(143662, 232613,  60); --Crate of Bobbers: Pepe
  AddItem(142529, 231319,  60); --Crate of Bobbers: Cat Head
  AddItem(142530, 231338,  60); --Crate of Bobbers: Tugboat
  AddItem(142528, 231291,  60); --Crate of Bobbers: Can of Worms
  AddItem(142532, 231349,  60); --Crate of Bobbers: Murloc Head
  AddItem(147308, 240800,  60); --Crate of Bobbers: Enchanted Bobber
  AddItem(142531, 231341,  60); --Crate of Bobbers: Squeaky Duck
  AddItem(147312, 240801,  60); --Crate of Bobbers: Demon Noggin
  AddItem(147307, 240803,  60); --Crate of Bobbers: Carved Wooden Helm
  AddItem(147309, 240806,  60); --Crate of Bobbers: Face of the Forest
  AddItem(147310, 240802,  60); --Crate of Bobbers: Floating Totem
  AddItem(147311, 240804,  60); --Crate of Bobbers: Replica Gondola
  AddItem(122117, 179872,  15); --Cursed Feather of Ikzan
  AddItem( 54653,  75532,  30); -- Darkspear Pride
  AddItem(108743, 160688,  10); --Deceptia's Smoldering Boots
  AddItem(129149, 193333,  30); --Death's Door Charm
  AddItem(159753, 279366,   5); --Desert Flute
  AddItem(164373, 281298,  10); --Enchanted Soup Stone
  AddItem(140780, 224992,   5); --Fal'dorei Egg
  AddItem(122304, 138927,  10); -- Fandral's Seed Pouch
  AddItem(102463, 148429,  10); -- Fire-Watcher's Oath
  AddItem(128471, 190655,  30); --Frostwolf Grunt's Battlegear
  AddItem(128462, 190653,  30); --Karabor Councilor's Attire
  AddItem(161342, 275089,  30); --Gem of Acquiescence
  AddItem(127659, 188228,  60); --Ghostly Iron Buccaneer's Hat
  AddItem( 54651,  75531,  30); -- Gnomeregan Pride
  AddItem(118716, 175832,   5); --Goren Garb
  AddItem(138900, 217708,  10); --Gravil Goldbraid's Famous Sausage Hat
  AddItem(159749, 277572,   5); --Haw'li's Hot & Spicy Chili
  AddItem(163742, 279997,  60); --Heartsbane Grimoire
  AddItem(129149, 193333,  60); -- Helheim Spirit Memory
  AddItem(140325, 223446,  10); --Home Made Party Mask
  AddItem(136855, 210642,0.25); --Hunter's Call
  AddItem( 43499,  58501,  10); -- Iron Boot Flask
  AddItem(118244, 173956,  60); --Iron Buccaneer's Hat
  AddItem(170380, 304369, 120); --Jar of Sunwarmed Sand
  AddItem(127668, 187174,   5); --Jewel of Hellfire
  AddItem( 26571, 127261,  10); --Kang's Bindstone
  AddItem( 68806,  96312,  30); -- Kalytha's Haunted Locket
  AddItem(163750, 280121,  10); --Kovork Kostume
  AddItem(164347, 281302,  10); --Magic Monkey Banana
  AddItem(118938, 176180,  10); --Manastorm's Duplicator
  AddItem(163775, 280133,  10); --Molok Morion
  AddItem(101571, 144787,   0); --Moonfang Shroud
  AddItem(105898, 145255,  10); --Moonfang's Paw
  AddItem( 52201,  73320,  10); --Muradin's Favor
  AddItem(138873, 217597,   5); --Mystical Frosh Hat
  AddItem(163795, 280308,  10); --Oomgut Ritual Drum
  AddItem(  1973,  16739,   5); --Orb of Deception
  AddItem( 35275, 160331,  30); --Orb of the Sin'dorei
  AddItem(158149, 264091,  30); --Overtuned Corgi Goggles
  AddItem(130158, 195949,   5); --Path of Elothir
  AddItem(127864, 188172,  60); --Personal Spotlight
  AddItem(127394, 186842,   5); --Podling Camouflage
  AddItem(108739, 162402,   5); --Pretty Draenor Pearl
  AddItem(129093, 129999,  10); --Ravenbear Disguise
  AddItem(153179, 254485,   5); --Blue Conservatory Scroll
  AddItem(153180, 254486,   5); --Yellow Conservatory Scroll
  AddItem(153181, 254487,   5); --Red Conservatory Scroll
  AddItem(104294, 148529,  15); --Rime of the Time-Lost Mariner
  AddItem(119215, 176898,  10); --Robo-Gnomebobulator
  AddItem(119134, 176569,  30); --Sargerei Disguise
  AddItem(129055,  62089,  60); --Shoe Shine Kit
  AddItem(163436, 279977,  30); --Spectral Visage
  AddItem(156871, 261981,  60); --Spitzy
  AddItem( 66888,   6405,   3); --Stave of Fur and Claw
  AddItem(111476, 169291,   5); --Stolen Breath
  AddItem(140160, 222630,  10); --Stormforged Vrykul Horn
  AddItem(163738, 279983,  30); --Syndicate Mask
  AddItem(130147, 195509,   5); --Thistleleaf Branch
  AddItem(113375, 166592,   5); --Vindicator's Armor Polish Kit
  AddItem(163565, 279407,   5); --Vulpera Scrapper's Armor
  AddItem(163924, 280632,  30); --Whiskerwax Candle
  AddItem( 97919, 141917,   3); --Whole-Body Shrinka'
  AddItem(167698, 293671,  60); --Secret Fish Goggles
  AddItem(169109, 299445,  60); --Beeholder's Goggles
  AddItem(191341, 371172,  30); -- Tepid Q3
  -- Dragonflight
  AddItem(199902, 388275,  30); -- Wayfarer's Compass
  AddItem(202019, 396172,  30); -- Golden Dragon Goblet
  AddItem(198857, 385941,  30); -- Lucky Duck


  -- Potions
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
    {SMARTBUFF_ELIXIR15, 60, SMARTBUFF_CONST_POTION, nil, SMARTBUFF_BELIXIR15},
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
