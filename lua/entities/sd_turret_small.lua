AddCSLuaFile()

DEFINE_BASECLASS("sd_turret_base")

ENT.Base 			= "sd_turret_base"

ENT.PrintName 		= "Small Turret"
ENT.Category 		= "Squirrel Defense"

ENT.Spawnable 		= true

ENT.SpawnRotation 	= 180

ENT.Model 			= false

ENT.UseCustomPhys 	= true
ENT.PhysMin 		= Vector(-10, -10, -12)
ENT.PhysMax 		= Vector(10, 10, 24)

ENT.TurretClass 	= "sd_gun_small"
ENT.TurretOffset 	= Vector(0, 0, 15)

if CLIENT then
	function ENT:SetupParts()
		BaseClass.SetupParts(self)

		local part

		part = TankLib.Part:Create(TankLib.Part.Model, self)
		part:SetModel("models/maxofs2d/button_05.mdl")
		part:SetCentered(true)
		part:SetPos(Vector(0, 0, 7))
		part:SetAngles(Angle(0, 0, 0))

		for i = 1, 4 do
			local pos = Vector(9, 0, -5)

			pos:Rotate(Angle(0, i * 90 + 45, 0))

			part = TankLib.Part:Create(TankLib.Part.Model, self)
			part:SetModel("models/props_c17/utilityconnecter005.mdl")
			part:SetCentered(true)
			part:SetPos(pos)
			part:SetAngles(Angle(-20, i * 90 + 45, 90))
		end
	end

	function ENT:Draw()
		TankLib.Part:Draw(self)
	end
end