AddCSLuaFile()

DEFINE_BASECLASS("sd_base")

ENT.Base 		= "sd_base"

ENT.PrintName 	= "Core"
ENT.Category 	= "Squirrel Defense"

ENT.Spawnable 	= true

function ENT:Initialize()
	BaseClass.Initialize(self)

	self:SetModel("models/props_lab/reciever_cart.mdl")

	if SERVER then
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)

		local grid = SquirrelDefense.DefenseGrid(self:GetCreator())

		grid:AddEntity(self)

		self.NextRadarUpdate = CurTime()
	end
end

function ENT:Think()
	if SERVER and self.NextRadarUpdate <= CurTime() then
		self.NextRadarUpdate = CurTime() + 1

		self:GetGrid():UpdateRadar()
	end

	self:NextThink(CurTime())

	return true
end

function ENT:OnRemove()
	self:GetGrid():Destroy()
end