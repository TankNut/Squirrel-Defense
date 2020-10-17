AddCSLuaFile()

DEFINE_BASECLASS("sd_base")

ENT.Base 			= "sd_base"

ENT.RenderGroup 	= RENDERGROUP_BOTH

ENT.PrintName 		= "Tesla Coil"
ENT.Category 		= "Squirrel Defense"

ENT.Spawnable 		= true

ENT.SDCanConnect 	= true

ENT.Model 			= Model("models/hunter/blocks/cube05x05x05.mdl")

ENT.UseCustomPhys 	= true
ENT.PhysMin 		= Vector(-12, -12, -12)
ENT.PhysMax 		= Vector(12, 12, 60)

ENT.ChargeTime 		= 2
ENT.DPS 			= 30

ENT.Range 			= 500

ENT.Offset 			= Vector(0, 0, 48)

function ENT:Initialize()
	BaseClass.Initialize(self)

	self:SetChargeTime(CurTime())
end

function ENT:SetupDataTables()
	BaseClass.SetupDataTables(self)

	self:NetworkVar("Float", 0, "ChargeTime")
end

if CLIENT then
	function ENT:SetupParts()
		BaseClass.SetupParts(self)

		local part

		part = TankLib.Part:Create(TankLib.Part.Model, self)
		part:SetModel("models/XQM/Rails/gumball_1.mdl")
		part:SetMaterial("phoenix_storms/Fender_chrome")
		part:SetScale(0.75)
		part:SetPos(self.Offset)
		part:SetAngles(Angle(90, 0, 0))

		part = TankLib.Part:Create(TankLib.Part.Model, self)
		part:SetModel("models/props_c17/utilityconnecter006c.mdl")
		part:SetScale(1)
		part:SetPos(Vector(0, 0, 30))
		part:SetAngles(Angle(0, 0, 0))
	end

	function ENT:DrawDebug()
		local pos = self:LocalToWorld(self.Offset)
		local color = Color(255, 0, 0, 10)

		render.SetColorMaterial()
		render.DrawSphere(pos, self.Range, 20, 20, color)
		render.DrawSphere(pos, -self.Range, 20, 20, color)

		local charge = self:GetCharge()

		self:DrawWorldText(Vector(0, 0, 63), string.format("Charge: %d%%", charge * 100))
	end
else
	function ENT:GetTarget(range, origin, blacklist)
		local pos = origin and origin:WorldSpaceCenter() or self:LocalToWorld(self.Offset)

		local targets = {}

		for _, v in pairs(self:GetTargets(range, pos)) do
			local ent = v[1]
			local dist = v[2]

			if blacklist and blacklist[ent] then
				continue
			end

			if self:IsValidTarget(ent, origin) then
				targets[dist] = ent
			end
		end

		for _, v in SortedPairs(targets) do
			return v
		end

		return NULL
	end

	function ENT:IsValidTarget(target, origin)
		local ent = origin or self

		if not ent:TestPVS(target) then
			return false
		end

		local owner = self:GetGrid():GetOwner()

		if target:IsPlayer() and target == owner then
			return false
		elseif target:IsNPC() and target:Disposition(owner) == D_LI then
			return false
		end

		local tr = util.TraceLine({
			start = ent:WorldSpaceCenter(),
			endpos = TankLib.Target:Get(target),
			filter = {ent, target},
			mask = MASK_SHOT
		})

		if tr.Fraction != 1 then
			return false
		end

		return true
	end

	function ENT:Discharge()
		self:EmitSound("ambient.electrical_random_zap_1")

		self:SetChargeTime(CurTime())

		local damage = self.DPS * self.ChargeTime
		local range = self.Range

		local blacklist = {}

		local origin
		local target = self:GetTarget(range)

		local function shoot()
			local pos = origin and origin:WorldSpaceCenter() or self:LocalToWorld(self.Offset)
			local tpos = TankLib.Target:Get(target)
			local dir = (tpos - pos):GetNormalized()

			local ed = EffectData()

			ed:SetStart(pos)
			ed:SetOrigin(tpos)

			util.Effect("sd_e_tesla", ed)

			local dmg = DamageInfo()

			dmg:SetDamage(damage)
			dmg:SetAttacker(self)
			dmg:SetInflictor(self)
			dmg:SetDamageType(DMG_SHOCK)
			dmg:SetReportedPosition(pos)
			dmg:SetDamageForce(dir * damage * 167) -- Idk where this constant came from but it's what you get when you compare the force given to ent:FireBullet() with the resulting GetDamageForce in the callback
			dmg:SetDamagePosition(tpos)

			target:TakeDamageInfo(dmg)
		end

		while IsValid(target) do
			shoot()

			range = range * 0.6

			blacklist[target] = true

			origin = target
			target = self:GetTarget(range, origin, blacklist)
		end
	end
end

function ENT:GetCharge()
	local time = CurTime() - self:GetChargeTime()

	return math.min(time / self.ChargeTime, 1)
end

function ENT:Think()
	local grid = self:GetGrid()

	if grid then
		local charge = self:GetCharge()

		if CLIENT then
			local pos = self:LocalToWorld(self.Offset)
			local ang = AngleRand()

			ang.r = 0

			local ed = EffectData()

			ed:SetStart(pos)
			ed:SetOrigin(pos + ang:Forward() * 5)
			ed:SetScale(charge * 0.5)
			ed:SetRadius(16 * charge)

			util.Effect("sd_e_tesla", ed)
		elseif SERVER then
			if charge >= 1 then
				local target = self:GetTarget(self.Range)

				if IsValid(target) then
					self:Discharge()
				end
			end
		end
	else
		self:SetChargeTime(CurTime())
	end

	self:NextThink(CurTime() + 0.05)

	return true
end