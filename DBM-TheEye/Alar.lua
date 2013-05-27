local mod	= DBM:NewMod("Alar", "DBM-TheEye")
local L		= mod:GetLocalizedStrings()

mod:SetRevision(("$Revision$"):sub(12, -3))
mod:SetCreatureID(19514)
mod:SetModelID(18945)
mod:SetZone()

mod:RegisterCombat("combat")

mod:RegisterEvents(
	"SPELL_AURA_APPLIED",
	"SPELL_AURA_REMOVED",
	"SPELL_HEAL"
)

local warnPhase1		= mod:NewPhaseAnnounce(1)
local warnQuill			= mod:NewSpellAnnounce(34229, 3)
local warnPhase2		= mod:NewPhaseAnnounce(2)
local warnArmor			= mod:NewTargetAnnounce(35410, 3)
local warnMeteor		= mod:NewSpellAnnounce(35181, 3)

local specWarnQuill		= mod:NewSpecialWarningSpell(34229)
local specWarnFire		= mod:NewSpecialWarningMove(35383)

local timerQuill		= mod:NewCastTimer(10, 34229)
local timerMeteor		= mod:NewCDTimer(54, 35181)
local timerArmor		= mod:NewTargetTimer(60, 35410)
local timerNextPlatform	= mod:NewTimer(34.5, "NextPlatform", 40192)--This has no spell trigger, the target scanning bosses target is still required if loop isn't accurate enough.

local berserkTimer		= mod:NewBerserkTimer(600)

local buffetName = GetSpellInfo(34121)
local UnitGUID = UnitGUID
local UnitName = UnitName
local flying = false
local phase2 = false

--Loop doesn't work do to varying travel time between platforms. We just need to do target scanning and start next platform timer when Al'ar reaches a platform and starts targeting player again
local function Platform()--An attempt to avoid ugly target scanning, but i get feeling this won't be accurate enough.
	timerNextPlatform:Start()
	flying = false
end

local function Add()--An attempt to avoid ugly target scanning, but i get feeling this won't be accurate enough.
	timerNextPlatform:Cancel()
	flying = true
end

mod:RegisterOnUpdateHandler(function(self)
	if self:IsInCombat() then
		local foundIt
		local target
		for uId in DBM:GetGroupMembers() do
			if self:GetCIDFromGUID(UnitGUID(uId.."target")) == 19514 then
				foundIt = true
				target = UnitName(uId)
				if not target and UnitCastingInfo(uId.."target") == buffetName then
					target = "Dummy"
				end
				break
			end
		end
		
		if foundIt and not target and not phase2 then--Al'ar is no longer targeting anything, which means he spawned an add and is moving platforms
			Add()
		elseif not target and type(phase2) == "number" and (GetTime() - phase2) > 25 then--No target in phase 2 means meteor
			warnMeteor:Show()
			timerMeteor:Start()
		elseif target and flying then--Al'ar has reached a platform and is once again targeting aggro player
			Platform()
		end
	end
end, 0.2)

function mod:OnCombatStart(delay)
	flying = false
	phase2 = false
	warnPhase1:Show()
	timerNextPlatform:Start(-delay)
end

function mod:SPELL_AURA_APPLIED(args)
	if args.spellId == 34229 then
		warnQuill:Show()
		specWarnQuill:Show()
		timerQuill:Start()
	elseif args.spellId == 35383 and args:IsPlayer() and self:AntiSpam(3, 1) then
		specWarnFire:Show()
	elseif args.spellId == 35410 then
		warnArmor:Show(args.destName)
		timerArmor:Start(args.destName)
	end
end

function mod:SPELL_AURA_REMOVED(args)
	if args.spellId == 35410 then
		timerArmor:Cancel(args.destName)
	end
end

--Target scanning is more accurate for finding phase 2 well before the heal, HOWEVER, fails if soloing alar and you aren't targeting him.
function mod:SPELL_HEAL(_, _, _, _, _, _, _, _, spellId)
	if spellId == 34342 then
		phase2 = GetTime()
		warnPhase2:Show()
		berserkTimer:Start()
		timerMeteor:Start(40)--This seems to vary slightly depending on where in room he shoots it.
		timerNextPlatform:Cancel()
	end
end

--[[
function mod:SPELL_DAMAGE(_, _, _, _, _, _, _, _, spellId)
	if (spellId == 35181 or spellId == 45680) and self:AntiSpam(30, 2) then
	end
end
mod.SPELL_MISSED = mod.SPELL_DAMAGE
--]]
