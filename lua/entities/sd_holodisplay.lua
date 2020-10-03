AddCSLuaFile()

DEFINE_BASECLASS("sd_base")

ENT.Base 			= "sd_base"

ENT.PrintName 		= "Holographic Display"
ENT.Category 		= "Squirrel Defense"

ENT.Spawnable 		= true

ENT.SDCanConnect 	= true

ENT.Radius 			= 10

ENT.DefaultRange 	= 2000
ENT.RangeSettings 	= {
	500,
	1000,
	2000,
	5000,
	10000
}

function ENT:Initialize()
	BaseClass.Initialize(self)

	self:SetModel("models/hunter/blocks/cube025x025x025.mdl")

	if SERVER then
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
	end

	self:SetRange(self.DefaultRange)
end

function ENT:SetupDataTables()
	BaseClass.SetupDataTables(self)

	self:NetworkVar("Int", 1, "Range")
end

function ENT:SetupHooks()
	BaseClass.SetupHooks(self)

	if CLIENT then
		self:Hook("PostDrawTranslucentRenderables")
	end
end

if CLIENT then
	local basecolor = Color(33, 255, 0)

	local color_red = Color(255, 0, 0)
	local color_green = Color(33, 255, 0)
	local color_yellow = Color(255, 255, 0)

	local resolution = 40

	local function circle(x, y, radius, seg)
		local tab = {}

		table.insert(tab, {
			x = x,
			y = y,
			u = 0.5,
			v = 0.5
		})

		for i = 0, seg do
			local a = math.rad((i / seg) * -360)

			table.insert(tab, {
				x = x + math.sin(a) * radius,
				y = y + math.cos(a) * radius,
				u = math.sin(a) / 2 + 0.5,
				v = math.cos(a) / 2 + 0.5
			})
		end

		local a = math.rad(0)

		table.insert(tab, {
			x = x + math.sin(a) * radius,
			y = y + math.cos(a) * radius,
			u = math.sin(a) / 2 + 0.5,
			v = math.cos(a) / 2 + 0.5
		})

		surface.DrawPoly(tab)
	end

	function ENT:DrawEntity(ent, col)
		local mult = self.Radius / self:GetRange()

		if not IsValid(ent) then
			return
		end

		local dist = (ent:GetPos() - self.DisplayOffset) * mult

		if dist:Length() > self.Radius then
			return
		end

		local ang = ent:GetAngles()
		local mins, maxs = ent:GetCollisionBounds()

		mins = mins * mult
		maxs = maxs * mult

		if ent == LocalPlayer() then
			ang.p = 0
		end

		render.DrawWireframeBox(self.DisplayPos + dist, ang, mins, maxs, col, true)

		local start = self.DisplayPos + dist
		local endpos = self.DisplayPos + Vector(dist.x, dist.y)

		if not endpos:WithinAABox(start + mins, start + maxs) then
			render.DrawLine(start, endpos, col, true)
		end
	end

	function ENT:DrawLine(pos1, pos2, col)
		local mult = self.Radius / self:GetRange()

		local dist1 = (pos1 - self.DisplayOffset) * mult
		local dist2 = (pos2 - self.DisplayOffset) * mult

		if dist1:Length() > self.Radius or dist2:Length() > self.Radius then
			return
		end

		render.DrawLine(self.DisplayPos + dist1, self.DisplayPos + dist2, col, true)
	end

	function ENT:PostDrawTranslucentRenderables()
		local grid = self:GetGrid()

		if not grid then
			return
		end

		self.DisplayPos = self:LocalToWorld(Vector(0, 0, 20))
		self.DisplayOffset = util.TraceLine({
			start = self.DisplayPos,
			endpos = self.DisplayPos - Vector(0, 0, 1024),
			mask = MASK_SOLID_BRUSHONLY
		}).HitPos

		if not self.PixVis then
			self.PixVis = util.GetPixelVisibleHandle()
		end

		local mult = util.PixelVisible(self.DisplayPos, self.Radius, self.PixVis)

		local noise = math.Rand(0.7, 1)

		local col1 = ColorAlpha(basecolor, 20 * mult * noise)
		local col2 = ColorAlpha(basecolor, 100 * mult * noise)

		color_red.a = 255 * mult * noise
		color_green.a = 255 * mult * noise
		color_yellow.a = 255 * mult * noise

		render.DrawWireframeSphere(self.DisplayPos, self.Radius, resolution, resolution, col1, false)
		render.DrawLine(self.DisplayPos + Vector(self.Radius, 0, 0), self.DisplayPos - Vector(self.Radius, 0, 0), col2, false)
		render.DrawLine(self.DisplayPos + Vector(0, self.Radius, 0), self.DisplayPos - Vector(0, self.Radius, 0), col2, false)
		render.DrawLine(self.DisplayPos + Vector(0, 0, self.Radius), self.DisplayPos - Vector(0, 0, self.Radius), col2, false)

		local ang = (self.DisplayPos - LocalPlayer():EyePos()):Angle()
		local scale = 10

		local start = self.DisplayPos + ang:Right() * self.Radius
		local offset = ang:Right() * self.Radius * 0.3 + Vector(0, 0, self.Radius * 0.5)

		surface.SetFont("DermaLarge")

		local w, h = surface.GetTextSize(self:GetRange())

		render.DrawLine(start, start + offset, col2, false)
		render.DrawLine(start + offset, start + offset + (w * (ang:Right() / scale)), col2, false)

		cam.Start3D2D(start + offset, Angle(0, ang.y - 90, 90), 1 / scale)
			surface.SetTextColor(col2)
			surface.SetTextPos(0, -h)
			surface.DrawText(self:GetRange())
		cam.End3D2D()

		cam.Start3D2D(self.DisplayPos, Angle(0, 0, 0), 1)
			draw.NoTexture()
			surface.SetDrawColor(col1)
			circle(0, 0, self.Radius, resolution)
		cam.End3D2D()

		cam.Start3D2D(self.DisplayPos, Angle(0, 0, 180), 1)
			draw.NoTexture()
			surface.SetDrawColor(col1)
			circle(0, 0, self.Radius, resolution)
		cam.End3D2D()

		for _, v in pairs(grid:GetTargets()) do
			self:DrawEntity(v, color_red)
		end

		for _, v in pairs(grid:GetFriendlies()) do
			self:DrawEntity(v, color_yellow)
		end

		for ent in pairs(grid:GetEntities()) do
			self:DrawEntity(ent, color_green)

			if ent.GetGun then
				local target = ent:GetGun():GetTarget()

				if IsValid(target) then
					self:DrawLine(ent:WorldSpaceCenter(), target:WorldSpaceCenter(), color_green)
				end
			end
		end
	end
end

properties.Add("sd_holodisplay_range", {
	MenuLabel = "Set Range",
	Order = 2,
	Filter = function(self, ent, ply)
		if not IsValid(ent) then return false end
		if ent:GetClass() != "sd_holodisplay" then return false end
		if not gamemode.Call("CanProperty", ply, "sd_holodisplay_range", ent) then return false end

		return ent:GetGrid() and ent:GetGrid():GetOwner() == ply
	end,
	Action = function(self, ent) end,
	Receive = function(self, len, ply)
		local ent = net.ReadEntity()
		local index = net.ReadUInt(6)

		if not properties.CanBeTargeted(ent, ply) then return end
		if not self:Filter(ent, ply) then return end

		ent:SetRange(ent.RangeSettings[index] or ent.DefaultRange)
	end,
	MenuOpen = function(self, dmenu, ent, tr)
		local submenu = dmenu:AddSubMenu()

		for k, v in pairs(ent.RangeSettings) do
			submenu:AddOption(v .. " units", function() self:SetRange(ent, k) end)
		end
	end,
	SetRange = function(self, ent, index)
		self:MsgStart()
			net.WriteEntity(ent)
			net.WriteUInt(index, 6)
		self:MsgEnd()
	end
})