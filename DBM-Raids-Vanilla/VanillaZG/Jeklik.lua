local isClassic = WOW_PROJECT_ID == (WOW_PROJECT_CLASSIC or 2)
local isBCC = WOW_PROJECT_ID == (WOW_PROJECT_BURNING_CRUSADE_CLASSIC or 5)
local isWrath = WOW_PROJECT_ID == (WOW_PROJECT_WRATH_CLASSIC or 11)
local catID
if isBCC or isClassic then
	catID = 4
elseif isWrath then--Wrath classic
	catID = 3
else--Cataclysm classic
	catID = 5
end
local mod	= DBM:NewMod("Jeklik", "DBM-Raids-Vanilla", catID)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("@file-date-integer@")
mod:SetCreatureID(14517)
mod:SetEncounterID(785)
mod:SetZone(309)

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 23954",
	"SPELL_CAST_SUCCESS 23918 22884",
	"SPELL_AURA_APPLIED 23952",
	"SPELL_AURA_REMOVED 23952"
)

--TODO, why is screech called screech when spellID is for psychic scream, is it wrong spellId/name?
--TODO, sonic Burst should probably be a target announce
local warnSonicBurst	= mod:NewSpellAnnounce(23918, 3)
local warnScreech		= mod:NewSpellAnnounce(22884, 3)
local warnPain			= mod:NewTargetNoFilterAnnounce(23952, 2, nil, "RemoveMagic|Healer")

local specWarnHeal		= mod:NewSpecialWarningInterrupt(23954, "HasInterrupt", nil, nil, 1, 2)

local timerSonicBurst	= mod:NewBuffActiveTimer(10, 23918, nil, nil, nil, 5, nil, DBM_COMMON_L.MAGIC_ICON)
local timerScreech		= mod:NewBuffActiveTimer(4, 22884, nil, nil, nil, 3)
local timerPain			= mod:NewTargetTimer(18, 23952, nil, "RemoveMagic|Healer", nil, 5, nil, DBM_COMMON_L.MAGIC_ICON)
local timerHealCD		= mod:NewNextTimer(20, 23954, nil, nil, nil, 4, nil, DBM_COMMON_L.INTERRUPT_ICON)

function mod:SPELL_CAST_START(args)
	if args:IsSpell(23954) and args:IsSrcTypeHostile() then
		timerHealCD:Start()
		if self:CheckInterruptFilter(args.sourceGUID, false, true) then
			specWarnHeal:Show(args.sourceName)
			specWarnHeal:Play("kickcast")
		end
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	if args:IsSpell(23918) then
		timerSonicBurst:Start()
		warnSonicBurst:Show()
	elseif args:IsSpell(22884) and args:IsSrcTypeHostile() then
		timerScreech:Start()
		warnScreech:Show()
	end
end

function mod:SPELL_AURA_APPLIED(args)
	if args:IsSpell(23952) and args:IsDestTypePlayer() then
		timerPain:Start(args.destName)
		warnPain:Show(args.destName)
	end
end

function mod:SPELL_AURA_REMOVED(args)
	if args:IsSpell(23952) and args:IsDestTypePlayer() then
		timerPain:Stop(args.destName)
	end
end
