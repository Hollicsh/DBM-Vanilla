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
local mod	= DBM:NewMod("Venoxis", "DBM-Raids-Vanilla", catID)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("@file-date-integer@")
mod:SetCreatureID(14507)
mod:SetEncounterID(784)
mod:SetHotfixNoticeRev(20200724000000)--2020, 7, 24
mod:SetMinSyncRevision(20200724000000)
mod:SetZone(309)

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 23860",
	"SPELL_CAST_SUCCESS 23861",
	"SPELL_AURA_APPLIED 23895 23860 23865",
	"SPELL_AURA_REMOVED 23895 23860",
	"UNIT_HEALTH mouseover target"
)

local warnSerpent		= mod:NewTargetNoFilterAnnounce(23865, 2)
local warnCloud			= mod:NewSpellAnnounce(23861)
local warnRenew			= mod:NewTargetNoFilterAnnounce(23895, 3)
local warnFire			= mod:NewTargetNoFilterAnnounce(23860, 2, nil, "RemoveMagic|Healer")
local prewarnPhase2		= mod:NewPrePhaseAnnounce(2, 2)

local specWarnHolyFire	= mod:NewSpecialWarningInterrupt(23860, "HasInterrupt", nil, nil, 1, 2)
local specWarnRenew		= mod:NewSpecialWarningDispel(23895, "MagicDispeller", nil, nil, 1, 2)

local timerCloud		= mod:NewBuffActiveTimer(10, 23861, nil, nil, nil, 3)
local timerRenew		= mod:NewTargetTimer(15, 23895, nil, "MagicDispeller", nil, 5, nil, DBM_COMMON_L.MAGIC_ICON)
local timerFire			= mod:NewTargetTimer(8, 23860, nil, "RemoveMagic|Healer", nil, 5, nil, DBM_COMMON_L.MAGIC_ICON)

mod:AddRangeFrameOption("10")

mod.vb.prewarn_Phase2 = false

function mod:OnCombatStart(delay)
	self.vb.prewarn_Phase2 = false
	if self.Options.RangeFrame then
		DBM.RangeCheck:Show(10)
	end
end

function mod:OnCombatEnd()
	if self.Options.RangeFrame then
		DBM.RangeCheck:Hide()
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	if args:IsSpell(23861) then
		warnCloud:Show()
		timerCloud:Start()
	end
end

function mod:SPELL_CAST_START(args)
	if args:IsSpell(23860) and args:IsSrcTypeHostile() then
		if self:CheckInterruptFilter(args.sourceGUID, false, true) then
			specWarnHolyFire:Show(args.sourceName)
			specWarnHolyFire:Play("kickcast")
		end
	end
end

function mod:SPELL_AURA_APPLIED(args)
	if args:IsSpell(23895) and args:IsDestTypeHostile() then
		if self.Options.SpecWarn23895dispel then
			specWarnRenew:Show(args.destName)
			specWarnRenew:Play("dispelboss")
		else
			warnRenew:Show(args.destName)
		end
		timerRenew:Start(args.destName)
	elseif args:IsSpell(23860) and args:IsDestTypePlayer() then
		warnFire:Show(args.destName)
		timerFire:Start(args.destName)
	elseif args:IsSpell(23865) then
		warnSerpent:Show(args.destName)
	end
end

function mod:SPELL_AURA_REMOVED(args)
	if args:IsSpell(23895) and args:IsDestTypeHostile() then
		timerRenew:Stop(args.destName)
	elseif args:IsSpell(23860) and args:IsDestTypePlayer() then
		timerFire:Stop(args.destName)
	end
end

function mod:UNIT_HEALTH(uId)
	if not self.vb.prewarn_Phase2 and self:GetUnitCreatureId(uId) == 14507 and UnitHealth(uId) / UnitHealthMax(uId) <= 0.53 then
		self.vb.prewarn_Phase2 = true
		prewarnPhase2:Show()
	end
end
