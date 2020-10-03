AddCSLuaFile()

DEFINE_BASECLASS("sd_gun_base")

ENT.Base 			= "sd_gun_base"

ENT.TurnRate 		= 180
ENT.ErrorMargin 	= Angle(5, 5, 5)

ENT.MaxRange 		= 1500

ENT.FireDelay 		= 0.5

ENT.Model 			= false

function ENT:GetShootPos()
	return self:LocalToWorld(Vector(18, 0, 0))
end

if CLIENT then
	function ENT:SetupParts()
		BaseClass.SetupParts(self)

		local part

		part = TankLib.Part:Create(TankLib.Part.Model, self)
		part:SetModel("models/props_lab/powerbox02d.mdl")
		part:SetCentered(true)
		part:SetPos(Vector(0, 0, -1.5))
		part:SetAngles(Angle(90, 0, 0))

		part = TankLib.Part:Create(TankLib.Part.Model, self)
		part:SetModel("models/props_lab/powerbox03a.mdl")
		part:SetCentered(true)
		part:SetPos(Vector(0.45, -6.5, 0))
		part:SetAngles(Angle(0, -90, 0))

		part = TankLib.Part:Create(TankLib.Part.Model, self)
		part:SetModel("models/dav0r/buttons/switch.mdl")
		part:SetCentered(true)
		part:SetPos(Vector(1, 5.5, 0))
		part:SetAngles(Angle(0, 0, -90))

		part = TankLib.Part:Create(TankLib.Part.Model, self)
		part:SetModel("models/props_lab/tpplug.mdl")
		part:SetCentered(true)
		part:SetPos(Vector(-5, 0, -0.2))
		part:SetAngles(Angle(0, 180, 0))

		part = TankLib.Part:Create(TankLib.Part.Model, self)
		part:SetModel("models/maxofs2d/camera.mdl")
		part:SetCentered(true)
		part:SetPos(Vector(-2, 0, 4))
		part:SetAngles(Angle(0, 0, 90))

		part = TankLib.Part:Create(TankLib.Part.Model, self)
		part:SetModel("models/props_lab/pipesystem03a.mdl")
		part:SetCentered(true)
		part:SetPos(Vector(4, 0, 0))
		part:SetAngles(Angle(0, 90, 0))

		part = TankLib.Part:Create(TankLib.Part.Model, self)
		part:SetModel("models/props_phx2/garbage_metalcan001a.mdl")
		part:SetCentered(true)
		part:SetPos(Vector(14, 0, -0.15))
		part:SetAngles(Angle(-90, 0, 0))
	end
else
	function ENT:FireGun()
		local abort = false

		for i = 0, 4 do
			timer.Simple(i * 0.075, function()
				if not IsValid(self) then
					return
				end

				if not abort then
					abort = not self:IsValidTarget(self:GetTarget())
				end

				if abort then
					return
				end

				local pos = self:GetShootPos()
				local ed = EffectData()

				ed:SetOrigin(pos)
				ed:SetAngles(self:GetForward():Angle())
				ed:SetScale(0.5)

				util.Effect("MuzzleEffect", ed)

				self:FireBullets({
					Attacker = self:GetParent(),
					Damage = 4,
					TracerName = "Tracer",
					Dir = self:GetForward(),
					Spread = Vector(0.02, 0.02, 0),
					Src = pos,
					IgnoreEntity = self:GetParent()
				})

				self:EmitSound("Weapon_SMG1.NPC_Single")

				self.NextFire = CurTime() + self.FireDelay
			end)
		end
	end
end