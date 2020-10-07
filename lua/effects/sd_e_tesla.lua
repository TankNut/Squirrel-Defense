EFFECT.Color = Color(255, 255, 255)
EFFECT.Mat = Material("sprites/rollermine_shock")

function EFFECT:Get(data, key, fallback)
	local val = data["Get" .. key](data)

	return val == 0 and fallback or val
end

function EFFECT:Init(data)
	self.Start = data:GetStart()
	self.End = data:GetOrigin()

	local distance = self.Start:Distance(self.End)

	self.Scale = self:Get(data, "Scale", 1)
	self.Radius = self:Get(data, "Radius", distance / 16)

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

	for i = 1, 4 do
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
			texture = texture + (previous and previous:Distance(v) / 32 or 0)

			if k == #data.Beams then
				self.Color.a = 0
			end

			render.AddBeam(v + VectorRand(), self.Scale * 16 - (data.Offshoot * 2), texture + 1, self.Color)

			previous = v
		end

		render.EndBeam()
	end
end