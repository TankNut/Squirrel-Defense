require("tanklib")

SquirrelDefense = SquirrelDefense or {
	Grids = {}
}

SquirrelDefense.NPCBlacklist = {
	["npc_enemyfinder"] = true
}

if SERVER then
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
			return not self.NPCBlacklist[target:GetClass()] and target:Health() > 0
		end

		return false
	end
end

include("squirrel_defense/sd_defensegrid.lua")