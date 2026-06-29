--[[
	Jejak Nusantara Final — GameClient.lua
	Client-side logic: UI, dialogue, mini-games, cultural insight display, endings.
	Mata kuliah: Pengembangan Game (MBKP-07.03.310)
	Team: Daffa Rifqi A.F (PM), Mahda Vidho Pratama, Sakti Hermawan, Rakha Andrianto Q.A
]]

---------------------------------------------------------------------
-- Services
---------------------------------------------------------------------
local Players            = game:GetService("Players")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local UserInputService   = game:GetService("UserInputService")
local TweenService       = game:GetService("TweenService")
local SoundService       = game:GetService("SoundService")
local StarterGui         = game:GetService("StarterGui")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

---------------------------------------------------------------------
-- Wait for Remotes
---------------------------------------------------------------------
local Remotes = ReplicatedStorage:WaitForChild("JN_Remotes", 10)

local function getRemote(name, className)
	return Remotes:WaitForChild(name, 10)
end

-- RemoteEvents
local RE_PlayerAction     = getRemote("PlayerAction",     "RemoteEvent")
local RE_UpdateUI         = getRemote("UpdateUI",         "RemoteEvent")
local RE_DialogueEvent    = getRemote("DialogueEvent",    "RemoteEvent")
local RE_MiniGameResult   = getRemote("MiniGameResult",   "RemoteEvent")
local RE_CulturalInsight  = getRemote("CulturalInsight",  "RemoteEvent")
local RE_TriggerEnding    = getRemote("TriggerEnding",    "RemoteEvent")
local RE_LevelTransition  = getRemote("LevelTransition",  "RemoteEvent")
local RE_JournalUpdate    = getRemote("JournalUpdate",    "RemoteEvent")

-- RemoteFunctions
local RF_GetPlayerData    = getRemote("GetPlayerData",    "RemoteFunction")

---------------------------------------------------------------------
-- CONSTANTS
---------------------------------------------------------------------
local LEVEL_DISPLAY = {
	Desa_Budaya        = "Desa Budaya — Jawa Barat",
	Sanggar_Seni       = "Sanggar Seni Tradisional",
	Pasar_Tradisional  = "Pasar Tradisional Nusantara",
	Tempat_Bersejarah  = "Tempat Bersejarah Indonesia",
}

local SKILL_LABELS = {
	Observation           = "Observasi",
	Communication         = "Komunikasi",
	CulturalUnderstanding = "Pemahaman Budaya",
	ProblemSolving        = "Pemecahan Masalah",
	DecisionMaking        = "Pengambilan Keputusan",
}

local THEME = {
	bgPrimary    = Color3.fromRGB(25, 20, 15),
	bgSecondary  = Color3.fromRGB(40, 32, 22),
	bgCard       = Color3.fromRGB(55, 45, 30),
	accent       = Color3.fromRGB(218, 165, 32),
	accentHover  = Color3.fromRGB(245, 190, 50),
	textPrimary  = Color3.fromRGB(255, 248, 230),
	textSecondary= Color3.fromRGB(200, 185, 150),
	textMuted    = Color3.fromRGB(140, 125, 100),
	success      = Color3.fromRGB(80, 180, 80),
	warning      = Color3.fromRGB(220, 160, 40),
	danger       = Color3.fromRGB(200, 60, 60),
	bronze       = Color3.fromRGB(205, 127, 50),
	silver       = Color3.fromRGB(192, 192, 192),
	gold         = Color3.fromRGB(255, 215, 0),
}

---------------------------------------------------------------------
-- UI HELPER UTILITIES
---------------------------------------------------------------------
local UI = {}

function UI.create(className, props, children)
	local inst = Instance.new(className)
	for k, v in pairs(props or {}) do
		if k ~= "Parent" then
			pcall(function() inst[k] = v end)
		end
	end
	for _, child in ipairs(children or {}) do
		child.Parent = inst
	end
	if props and props.Parent then
		inst.Parent = props.Parent
	end
	return inst
end

function UI.roundedCorner(radius)
	return UI.create("UICorner", { CornerRadius = UDim.new(0, radius or 8) })
end

function UI.padding(t, r, b, l)
	return UI.create("UIPadding", {
		PaddingTop    = UDim.new(0, t or 8),
		PaddingRight  = UDim.new(0, r or t or 8),
		PaddingBottom = UDim.new(0, b or t or 8),
		PaddingLeft   = UDim.new(0, l or r or t or 8),
	})
end

function UI.listLayout(dir, gap, align)
	return UI.create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		FillDirection = dir or Enum.FillDirection.Vertical,
		Padding = UDim.new(0, gap or 6),
		HorizontalAlignment = align or Enum.HorizontalAlignment.Center,
	})
end

function UI.tween(obj, props, duration, style, dir)
	local info = TweenInfo.new(duration or 0.3, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out)
	local tw = TweenService:Create(obj, info, props)
	tw:Play()
	return tw
end

function UI.fadeIn(obj, dur)
	obj.BackgroundTransparency = 1
	if obj:IsA("TextLabel") or obj:IsA("TextButton") then
		obj.TextTransparency = 1
	end
	UI.tween(obj, { BackgroundTransparency = 0 }, dur or 0.4)
	if obj:IsA("TextLabel") or obj:IsA("TextButton") then
		UI.tween(obj, { TextTransparency = 0 }, dur or 0.4)
	end
end

function UI.fadeOut(obj, dur)
	local tw = UI.tween(obj, { BackgroundTransparency = 1 }, dur or 0.3)
	if obj:IsA("TextLabel") or obj:IsA("TextButton") then
		UI.tween(obj, { TextTransparency = 1 }, dur or 0.3)
	end
	tw.Completed:Wait()
end

---------------------------------------------------------------------
-- SCREEN GUI (root)
---------------------------------------------------------------------
local screenGui = UI.create("ScreenGui", {
	Name = "JN_MainGUI",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	IgnoreGuiInset = true,
	Parent = playerGui,
})

---------------------------------------------------------------------
-- HUD (always visible during gameplay)
---------------------------------------------------------------------
local hudFrame = UI.create("Frame", {
	Name = "HUD",
	Size = UDim2.new(1, 0, 0, 60),
	Position = UDim2.new(0, 0, 0, 0),
	BackgroundColor3 = THEME.bgPrimary,
	BackgroundTransparency = 0.15,
	Parent = screenGui,
}, {
	UI.roundedCorner(0),
	UI.create("UIStroke", { Color = THEME.accent, Thickness = 1, Transparency = 0.6 }),
})

-- Level title
local levelLabel = UI.create("TextLabel", {
	Name = "LevelTitle",
	Size = UDim2.new(0.4, 0, 1, 0),
	Position = UDim2.new(0, 16, 0, 0),
	BackgroundTransparency = 1,
	Text = "Jejak Nusantara",
	TextColor3 = THEME.accent,
	TextSize = 22,
	Font = Enum.Font.GothamBold,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = hudFrame,
})

-- Progress indicator
local progressFrame = UI.create("Frame", {
	Name = "Progress",
	Size = UDim2.new(0.25, 0, 0, 8),
	Position = UDim2.new(0.5, -60, 0.5, -4),
	BackgroundColor3 = THEME.bgSecondary,
	Parent = hudFrame,
}, {
	UI.roundedCorner(4),
})

local progressBar = UI.create("Frame", {
	Name = "Fill",
	Size = UDim2.new(0, 0, 1, 0),
	BackgroundColor3 = THEME.accent,
	Parent = progressFrame,
}, {
	UI.roundedCorner(4),
})

