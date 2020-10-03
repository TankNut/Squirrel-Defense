AddCSLuaFile()

ENT.Type 			= "anim"

ENT.Author 			= "TankNut"

ENT.SpawnRotation 	= 0

ENT.UseCustomPhys 	= false
ENT.PhysMin 		= Vector()
ENT.PhysMax 		= Vector()

if SERVER then
	function ENT:SpawnFunction(ply, tr, class)
		if not tr.Hit then
			return
		end

		local ent = ents.Create(class)
		local ang = Angle(0, ply:EyeAngles().y + 180, 0) + Angle(0, self.SpawnRotation, 0)

		ent:SetCreator(ply)
		ent:SetPos(tr.HitPos)
		ent:SetAngles(ang)

		ent:Spawn()
		ent:Activate()

		local pos = tr.HitPos - (tr.HitNormal * 512)

		pos = ent:NearestPoint(pos)
		pos = ent:GetPos() - pos
		pos = tr.HitPos + pos

		ent:SetPos(pos)

		return ent
	end
end

function ENT:Initialize()
	self:SetupHooks()

	if CLIENT then
		self:SetupParts()
	end

	self:SetModel(self.Model or "models/hunter/plates/plate.mdl")

	if self.UseCustomPhys then
		self:SetupPhysics(self.PhysMin, self.PhysMax)
	elseif SERVER then
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
	end
end

function ENT:SetupPhysics(mins, maxs)
	if IsValid(self.PhysCollide) then
		self.PhysCollide:Destroy()
	end

	self.PhysCollide = CreatePhysCollideBox(mins, maxs)
	self:SetCollisionBounds(mins, maxs)

	if CLIENT then
		self:SetRenderBounds(mins, maxs)
	else
		self:PhysicsInitBox(mins, maxs)
		self:SetSolid(SOLID_VPHYSICS)
		self:PhysWake()
	end

	self:EnableCustomCollisions(true)
end

function ENT:SetupDataTables()
	self:NetworkVar("Int", 0, "GridID")
end

if CLIENT then
	function ENT:SetupParts()
		TankLib.Part:Clear(self)
	end

	function ENT:Draw()
		self:DrawModel()

		TankLib.Part:Draw(self)
	end
end

function ENT:SetupHooks()
	if self.Hooks then
		for k in pairs(self.Hooks) do
			hook.Remove(k, self)
		end

		table.Empty(self.Hooks)
	else
		self.Hooks = {}
	end
end

function ENT:Hook(name)
	self.Hooks[name] = true

	hook.Add(name, self, self[name])
end

function ENT:OnReloaded()
	self:SetupHooks()

	if CLIENT then
		self:SetupParts()
	end
end

function ENT:GetGrid()
	return TankLib.Class.NetworkTable[self:GetGridID()]
end

function ENT:TestCollision(start, delta, isbox, extends)
	if not IsValid(self.PhysCollide) then
		return
	end

	local max = extends
	local min = -extends

	max.z = max.z - min.z
	min.z = 0

	local hit, norm, frac = self.PhysCollide:TraceBox(self:GetPos(), self:GetAngles(), start, start + delta, min, max)

	if not hit then
		return
	end

	return {
		HitPos = hit,
		Normal = norm,
		Fraction = frac
	}
end

properties.Add("sd_link", {
	MenuLabel = "Link to grid",
	Order = 1,
	Filter = function(self, ent, ply)
		local ok = false

		for _, v in pairs(SquirrelDefense.Grids) do
			if v:GetOwner() == ply then
				ok = true

				break
			end
		end

		if not ok then
			return false
		end

		if not IsValid(ent) then return false end
		if not ent.SDCanConnect then return false end
		if not gamemode.Call("CanProperty", ply, "sd_link", ent) then return false end

		return ent:GetGridID() == 0
	end,
	Action = function(self, ent) end,
	Receive = function(self, len, ply)
		local ent = net.ReadEntity()
		local id = net.ReadUInt(16)

		if not properties.CanBeTargeted(ent, ply) then return end
		if not self:Filter(ent, ply) then return end

		local grid = TankLib.Class:GetNetworked(id)

		if not grid or not grid:IsInstanceOf(SquirrelDefense.DefenseGrid) then return end
		if grid:GetOwner() != ply then return end

		grid:AddEntity(ent)
	end,
	MenuOpen = function(self, dmenu, ent, tr)
		local submenu = dmenu:AddSubMenu()

		for _, v in pairs(SquirrelDefense.Grids) do
			if v:GetOwner() == LocalPlayer() then
				submenu:AddOption(v:GetName(), function() self:SetID(ent, v.NetworkID) end)
			end
		end
	end,
	SetID = function(self, ent, id)
		self:MsgStart()
			net.WriteEntity(ent)
			net.WriteUInt(id, 16)
		self:MsgEnd()
	end
})