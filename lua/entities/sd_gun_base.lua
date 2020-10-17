AddCSLuaFile()

DEFINE_BASECLASS("sd_base")

ENT.Base 			= "sd_base"

ENT.RenderGroup 	= RENDERGROUP_BOTH

ENT.TurnRate 		= 180
ENT.ErrorMargin 	= Angle(0, 0, 0)

ENT.Range 			= 1000

ENT.FireDelay 		= 0.1

ENT.Model 			= false

function ENT:Initialize()
	BaseClass.Initialize(self)

	self.LastThink = CurTime()

	if SERVER then
		self.NextTarget = CurTime()
		self.NextFire = CurTime()

		self.TurretDelta = Angle()
	end
end

function ENT:SetupDataTables()
	BaseClass.SetupDataTables(self)

	self:NetworkVar("Entity", 0, "Target")
	self:NetworkVar("Entity", 1, "Turret")
end

function ENT:GetGrid()
	return self:GetTurret():GetGrid()
end

function ENT:CanFire()
	return self.TurretDelta:InRange(-self.ErrorMargin, self.ErrorMargin) and self.NextFire <= CurTime()
end

function ENT:Think()
	if CLIENT then
		self:UpdateParts()

		if self:IsDormant() then
			return
		end
	end

	local delta = CurTime() - self.LastThink
	local grid = self:GetGrid()

	if grid then
		local found

		if SERVER then
			found = self:FindTarget()
		end

		self:UpdateTurretAngle(delta)

		if SERVER and found and self:CanFire() then
			self:FireGun()
		end
	end

	self.LastThink = CurTime()
	self:NextThink(CurTime() + 0.05)

	return true
end

if CLIENT then
	function ENT:UpdateParts()
	end

	function ENT:Draw()
		if self.Model then
			self:DrawModel()
		end

		TankLib.Part:Draw(self)
	end

	local col = Color(255, 0, 0, 20)

	function ENT:DrawDebug()
		local pos = self:WorldSpaceCenter()

		render.SetColorMaterial()
		render.DrawSphere(pos, self.Range, 20, 20, col)
		render.DrawSphere(pos, -self.Range, 20, 20, col)

		local target = self:GetTarget()

		self:DrawWorldText(Vector(0, 0, 12), string.format("Target: %s", target))
	end
else
	-- returns true if we have a target
	function ENT:FindTarget()
		local target_old = self:GetTarget()
		local target_new

		if not self:IsValidTarget(target_old, true) then
			target_old = nil
		end

		local distance_old = math.huge
		local distance_new = math.huge

		for _, v in pairs(self:GetTargets(self.MaxRange)) do
			local ent = v[1]
			local dist = v[2]

			if ent == target_old then
				distance_old = dist
			end

			if dist > distance_new then
				continue
			end

			if self:IsValidTarget(ent) then
				distance_new = dist
				target_new = ent
			end
		end

		if target_new then
			if target_new != target_old and distance_new < (distance_old * 0.75) then
				self:SetTarget(target_new)
			end

			return true
		end

		self:SetTarget(NULL)

		return false
	end

	function ENT:IsValidTarget(target, validate)
		if validate and not SquirrelDefense:IsValidTarget(target) then
			return false
		end

		local owner = self:GetGrid():GetOwner()

		if target:IsPlayer() and target == owner then
			return false
		elseif target:IsNPC() and target:Disposition(owner) == D_LI then
			return false
		end

		if not self:TestPVS(target) then
			return false
		end

		local tr = util.TraceLine({
			start = self:WorldSpaceCenter(),
			endpos = TankLib.Target:Get(target),
			filter = {self, self:GetParent(), target},
			mask = MASK_SHOT
		})

		if tr.Fraction != 1 then
			return false
		end

		return true
	end

	function ENT:FireGun()
	end
end

function ENT:GetShootPos()
	return self:WorldSpaceCenter()
end

function ENT:GetTargetAngle()
	local target = self:GetTarget()

	if not IsValid(target) then
		return self:GetParent():GetAngles()
	end

	return (TankLib.Target:Get(target) - self:GetShootPos()):Angle()
end

function ENT:UpdateTurretAngle(delta)
	local target = self:GetTargetAngle()

	local ang = self:GetAngles()
	local diff = target - ang

	diff:Normalize()

	local ratio = math.max(math.abs(diff.p), math.abs(diff.y))

	if ratio == 0 then
		return angle_zero
	end

	local pitch = math.ApproachAngle(ang.p, target.p, (diff.p / ratio) * self.TurnRate * delta)
	local yaw = math.ApproachAngle(ang.y, target.y, (diff.y / ratio) * self.TurnRate * delta)

	self.TurretDelta = target - self:SetTurretAngle(Angle(pitch, yaw, 0))
	self.TurretDelta.r = 0
	self.TurretDelta:Normalize()
end

function ENT:SetTurretAngle(ang)
	local _, lang = WorldToLocal(vector_origin, ang, vector_origin, self:GetParent():GetAngles())

	self.Yaw = lang.y

	ang.r = -lang.r

	self:SetAngles(ang)

	return ang
end