local progressLabel = UI.create("TextLabel", {
	Name = "ProgressText",
	Size = UDim2.new(0, 80, 1, 0),
	Position = UDim2.new(1, 8, 0, 0),
	BackgroundTransparency = 1,
	Text = "0%",
	TextColor3 = THEME.textSecondary,
	TextSize = 14,
	Font = Enum.Font.Gotham,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = progressFrame,
})

-- Skills display (right side of HUD)
local skillsFrame = UI.create("Frame", {
	Name = "SkillsHUD",
	Size = UDim2.new(0.3, -16, 1, -16),
	Position = UDim2.new(0.7, 0, 0, 8),
	BackgroundTransparency = 1,
	Parent = hudFrame,
}, {
	UI.listLayout(Enum.FillDirection.Horizontal, 8, Enum.HorizontalAlignment.Right),
})

local skillBars = {}
for skillKey, label in pairs(SKILL_LABELS) do
	local sf = UI.create("Frame", {
		Name = skillKey,
		Size = UDim2.new(0, 90, 1, 0),
		BackgroundColor3 = THEME.bgCard,
		Parent = skillsFrame,
	}, {
		UI.roundedCorner(4),
		UI.padding(2, 4, 2, 4),
	})

	UI.create("TextLabel", {
		Size = UDim2.new(1, 0, 0.4, 0),
		BackgroundTransparency = 1,
		Text = label,
		TextColor3 = THEME.textMuted,
		TextSize = 9,
		Font = Enum.Font.Gotham,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = sf,
	})

	local barBg = UI.create("Frame", {
		Size = UDim2.new(1, 0, 0.3, 0),
		Position = UDim2.new(0, 0, 0.55, 0),
		BackgroundColor3 = THEME.bgSecondary,
		Parent = sf,
	}, { UI.roundedCorner(2) })

	local barFill = UI.create("Frame", {
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = THEME.accent,
		Parent = barBg,
	}, { UI.roundedCorner(2) })

	skillBars[skillKey] = { frame = sf, bar = barFill, label = label }
end

---------------------------------------------------------------------
-- JOURNAL PANEL
---------------------------------------------------------------------
local journalVisible = false
local journalFrame = UI.create("Frame", {
	Name = "Journal",
	Size = UDim2.new(0.35, 0, 0.7, 0),
	Position = UDim2.new(0.02, 0, 0.15, 0),
	BackgroundColor3 = THEME.bgSecondary,
	Visible = false,
	Parent = screenGui,
}, {
	UI.roundedCorner(12),
	UI.create("UIStroke", { Color = THEME.accent, Thickness = 1, Transparency = 0.5 }),
	UI.padding(12, 12, 12, 12),
})

UI.create("TextLabel", {
	Size = UDim2.new(1, 0, 0, 32),
	BackgroundTransparency = 1,
	Text = "📖 Jurnal Perjalanan",
	TextColor3 = THEME.accent,
	TextSize = 20,
	Font = Enum.Font.GothamBold,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = journalFrame,
})

local journalScroll = UI.create("ScrollingFrame", {
	Name = "Entries",
	Size = UDim2.new(1, 0, 1, -40),
	Position = UDim2.new(0, 0, 0, 38),
	BackgroundTransparency = 1,
	ScrollBarThickness = 4,
	ScrollBarImageColor3 = THEME.accent,
	CanvasSize = UDim2.new(0, 0, 0, 0),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	Parent = journalFrame,
}, {
	UI.listLayout(Enum.FillDirection.Vertical, 6),
	UI.padding(4, 4, 4, 4),
})

local function addJournalEntry(text, isInsight)
	local entry = UI.create("TextLabel", {
		Size = UDim2.new(1, -8, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = isInsight and Color3.fromRGB(60, 50, 20) or THEME.bgCard,
		Text = text,
		TextColor3 = isInsight and THEME.gold or THEME.textPrimary,
		TextSize = 13,
		Font = Enum.Font.Gotham,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Parent = journalScroll,
	}, {
		UI.roundedCorner(6),
		UI.padding(8, 8, 8, 8),
	})
	UI.fadeIn(entry, 0.3)
end

-- Toggle journal with J key
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.J then
		journalVisible = not journalVisible
		journalFrame.Visible = journalVisible
		if journalVisible then
			UI.fadeIn(journalFrame, 0.2)
		end
	end
end)

---------------------------------------------------------------------
-- MAP PANEL (peta sederhana)
---------------------------------------------------------------------
local mapVisible = false
local mapFrame = UI.create("Frame", {
	Name = "Map",
	Size = UDim2.new(0.4, 0, 0.5, 0),
	Position = UDim2.new(0.3, 0, 0.2, 0),
	BackgroundColor3 = THEME.bgSecondary,
	Visible = false,
	Parent = screenGui,
}, {
	UI.roundedCorner(12),
	UI.create("UIStroke", { Color = THEME.accent, Thickness = 1, Transparency = 0.5 }),
	UI.padding(12, 12, 12, 12),
})

UI.create("TextLabel", {
	Size = UDim2.new(1, 0, 0, 32),
	BackgroundTransparency = 1,
	Text = "🗺️ Peta Nusantara",
	TextColor3 = THEME.accent,
	TextSize = 20,
	Font = Enum.Font.GothamBold,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = mapFrame,
})

local mapContent = UI.create("Frame", {
	Size = UDim2.new(1, 0, 1, -40),
	Position = UDim2.new(0, 0, 0, 38),
	BackgroundTransparency = 1,
	Parent = mapFrame,
}, {
	UI.listLayout(Enum.FillDirection.Vertical, 10),
	UI.padding(8, 8, 8, 8),
})

local mapNodes = {}
local levelOrder = { "Desa_Budaya", "Sanggar_Seni", "Pasar_Tradisional", "Tempat_Bersejarah" }

for i, levelKey in ipairs(levelOrder) do
	local node = UI.create("Frame", {
		Name = levelKey,
		Size = UDim2.new(1, 0, 0, 50),
		BackgroundColor3 = THEME.bgCard,
		Parent = mapContent,
	}, {
		UI.roundedCorner(8),
		UI.padding(10, 12, 10, 12),
	})

	UI.create("TextLabel", {
		Size = UDim2.new(0.6, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = i .. ". " .. (LEVEL_DISPLAY[levelKey] or levelKey),
		TextColor3 = THEME.textPrimary,
		TextSize = 15,
		Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = node,
	})

	local statusLabel = UI.create("TextLabel", {
		Size = UDim2.new(0.35, 0, 1, 0),
		Position = UDim2.new(0.65, 0, 0, 0),
		BackgroundTransparency = 1,
		Text = "🔒 Terkunci",
		TextColor3 = THEME.textMuted,
		TextSize = 13,
		Font = Enum.Font.Gotham,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = node,
	})

	mapNodes[levelKey] = { frame = node, status = statusLabel }
end

-- Toggle map with M key
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.M then
		mapVisible = not mapVisible
		mapFrame.Visible = mapVisible
		if mapVisible then
			UI.fadeIn(mapFrame, 0.2)
		end
	end
end)

---------------------------------------------------------------------
-- DIALOGUE SYSTEM
---------------------------------------------------------------------
local dialogueActive = false
local dialogueFrame = UI.create("Frame", {
	Name = "Dialogue",
	Size = UDim2.new(0.6, 0, 0, 0),
	Position = UDim2.new(0.2, 0, 0.95, 0),
	AnchorPoint = Vector2.new(0, 1),
	BackgroundColor3 = THEME.bgPrimary,
	BackgroundTransparency = 0.05,
	ClipsDescendants = true,
	Visible = false,
	Parent = screenGui,
}, {
	UI.roundedCorner(12),
	UI.create("UIStroke", { Color = THEME.accent, Thickness = 1, Transparency = 0.4 }),
	UI.padding(16, 20, 16, 20),
})

