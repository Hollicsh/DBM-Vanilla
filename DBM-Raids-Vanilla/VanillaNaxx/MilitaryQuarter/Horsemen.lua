local mod	= DBM:NewMod("HorsemenVanilla", "DBM-Raids-Vanilla", 1)
local L		= mod:GetLocalizedStrings()

if DBM:IsSeasonal("SeasonOfDiscovery") then
	mod.statTypes = "normal,heroic,mythic"
else
	mod.statTypes = "normal"
end

mod:SetRevision("@file-date-integer@")
mod:SetCreatureID(16062, 16063, 16064, 16065)--30549
mod:SetEncounterID(1121)
mod:SetModelID(10729)
mod:SetBossHPInfoToHighest()
mod:SetZone(533)

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_SUCCESS 28832 28833 28834 28835 28863 28883 28884 1226218 1226219 1226220 1226221",
	"SPELL_AURA_APPLIED 29061",
	"SPELL_AURA_REMOVED 29061",
	"SPELL_AURA_APPLIED_DOSE 28832 28833 28834 28835"
)

-- SoD uses new spell IDs for all marks, holy bolt, shadow bolt and unyielding pain. Only marks are relevant here
-- Meteor, void zone, holy wrath are confirmed old IDs

--[[
(ability.id = 28832 or ability.id = 28833 or ability.id = 28834 or ability.id = 28835 or ability.id = 28863 or ability.id = 28883 or ability.id = 28884) and type = "cast"
--]]
--TODO, shouldn't timers stop when horseman die?
mod:AddInfoFrameOption()

local warnMarkSoon				= mod:NewAnnounce("WarningMarkSoon", 1, 28835, false)
local warnMeteor				= mod:NewSpellAnnounce(28884, 4)
local warnVoidZone				= mod:NewTargetNoFilterAnnounce(28863, 3)--Only warns for nearby targets, to reduce spam
local warnHolyWrath				= mod:NewTargetNoFilterAnnounce(28883, 3, nil, false)
local warnBoneBarrier			= mod:NewTargetNoFilterAnnounce(29061, 2)

local specWarnMarkOnPlayer		= mod:NewSpecialWarning("SpecialWarningMarkOnPlayer", nil, nil, nil, 1, 6)
local specWarnVoidZone			= mod:NewSpecialWarningYou(28863, nil, nil, nil, 1, 2)
local yellVoidZone				= mod:NewYell(28863)

local timerMarkCD				= mod:NewTimer(DBM:IsSeasonal("SeasonOfDiscovery") and 13 or 12.9, "timerMark", 28835, nil, nil, 2)-- 12.9
local timerMeteorCD				= mod:NewVarTimer("v12.9-14.6", 28884, nil, nil, nil, 3)-- 12.9-14.6
local timerVoidZoneCD			= mod:NewVarTimer("v12.9-16", 28863, nil, nil, nil, 3)-- 12.9-16
local timerHolyWrathCD			= mod:NewVarTimer("v11.3-14.5", 28883, nil, nil, nil, 3)-- 11.3-14.5
local timerBoneBarrier			= mod:NewTargetTimer(20, 29061, nil, nil, nil, 5)

mod.vb.markCount = 0

function mod:OnCombatStart(delay)
	self.vb.markCount = 0
	timerVoidZoneCD:Start("v14.5-16.1")--14.5-16.1
	timerMarkCD:Start(20.9 - delay, 1)-- 20.98-21.44
	timerMeteorCD:Start(20.9 - delay)
	timerHolyWrathCD:Start(20.9 - delay)
	warnMarkSoon:Schedule(16 - delay)
	if self.Options.InfoFrame then
		local bosses = {
			[16062] = true,
			[16063] = true,
			[16064] = true,
			[16065] = true,
		}
		DBM.InfoFrame:Show(10, "bosshealth", bosses)
		self.bossHealthUpdateTime = 0.5
	end
end

function mod:OnCombatEnd()
	if self.Options.InfoFrame then
		DBM.InfoFrame:Hide()
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	if args:IsSpell(28832, 28833, 28834, 28835, 1226218, 1226219, 1226220, 1226221) and self:AntiSpam(10) then
		self.vb.markCount = self.vb.markCount + 1
		timerMarkCD:Start(nil, self.vb.markCount + 1)
		warnMarkSoon:Schedule(9.9, self.vb.markCount + 1)
	elseif args:IsSpell(28863) then
		timerVoidZoneCD:Start()
		if args:IsPlayer() then
			specWarnVoidZone:Show()
			specWarnVoidZone:Play("targetyou")
			yellVoidZone:Yell()
		else
			warnVoidZone:Show(args.destName)
		end
	elseif args:IsSpell(28883) then
		warnHolyWrath:Show(args.destName)
		timerHolyWrathCD:Start()
	elseif args:IsSpell(28884) then
		warnMeteor:Show()
		timerMeteorCD:Start()
	end
end


function mod:SPELL_AURA_APPLIED_DOSE(args)
	if args:IsSpell(28832, 28833, 28834, 28835) and args:IsPlayer() then
		if args.amount >= 4 then
			specWarnMarkOnPlayer:Show(args.spellName, args.amount)
			specWarnMarkOnPlayer:Play("stackhigh")
		end
	end
end

function mod:SPELL_AURA_APPLIED(args)
	if args:IsSpell(29061) and args:IsSrcTypeHostile() then
		warnBoneBarrier:Show(args.destName)
		timerBoneBarrier:Start(20, args.destName)
	end
end

function mod:SPELL_AURA_REMOVED(args)
	if args:IsSpell(29061) then
		timerBoneBarrier:Stop(args.destName)
	end
end
