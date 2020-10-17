AddCSLuaFile()

DEFINE_BASECLASS("sd_gun_base")

ENT.Base 			= "sd_gun_base"

ENT.TurnRate 		= 180
ENT.ErrorMargin 	= Angle(5, 5, 5)

ENT.MaxRange 		= 500

ENT.FireDelay 		= 60 / 900

ENT.Model 			= false

function ENT:GetShootPos()
	return self:LocalToWorld(Vector(20, 0, 0))
end

if CLIENT then
	function ENT:SetupParts()
		BaseClass.SetupParts(self)

		local part

		part = TankLib.Part:Create(TankLib.Part.Model, self)
		part:SetModel("models/props_lab/powerbox02c.mdl")
		part:SetCentered(true)
		part:SetAngles(Angle(-90, 90, 0))

		part = TankLib.Part:Create(TankLib.Part.Model, self)
		part:SetModel("models/props_c17/utilityconnecter006.mdl")
		part:SetCentered(true)
		part:SetPos(Vector(14, 0, 0))
		part:SetAngles(Angle(0, 90, 0))

		part = TankLib.Part:Create(TankLib.Part.Model, self)
		part:SetModel("models/props_junk/propanecanister001a.mdl")
		part:SetCentered(true)
		part:SetPos(Vector(-6, 0, -1.5))
		part:SetAngles(Angle(90, 90, 90))

		part = TankLib.Part:Create(TankLib.Part.Model, self)
		part:SetModel("models/props_phx/wheels/magnetic_small_base.mdl")
		part:SetCentered(true)
		part:SetPos(Vector(0, 0, 3.5))
		part:SetAngles(Angle(0, 90, 0))

		part = TankLib.Part:Create(TankLib.Part.Model, part)
		part:SetModel("models/mechanics/various/211.mdl")
		part:SetCentered(true)
		part:SetPos(Vector(0, 0, 2.5))
		part:SetAngles(Angle(90, -90, 0))
	end

	function ENT:UpdateParts()
		self:GetTurret().Bracket:SetAngles(Angle(0, self.Yaw, 0))
	end
else
	function ENT:FireGun()
		self:FireBullets({
			Attacker = self:GetParent(),
			Damage = 8,
			TracerName = "AR2Tracer",
			Dir = self:GetForward(),
			Spread = Vector(0.01, 0.01, 0),
			Src = self:GetShootPos(),
			IgnoreEntity = self:GetParent()
		})

		self:EmitSound("Weapon_AR2.NPC_Single")

		self.NextFire = CurTime() + self.FireDelay
	end
end