local npcNameLabel = UI.create("TextLabel", {
	Name = "NPCName",
	Size = UDim2.new(1, 0, 0, 24),
	BackgroundTransparency = 1,
	Text = "",
	TextColor3 = THEME.accent,
	TextSize = 18,
	Font = Enum.Font.GothamBold,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = dialogueFrame,
})

local dialogueTextLabel = UI.create("TextLabel", {
	Name = "DialogueText",
	Size = UDim2.new(1, 0, 0, 40),
	Position = UDim2.new(0, 0, 0, 28),
	BackgroundTransparency = 1,
	Text = "",
	TextColor3 = THEME.textPrimary,
	TextSize = 15,
	Font = Enum.Font.Gotham,
	TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	AutomaticSize = Enum.AutomaticSize.Y,
	Parent = dialogueFrame,
})

local choicesFrame = UI.create("ScrollingFrame", {
	Name = "Choices",
	Size = UDim2.new(1, 0, 0, 0),
	Position = UDim2.new(0, 0, 1, 8),
	AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundTransparency = 1,
	ScrollBarThickness = 3,
	CanvasSize = UDim2.new(0, 0, 0, 0),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	Parent = dialogueFrame,
}, {
	UI.listLayout(Enum.FillDirection.Vertical, 6),
	UI.padding(0, 0, 0, 0),
})

local function typewriterEffect(label, text, speed)
	label.Text = ""
	for i = 1, #text do
		label.Text = string.sub(text, 1, i)
		task.wait(speed or 0.03)
	end
end

