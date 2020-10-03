AddCSLuaFile()

DEFINE_BASECLASS("sd_base")

ENT.Base 			= "sd_base"

ENT.SDCanConnect 	= true

ENT.Model 			= false

ENT.UseCustomPhys 	= false
ENT.PhysMin 		= Vector()
ENT.PhysMax 		= Vector()

ENT.TurretClass 	= ""
ENT.TurretOffset 	= Vector()

function ENT:Initialize()
	BaseClass.Initialize(self)

	if SERVER then
		local gun = ents.Create(self.TurretClass)

		gun:SetPos(self:LocalToWorld(self.TurretOffset))
		gun:SetAngles(self:GetAngles())
		gun:SetParent(self)

		gun:Spawn()
		gun:Activate()

		gun:SetTurret(self)

		self:SetGun(gun)

		self:DeleteOnRemove(gun)
	end
end

function ENT:SetupDataTables()
	BaseClass.SetupDataTables(self)

	self:NetworkVar("Entity", 0, "Gun")
end

if CLIENT then
	function ENT:Draw()
		if self.Model then
			self:DrawModel()
		end

		TankLib.Part:Draw(self)
	end
end