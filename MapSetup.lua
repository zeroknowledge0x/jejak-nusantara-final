--[[
	Jejak Nusantara Final — MapSetup.lua
	Auto-generates: terrain, buildings, NPCs, decorations for all 4 levels.
	Taruh di ServerScriptService (bersama GameServer.lua).
	Level akan auto-create saat player masuk.
	Mata kuliah: Pengembangan Game (MBKP-07.03.310)
	Team: Daffa Rifqi A.F (PM), Mahda Vidho Pratama, Sakti Hermawan, Rakha Andrianto Q.A
]]

local Workspace = game:GetService("Workspace")
local ServerStorage = game:GetService("ServerStorage")

---------------------------------------------------------------------
-- CONSTANTS
---------------------------------------------------------------------
local LEVEL_POSITIONS = {
	Desa_Budaya       = Vector3.new(0, 0, 0),
	Sanggar_Seni      = Vector3.new(200, 0, 0),
	Pasar_Tradisional = Vector3.new(400, 0, 0),
	Tempat_Bersejarah = Vector3.new(600, 0, 0),
}

local NPC_DATA = {
	-- Level 1: Desa Budaya
	{ name = "Sesepuh Angklung",   level = "Desa_Budaya",       pos = Vector3.new(15, 3, 10),  dialog = "Selamat datang, anak muda. Mau belajar angklung?" },
	{ name = "Pengrajin Bambu",    level = "Desa_Budaya",       pos = Vector3.new(-10, 3, 15), dialog = "Angklung terbuat dari bambu pilihan. Mari saya ajari." },
	{ name = "Penari Sunda",       level = "Desa_Budaya",       pos = Vector3.new(20, 3, -5),  dialog = "Tari Jaipong adalah warisan leluhur kita." },
	{ name = "Petani Padi",        level = "Desa_Budaya",       pos = Vector3.new(-5, 3, -15), dialog = "Sawah ini sudah diwariskan turun-temurun." },
	{ name = "Ibu Penjual Kue",    level = "Desa_Budaya",       pos = Vector3.new(8, 3, 20),   dialog = "Coba dodol Garut, khas Jawa Barat!" },
	{ name = "Rahasia (di Balik Sawah)", level = "Desa_Budaya", pos = Vector3.new(-25, 3, -25), dialog = "Kamu menemukan saya! Ini rahasia: ada gua tersembunyi di sini.", hidden = true },

	-- Level 2: Sanggar Seni
	{ name = "Maestro Gamelan",    level = "Sanggar_Seni",      pos = Vector3.new(215, 3, 10), dialog = "Gamelan sudah ada sejak abad ke-8. Mari dengarkan." },
	{ name = "Pelukis Batik",      level = "Sanggar_Seni",      pos = Vector3.new(190, 3, 15), dialog = "Setiap motif batik punya makna mendalam." },
	{ name = "Penari Topeng",      level = "Sanggar_Seni",      pos = Vector3.new(205, 3, -10), dialog = "Tari Topeng menceritakan kisah panji." },
	{ name = "Dalang Wayang",      level = "Sanggar_Seni",      pos = Vector3.new(220, 3, 5),  dialog = "Wayang kulit diakui UNESCO sebagai warisan budaya." },
	{ name = "Pemahat Kayu",       level = "Sanggar_Seni",      pos = Vector3.new(195, 3, -20), dialog = "Ukiran Jepara terkenal ke seluruh dunia." },

	-- Level 3: Pasar Tradisional
	{ name = "Pedagang Batik",     level = "Pasar_Tradisional", pos = Vector3.new(415, 3, 10), dialog = "Batik tulis asli, harga bisa ditawar!" },
	{ name = "Penjual Rempah",     level = "Pasar_Tradisional", pos = Vector3.new(390, 3, 15), dialog = "Rempah-rempah Nusantara terkenal sejak zaman Majapahit." },
	{ name = "Tukang Emas",        level = "Pasar_Tradisional", pos = Vector3.new(405, 3, -10), dialog = "Perhiasan tradisional Minangkabau, indah bukan?" },
	{ name = "Penjual Makanan",    level = "Pasar_Tradisional", pos = Vector3.new(420, 3, 5),  dialog = "Rendang, nasi goreng, sate — semua ada!" },
	{ name = "Pedagang Kerajinan", level = "Pasar_Tradisional", pos = Vector3.new(395, 3, -20), dialog = "Anyaman rotan dari Kalimantan, dibuat tangan." },

	-- Level 4: Tempat Bersejarah
	{ name = "Pemandu Candi",      level = "Tempat_Bersejarah", pos = Vector3.new(615, 3, 10), dialog = "Candi ini dibangun abad ke-9 oleh Dinasti Syailendra." },
	{ name = "Arkeolog",           level = "Tempat_Bersejarah", pos = Vector3.new(590, 3, 15), dialog = "Kami menemukan prasasti kuno di sini." },
	{ name = "Sejarawan",          level = "Tempat_Bersejarah", pos = Vector3.new(605, 3, -10), dialog = "Majapahit pernah menguasai seluruh Nusantara." },
	{ name = "Penjaga Museum",     level = "Tempat_Bersejarah", pos = Vector3.new(620, 3, 5),  dialog = "Museum ini menyimpan artefak dari kerajaan-kerajaan Nusantara." },
}