local function showDialogue(npcName, text, choices)
	dialogueActive = true
	dialogueFrame.Visible = true

	-- Clear old choices
	for _, child in ipairs(choicesFrame:GetChildren()) do
		if child:IsA("TextButton") then child:Destroy() end
	end

	npcNameLabel.Text = npcName
	dialogueTextLabel.Text = ""

	-- Animate frame up
	dialogueFrame.Size = UDim2.new(0.6, 0, 0, 0)
	UI.tween(dialogueFrame, { Size = UDim2.new(0.6, 0, 0, 120) }, 0.3)

	-- Typewriter dialogue
	typewriterEffect(dialogueTextLabel, text, 0.025)

	-- Show choices
	if choices and #choices > 0 then
		task.wait(0.3)
		for i, choice in ipairs(choices) do
			local btn = UI.create("TextButton", {
				Size = UDim2.new(1, 0, 0, 36),
				BackgroundColor3 = THEME.bgCard,
				Text = "  " .. choice.label,
				TextColor3 = THEME.textPrimary,
				TextSize = 14,
				Font = Enum.Font.Gotham,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = choicesFrame,
			}, {
				UI.roundedCorner(6),
				UI.padding(6, 10, 6, 10),
			})

			-- Hover effect
			btn.MouseEnter:Connect(function()
				UI.tween(btn, { BackgroundColor3 = THEME.accent }, 0.15)
			end)
			btn.MouseLeave:Connect(function()
				UI.tween(btn, { BackgroundColor3 = THEME.bgCard }, 0.15)
			end)

			btn.MouseButton1Click:Connect(function()
				-- Send choice to server
				RE_DialogueEvent:FireServer(choice.next, choice.skill or "")
				dialogueActive = false
				UI.tween(dialogueFrame, { Size = UDim2.new(0.6, 0, 0, 0) }, 0.25)
				task.wait(0.3)
				dialogueFrame.Visible = false
			end)

			UI.fadeIn(btn, 0.2)
			task.wait(0.1)
		end

		-- Adjust frame height for choices
		local totalH = 120 + (#choices * 42) + 16
		totalH = math.min(totalH, 320)
		UI.tween(dialogueFrame, { Size = UDim2.new(0.6, 0, 0, totalH) }, 0.3)
	else
		-- No choices — click to dismiss
		local dismissBtn = UI.create("TextButton", {
			Size = UDim2.new(1, 0, 0, 30),
			BackgroundTransparency = 1,
			Text = "[ Klik untuk lanjut ]",
			TextColor3 = THEME.textMuted,
			TextSize = 12,
			Font = Enum.Font.GothamItalic,
			Parent = choicesFrame,
		})
		dismissBtn.MouseButton1Click:Connect(function()
			RE_DialogueEvent:FireServer("", "")
			dialogueActive = false
			UI.tween(dialogueFrame, { Size = UDim2.new(0.6, 0, 0, 0) }, 0.25)
			task.wait(0.3)
			dialogueFrame.Visible = false
		end)
	end
end

---------------------------------------------------------------------
-- MINI GAME INTERFACES
---------------------------------------------------------------------

-- ==================== ANGKLUNG RHYTHM GAME ====================
local angklungActive = false

local angklungFrame = UI.create("Frame", {
	Name = "AngklungGame",
	Size = UDim2.new(0.5, 0, 0.6, 0),
	Position = UDim2.new(0.25, 0, 0.2, 0),
	BackgroundColor3 = THEME.bgPrimary,
	Visible = false,
	Parent = screenGui,
}, {
	UI.roundedCorner(16),
	UI.create("UIStroke", { Color = THEME.accent, Thickness = 2 }),
	UI.padding(16, 16, 16, 16),
})

UI.create("TextLabel", {
	Size = UDim2.new(1, 0, 0, 36),
	BackgroundTransparency = 1,
	Text = "🎵 Mengikuti Nada Angklung",
	TextColor3 = THEME.accent,
	TextSize = 22,
	Font = Enum.Font.GothamBold,
	Parent = angklungFrame,
})

local angklungScore = UI.create("TextLabel", {
	Size = UDim2.new(0.3, 0, 0, 28),
	Position = UDim2.new(0.7, 0, 0, 40),
	BackgroundTransparency = 1,
	Text = "Skor: 0",
	TextColor3 = THEME.textPrimary,
	TextSize = 16,
	Font = Enum.Font.GothamMedium,
	TextXAlignment = Enum.TextXAlignment.Right,
	Parent = angklungFrame,
})

local angklungPatternDisplay = UI.create("TextLabel", {
	Size = UDim2.new(1, 0, 0, 50),
	Position = UDim2.new(0, 0, 0, 80),
	BackgroundColor3 = THEME.bgCard,
	Text = "",
	TextColor3 = THEME.gold,
	TextSize = 28,
	Font = Enum.Font.GothamBold,
	Parent = angklungFrame,
}, { UI.roundedCorner(8) })

local notes = { "Do", "Re", "Mi", "Fa", "Sol", "La", "Si" }
local noteColors = {
	Color3.fromRGB(255, 80, 80),   -- Do - merah
	Color3.fromRGB(255, 140, 60),  -- Re - oranye
	Color3.fromRGB(255, 220, 50),  -- Mi - kuning
	Color3.fromRGB(80, 200, 80),   -- Fa - hijau
	Color3.fromRGB(60, 180, 220),  -- Sol - biru muda
	Color3.fromRGB(100, 100, 255), -- La - biru
	Color3.fromRGB(180, 80, 220),  -- Si - ungu
}

local angklungButtons = UI.create("Frame", {
	Name = "NoteButtons",
	Size = UDim2.new(1, 0, 0, 60),
	Position = UDim2.new(0, 0, 0, 150),
	BackgroundTransparency = 1,
	Parent = angklungFrame,
}, {
	UI.listLayout(Enum.FillDirection.Horizontal, 6, Enum.HorizontalAlignment.Center),
})

local noteBtns = {}
for i, note in ipairs(notes) do
	local btn = UI.create("TextButton", {
		Name = note,
		Size = UDim2.new(0, 64, 1, 0),
		BackgroundColor3 = noteColors[i],
		Text = note,
		TextColor3 = Color3.new(1, 1, 1),
		TextSize = 18,
		Font = Enum.Font.GothamBold,
		Parent = angklungButtons,
	}, { UI.roundedCorner(8) })
	noteBtns[note] = btn
end

local angklungProgress = UI.create("TextLabel", {
	Size = UDim2.new(1, 0, 0, 30),
	Position = UDim2.new(0, 0, 1, -40),
	BackgroundTransparency = 1,
	Text = "",
	TextColor3 = THEME.textSecondary,
	TextSize = 14,
	Font = Enum.Font.Gotham,
	Parent = angklungFrame,
})

local function runAngklungGame(pattern, currentIndex, score, totalNotes)
	if currentIndex > #pattern then
		-- Game complete
		angklungProgress.Text = "Selesai! Skor akhir: " .. score .. "/" .. totalNotes
		RE_MiniGameResult:FireServer("angklung", score, totalNotes)
		task.wait(2)
		angklungFrame.Visible = false
		angklungActive = false
		return
	end

	local targetNote = pattern[currentIndex]
	angklungPatternDisplay.Text = "Mainkan: " .. targetNote
	angklungProgress.Text = "Langkah " .. currentIndex .. " / " .. #pattern
	angklungScore.Text = "Skor: " .. score

	-- Highlight correct note
	if noteBtns[targetNote] then
		UI.tween(noteBtns[targetNote], { Size = UDim2.new(0, 72, 1, 0) }, 0.15)
		task.delay(0.3, function()
			UI.tween(noteBtns[targetNote], { Size = UDim2.new(0, 64, 1, 0) }, 0.15)
		end)
	end

	-- Wait for player input
	local clicked = false
	local connections = {}

	for note, btn in pairs(noteBtns) do
		local conn
		conn = btn.MouseButton1Click:Connect(function()
			if clicked then return end
			clicked = true

			-- Disconnect all
			for _, c in ipairs(connections) do c:Disconnect() end

			if note == targetNote then
				score = score + 10
				angklungProgress.Text = "✓ Benar!"
				angklungProgress.TextColor3 = THEME.success
			else
				score = math.max(0, score - 5)
				angklungProgress.Text = "✗ Salah! Seharusnya: " .. targetNote
				angklungProgress.TextColor3 = THEME.danger
			end

			angklungScore.Text = "Skor: " .. score
			task.wait(0.6)
			angklungProgress.TextColor3 = THEME.textSecondary
			runAngklungGame(pattern, currentIndex + 1, score, totalNotes)
		end)
		table.insert(connections, conn)
	end

	-- Timeout after 5 seconds
	task.delay(5, function()
		if not clicked then
			clicked = true
			for _, c in ipairs(connections) do c:Disconnect() end
			angklungProgress.Text = "⏰ Terlambat!"
			angklungProgress.TextColor3 = THEME.warning
			task.wait(0.6)
			runAngklungGame(pattern, currentIndex + 1, score, totalNotes)
		end
	end)
end

local function startAngklungGame(patternLength)
	angklungActive = true
	angklungFrame.Visible = true
	UI.fadeIn(angklungFrame, 0.3)

	local pattern = {}
	for i = 1, (patternLength or 5) do
		table.insert(pattern, notes[math.random(1, #notes)])
	end

	runAngklungGame(pattern, 1, 0, #pattern)
end

-- ==================== TARI TOPENG GAME ====================
local tariFrame = UI.create("Frame", {
	Name = "TariGame",
	Size = UDim2.new(0.5, 0, 0.55, 0),
	Position = UDim2.new(0.25, 0, 0.22, 0),
	BackgroundColor3 = THEME.bgPrimary,
	Visible = false,
	Parent = screenGui,
}, {
	UI.roundedCorner(16),
	UI.create("UIStroke", { Color = THEME.accent, Thickness = 2 }),
	UI.padding(16, 16, 16, 16),
})

UI.create("TextLabel", {
	Size = UDim2.new(1, 0, 0, 36),
	BackgroundTransparency = 1,
	Text = "💃 Gerakan Tari Topeng",
	TextColor3 = THEME.accent,
	TextSize = 22,
	Font = Enum.Font.GothamBold,
	Parent = tariFrame,
})

local tariSequenceDisplay = UI.create("TextLabel", {
	Size = UDim2.new(1, 0, 0, 60),
	Position = UDim2.new(0, 0, 0, 50),
	BackgroundColor3 = THEME.bgCard,
	Text = "",
	TextColor3 = THEME.gold,
	TextSize = 24,
	Font = Enum.Font.GothamBold,
	Parent = tariFrame,
}, { UI.roundedCorner(8) })

local tariDirectionButtons = UI.create("Frame", {
	Name = "Directions",
	Size = UDim2.new(0, 200, 0, 200),
	Position = UDim2.new(0.5, -100, 0, 130),
	BackgroundTransparency = 1,
	Parent = tariFrame,
})

local tariArrows = {
	{ dir = "↑", key = "Atas",    pos = UDim2.new(0.33, 0, 0, 0),     size = UDim2.new(0.33, 0, 0.33, 0) },
	{ dir = "←", key = "Kiri",    pos = UDim2.new(0, 0, 0.33, 0),     size = UDim2.new(0.33, 0, 0.33, 0) },
	{ dir = "→", key = "Kanan",   pos = UDim2.new(0.66, 0, 0.33, 0),  size = UDim2.new(0.33, 0, 0.33, 0) },
	{ dir = "↓", key = "Bawah",   pos = UDim2.new(0.33, 0, 0.66, 0),  size = UDim2.new(0.33, 0, 0.33, 0) },
}

local tariBtnMap = {}
for _, a in ipairs(tariArrows) do
	local btn = UI.create("TextButton", {
		Name = a.key,
		Size = a.size,
		Position = a.pos,
		BackgroundColor3 = THEME.bgCard,
		Text = a.dir,
		TextColor3 = THEME.textPrimary,
		TextSize = 32,
		Font = Enum.Font.GothamBold,
		Parent = tariDirectionButtons,
	}, { UI.roundedCorner(8) })
	tariBtnMap[a.key] = btn
end

local tariScoreLabel = UI.create("TextLabel", {
	Size = UDim2.new(1, 0, 0, 30),
	Position = UDim2.new(0, 0, 1, -40),
	BackgroundTransparency = 1,
	Text = "Skor: 0",
	TextColor3 = THEME.textPrimary,
	TextSize = 16,
	Font = Enum.Font.GothamMedium,
	Parent = tariFrame,
})

local dirKeys = { "Atas", "Kiri", "Kanan", "Bawah" }
local dirSymbols = { Atas = "↑", Kiri = "←", Kanan = "→", Bawah = "↓" }

local function runTariGame(sequence, idx, score)
	if idx > #sequence then
		tariSequenceDisplay.Text = "Selesai! Skor: " .. score
		RE_MiniGameResult:FireServer("tari_topeng", score, #sequence)
		task.wait(2)
		tariFrame.Visible = false
		return
	end

	local target = sequence[idx]
	tariSequenceDisplay.Text = "Gerakan " .. idx .. "/" .. #sequence .. ": " .. dirSymbols[target]
	tariScoreLabel.Text = "Skor: " .. score

	local clicked = false
	local conns = {}

	for dir, btn in pairs(tariBtnMap) do
		local c
		c = btn.MouseButton1Click:Connect(function()
			if clicked then return end
			clicked = true
			for _, cc in ipairs(conns) do cc:Disconnect() end

			if dir == target then
				score = score + 10
				tariSequenceDisplay.Text = "✓ Tepat!"
				tariSequenceDisplay.TextColor3 = THEME.success
			else
				score = math.max(0, score - 5)
				tariSequenceDisplay.Text = "✗ Salah!"
				tariSequenceDisplay.TextColor3 = THEME.danger
			end
			tariScoreLabel.Text = "Skor: " .. score
			task.wait(0.5)
			tariSequenceDisplay.TextColor3 = THEME.gold
			runTariGame(sequence, idx + 1, score)
		end)
		table.insert(conns, c)
	end

	task.delay(4, function()
		if not clicked then
			clicked = true
			for _, c in ipairs(conns) do c:Disconnect() end
			tariSequenceDisplay.Text = "⏰ Terlambat!"
			tariSequenceDisplay.TextColor3 = THEME.warning
			task.wait(0.5)
			tariSequenceDisplay.TextColor3 = THEME.gold
			runTariGame(sequence, idx + 1, score)
		end
	end)
end

local function startTariGame(seqLength)
	tariFrame.Visible = true
	UI.fadeIn(tariFrame, 0.3)
	local seq = {}
	for i = 1, (seqLength or 6) do
		table.insert(seq, dirKeys[math.random(1, #dirKeys)])
	end
	runTariGame(seq, 1, 0)
end

-- ==================== TAWAR-MENAWAR (BARGAINING) GAME ====================
local tawarFrame = UI.create("Frame", {
	Name = "TawarGame",
	Size = UDim2.new(0.45, 0, 0.45, 0),
	Position = UDim2.new(0.275, 0, 0.25, 0),
	BackgroundColor3 = THEME.bgPrimary,
	Visible = false,
	Parent = screenGui,
}, {
	UI.roundedCorner(16),
	UI.create("UIStroke", { Color = THEME.accent, Thickness = 2 }),
	UI.padding(16, 16, 16, 16),
})

UI.create("TextLabel", {
	Size = UDim2.new(1, 0, 0, 36),
	BackgroundTransparency = 1,
	Text = "🛒 Tawar-Menawar di Pasar",
	TextColor3 = THEME.accent,
	TextSize = 22,
	Font = Enum.Font.GothamBold,
	Parent = tawarFrame,
})

local tawarItemLabel = UI.create("TextLabel", {
	Size = UDim2.new(1, 0, 0, 30),
	Position = UDim2.new(0, 0, 0, 45),
	BackgroundTransparency =1,
	Text = "",
	TextColor3 = THEME.textPrimary,
	TextSize = 16,
	Font = Enum.Font.GothamMedium,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = tawarFrame,
})

local tawarPriceLabel = UI.create("TextLabel", {
	Size = UDim2.new(1, 0, 0, 30),
	Position = UDim2.new(0, 0, 0, 75),
	BackgroundTransparency = 1,
	Text = "",
	TextColor3 = THEME.gold,
	TextSize = 18,
	Font = Enum.Font.GothamBold,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = tawarFrame,
})

local tawarOfferBox = UI.create("TextBox", {
	Size = UDim2.new(0.5, 0, 0, 40),
	Position = UDim2.new(0, 0, 0, 115),
	BackgroundColor3 = THEME.bgCard,
	Text = "",
	PlaceholderText = "Tawaran harga (Rp)...",
	TextColor3 = THEME.textPrimary,
	PlaceholderColor3 = THEME.textMuted,
	TextSize = 16,
	Font = Enum.Font.Gotham,
	ClearTextOnFocus = true,
	Parent = tawarFrame,
}, { UI.roundedCorner(8), UI.padding(8, 12, 8, 12) })

local tawarSubmitBtn = UI.create("TextButton", {
	Size = UDim2.new(0.25, 0, 0, 40),
	Position = UDim2.new(0.55, 0, 0, 115),
	BackgroundColor3 = THEME.accent,
	Text = "Tawar!",
	TextColor3 = THEME.bgPrimary,
	TextSize = 16,
	Font = Enum.Font.GothamBold,
	Parent = tawarFrame,
}, { UI.roundedCorner(8) })

local tawarResultLabel = UI.create("TextLabel", {
	Size = UDim2.new(1, 0, 0, 60),
	Position = UDim2.new(0, 0, 0, 170),
	BackgroundTransparency = 1,
	Text = "",
	TextColor3 = THEME.textSecondary,
	TextSize = 14,
	Font = Enum.Font.Gotham,
	TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	Parent = tawarFrame,
})

local function startTawarGame(itemName, minPrice, maxPrice, attempts)
	tawarFrame.Visible = true
	UI.fadeIn(tawarFrame, 0.3)

	local targetPrice = math.random(minPrice, maxPrice)
	local tries = 0
	local maxTries = attempts or 5
	local won = false

	tawarItemLabel.Text = "Barang: " .. itemName
	tawarPriceLabel.Text = "Harga pedagang: Rp " .. string.format("%d", maxPrice)
	tawarResultLabel.Text = "Kesempatan: " .. maxTries .. "x"
	tawarOfferBox.Text = ""

	local conn
	conn = tawarSubmitBtn.MouseButton1Click:Connect(function()
		if won then return end
		local offer = tonumber(tawarOfferBox.Text)
		if not offer then
			tawarResultLabel.Text = "Masukkan angka yang valid!"
			tawarResultLabel.TextColor3 = THEME.warning
			return
		end

		tries = tries + 1
		local diff = math.abs(offer - targetPrice)
		local pctDiff = diff / targetPrice

		if pctDiff <= 0.1 then
			-- Close enough!
			won = true
			tawarResultLabel.Text = "✓ Deal! Harga sepakat: Rp " .. string.format("%d", offer)
			tawarResultLabel.TextColor3 = THEME.success
			RE_MiniGameResult:FireServer("tawar_menawar", maxTries - tries + 1, maxTries)
			conn:Disconnect()
			task.wait(2)
			tawarFrame.Visible = false
		elseif offer < targetPrice then
			tawarResultLabel.Text = "Pedagang: \"Terlalu murah! Naikkan lagi.\" (" .. (maxTries - tries) .. " kesempatan)"
			tawarResultLabel.TextColor3 = THEME.warning
		else
			tawarResultLabel.Text = "Pedagang: \"Kemahalan! Turunkan dong.\" (" .. (maxTries - tries) .. " kesempatan)"
			tawarResultLabel.TextColor3 = THEME.warning
		end

		if tries >= maxTries and not won then
			won = true -- prevent further clicks
			tawarResultLabel.Text = "✗ Pedagang sudah bosan! Harga tetap Rp " .. string.format("%d", maxPrice)
			tawarResultLabel.TextColor3 = THEME.danger
			RE_MiniGameResult:FireServer("tawar_menawar", 0, maxTries)
			conn:Disconnect()
			task.wait(2)
			tawarFrame.Visible = false
		end

		tawarOfferBox.Text = ""
	end)
end

-- ==================== PUZZLE SEJARAH GAME ====================
local puzzleFrame = UI.create("Frame", {
	Name = "PuzzleGame",
	Size = UDim2.new(0.5, 0, 0.55, 0),
	Position = UDim2.new(0.25, 0, 0.22, 0),
	BackgroundColor3 = THEME.bgPrimary,
	Visible = false,
	Parent = screenGui,
}, {
	UI.roundedCorner(16),
	UI.create("UIStroke", { Color = THEME.accent, Thickness = 2 }),
	UI.padding(16, 16, 16, 16),
})

UI.create("TextLabel", {
	Size = UDim2.new(1, 0, 0, 36),
	BackgroundTransparency = 1,
	Text = "🧩 Puzzle Sejarah",
	TextColor3 = THEME.accent,
	TextSize = 22,
	Font = Enum.Font.GothamBold,
	Parent = puzzleFrame,
})

local puzzleQuestionLabel = UI.create("TextLabel", {
	Size = UDim2.new(1, 0, 0, 60),
	Position = UDim2.new(0, 0, 0, 45),
	BackgroundColor3 = THEME.bgCard,
	Text = "",
	TextColor3 = THEME.textPrimary,
	TextSize = 15,
	Font = Enum.Font.Gotham,
	TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	Parent = puzzleFrame,
}, { UI.roundedCorner(8), UI.padding(10, 12, 10, 12) })

local puzzleChoicesFrame = UI.create("Frame", {
	Name = "Choices",
	Size = UDim2.new(1, 0, 0, 160),
	Position = UDim2.new(0, 0, 0, 120),
	BackgroundTransparency = 1,
	Parent = puzzleFrame,
}, {
	UI.listLayout(Enum.FillDirection.Vertical, 8),
	UI.padding(4, 4, 4, 4),
})

local puzzleScoreLabel = UI.create("TextLabel", {
	Size = UDim2.new(1, 0, 0, 30),
	Position = UDim2.new(0, 0, 1, -40),
	BackgroundTransparency = 1,
	Text = "",
	TextColor3 = THEME.textPrimary,
	TextSize = 16,
	Font = Enum.Font.GothamMedium,
	Parent = puzzleFrame,
})

local function runPuzzleGame(questions, qIdx, score)
	if qIdx > #questions then
		puzzleQuestionLabel.Text = "Puzzle selesai!"
		puzzleScoreLabel.Text = "Skor akhir: " .. score .. " / " .. (#questions * 10)
		RE_MiniGameResult:FireServer("puzzle_sejarah", score, #questions * 10)
		task.wait(2.5)
		puzzleFrame.Visible = false
		return
	end

	local q = questions[qIdx]
	puzzleQuestionLabel.Text = "Soal " .. qIdx .. "/" .. #questions .. ":\n" .. q.question
	puzzleScoreLabel.Text = "Skor: " .. score

	-- Clear old choices
	for _, child in ipairs(puzzleChoicesFrame:GetChildren()) do
		if child:IsA("TextButton") then child:Destroy() end
	end

	local answered = false
	local conns = {}

	for i, opt in ipairs(q.options) do
		local btn = UI.create("TextButton", {
			Size = UDim2.new(1, 0, 0, 34),
			BackgroundColor3 = THEME.bgCard,
			Text = "  " .. string.char(64 + i) .. ". " .. opt,
			TextColor3 = THEME.textPrimary,
			TextSize = 14,
			Font = Enum.Font.Gotham,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = puzzleChoicesFrame,
		}, { UI.roundedCorner(6), UI.padding(6, 10, 6, 10) })

		btn.MouseEnter:Connect(function()
			if not answered then UI.tween(btn, { BackgroundColor3 = THEME.bgSecondary }, 0.1) end
		end)
		btn.MouseLeave:Connect(function()
			if not answered then UI.tween(btn, { BackgroundColor3 = THEME.bgCard }, 0.1) end
		end)

		local c
		c = btn.MouseButton1Click:Connect(function()
			if answered then return end
			answered = true
			for _, cc in ipairs(conns) do cc:Disconnect() end

			if i == q.answer then
				score = score + 10
				btn.BackgroundColor3 = THEME.success
				puzzleScoreLabel.Text = "✓ Benar! Skor: " .. score
			else
				btn.BackgroundColor3 = THEME.danger
				-- Highlight correct answer
				local correctBtn = puzzleChoicesFrame:GetChildren()[q.answer]
				if correctBtn and correctBtn:IsA("TextButton") then
					correctBtn.BackgroundColor3 = THEME.success
				end
				puzzleScoreLabel.Text = "✗ Salah! Skor: " .. score
			end

			task.wait(1.2)
			runPuzzleGame(questions, qIdx + 1, score)
		end)
		table.insert(conns, c)
	end
end

local function startPuzzleGame(questions)
	puzzleFrame.Visible = true
	UI.fadeIn(puzzleFrame, 0.3)
	runPuzzleGame(questions, 1, 0)
end

---------------------------------------------------------------------
-- CULTURAL INSIGHT DISPLAY
---------------------------------------------------------------------
local insightFrame = UI.create("Frame", {
	Name = "CulturalInsight",
	Size = UDim2.new(0, 350, 0, 0),
	Position = UDim2.new(0.5, -175, 0, -80),
	BackgroundColor3 = THEME.bgPrimary,
	ClipsDescendants = true,
	Parent = screenGui,
}, {
	UI.roundedCorner(12),
	UI.create("UIStroke", { Color = THEME.gold, Thickness = 2 }),
	UI.padding(12, 16, 12, 16),
})

UI.create("TextLabel", {
	Name = "Title",
	Size = UDim2.new(1, 0, 0, 20),
	BackgroundTransparency = 1,
	Text = "💡 Wawasan Budaya",
	TextColor3 = THEME.gold,
	TextSize = 14,
	Font = Enum.Font.GothamBold,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = insightFrame,
})

local insightText = UI.create("TextLabel", {
	Name = "Text",
	Size = UDim2.new(1, 0, 0, 50),
	Position = UDim2.new(0, 0, 0, 24),
	BackgroundTransparency = 1,
	Text = "",
	TextColor3 = THEME.textPrimary,
	TextSize = 13,
	Font = Enum.Font.Gotham,
	TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	Parent = insightFrame,
})

local function showCulturalInsight(title, text)
	insightText.Text = text
	insightFrame.Size = UDim2.new(0, 350, 0, 0)

	-- Slide down
	UI.tween(insightFrame, { Size = UDim2.new(0, 350, 0, 90), Position = UDim2.new(0.5, -175, 0, 70) }, 0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

	-- Add to journal
	addJournalEntry("💡 " .. title .. ": " .. text, true)

	-- Auto-hide after 5 seconds
	task.delay(5, function()
		UI.tween(insightFrame, { Size = UDim2.new(0, 350, 0, 0), Position = UDim2.new(0.5, -175, 0, -80) }, 0.4)
	end)
end

---------------------------------------------------------------------
-- ENDING SCREEN
---------------------------------------------------------------------
local endingFrame = UI.create("Frame", {
	Name = "EndingScreen",
	Size = UDim2.new(1, 0, 1, 0),
	BackgroundColor3 = Color3.new(0, 0, 0),
	BackgroundTransparency = 0,
	Visible = false,
	Parent = screenGui,
}, {
	UI.padding(40, 40, 40, 40),
})

local endingContent = UI.create("Frame", {
	Size = UDim2.new(0.6, 0, 1, 0),
	Position = UDim2.new(0.2, 0, 0, 0),
	BackgroundTransparency = 1,
	Parent = endingFrame,
}, {
	UI.listLayout(Enum.FillDirection.Vertical, 16, Enum.HorizontalAlignment.Center),
	UI.padding(60, 20, 40, 20),
})

local endingTitle = UI.create("TextLabel", {
	Size = UDim2.new(1, 0, 0, 50),
	BackgroundTransparency = 1,
	Text = "",
	TextColor3 = THEME.gold,
	TextSize = 32,
	Font = Enum.Font.GothamBold,
	Parent = endingContent,
})

local endingText = UI.create("TextLabel", {
	Size = UDim2.new(1, 0, 0, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundTransparency = 1,
	Text = "",
	TextColor3 = THEME.textPrimary,
	TextSize = 16,
	Font = Enum.Font.Gotham,
	TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Center,
	Parent = endingContent,
})

local endingSkillsFrame = UI.create("Frame", {
	Size = UDim2.new(1, 0, 0, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundTransparency = 1,
	Parent = endingContent,
}, {
	UI.listLayout(Enum.FillDirection.Vertical, 6, Enum.HorizontalAlignment.Center),
})

local endingRestartBtn = UI.create("TextButton", {
	Size = UDim2.new(0, 200, 0, 50),
	BackgroundColor3 = THEME.accent,
	Text = "↺ Main Lagi",
	TextColor3 = THEME.bgPrimary,
	TextSize = 18,
	Font = Enum.Font.GothamBold,
	Visible = false,
	Parent = endingContent,
}, { UI.roundedCorner(10) })

local function showEndingScreen(endingType, title, desc, skills, insights)
	endingFrame.Visible = true
	endingRestartBtn.Visible = false

	-- Black fade in
	endingFrame.BackgroundTransparency = 0

	-- Clear old skill entries
	for _, child in ipairs(endingSkillsFrame:GetChildren()) do
		if child:IsA("TextLabel") then child:Destroy() end
	end

	endingTitle.Text = title
	endingTitle.TextTransparency = 1
	endingText.Text = desc
	endingText.TextTransparency = 1

	-- Animate title
	task.wait(1)
	UI.tween(endingTitle, { TextTransparency = 0 }, 1)
	task.wait(1.5)
	UI.tween(endingText, { TextTransparency = 0 }, 1)
	task.wait(1)

	-- Show skills summary
	if skills then
		for skill, pts in pairs(skills) do
			local label = SKILL_LABELS[skill] or skill
			local lbl = UI.create("TextLabel", {
				Size = UDim2.new(1, 0, 0, 24),
				BackgroundTransparency = 1,
				Text = label .. ": " .. pts .. " poin",
				TextColor3 = THEME.accent,
				TextSize = 14,
				Font = Enum.Font.Gotham,
				TextTransparency = 1,
				Parent = endingSkillsFrame,
			})
			UI.tween(lbl, { TextTransparency = 0 }, 0.5)
			task.wait(0.3)
		end
	end

	-- Show insights count
	if insights then
		task.wait(0.5)
		local insLbl = UI.create("TextLabel", {
			Size = UDim2.new(1, 0, 0, 24),
			BackgroundTransparency = 1,
			Text = "Wawasan budaya terkumpul: " .. #insights,
			TextColor3 = THEME.gold,
			TextSize = 14,
			Font = Enum.Font.GothamMedium,
			TextTransparency = 1,
			Parent = endingSkillsFrame,
		})
		UI.tween(insLbl, { TextTransparency = 0 }, 0.5)
	end

	-- Show restart button
	task.wait(1)
	endingRestartBtn.Visible = true
	UI.fadeIn(endingRestartBtn, 0.5)
end

endingRestartBtn.MouseButton1Click:Connect(function()
	endingFrame.Visible = false
	RE_PlayerAction:FireServer("restart")
end)

---------------------------------------------------------------------
-- LEVEL TRANSITION OVERLAY
---------------------------------------------------------------------
local transitionFrame = UI.create("Frame", {
	Name = "Transition",
	Size = UDim2.new(1, 0, 1, 0),
	BackgroundColor3 = THEME.bgPrimary,
	BackgroundTransparency = 1,
	Visible = false,
	Parent = screenGui,
})

local transitionText = UI.create("TextLabel", {
	Size = UDim2.new(0.8, 0, 0, 60),
	Position = UDim2.new(0.1, 0, 0.45, 0),
	BackgroundTransparency = 1,
	Text = "",
	TextColor3 = THEME.accent,
	TextSize = 28,
	Font = Enum.Font.GothamBold,
	TextTransparency = 1,
	Parent = transitionFrame,
})

local function showLevelTransition(levelName)
	transitionFrame.Visible = true
	transitionText.Text = LEVEL_DISPLAY[levelName] or levelName
	transitionText.TextTransparency = 1
	transitionFrame.BackgroundTransparency = 1

	-- Fade to black
	UI.tween(transitionFrame, { BackgroundTransparency = 0 }, 0.8)
	task.wait(1)
	UI.tween(transitionText, { TextTransparency = 0 }, 0.5)
	task.wait(2)
	UI.tween(transitionText, { TextTransparency = 1 }, 0.5)
	task.wait(0.5)
	UI.tween(transitionFrame, { BackgroundTransparency = 1 }, 0.8)
	task.wait(1)
	transitionFrame.Visible = false
end

---------------------------------------------------------------------
-- NPC INTERACTION PROMPT
---------------------------------------------------------------------
local interactPrompt = UI.create("TextLabel", {
	Name = "InteractPrompt",
	Size = UDim2.new(0, 200, 0, 40),
	Position = UDim2.new(0.5, -100, 0.65, 0),
	BackgroundColor3 = THEME.bgPrimary,
	BackgroundTransparency = 0.2,
	Text = "[E] Bicara dengan NPC",
	TextColor3 = THEME.accent,
	TextSize = 14,
	Font = Enum.Font.GothamMedium,
	Visible = false,
	Parent = screenGui,
}, {
	UI.roundedCorner(8),
	UI.create("UIStroke", { Color = THEME.accent, Thickness = 1, Transparency = 0.5 }),
})

---------------------------------------------------------------------
-- NOTIFICATION SYSTEM
---------------------------------------------------------------------
local function showNotification(text, color, duration)
	local notif = UI.create("TextLabel", {
		Size = UDim2.new(0, 300, 0, 40),
		Position = UDim2.new(0.5, -150, 0, -50),
		BackgroundColor3 = THEME.bgCard,
		Text = text,
		TextColor3 = color or THEME.textPrimary,
		TextSize = 14,
		Font = Enum.Font.GothamMedium,
		Parent = screenGui,
	}, {
		UI.roundedCorner(8),
		UI.create("UIStroke", { Color = color or THEME.accent, Thickness = 1, Transparency = 0.5 }),
		UI.padding(6, 12, 6, 12),
	})

	-- Slide in
	UI.tween(notif, { Position = UDim2.new(0.5, -150, 0, 70) }, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

	task.delay(duration or 3, function()
		UI.tween(notif, { Position = UDim2.new(0.5, -150, 0, -50) }, 0.3)
		task.wait(0.4)
		notif:Destroy()
	end)
end

---------------------------------------------------------------------
-- LOCAL STATE
---------------------------------------------------------------------
local playerData = nil
local currentLevel = nil

---------------------------------------------------------------------
-- UPDATE HUD FROM SERVER DATA
---------------------------------------------------------------------
local function updateHUD(data)
	if not data then return end
	playerData = data

	-- Update skill bars
	if data.skills then
		for skillKey, barInfo in pairs(skillBars) do
			local val = data.skills[skillKey] or 0
			local pct = math.clamp(val / 100, 0, 1)
			UI.tween(barInfo.bar, { Size = UDim2.new(pct, 0, 1, 0) }, 0.5)
		end
	end

	-- Update progress
	if data.levelIndex and data.totalLevels then
		local pct = data.levelIndex / data.totalLevels
		UI.tween(progressBar, { Size = UDim2.new(pct, 0, 1, 0) }, 0.5)
		progressLabel.Text = math.floor(pct * 100) .. "%"
	end

	-- Update level title
	if data.currentLevel then
		currentLevel = data.currentLevel
		levelLabel.Text = LEVEL_DISPLAY[data.currentLevel] or "Jejak Nusantara"

		-- Update map
		if mapNodes[data.currentLevel] then
			mapNodes[data.currentLevel].status.Text = "📍 Di sini"
			mapNodes[data.currentLevel].status.TextColor3 = THEME.accent
		end
	end

	-- Update completed levels on map
	if data.completedLevels then
		for _, lvl in ipairs(data.completedLevels) do
			if mapNodes[lvl] then
				mapNodes[lvl].status.Text = "✅ Selesai"
				mapNodes[lvl].status.TextColor3 = THEME.success
			end
		end
	end

	-- Unlock next level on map
	if data.unlockedLevel and mapNodes[data.unlockedLevel] then
		if mapNodes[data.unlockedLevel].status.Text == "🔒 Terkunci" then
			mapNodes[data.unlockedLevel].status.Text = "🔓 Terbuka"
			mapNodes[data.unlockedLevel].status.TextColor3 = THEME.warning
		end
	end
end

---------------------------------------------------------------------
-- REMOTE EVENT HANDLERS
---------------------------------------------------------------------

-- UI Update from server
RE_UpdateUI.OnClientEvent:Connect(function(payload)
	if type(payload) ~= "table" then return end
	local action = payload.type or payload.action
	local data = payload

	if action == "sync" or action == "init" then
		updateHUD(data)
	elseif action == "skill_update" or action == "skill_up" then
		local skill = data.skill
		local pts = data.points or data.value or 0
		if skillBars[skill] then
			showNotification("+" .. pts .. " " .. (SKILL_LABELS[skill] or skill), THEME.accent, 2)
		end
	elseif action == "level_start" then
		showLevelTransition(data.level)
		updateHUD(data)
		levelLabel.Text = LEVEL_DISPLAY[data.level] or data.level
		addJournalEntry("━━━ Memasuki: " .. (LEVEL_DISPLAY[data.level] or data.level) .. " ━━━")
	elseif action == "progress" then
		if data.message then
			addJournalEntry(data.message)
		end
	elseif action == "cultural_points" then
		-- Update progress display
		if data.value then
			showNotification("💡 +" .. data.value .. " Poin Budaya", THEME.gold, 2)
		end
	elseif action == "npc_blocked" then
		showNotification(data.reason or "NPC tidak tersedia", THEME.warning, 3)
	elseif action == "dialogue_blocked" then
		showNotification(data.reason or "Dialog terkunci", THEME.warning, 3)
	end
end)

-- Dialogue from server
RE_DialogueEvent.OnClientEvent:Connect(function(dlgKey, dlgStep)
	if type(dlgStep) == "table" then
		local npcName = dlgStep.speaker or dlgKey or "NPC"
		local text = dlgStep.text or dlgStep.message or ""
		local choices = dlgStep.choices
		showDialogue(npcName, text, choices)
	elseif type(dlgStep) == "string" then
		-- Simple text dialogue
		showDialogue(dlgKey or "NPC", dlgStep, nil)
	end
end)

-- Cultural insight from server
RE_CulturalInsight.OnClientEvent:Connect(function(payload)
	if type(payload) == "table" then
		showCulturalInsight(payload.title or "Wawasan", payload.text or "")
	elseif type(payload) == "string" then
		showCulturalInsight("Wawasan", payload)
	end
end)

-- Ending from server
RE_TriggerEnding.OnClientEvent:Connect(function(payload)
	if type(payload) == "table" then
		showEndingScreen(
			payload.id or "ending",
			payload.title or "Selesai",
			payload.desc or "",
			payload.skills,
			payload.insights
		)
	end
end)

-- Level transition from server
RE_LevelTransition.OnClientEvent:Connect(function(levelName)
	showLevelTransition(levelName)
end)

-- Journal update from server
RE_JournalUpdate.OnClientEvent:Connect(function(text)
	addJournalEntry(text)
end)

-- Mini game trigger from server
RE_MiniGameResult.OnClientEvent:Connect(function(gameType, ...)
	-- Server tells client which game to start
	if gameType == "start_angklung" then
		local patternLen = select(1, ...) or 5
		startAngklungGame(patternLen)
	elseif gameType == "start_tari" then
		local seqLen = select(1, ...) or 6
		startTariGame(seqLen)
	elseif gameType == "start_tawar" then
		local item, minP, maxP, attempts = ...
		startTawarGame(item or "Batik Tulis", minP or 50000, maxP or 200000, attempts or 5)
	elseif gameType == "start_puzzle" then
		local questions = select(1, ...)
		if questions then
			startPuzzleGame(questions)
		end
	end
end)

---------------------------------------------------------------------
-- INPUT HANDLING (E to interact with NPC)
---------------------------------------------------------------------
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end

	if input.KeyCode == Enum.KeyCode.E then
		if interactPrompt.Visible then
			RE_PlayerAction:FireServer("interact_npc")
		end
	end
end)

---------------------------------------------------------------------
-- NPC PROXIMITY DETECTION
---------------------------------------------------------------------
local function setupNPCProximity()
	-- This would be connected to actual NPC parts in workspace
	-- For now, listen for server signals
	RE_PlayerAction.OnClientEvent:Connect(function(action, data)
		if action == "near_npc" then
			interactPrompt.Text = "[E] Bicara dengan " .. (data.npcName or "NPC")
			interactPrompt.Visible = true
		elseif action == "leave_npc" then
			interactPrompt.Visible = false
		end
	end)
end

---------------------------------------------------------------------
-- INIT
---------------------------------------------------------------------
local function init()
	-- Fetch initial player data
	local success, data = pcall(function()
		return RF_GetPlayerData:InvokeServer()
	end)

	if success and data then
		updateHUD(data)
	end

	setupNPCProximity()

	-- Welcome
	addJournalEntry("━━━ Jejak Nusantara — Petualangan Budaya Indonesia ━━━")
	addJournalEntry("Jelajahi 4 level budaya Nusantara.")
	addJournalEntry("Tekan [J] untuk jurnal, [M] untuk peta, [E] untuk berinteraksi.")
	addJournalEntry("")

	showNotification("Selamat datang di Jejak Nusantara! 🇮🇩", THEME.accent, 4)
end

init()

---------------------------------------------------------------------
-- EXPOSE API (for other scripts to call)
---------------------------------------------------------------------
local GameClient = {}

function GameClient.showDialogue(npcName, text, choices)
	showDialogue(npcName, text, choices)
end

function GameClient.showInsight(title, text)
	showCulturalInsight(title, text)
end

function GameClient.showNotification(text, color, duration)
	showNotification(text, color, duration)
end

function GameClient.startAngklung(patternLen)
	startAngklungGame(patternLen)
end

function GameClient.startTari(seqLen)
	startTariGame(seqLen)
end

function GameClient.startTawar(item, minP, maxP, attempts)
	startTawarGame(item, minP, maxP, attempts)
end

function GameClient.startPuzzle(questions)
	startPuzzleGame(questions)
end

function GameClient.showEnding(endingType, title, desc, skills, insights)
	showEndingScreen(endingType, title, desc, skills, insights)
end

function GameClient.updateHUD(data)
	updateHUD(data)
end

return GameClient