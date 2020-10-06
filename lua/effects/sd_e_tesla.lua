EFFECT.Mat = Material("sprites/rollermine_shock")
EFFECT.Color = Color(255, 255, 255)

function EFFECT:Init(data)
	self.Start = data:GetStart()
	self.End = data:GetOrigin()

	self.Scale = data:GetScale()
	self.Magnitude = data:GetMagnitude()
	self.Radius = data:GetRadius()

	if self.Scale == 0 then
		self.Scale = 1
	end

	if self.Magnitude == 0 then
		self.Magnitude = 1
	end

	local distance = self.Start:Distance(self.End)

	if self.Radius == 0 then
		self.Radius = distance / 16
	end

	self:SetRenderBoundsWS(self.Start, self.End)

	self.StartTime = CurTime()
	self.Lifetime = 0.1

	self:GenerateLightning()
end

function EFFECT:GenerateLightning()
	self.Beams = {{
		Beams = {self.Start, self.End},
		Offshoot = 1
	}}

	local subdivisions = self.Magnitude * 4

	for i = 1, subdivisions do
		local rand = self.Radius / i

		for j = 1, #self.Beams do
			local data = self.Beams[j]
			local new = {}

			table.insert(new, data.Beams[1])

			local offshoot = math.random(1, #data.Beams - 1)

			for k, origin in pairs(data.Beams) do
				if k == #data.Beams then
					break
				end

				local target = data.Beams[k + 1]

				local midpoint = (target + origin) * 0.5
				local direction = target - origin

				local offset = VectorRand(-rand, rand)

				offset.x = 0
				offset:Rotate(direction:Angle())

				local pos = midpoint + offset

				table.insert(new, pos)
				table.insert(new, target)

				if k == offshoot then
					table.insert(self.Beams, {
						Beams = {pos, pos + (direction * 0.4)},
						Offshoot = data.Offshoot + 1
					})
				end
			end

			data.Beams = new
		end
	end
end

function EFFECT:GetAlpha()
	return math.Remap(CurTime() - self.StartTime, 0, self.Lifetime, 255, 0)
end

function EFFECT:Think()
	if CurTime() - self.StartTime > self.Lifetime then
		return false
	end

	return true
end

function EFFECT:Render()
	local alpha = self:GetAlpha()

	if alpha < 0 then
		return
	end

	render.SetMaterial(self.Mat)

	for _, data in pairs(self.Beams) do
		render.StartBeam(#data.Beams)

		local beamalpha = alpha / (data.Offshoot ^ 2)

		if beamalpha < 1 then
			continue
		end

		self.Color.a = beamalpha

		local previous = nil
		local texture = 0

		for k, v in ipairs(data.Beams) do
			texture = texture + ((previous != nil) and (previous:Distance(v) / 32) or 0)

			if k == #data.Beams then
				self.Color.a = 0
			end

			render.AddBeam(v + VectorRand(), self.Scale * 16 - (data.Offshoot * 2), texture + 1, self.Color)

			previous = v
		end

		render.EndBeam()
	end
end