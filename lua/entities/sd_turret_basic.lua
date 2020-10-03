AddCSLuaFile()

DEFINE_BASECLASS("sd_turret_base")

ENT.Base 			= "sd_turret_base"

ENT.PrintName 		= "Basic Turret"
ENT.Category 		= "Squirrel Defense"

ENT.Spawnable 		= true

ENT.SpawnRotation 	= 180

ENT.Model 			= Model("models/hunter/blocks/cube05x05x05.mdl")

ENT.UseCustomPhys 	= true
ENT.PhysMin 		= Vector(-12, -12, -12)
ENT.PhysMax 		= Vector(12, 12, 36)

ENT.TurretClass 	= "sd_gun_basic"
ENT.TurretOffset 	= Vector(0, 0, 24)

if CLIENT then
	function ENT:SetupParts()
		BaseClass.SetupParts(self)

		self.Bracket = TankLib.Part:Create(TankLib.Part.Model, self)

		self.Bracket:SetModel("models/props_wasteland/light_spotlight01_base.mdl")
		self.Bracket:SetPos(Vector(0, 0, 19))
	end
end