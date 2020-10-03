AddCSLuaFile()

DEFINE_BASECLASS("sd_base")

ENT.Base 			= "sd_base"

ENT.PrintName 		= "Radar"
ENT.Category 		= "Squirrel Defense"

ENT.Spawnable 		= true

ENT.SDCanConnect 	= true

ENT.Radius 			= 5000

ENT.Model 			= Model("models/hunter/blocks/cube1x1x05.mdl")

ENT.UseCustomPhys 	= true
ENT.PhysMin 		= Vector(-24, -24, -12)
ENT.PhysMax 		= Vector(24, 24, 48)

function ENT:Initialize()
	BaseClass.Initialize(self)

	if SERVER then
		self.NextRadar = CurTime()
		self.Entities = {}
	end
end

if CLIENT then
	function ENT:SetupParts()
		BaseClass.SetupParts(self)

		self.BasePart = TankLib.Part:Create(TankLib.Part.Baseclass, self)

		self.BasePart:SetPos(Vector(0, 0, 13))
		self.BasePart:SetAngles(Angle(0, 180, 0))

		local wheel = TankLib.Part:Create(TankLib.Part.Model, self.BasePart)

		wheel:SetModel("models/props_c17/pulleywheels_large01.mdl")
		wheel:SetAngles(Angle(90, 0, 0))
		wheel:SetCentered(true)

		local ringbase = TankLib.Part:Create(TankLib.Part.Baseclass, self.BasePart)

		ringbase:SetPos(Vector(7.5, 0, 18))
		ringbase:SetAngles(Angle(5, 0, 0))

		for i = -1, 1, 2 do
			local ring = TankLib.Part:Create(TankLib.Part.Model, ringbase)

			ring:SetModel("models/props_lab/teleportgate.mdl")
			ring:SetPos(Vector(0, 0, i * 2.5))
			ring:SetAngles(Angle(0, 0, 90 + i * 90))
			ring:SetScale(0.6)
		end

		local truss = TankLib.Part:Create(TankLib.Part.Model, ringbase)

		truss:SetModel("models/props_c17/truss02e.mdl")
		truss:SetPos(Vector(-7.5, 0, -7.5))
		truss:SetAngles(Angle(0, 90, 0))
		truss:SetScale(0.1)

		local emitter = TankLib.Part:Create(TankLib.Part.Model, truss)

		emitter:SetModel("models/props_lab/monitor02.mdl")
		emitter:SetPos(Vector(0, 11, 0))
		emitter:SetAngles(Angle(0, -90, 0))
		emitter:SetScale(0.3)
	end

	function ENT:UpdateParts()
		if self:GetGrid() then
			self.BasePart:SetAngles(Angle(0, CurTime() * 180, 0))
		end
	end
end

function ENT:Think()
	if CLIENT then
		self:UpdateParts()
	end

	self:NextThink(CurTime())

	return true
end

if SERVER then
	function ENT:GetTargets()
		local entities = ents.FindInSphere(self:WorldSpaceCenter(), self.Radius)
		local owner = self:GetGrid():GetOwner()

		table.Filter(entities, function(key, val)
			if not SquirrelDefense:IsValidTarget(val) then
				return false
			end

			if val:IsPlayer() then
				return val != self:GetGrid():GetOwner()
			elseif val:IsNPC() then
				return val:Disposition(owner) != D_LI
			end
		end)

		return entities
	end

	function ENT:GetFriendlies()
		local entities = ents.FindInSphere(self:WorldSpaceCenter(), self.Radius)
		local owner = self:GetGrid():GetOwner()

		table.Filter(entities, function(key, val)
			if not SquirrelDefense:IsValidTarget(val) then
				return false
			end

			if val:IsPlayer() then
				return val == self:GetGrid():GetOwner()
			elseif val:IsNPC() then
				return val:Disposition(owner) == D_LI
			end

			return false
		end)

		return entities
	end
end