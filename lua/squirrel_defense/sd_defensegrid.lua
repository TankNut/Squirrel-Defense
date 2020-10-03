AddCSLuaFile()

local class = TankLib.Class:New("SquirrelDefense.DefenseGrid", TankLib.Class.Replicated)

class:RegisterNetworkVar("Name", "")
class:RegisterNetworkVar("Owner", NULL)
class:RegisterNetworkVar("Targets", {})
class:RegisterNetworkVar("Friendlies", {})
class:RegisterNetworkVar("Entities", {})

if CLIENT then
	function class:Initialize()
		SquirrelDefense.Grids[self.NetworkID] = self
	end
else
	function class:Initialize(owner)
		SquirrelDefense.Grids[self.NetworkID] = self

		self:SetOwner(owner)
		self:SetName(string.format("%s's Defense Grid (#%s)", owner:Nick(), self.NetworkID))
	end

	function class:UpdateRadar()
		local targets = {}
		local friendlies = {}

		for _, v in pairs(ents.FindByClass("sd_radar")) do
			if v:GetGrid() == self then
				table.Add(targets, v:GetTargets())
				table.Add(friendlies, v:GetFriendlies())
			end
		end

		self:SetTargets(table.GetUnique(targets))
		self:SetFriendlies(table.GetUnique(friendlies))
	end

	function class:AddEntity(ent)
		ent:SetGridID(self.NetworkID)

		local tab = self:GetEntities()

		tab[ent] = true

		self:SetEntities(tab)
	end
end

function class:Destroy()
	SquirrelDefense.Grids[self.NetworkID] = nil

	for _, v in pairs(ents.GetAll()) do
		if v.SDCanConnect and v:GetGridID() == self.NetworkID then
			v:SetGridID(0)
		end
	end

	TankLib.Class.Replicated.Destroy(self)
end

SquirrelDefense.DefenseGrid = class