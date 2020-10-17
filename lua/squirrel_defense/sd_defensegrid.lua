AddCSLuaFile()

local class = TankLib.Class:New("SquirrelDefense.DefenseGrid", TankLib.Class.Replicated)

class:RegisterNetworkVar("Name", "")
class:RegisterNetworkVar("Owner", NULL)
class:RegisterNetworkVar("Enemies", {})
class:RegisterNetworkVar("Friendlies", {})
class:RegisterNetworkVar("Entities", {})

function class:Initialize(owner)
	SquirrelDefense.Grids[self.NetworkID] = self

	if SERVER then
		self:SetOwner(owner)
		self:SetName(string.format("%s's Defense Grid (#%s)", owner:Nick(), self.NetworkID))
	end
end

if SERVER then
	function class:UpdateRadar()
		local enemies = {}
		local friendlies = {}

		for _, v in pairs(self:GetEntities()) do
			if v:GetClass() == "sd_radar" then
				table.Add(enemies, v:GetEnemies())
				table.Add(friendlies, v:GetFriendlies())
			end
		end

		self:SetEnemies(table.GetUnique(enemies))
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