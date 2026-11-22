-- The survey print is a still-life of the player who just split the specimen.
-- Photograph the character and the dressed pick through the film's own lens.
local F = require(script.Parent.ExposureSheet).frames
local SurveyPrint = require(script.Parent.SurveyPrint)
local Portrait = {}
Portrait.__index = Portrait

local function viewport(parent, name, z)
	local view = Instance.new("ViewportFrame")
	view.Name, view.BackgroundTransparency, view.BorderSizePixel = name, 1, 0
	view.Size, view.ZIndex, view.Parent = UDim2.fromScale(1, 1), z, parent
	local camera = Instance.new("Camera")
	camera.Parent, view.CurrentCamera = view, camera
	local world = Instance.new("WorldModel")
	world.Name, world.Parent = "Isolated subject", view
	return { view = view, eye = camera, world = world }
end

local function removeFromPrint(item)
	return item:IsA("LuaSourceContainer")
		or item:IsA("Tool")
		or item:IsA("Constraint")
		or item:IsA("JointInstance")
		or item:IsA("Animator")
		or item:IsA("BodyMover")
		or item:IsA("LayerCollector")
		or item:IsA("Sound")
		or item:IsA("ParticleEmitter")
		or item:IsA("Trail")
		or item:IsA("Beam")
		or item:IsA("Highlight")
		or item:IsA("Light")
		or item:IsA("ForceField")
		or item:IsA("Fire")
		or item:IsA("Smoke")
		or item:IsA("Sparkles")
end

local function register(source, copy, poses, ink)
	local siblings = {}
	for _, child in source:GetChildren() do
		if child.Archivable then
			local key = child.ClassName .. "|" .. child.Name
			local list = siblings[key] or {}
			list[#list + 1], siblings[key] = child, list
		end
	end
	for _, child in copy:GetChildren() do
		local list = siblings[child.ClassName .. "|" .. child.Name]
		local original = list and table.remove(list, 1)
		if not original or removeFromPrint(child) then
			child:Destroy()
		elseif
			ink
			and (
				child:IsA("SurfaceAppearance")
				or child:IsA("Decal")
				or child:IsA("Clothing")
				or child:IsA("ShirtGraphic")
				or child:IsA("BodyColors")
			)
		then
			child:Destroy()
		else
			if child:IsA("BasePart") then
				child.Anchored, child.CanCollide, child.CanTouch, child.CanQuery = true, false, false, false
				child.CastShadow = false
				if ink then
					child.Color, child.Material = Color3.fromHex("EEC894"), Enum.Material.SmoothPlastic
					if child:IsA("MeshPart") then
						child.TextureID = ""
					end
				end
				poses[#poses + 1] = { original, child }
			elseif ink and child:IsA("SpecialMesh") then
				child.TextureId, child.VertexColor = "", Vector3.one
			elseif child:IsA("Humanoid") then
				child.DisplayDistanceType, child.EvaluateStateMachine = Enum.HumanoidDisplayDistanceType.None, false
			elseif child:IsA("Bone") then
				poses[#poses + 1] = { original, child, true }
			end
			register(original, child, poses, ink)
		end
	end
end

local function copySubject(source, layer, poses, ink)
	local was = source.Archivable
	source.Archivable = true
	local ok, copy = pcall(source.Clone, source)
	source.Archivable = was
	if not ok or not copy then
		return
	end
	register(source, copy, poses, ink)
	copy.Parent = layer.world
end

function Portrait.new(stage, screen)
	local root = Instance.new("Frame")
	root.Name, root.BorderSizePixel, root.BackgroundTransparency = "Fault reader | two-ink registration", 0, 1
	root.Size, root.ZIndex, root.Visible = UDim2.fromScale(1, 1), 3, false
	root.ClipsDescendants, root.Parent = true, screen
	return setmetatable({ stage = stage, root = root }, Portrait)
end

function Portrait:prepare(character, pick)
	if not self.art then
		self.art = SurveyPrint.new(self.root)
		self.under = viewport(self.root, "Warm cut edge", 5)
		self.under.view.Ambient, self.under.view.LightColor = Color3.new(1, 1, 1), Color3.new()
		self.subject = viewport(self.root, "Player and shouldered pick", 6)
		self.subject.view.Ambient = Color3.fromHex("CAD2D9")
		self.subject.view.LightColor = Color3.fromHex("FFDFC4")
	end
	if self.character == character and self.pick == pick then
		return
	end
	self.character, self.pick, self.poses = character, pick, {}
	for index, layer in { self.under, self.subject } do
		layer.world:ClearAllChildren()
		copySubject(character, layer, self.poses, index == 1)
		if pick then
			copySubject(pick, layer, self.poses, index == 1)
		end
	end
end

function Portrait:draw(actor, camera, frame, motion)
	local root = actor and actor.root
	local character = root and root.Parent
	if
		not character
		or not character:IsA("Model")
		or not actor.head
		or not actor.head.Parent
		or frame < F.portrait - 12
		or frame >= F.commission
	then
		self.root.Visible = false
		return
	end
	local pick = actor.assay and actor.assay.tool
	self:prepare(character, pick and pick.Parent and pick)
	if frame < F.portrait or #self.poses == 0 then
		self.root.Visible = false
		return
	end
	for _, pair in self.poses do
		local original, copy = pair[1], pair[2]
		if original.Parent then
			if pair[3] then
				copy.Transform = original.Transform
			else
				copy.CFrame, copy.Transparency = original.CFrame, original.Transparency
				copy.LocalTransparencyModifier = original.LocalTransparencyModifier
			end
		elseif not pair[3] then
			copy.Transparency = 1
		end
	end
	local size = camera.ViewportSize
	local offset = math.max(2, math.round(math.min(size.X, size.Y) * 0.0055))
	local face = camera:WorldToViewportPoint(actor.head.Position)
	self.root.Visible = true
	self.under.view.Position = UDim2.fromOffset(-offset, offset)
	self.subject.view.LightDirection = camera.CFrame:VectorToWorldSpace(Vector3.new(0.57, -0.72, -0.49))
	for _, layer in { self.subject, self.under } do
		layer.eye.CFrame, layer.eye.FieldOfView = camera.CFrame, camera.FieldOfView
	end
	self.art:draw(size, face, frame - F.portrait, motion)
end

function Portrait:Destroy()
	self.root:Destroy()
	self.poses, self.character, self.pick = nil, nil, nil
end

return Portrait
