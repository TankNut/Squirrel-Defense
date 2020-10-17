require("tanklib")

SquirrelDefense = SquirrelDefense or {
	Grids = {}
}

SquirrelDefense.NPCBlacklist = {
	["npc_enemyfinder"] = true
}

if SERVER then
	SquirrelDefense.Targets = SquirrelDefense.Targets or {}

	function SquirrelDefense:IsValidTarget(target)
		if not IsValid(target) then
			return false
		end

		if target:IsFlagSet(FL_NOTARGET) then
			return false
		end

		if target:IsPlayer() then
			return target:Alive()
		elseif target:IsNPC() then
			return target:Health() > 0
		end

		return false
	end

	hook.Add("OnEntityCreated", "SquirrelDefense", function(ent)
		if not IsValid(ent) then
			return
		end

		if ent:IsPlayer() or (ent:IsNPC() and not SquirrelDefense.NPCBlacklist[ent:GetClass()]) then
			SquirrelDefense.Targets[ent] = true
		end
	end)

	hook.Add("EntityRemoved", "SquirrelDefense", function(ent)
		SquirrelDefense.Targets[ent] = nil
	end)
end

include("squirrel_defense/sd_defensegrid.lua")