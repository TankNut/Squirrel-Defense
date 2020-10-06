AddCSLuaFile()

DEFINE_BASECLASS("sd_base")

ENT.Base 			= "sd_base"

ENT.RenderGroup 	= RENDERGROUP_BOTH

ENT.PrintName 		= "Tesla Coil"
ENT.Category 		= "Squirrel Defense"

ENT.Spawnable 		= true

ENT.SDCanConnect 	= true

ENT.Model 			= Model("models/hunter/blocks/cube05x05x05.mdl")

ENT.UseCustomPhys 	= false
ENT.PhysMin 		= Vector()
ENT.PhysMax 		= Vector()

ENT.ChargeTime 		= 2
ENT.Damage 			= 60

ENT.Range 			= 300
ENT.Delay 			= 0

ENT.Offset 			= Vector(0, 0, 48)

function ENT:Initialize()
	BaseClass.Initialize(self)

	self:SetChargeTime(CurTime())
end

function ENT:SetupDataTables()
	BaseClass.SetupDataTables(self)

	self:NetworkVar("Float", 0, "ChargeTime")
end

function ENT:SetupHooks()
	BaseClass.SetupHooks(self)

	if CLIENT then
		self:Hook("PostDrawTranslucentRenderables")
	end
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
		part:SetAngles(Angle(0, 0, 0))

		part = TankLib.Part:Create(TankLib.Part.Model, self)
		part:SetModel("models/props_c17/utilityconnecter006c.mdl")
		part:SetScale(1)
		part:SetPos(Vector(0, 0, 30))
		part:SetAngles(Angle(0, 0, 0))
	end

	local convar = GetConVar("developer")

	function ENT:DrawWorldText(offset, text)
		local pos = self:GetPos() + offset
		local ang = (pos - EyePos()):Angle()

		cam.Start3D2D(pos, Angle(0, ang.y - 90, 90), 0.25)
			render.PushFilterMag(TEXFILTER.NONE)
			render.PushFilterMin(TEXFILTER.NONE)
				surface.SetFont("BudgetLabel")

				local w, h = surface.GetTextSize(text)

				surface.SetTextColor(255, 255, 255, 255)
				surface.SetTextPos(-w * 0.5, -h * 0.5)

				surface.DrawText(text)
			render.PopFilterMin()
			render.PopFilterMag()
		cam.End3D2D()
	end

	function ENT:DrawTranslucent()
		if convar:GetBool() then
			local charge = self:GetCharge()

			self:DrawWorldText(Vector(0, 0, 63), string.format("Charge: %d%%", charge * 100))
		end
	end

	function ENT:PostDrawTranslucentRenderables()
		if convar:GetBool() then
			local pos = self:LocalToWorld(self.Offset)
			local color = Color(255, 0, 0, 50)

			render.SetColorMaterial()
			render.DrawSphere(pos, self.Range, 20, 20, color)
			render.DrawSphere(pos, -self.Range, 20, 20, color)
		end
	end
else
	function ENT:GetTarget(range, origin, blacklist)
		local pos = origin and origin:WorldSpaceCenter() or self:LocalToWorld(self.Offset)
		local max = range * range

		local targets = {}

		for _, v in pairs(self:GetGrid():GetTargets()) do
			if not IsValid(v) then
				continue
			end

			if blacklist and blacklist[v] then
				continue
			end

			local dist = pos:DistToSqr(v:WorldSpaceCenter())

			if dist >= max then
				continue
			end

			if self:IsValidTarget(v, origin) then
				targets[dist] = v
			end
		end

		for _, v in SortedPairs(targets) do
			return v
		end

		return NULL
	end

	function ENT:IsValidTarget(target, origin)
		local ent = origin or self

		if not SquirrelDefense:IsValidTarget(target) then
			return false
		end

		if not ent:TestPVS(target) then
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
		self.NextDischarge = nil

		local damage = self.Damage
		local range = self.Range

		local blacklist = {}

		local origin
		local target = self:GetTarget(self.Range)

		local function shoot()
			local pos = origin and origin:WorldSpaceCenter() or self:LocalToWorld(self.Offset)
			local tpos = TankLib.Target:Get(target)
			local dir = (tpos - pos):GetNormalized()

			local ed = EffectData()

			ed:SetStart(pos)
			ed:SetOrigin(tpos)
			ed:SetScale(damage / self.Damage)

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
			if self.NextDischarge then
				if self.NextDischarge <= CurTime() then
					self:Discharge()
				end
			elseif charge >= 1 then
				local target = self:GetTarget(self.Range)

				if IsValid(target) then
					self.NextDischarge = CurTime() + self.Delay
				end
			end
		end
	else
		self:SetChargeTime(CurTime())
	end

	self:NextThink(CurTime() + 0.05)

	return true
end