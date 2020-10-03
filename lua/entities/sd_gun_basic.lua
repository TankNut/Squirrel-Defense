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

function ENT:DoImpactEffect()
	return true
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
	function ENT:Initialize()
		BaseClass.Initialize(self)

		local filter = RecipientFilter()

		filter:AddAllPlayers()

		self.Sound = CreateSound(self, "ambient/energy/electric_loop.wav", filter)
	end

	function ENT:Think()
		BaseClass.Think(self)

		if self.NextFire <= CurTime() and self.Sound:IsPlaying() then
			self.Sound:Stop()
		end

		return true
	end

	function ENT:OnRemove()
		self.Sound:Stop()
	end

	function ENT:FireGun()
		self:FireBullets({
			Attacker = self:GetParent(),
			Damage = 8,
			TracerName = "sd_e_tesla",
			Dir = self:GetForward(),
			Spread = Vector(0.01, 0.01, 0),
			Src = self:GetShootPos(),
			IgnoreEntity = self:GetParent(),
			Callback = function(attacker, tr, dmg)
				dmg:SetDamageType(DMG_SHOCK)
			end
		})

		if not self.Sound:IsPlaying() then
			self.Sound:Play()
		end

		self.NextFire = CurTime() + self.FireDelay
	end
end