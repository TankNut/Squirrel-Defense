AddCSLuaFile()

DEFINE_BASECLASS("sd_base")

ENT.Base 			= "sd_base"

ENT.PrintName 		= "Tesla Coil"
ENT.Category 		= "Squirrel Defense"

ENT.Spawnable 		= true

ENT.SDCanConnect 	= true

ENT.Model 			= Model("models/hunter/blocks/cube05x05x05.mdl")

ENT.UseCustomPhys 	= false
ENT.PhysMin 		= Vector()
ENT.PhysMax 		= Vector()

ENT.ChargeRate 		= 5
ENT.ChargeMax 		= 30

if CLIENT then
	function ENT:SetupParts()
		BaseClass.SetupParts(self)

		local part

		part = TankLib.Part:Create(TankLib.Part.Model, self)

		part:SetModel("models/XQM/Rails/gumball_1.mdl")
		part:SetScale(0.5)
		part:SetPos(Vector(0, 0, 48))
		part:SetAngles(Angle(0, 0, 0))
	end
end

function ENT:Think()
	local charge = math.min((CurTime() - self:GetCreationTime()) * self.ChargeRate, self.ChargeMax)
	local fraction = charge / self.ChargeMax

	if CLIENT then
		local ed = EffectData()

		local pos = self:LocalToWorld(Vector(0, 0, 48))
		local ang = AngleRand()

		ang.r = 0

		ed:SetStart(pos)
		ed:SetOrigin(pos + ang:Forward() * 5)
		ed:SetScale(fraction * 0.2)
		ed:SetMagnitude(1)
		ed:SetRadius(10 * fraction)

		util.Effect("sd_e_tesla", ed)
	end
end