---------------------------------------------------------------------
-- MATERIAL & COLOR PRESETS
---------------------------------------------------------------------
local MAT = Enum.Material
local function c3(r, g, b) return Color3.fromRGB(r, g, b) end

local LEVEL_STYLES = {
	Desa_Budaya = {
		groundColor = c3(86, 140, 50),   groundMat = MAT.Grass,
		wallColor   = c3(160, 120, 60),   wallMat   = MAT.Wood,
		roofColor   = c3(140, 60, 30),    roofMat   = MAT.WoodPlanks,
		accentColor = c3(218, 165, 32),
		waterColor  = c3(50, 130, 180),   waterMat  = MAT.Water,
		treeColor   = c3(40, 120, 40),    treeMat   = MAT.LeafyGrass,
	},
	Sanggar_Seni = {
		groundColor = c3(180, 150, 100),  groundMat = MAT.Sand,
		wallColor   = c3(170, 130, 70),   wallMat   = MAT.Brick,
		roofColor   = c3(120, 50, 20),    roofMat   = MAT.Slate,
		accentColor = c3(200, 50, 50),
		waterColor  = c3(60, 140, 190),   waterMat  = MAT.Water,
		treeColor   = c3(50, 130, 50),    treeMat   = MAT.LeafyGrass,
	},
	Pasar_Tradisional = {
		groundColor = c3(160, 140, 100),  groundMat = MAT.Cobblestone,
		wallColor   = c3(180, 160, 120),  wallMat   = MAT.Concrete,
		roofColor   = c3(200, 80, 30),    roofMat   = MAT.Slate,
		accentColor = c3(255, 200, 50),
		waterColor  = c3(40, 120, 170),   waterMat  = MAT.Water,
		treeColor   = c3(60, 140, 60),    treeMat   = MAT.LeafyGrass,
	},
	Tempat_Bersejarah = {
		groundColor = c3(140, 130, 100),  groundMat = MAT.Slate,
		wallColor   = c3(150, 140, 110),  wallMat   = MAT.Stone,
		roofColor   = c3(100, 90, 70),    roofMat   = MAT.Basalt,
		accentColor = c3(180, 160, 80),
		waterColor  = c3(30, 100, 150),   waterMat  = MAT.Water,
		treeColor   = c3(35, 100, 35),    treeMat   = MAT.LeafyGrass,
	},
}

