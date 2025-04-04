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
local mod	= DBM:NewMod("EdgeOfMadness", "DBM-Raids-Vanilla", catID)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("@file-date-integer@")
mod:SetCreatureID(15083)
mod:SetEncounterID(788)
mod:SetZone(309)

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_SUCCESS 24684 24699 24683 24646",
	"SPELL_AURA_APPLIED 24664 8269 24699",
	"SPELL_SUMMON 24728 24683"
)

--TODO, this mod was a huge mess, wrong spellIds, duplicate events. So It needs heavy review with logs
local warnIllusions	= mod:NewSpellAnnounce(24728)
local warnSleep		= mod:NewSpellAnnounce(24664)
local warnChainBurn	= mod:NewSpellAnnounce(24684)
local warnFrenzy	= mod:NewSpellAnnounce(8269)
local warnVanish	= mod:NewSpellAnnounce(24699)
local warnCloud		= mod:NewSpellAnnounce(24683)

local specWarnKite	= mod:NewSpecialWarningMove(24646, true, nil, nil, 1, 2)

local timerSleep	= mod:NewBuffActiveTimer(6, 24664, nil, nil, nil, 3)
local timerCloud	= mod:NewBuffActiveTimer(15, 24683, nil, nil, nil, 3)
local timerKite		= mod:NewBuffActiveTimer(15, 24646)

function mod:SPELL_CAST_SUCCESS(args)
	if args:IsSpell(24684) then
		warnChainBurn:Show()
	elseif args:IsSpell(24699) and args:IsSrcTypeHostile() then
		warnVanish:Show()
	elseif args:IsSpell(24683) then
		warnCloud:Show()
		timerCloud:Start()
	elseif args:IsSpell(24646) then -- Gri'lek kiting
		specWarnKite:Show()
		specWarnKite:Play("keepmove")
		timerKite:Start()
	end
end

function mod:SPELL_AURA_APPLIED(args)
	if args:IsSpell(24664) and args:IsDestTypePlayer() and  self:AntiSpam(3, 1) then
		warnSleep:Show()
		timerSleep:Start()
	elseif args:IsSpell(24699) and args:IsDestTypeHostile() then
		warnFrenzy:Show()
	end
end

function mod:SPELL_SUMMON(args)
	if args:IsSpell(24728) then
		warnIllusions:Show()
	--elseif args:IsSpell(24683) then
	--	warnCloud:Show()
	--	timerCloud:Start()
	end
end