---------------------------------------------------------------------
-- HELPER FUNCTIONS
---------------------------------------------------------------------
local function createPart(props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.Size = props.Size or Vector3.new(4, 4, 4)
	p.Position = props.Position or Vector3.new(0, 0, 0)
	p.Color = props.Color or Color3.new(1, 1, 1)
	p.Material = props.Material or Enum.Material.SmoothPlastic
	p.Name = props.Name or "Part"
	if props.Transparency then p.Transparency = props.Transparency end
	if props.CanCollide ~= nil then p.CanCollide = props.CanCollide end
	if props.Shape then p.Shape = props.Shape end
	if props.CFrame then p.CFrame = props.CFrame end
	p.Parent = props.Parent or Workspace
	return p
end

local function createModel(name, parent)
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent or Workspace
	return m
end

local function createSpotlight(parent, color, brightness, range)
	local light = Instance.new("SpotLight")
	light.Color = color or Color3.new(1, 1, 0.8)
	light.Brightness = brightness or 1
	light.Range = range or 20
	light.Face = Enum.NormalId.Top
	light.Parent = parent
end

---------------------------------------------------------------------
-- BUILD LEVEL STRUCTURES
---------------------------------------------------------------------

-- Ground platform
local function buildGround(levelKey, origin, style)
	local model = createModel(levelKey .. "_Ground", Workspace)

	-- Main ground
	createPart({
		Name = "Floor",
		Size = Vector3.new(120, 2, 120),
		Position = origin - Vector3.new(0, 1, 0),
		Color = style.groundColor,
		Material = style.groundMat,
		Parent = model,
	})

	-- Decorative border
	for _, offset in ipairs({
		Vector3.new(-60, 0, 0), Vector3.new(60, 0, 0),
		Vector3.new(0, 0, -60), Vector3.new(0, 0, 60),
	}) do
		createPart({
			Name = "Border",
			Size = Vector3.new(offset.X == 0 and 120 or 2, 4, offset.Z == 0 and 120 or 2),
			Position = origin + offset + Vector3.new(0, 1, 0),
			Color = style.accentColor,
			Material = Enum.Material.SmoothPlastic,
			Parent = model,
		})
	end

	return model
end

-- Rumah adat / building
local function buildRumah(origin, style, name, size)
	local w = size and size.X or 14
	local h = size and size.Y or 8
	local d = size and size.Z or 12
	local model = createModel(name or "Rumah", Workspace)

	-- Walls
	createPart({
		Name = "Wall1", Size = Vector3.new(w, h, 1),
		Position = origin + Vector3.new(0, h/2, d/2),
		Color = style.wallColor, Material = style.wallMat, Parent = model,
	})
	createPart({
		Name = "Wall2", Size = Vector3.new(w, h, 1),
		Position = origin + Vector3.new(0, h/2, -d/2),
		Color = style.wallColor, Material = style.wallMat, Parent = model,
	})
	createPart({
		Name = "Wall3", Size = Vector3.new(1, h, d),
		Position = origin + Vector3.new(-w/2, h/2, 0),
		Color = style.wallColor, Material = style.wallMat, Parent = model,
	})
	createPart({
		Name = "Wall4", Size = Vector3.new(1, h, d),
		Position = origin + Vector3.new(w/2, h/2, 0),
		Color = style.wallColor, Material = style.wallMat, Parent = model,
	})

	-- Floor
	createPart({
		Name = "Floor", Size = Vector3.new(w, 0.5, d),
		Position = origin + Vector3.new(0, 0.25, 0),
		Color = style.wallColor, Material = style.wallMat, Parent = model,
	})

	-- Roof (pyramid approximation)
	createPart({
		Name = "Roof", Size = Vector3.new(w + 4, 1, d + 4),
		Position = origin + Vector3.new(0, h + 0.5, 0),
		Color = style.roofColor, Material = style.roofMat, Parent = model,
	})
	createPart({
		Name = "RoofPeak", Size = Vector3.new(w * 0.4, 2, d * 0.4),
		CFrame = CFrame.new(origin + Vector3.new(0, h + 3, 0)) * CFrame.Angles(0, 0, 0),
		Color = style.roofColor, Material = style.roofMat, Parent = model,
	})

	-- Door opening (transparent)
	createPart({
		Name = "Door", Size = Vector3.new(3, 5, 1.2),
		Position = origin + Vector3.new(0, 2.5, d/2),
		Color = Color3.fromRGB(80, 50, 20),
		Material = Enum.Material.Wood,
		Transparency = 0.3,
		Parent = model,
	})

	-- Window
	createPart({
		Name = "Window", Size = Vector3.new(2, 2, 1.2),
		Position = origin + Vector3.new(w/4, h/2 + 1, d/2),
		Color = Color3.fromRGB(150, 200, 230),
		Material = Enum.Material.Neon,
		Transparency = 0.5,
		Parent = model,
	})

	return model
end

-- Tree
local function buildTree(origin, style, height)
	local h = height or math.random(8, 14)
	local model = createModel("Tree", Workspace)

	-- Trunk
	createPart({
		Name = "Trunk", Size = Vector3.new(1.5, h, 1.5),
		Position = origin + Vector3.new(0, h/2, 0),
		Color = Color3.fromRGB(100, 70, 30),
		Material = Enum.Material.Wood,
		Shape = Enum.PartType.Cylinder,
		Parent = model,
	})

	-- Canopy (3 layers)
	for i = 0, 2 do
		local s = 8 - i * 2
		createPart({
			Name = "Canopy" .. i,
			Size = Vector3.new(s, 3, s),
			Position = origin + Vector3.new(0, h + i * 2, 0),
			Color = style.treeColor,
			Material = style.treeMat,
			Shape = Enum.PartType.Ball,
			Parent = model,
		})
	end

	return model
end

-- Water (kolam/sungai)
local function buildWater(origin, style, size)
	createPart({
		Name = "Water",
		Size = size or Vector3.new(20, 0.3, 20),
		Position = origin,
		Color = style.waterColor,
		Material = style.waterMat,
		Transparency = 0.4,
		CanCollide = false,
		Parent = Workspace,
	})
end

-- Pagoda / Candi
local function buildCandi(origin, style, height)
	local h = height or 12
	local model = createModel("Candi", Workspace)

	-- Base tiers
	for i = 0, 3 do
		local s = 16 - i * 3
		local y = i * 3
		createPart({
			Name = "Tier" .. i,
			Size = Vector3.new(s, 3, s),
			Position = origin + Vector3.new(0, y + 1.5, 0),
			Color = style.wallColor,
			Material = style.wallMat,
			Parent = model,
		})

		-- Decorative stairs on each tier
		if i < 3 then
			createPart({
				Name = "Stairs" .. i,
				Size = Vector3.new(3, 1, 3),
				Position = origin + Vector3.new(0, y + 0.5, s/2 + 1),
				Color = style.accentColor,
				Material = Enum.Material.SmoothPlastic,
				Parent = model,
			})
		end
	end

	-- Top stupa
	createPart({
		Name = "Stupa",
		Size = Vector3.new(4, 6, 4),
		Position = origin + Vector3.new(0, 15, 0),
		Color = style.accentColor,
		Material = Enum.Material.Neon,
		Transparency = 0.2,
		Shape = Enum.PartType.Ball,
		Parent = model,
	})

	return model
end

-- Stage (panggung)
local function buildStage(origin, style, name)
	local model = createModel(name or "Panggung", Workspace)

	-- Platform
	createPart({
		Name = "Stage", Size = Vector3.new(20, 1.5, 14),
		Position = origin + Vector3.new(0, 0.75, 0),
		Color = style.wallColor,
		Material = style.wallMat,
		Parent = model,
	})

	-- Backdrop
	createPart({
		Name = "Backdrop", Size = Vector3.new(20, 10, 1),
		Position = origin + Vector3.new(0, 6, -7),
		Color = style.accentColor,
		Material = Enum.Material.SmoothPlastic,
		Parent = model,
	})

	-- Pillars
	for _, x in ipairs({-9, 9}) do
		createPart({
			Name = "Pillar", Size = Vector3.new(1.5, 10, 1.5),
			Position = origin + Vector3.new(x, 6, 6),
			Color = style.accentColor,
			Material = Enum.Material.SmoothPlastic,
			Parent = model,
		})
	end

	return model
end

-- Market stall (kios pasar)
local function buildStall(origin, style, name, color)
	local model = createModel(name or "Kios", Workspace)

	-- Table
	createPart({
		Name = "Table", Size = Vector3.new(8, 1, 5),
		Position = origin + Vector3.new(0, 2, 0),
		Color = Color3.fromRGB(140, 100, 50),
		Material = Enum.Material.Wood,
		Parent = model,
	})

	-- Roof
	createPart({
		Name = "Roof", Size = Vector3.new(10, 0.5, 7),
		Position = origin + Vector3.new(0, 5, 0),
		Color = color or style.roofColor,
		Material = style.roofMat,
		Parent = model,
	})

	-- Poles
	for _, xOff in ipairs({-4, 4}) do
		for _, zOff in ipairs({-2.5, 2.5}) do
			createPart({
				Name = "Pole", Size = Vector3.new(0.5, 4, 0.5),
				Position = origin + Vector3.new(xOff, 3.5, zOff),
				Color = Color3.fromRGB(120, 80, 30),
				Material = Enum.Material.Wood,
				Parent = model,
			})
		end
	end

	-- Items on table
	for i = 1, 3 do
		createPart({
			Name = "Item" .. i,
			Size = Vector3.new(1.5, 1.5, 1.5),
			Position = origin + Vector3.new(-2 + i * 2, 3, 0),
			Color = color or style.accentColor,
			Material = Enum.Material.SmoothPlastic,
			Shape = Enum.PartType.Ball,
			Parent = model,
		})
	end

	return model
end

---------------------------------------------------------------------
-- NPC CREATION
---------------------------------------------------------------------
local function createNPC(npcInfo, origin)
	local pos = origin + npcInfo.pos
	local model = createModel("NPC_" .. npcInfo.name, Workspace)

	-- Body
	local body = createPart({
		Name = "Body",
		Size = Vector3.new(2, 4, 1.5),
		Position = pos,
		Color = Color3.fromRGB(200, 160, 100),
		Material = Enum.Material.SmoothPlastic,
		Parent = model,
	})

	-- Head
	createPart({
		Name = "Head",
		Size = Vector3.new(1.5, 1.5, 1.5),
		Shape = Enum.PartType.Ball,
		Position = pos + Vector3.new(0, 3.25, 0),
		Color = Color3.fromRGB(220, 180, 130),
		Material = Enum.Material.SmoothPlastic,
		Parent = model,
	})

	-- NPC name tag (BillboardGui)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "NameTag"
	billboard.Size = UDim2.new(0, 200, 0, 50)
	billboard.StudsOffset = Vector3.new(0, 5, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = body

	local nameLabel = Instance.new("TextLabel")
 nameLabel.Size = UDim2.new(1, 0, 0.6, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = npcInfo.name
	nameLabel.TextColor3 = Color3.fromRGB(255, 248, 230)
	nameLabel.TextSize = 14
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextStrokeTransparency = 0.5
	nameLabel.Parent = billboard

	if npcInfo.dialog then
		local hintLabel = Instance.new("TextLabel")
		hintLabel.Size = UDim2.new(1, 0, 0.4, 0)
		hintLabel.Position = UDim2.new(0, 0, 0.6, 0)
		hintLabel.BackgroundTransparency = 1
		hintLabel.Text = "[E] Bicara"
		hintLabel.TextColor3 = Color3.fromRGB(218, 165, 32)
		hintLabel.TextSize = 12
		hintLabel.Font = Enum.Font.Gotham
		hintLabel.TextStrokeTransparency = 0.5
		hintLabel.Parent = billboard
	end

	-- Store NPC data as attributes
	body:SetAttribute("NPC_Name", npcInfo.name)
	body:SetAttribute("NPC_Dialog", npcInfo.dialog or "")
	body:SetAttribute("NPC_Level", npcInfo.level)
	body:SetAttribute("NPC_Hidden", npcInfo.hidden or false)

	-- Proximity detection (ClickDetector)
	local click = Instance.new("ClickDetector")
	click.MaxActivationDistance = 15
	click.Parent = body

	-- Interaction via ClickDetector (backup for E key)
	click.MouseClick:Connect(function(player)
		-- Fire to GameServer
		local remotes = game.ReplicatedStorage:FindFirstChild("JN_Remotes")
		if remotes then
			local re = remotes:FindFirstChild("PlayerAction")
			if re then
				re:FireServer("talk_npc", npcInfo.name)
			end
		end
	end)

	return model
end

---------------------------------------------------------------------
-- BUILD ALL LEVELS
---------------------------------------------------------------------
local function buildAllLevels()
	print("[MapSetup] Building Jejak Nusantara world...")

	-- Spawn area (center)
	createPart({
		Name = "SpawnPlatform",
		Size = Vector3.new(30, 1, 30),
		Position = Vector3.new(-50, 0, 0),
		Color = Color3.fromRGB(218, 165, 32),
		Material = Enum.Material.Neon,
		Transparency = 0.3,
		Parent = Workspace,
	})

	-- Arch gate
	createPart({
		Name = "GateLeft",
		Size = Vector3.new(2, 12, 2),
		Position = Vector3.new(-20, 6, -6),
		Color = Color3.fromRGB(218, 165, 32),
		Material = Enum.Material.SmoothPlastic,
		Parent = Workspace,
	})
	createPart({
		Name = "GateRight",
		Size = Vector3.new(2, 12, 2),
		Position = Vector3.new(-20, 6, 6),
		Color = Color3.fromRGB(218, 165, 32),
		Material = Enum.Material.SmoothPlastic,
		Parent = Workspace,
	})
	createPart({
		Name = "GateTop",
		Size = Vector3.new(2, 2, 14),
		Position = Vector3.new(-20, 12, 0),
		Color = Color3.fromRGB(218, 165, 32),
		Material = Enum.Material.SmoothPlastic,
		Parent = Workspace,
	})

	local welcomeSign = Instance.new("Part")
	welcomeSign.Name = "WelcomeSign"
	welcomeSign.Size = Vector3.new(12, 3, 0.5)
	welcomeSign.Position = Vector3.new(-20, 14, 0)
	welcomeSign.Color = Color3.fromRGB(60, 40, 20)
	welcomeSign.Material = Enum.Material.Wood
	welcomeSign.Anchored = true
	welcomeSign.Parent = Workspace

	local signGui = Instance.new("SurfaceGui")
	signGui.Face = Enum.NormalId.Front
	signGui.Parent = welcomeSign

	local signText = Instance.new("TextLabel")
	signText.Size = UDim2.new(1, 0, 1, 0)
	signText.BackgroundTransparency = 1
	signText.Text = "🇮🇩 JEJAK NUSANTARA 🇮🇩\nPetualangan Budaya Indonesia"
	signText.TextColor3 = Color3.fromRGB(255, 248, 230)
	signText.TextSize = 18
	signText.Font = Enum.Font.GothamBold
	signText.Parent = signGui

	-- Path between levels
	for i = 0, 3 do
		local levelKeys = { "Desa_Budaya", "Sanggar_Seni", "Pasar_Tradisional", "Tempat_Bersejarah" }
		local key = levelKeys[i + 1]
		local origin = LEVEL_POSITIONS[key]
		local style = LEVEL_STYLES[key]

		-- Build ground
		buildGround(key, origin, style)

		-- Path from spawn/previous level
		local pathStart = i == 0 and Vector3.new(-20, 0.5, 0) or LEVEL_POSITIONS[levelKeys[i]]
		local pathEnd = origin
		local pathMid = (pathStart + pathEnd) / 2
		local pathLen = (pathEnd - pathStart).Magnitude

		createPart({
			Name = "Path_" .. key,
			Size = Vector3.new(pathLen, 0.5, 8),
			Position = pathMid + Vector3.new(0, 0.25, 0),
			Color = Color3.fromRGB(180, 160, 120),
			Material = Enum.Material.Cobblestone,
			Parent = Workspace,
		})

		-- Level-specific structures
		if key == "Desa_Budaya" then
			-- Rumah-rumah adat Sunda
			buildRumah(origin + Vector3.new(-20, 0, -15), style, "Rumah_Saung", Vector3.new(12, 7, 10))
			buildRumah(origin + Vector3.new(20, 0, -15), style, "Rumah_Adat", Vector3.new(14, 8, 12))
			buildRumah(origin + Vector3.new(-15, 0, 20), style, "Balai_Desa", Vector3.new(18, 10, 14))
			-- Sawah (rice field - green flat)
			createPart({
				Name = "Sawah", Size = Vector3.new(30, 0.3, 20),
				Position = origin + Vector3.new(-20, 0.15, -30),
				Color = Color3.fromRGB(100, 180, 60),
				Material = Enum.Material.Grass,
				Parent = Workspace,
			})
			-- Kolam
			buildWater(origin + Vector3.new(25, 0.15, 20), style, Vector3.new(15, 0.3, 15))
			-- Trees
			for t = 1, 8 do
				buildTree(origin + Vector3.new(math.random(-50, 50), 0, math.random(-50, 50)), style)
			end
			-- Panggung angklung
			buildStage(origin + Vector3.new(0, 0, -5), style, "Panggung_Angklung")

		elseif key == "Sanggar_Seni" then
			-- Sanggar utama
			buildRumah(origin + Vector3.new(0, 0, -10), style, "Sanggar_Utama", Vector3.new(20, 12, 16))
			-- Workshops kecil
			buildRumah(origin + Vector3.new(-25, 0, 10), style, "Sanggar_Batik", Vector3.new(10, 7, 8))
			buildRumah(origin + Vector3.new(25, 0, 10), style, "Sanggar_Ukir", Vector3.new(10, 7, 8))
			-- Display area
			buildStage(origin + Vector3.new(0, 0, 15), style, "Panggung_Gamelan")
			-- Water feature
			buildWater(origin + Vector3.new(-30, 0.15, -20), style, Vector3.new(12, 0.3, 12))
			-- Trees
			for t = 1, 6 do
				buildTree(origin + Vector3.new(math.random(-45, 45), 0, math.random(-45, 45)), style)
			end

		elseif key == "Pasar_Tradisional" then
			-- Market stalls in rows
			for row = 0, 1 do
				for col = 0, 3 do
					local stallColor = Color3.fromRGB(
						math.random(150, 255),
						math.random(80, 200),
						math.random(30, 100)
					)
					buildStall(
						origin + Vector3.new(-20 + col * 14, 0, -15 + row * 30),
						style,
						"Kios_" .. (row * 4 + col + 1),
						stallColor
					)
				end
			end
			-- Central fountain
			buildWater(origin + Vector3.new(0, 0.15, 0), style, Vector3.new(10, 0.3, 10))
			createPart({
				Name = "FountainCenter",
				Size = Vector3.new(2, 4, 2),
				Position = origin + Vector3.new(0, 2, 0),
				Color = style.accentColor,
				Material = Enum.Material.Neon,
				Shape = Enum.PartType.Cylinder,
				Parent = Workspace,
			})
			-- Decorations
			for t = 1, 4 do
				buildTree(origin + Vector3.new(math.random(-40, 40), 0, math.random(-40, 40)), style)
			end

		elseif key == "Tempat_Bersejarah" then
			-- Main candi
			buildCandi(origin + Vector3.new(0, 0, -10), style, 16)
			-- Smaller temples
			buildCandi(origin + Vector3.new(-25, 0, 10), style, 8)
			buildCandi(origin + Vector3.new(25, 0, 10), style, 8)
			-- Museum building
			buildRumah(origin + Vector3.new(0, 0, 25), style, "Museum", Vector3.new(24, 10, 16))
			-- Garden
			for t = 1, 10 do
				buildTree(origin + Vector3.new(math.random(-50, 50), 0, math.random(-50, 50)), style)
			end
			-- Pond
			buildWater(origin + Vector3.new(35, 0.15, -20), style, Vector3.new(18, 0.3, 18))
		end

		-- Signpost for each level
		local sign = Instance.new("Part")
		sign.Name = "Sign_" .. key
		sign.Size = Vector3.new(6, 3, 0.5)
		sign.Position = origin + Vector3.new(0, 5, -55)
		sign.Color = Color3.fromRGB(80, 50, 20)
		sign.Material = Enum.Material.Wood
		sign.Anchored = true
		sign.Parent = Workspace

		local sGui = Instance.new("SurfaceGui")
		sGui.Face = Enum.NormalId.Front
		sGui.Parent = sign

		local sText = Instance.new("TextLabel")
		sText.Size = UDim2.new(1, 0, 1, 0)
		sText.BackgroundTransparency = 1
		sText.Text = (i + 1) .. ". " .. (key:gsub("_", " "))
		sText.TextColor3 = Color3.fromRGB(255, 248, 230)
		sText.TextSize = 16
		sText.Font = Enum.Font.GothamBold
		sText.Parent = sGui

		print("[MapSetup] Level " .. (i + 1) .. ": " .. key .. " built.")
	end

	-- Create all NPCs
	for _, npc in ipairs(NPC_DATA) do
		local origin = LEVEL_POSITIONS[npc.level] or Vector3.new(0, 0, 0)
		createNPC(npc, origin)
	end

	print("[MapSetup] All NPCs placed: " .. #NPC_DATA)
	print("[MapSetup] World generation complete!")
end

---------------------------------------------------------------------
-- LIGHTING & ATMOSPHERE
---------------------------------------------------------------------
local function setupLighting()
	local lighting = game:GetService("Lighting")

	-- Warm tropical lighting
	lighting.Ambient = Color3.fromRGB(180, 160, 130)
	lighting.Brightness = 2
	lighting.ClockTime = 14.5  -- Afternoon
	lighting.GeographicLatitude = -6  -- Indonesia latitude
	lighting.OutdoorAmbient = Color3.fromRGB(160, 150, 120)

	-- Atmosphere
	local atmo = Instance.new("Atmosphere")
	atmo.Density = 0.3
	atmo.Offset = 0.2
	atmo.Color = Color3.fromRGB(220, 200, 170)
	atmo.Decay = Color3.fromRGB(180, 150, 100)
	atmo.Glare = 0.5
	atmo.Haze = 2
	atmo.Parent = lighting

	-- Sky
	local sky = Instance.new("Sky")
	sky.StarCount = 0
	sky.SunAngularSize = 15
	sky.Parent = lighting

	-- Bloom
	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.3
	bloom.Size = 20
	bloom.Threshold = 0.8
	bloom.Parent = lighting

	-- Color correction
	local cc = Instance.new("ColorCorrectionEffect")
	cc.Brightness = 0.05
	cc.Contrast = 0.1
	cc.Saturation = 0.2
	cc.TintColor = Color3.fromRGB(255, 245, 230)
	cc.Parent = lighting

	print("[MapSetup] Lighting configured.")
end

---------------------------------------------------------------------
-- SPAWN POINT
---------------------------------------------------------------------
local function setupSpawn()
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "MainSpawn"
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.Position = Vector3.new(-50, 1, 0)
	spawn.Color = Color3.fromRGB(218, 165, 32)
	spawn.Material = Enum.Material.Neon
	spawn.Transparency = 0.3
	spawn.Anchored = true
	spawn.CanCollide = true
	spawn.TeamColor = BrickColor.new("White")
	spawn.Neutral = true
	spawn.Parent = Workspace

	-- Force spawn here
	spawn.DescendantRemoving:Connect(function() end) -- prevent accidental deletion
end

---------------------------------------------------------------------
-- EXECUTE
---------------------------------------------------------------------
buildAllLevels()
setupLighting()
setupSpawn()

print("[MapSetup] ==============================")
print("[MapSetup] JEJAK NUSANTARA SIAP DIMAINKAN!")
print("[MapSetup] 4 Level | " .. #NPC_DATA .. " NPC | Full Map")
print("[MapSetup] ==============================")
