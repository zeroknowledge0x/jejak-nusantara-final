--[[
    ============================================
    JEJAK NUSANTARA v4.0 - COMPLETE SERVER SCRIPT
    ============================================
    Place in: ServerScriptService (Script)
    
    Features:
    - 5 NPCs with ProximityPrompt
    - 4 portals with ProximityPrompt + level gating
    - Quiz system (4 wilayah, 12 soal)
    - Dialogue system with branching choices & state machine
    - XP, Level, Coin system
    - DataStore save/load
    - Journal system
    - 3 Endings (Budayawan / Penjelajah / Pemula)
    
    v4.0 fixes:
    - Bug #1: activeNPC tracking per player
    - Bug #2: quizId sent with QuizStart
    - Bug #3: proper dialogue state machine
    - Added: DataStore, endings, level progression, journal
]]

print("🎮 Jejak Nusantara v4.0 - Loading...")

-- ============================================
-- SERVICES
-- ============================================
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

-- ============================================
-- DATA STORE (lazy init — won't crash if API disabled)
-- ============================================
local dataStore = nil
local function getDataStore()
    if dataStore then return dataStore end
    local ok, ds = pcall(function()
        return DataStoreService:GetDataStore("JejakNusantara_v4")
    end)
    if ok then dataStore = ds end
    return dataStore
end

-- ============================================
-- CREATE REMOTE EVENTS
-- ============================================
local function createRemote(className, name)
    local r = Instance.new(className)
    r.Name = name
    r.Parent = RS
    return r
end

-- Game Flow
createRemote("RemoteEvent", "GameStart")
createRemote("RemoteEvent", "DialogueStart")
createRemote("RemoteEvent", "DialogueEnd")
createRemote("RemoteEvent", "DialogueChoice")

-- Quiz
createRemote("RemoteEvent", "QuizStart")
createRemote("RemoteEvent", "QuizAnswer")
createRemote("RemoteEvent", "QuizEnd")

-- Progression
createRemote("RemoteEvent", "ShowNotification")
createRemote("RemoteEvent", "StateUpdate")
createRemote("RemoteFunction", "GetPlayerData")

-- New for v4
createRemote("RemoteEvent", "JournalUpdate")
createRemote("RemoteEvent", "EndingTriggered")
createRemote("RemoteEvent", "LevelUnlocked")

print("✅ Remote events created!")

-- ============================================
-- QUIZ DATA
-- ============================================
local QUIZZES = {
    quiz_jawa = {
        title = "Quiz Budaya Jawa",
        questions = {
            {q = "Apa nama rumah adat Jawa Tengah?", a = {"Joglo", "Rumah Gadang", "Tongkonan", "Honai"}, correct = 1},
            {q = "Alat musik tradisional Jawa?", a = {"Angklung", "Gamelan", "Sasando", "Kolintang"}, correct = 2},
            {q = "Tarian tradisional dari Jawa?", a = {"Tari Kecak", "Tari Piring", "Tari Gambyong", "Tari Saman"}, correct = 3}
        }
    },
    quiz_sumatra = {
        title = "Quiz Budaya Sumatra",
        questions = {
            {q = "Apa nama rumah adat Sumatra Barat?", a = {"Joglo", "Rumah Gadang", "Tongkonan", "Honai"}, correct = 2},
            {q = "Tarian tradisional dari Sumatra?", a = {"Tari Kecak", "Tari Piring", "Tari Saman", "Tari Gambyong"}, correct = 3},
            {q = "Alat musik dari Sumatra?", a = {"Gamelan", "Angklung", "Sasando", "Kolintang"}, correct = 2}
        }
    },
    quiz_bali = {
        title = "Quiz Budaya Bali",
        questions = {
            {q = "Apa nama pura terkenal di Bali?", a = {"Pura Besakih", "Pura Ulun Danu", "Pura Tanah Lot", "Pura Uluwatu"}, correct = 1},
            {q = "Tarian tradisional dari Bali?", a = {"Tari Kecak", "Tari Piring", "Tari Saman", "Tari Gambyong"}, correct = 1},
            {q = "Upacara adat di Bali?", a = {"Ngaben", "Rambu Solo", "Tabuik", "Seren Taun"}, correct = 1}
        }
    },
    quiz_papua = {
        title = "Quiz Budaya Papua",
        questions = {
            {q = "Apa nama rumah adat Papua?", a = {"Joglo", "Rumah Gadang", "Tongkonan", "Honai"}, correct = 4},
            {q = "Tarian tradisional dari Papua?", a = {"Tari Kecak", "Tari Piring", "Tari Selamat Datang", "Tari Gambyong"}, correct = 3},
            {q = "Senjata tradisional Papua?", a = {"Keris", "Rencong", "Parang", "Tombak"}, correct = 4}
        }
    }
}

-- ============================================
-- DIALOGUE DATA
-- ============================================
local DIALOGUES = {
    Dosen = {
        name = "Pak Dosen",
        lines = {
            {
                text = "Selamat datang, mahasiswa! Saya akan mengajak kalian menjelajahi budaya Indonesia melalui game ini.",
                choices = {
                    {text = "Siap, Pak!", next = 2},
                    {text = "Apa yang harus saya lakukan?", next = 3}
                }
            },
            {
                text = "Bagus! Klik portal di setiap wilayah untuk mempelajari budayanya. Setiap wilayah punya quiz!",
                choices = {
                    {text = "Saya mengerti!", next = 4},
                    {text = "Tunjukkan caranya", next = 5}
                }
            },
            {
                text = "Kalian akan belajar budaya dari 4 wilayah: Jawa, Sumatra, Bali, dan Papua. Klik portal untuk mulai!",
                choices = {
                    {text = "Siap!", next = 4}
                }
            },
            {
                text = "Selamat belajar! Semoga kalian menjadi generasi yang mencintai budaya Indonesia!",
                choices = {
                    {text = "Terima kasih, Pak!", action = "end"}
                }
            },
            {
                text = "Lihat ada 4 portal berwarna di sekitar kalian. Klik salah satu untuk masuk ke wilayah tersebut!",
                choices = {
                    {text = "Baik, Pak!", action = "end"}
                }
            }
        }
    },
    Karso = {
        name = "Pak Karso",
        lines = {
            {
                text = "Sugeng rawuh! Saya Pak Karso, budayawan dari Jawa Tengah. Mau tahu apa tentang budaya Jawa?",
                choices = {
                    {text = "Apa itu Gamelan?", next = 2},
                    {text = "Ceritakan tentang batik", next = 3},
                    {text = "Apa rumah adat Jawa?", next = 4}
                }
            },
            {
                text = "Gamelan adalah ansambel musik tradisional Jawa. Alat musiknya terdiri dari bonang, saron, gong, dan lainnya. Bunyinya khas dan menenangkan!",
                choices = {
                    {text = "Menarik!", next = 5}
                }
            },
            {
                text = "Batik adalah seni menggambar di kain menggunakan malam (lilin). Setiap motif punya makna filosofis. Batik sudah diakui UNESCO!",
                choices = {
                    {text = "Luar biasa!", next = 5}
                }
            },
            {
                text = "Rumah adat Jawa Tengah adalah Joglo. Bentuknya unik dengan atap menjulang tinggi, melambangkan gunung yang menjulang.",
                choices = {
                    {text = "Keren!", next = 5}
                }
            },
            {
                text = "Jawa punya budaya yang sangat kaya. Dari wayang kulit, tari gambyong, hingga kuliner gudeg dan soto!",
                choices = {
                    {text = "Terima kasih, Pak Karso!", action = "end"}
                }
            }
        }
    },
    Ratna = {
        name = "Ibu Ratna",
        lines = {
            {
                text = "Halo! Saya Ibu Ratna dari Sumatra Barat. Mau tahu tentang budaya Minangkabau?",
                choices = {
                    {text = "Apa itu Rumah Gadang?", next = 2},
                    {text = "Ceritakan tentang rendang", next = 3},
                    {text = "Apa tarian khas Sumatra?", next = 4}
                }
            },
            {
                text = "Rumah Gadang adalah rumah adat Minangkabau dengan atap runcing seperti tanduk kerbau. Simbol kekuatan dan kearifan!",
                choices = {
                    {text = "Indah sekali!", next = 5}
                }
            },
            {
                text = "Rendang adalah masakan daging dengan santan dan rempah. Dimasak berjam-jam hingga kering. Dinobatkan sebagai makanan terenak di dunia!",
                choices = {
                    {text = "Lapar jadinya!", next = 5}
                }
            },
            {
                text = "Tari Piring berasal dari Sumatra Barat. Penari membawa piring di tangan dan bergerak lincah. Sangat indah!",
                choices = {
                    {text = "Ingin lihat!", next = 5}
                }
            },
            {
                text = "Sumatra kaya akan budaya! Dari Tor-tor Batak, randai Minang, hingga kuliner pempek Palembang!",
                choices = {
                    {text = "Terima kasih, Ibu Ratna!", action = "end"}
                }
            }
        }
    },
    Wayan = {
        name = "Mang Wayan",
        lines = {
            {
                text = "Om Swastiastu! Saya Mang Wayan dari Bali. Mau tahu tentang Pulau Dewata?",
                choices = {
                    {text = "Apa itu Pura?", next = 2},
                    {text = "Ceritakan tentang Tari Kecak", next = 3},
                    {text = "Apa upacara khas Bali?", next = 4}
                }
            },
            {
                text = "Pura adalah tempat ibadah umat Hindu Bali. Ada ribuan pura di Bali! Yang terkenal adalah Pura Besakih dan Tanah Lot.",
                choices = {
                    {text = "Megah!", next = 5}
                }
            },
            {
                text = "Tari Kecak adalah tari massal yang dibawakan puluhan penari sambil duduk melingkar dan meneriakkan 'cak-cak-cak'. Sangat ikonik!",
                choices = {
                    {text = "Ingin nonton!", next = 5}
                }
            },
            {
                text = "Ngaben adalah upacara kremasi jenazah. Bali memang unik! Ada juga Nyepi, hari di mana seluruh Bali sunyi senyap.",
                choices = {
                    {text = "Menarik!", next = 5}
                }
            },
            {
                text = "Bali terkenal dengan seni, budaya, dan alamnya. Dari tari barong, ukiran kayu, hingga kuliner babi guling!",
                choices = {
                    {text = "Terima kasih, Mang Wayan!", action = "end"}
                }
            }
        }
    },
    Yanu = {
        name = "Bapak Yanu",
        lines = {
            {
                text = "Halo! Saya Bapak Yanu dari Papua. Mau tahu tentang tanah Cenderawasih?",
                choices = {
                    {text = "Apa itu Honai?", next = 2},
                    {text = "Ceritakan tentang tari Papua", next = 3},
                    {text = "Apa senjata khas Papua?", next = 4}
                }
            },
            {
                text = "Honai adalah rumah tradisional Papua berbentuk bulat dengan atap jerami. Di dalamnya hangat dan nyaman!",
                choices = {
                    {text = "Unik!", next = 5}
                }
            },
            {
                text = "Tari Selamat Datang adalah tari penyambutan dari Papua. Penari membawa tombak dan perisai, gerakannya gagah!",
                choices = {
                    {text = "Keren!", next = 5}
                }
            },
            {
                text = "Papua punya senjata tradisional seperti tombak, panah, dan parang. Juga ada alat musik tifa yang bunyinya khas!",
                choices = {
                    {text = "Menarik!", next = 5}
                }
            },
            {
                text = "Papua surga tersembunyi Indonesia! Dari Raja Ampat, Danau Sentani, hingga burung Cenderawasih yang indah!",
                choices = {
                    {text = "Terima kasih, Bapak Yanu!", action = "end"}
                }
            }
        }
    }
}

-- ============================================
-- PORTAL UNLOCK ORDER
-- ============================================
local PORTAL_ORDER = {
    {quizId = "quiz_jawa", portalName = "PortalJawa"},
    {quizId = "quiz_sumatra", portalName = "PortalSumatra"},
    {quizId = "quiz_bali", portalName = "PortalBali"},
    {quizId = "quiz_papua", portalName = "PortalPapua"},
}

-- ============================================
-- ENDING DATA
-- ============================================
local ENDINGS = {
    budayawan = {
        title = "🏆 Budayawan Nusantara",
        description = "Kamu telah menyelesaikan semua quiz dan mengumpulkan pengetahuan budaya yang luar biasa! Kamu adalah pewaris budaya Indonesia yang sesungguhnya. Teruslah melestarikan kekayaan nusantara!",
        color = {255, 215, 0},
    },
    penjelajah = {
        title = "🗺️ Penjelajah Budaya",
        description = "Kamu sudah menjelajahi cukup banyak budaya Indonesia! Meskipun belum sempurna, semangat eksplorasimu patut diacungi jempol. Teruslah belajar!",
        color = {0, 200, 200},
    },
    pemula = {
        title = "🌱 Pemula",
        description = "Perjalanan budaya baru dimulai! Masih banyak yang bisa dipelajari. Jangan menyerah, teruslah bertualang dan berinteraksi dengan NPC untuk belajar lebih banyak!",
        color = {200, 200, 200},
    },
}

print("✅ Game data loaded!")

-- ============================================
-- PLAYER DATA (with DataStore persistence)
-- ============================================
local playerData = {}
local playerActiveNPC = {} -- Bug #1 fix: track which NPC each player is talking to
local playerDialogueLine = {} -- Bug #3 fix: track current dialogue line per player

local function createDefaultData()
    return {
        level = 1,
        xp = 0,
        xpToNext = 1000,
        coins = 0,
        completedQuizzes = {},
        talkCount = 0,
        journal = {},
        unlockedPortals = {quiz_jawa = true},
    }
end

local function loadPlayerData(player)
    local success, data = pcall(function()
        return getDataStore():GetAsync("player_" .. player.UserId)
    end)
    if success and data then
        -- Merge with defaults so new fields are present
        local merged = createDefaultData()
        for k, v in pairs(data) do
            merged[k] = v
        end
        -- Ensure unlockedPortals table exists
        if not merged.unlockedPortals then
            merged.unlockedPortals = {quiz_jawa = true}
        end
        if not merged.journal then
            merged.journal = {}
        end
        return merged
    end
    return nil
end

local function savePlayerData(player)
    local data = playerData[player.UserId]
    if not data then return end
    local success, err = pcall(function()
        getDataStore():SetAsync("player_" .. player.UserId, data)
    end)
    if success then
        print("[DataStore] Saved: " .. player.Name)
    else
        warn("[DataStore] Save failed: " .. player.Name .. " Error: " .. tostring(err))
    end
end

local function getPlayerData(player)
    if not playerData[player.UserId] then
        playerData[player.UserId] = createDefaultData()
    end
    return playerData[player.UserId]
end

-- GetPlayerData RemoteFunction
RS.GetPlayerData.OnServerInvoke = function(player)
    return getPlayerData(player)
end

-- ============================================
-- STATE SYNC HELPER
-- ============================================
local function syncState(player, key, value)
    RS.StateUpdate:FireClient(player, key, value)
end

-- ============================================
-- XP, COIN, LEVEL SYSTEM
-- ============================================
local function addXP(player, amount)
    local data = getPlayerData(player)
    data.xp = data.xp + amount

    -- Level up check
    while data.xp >= data.xpToNext do
        data.xp = data.xp - data.xpToNext
        data.level = data.level + 1
        data.xpToNext = data.xpToNext + 500
        RS.ShowNotification:FireClient(player, "🎉 Level Up! Level " .. data.level)
        syncState(player, "level", data.level)
    end

    RS.ShowNotification:FireClient(player, "+" .. amount .. " XP")
    syncState(player, "xp", data.xp)
    syncState(player, "xpToNext", data.xpToNext)
end

local function addCoins(player, amount)
    local data = getPlayerData(player)
    data.coins = data.coins + amount
    RS.ShowNotification:FireClient(player, "+" .. amount .. " Koin 💰")
    syncState(player, "coins", data.coins)
end

-- ============================================
-- JOURNAL SYSTEM
-- ============================================
local function addJournalEntry(player, entry)
    local data = getPlayerData(player)
    table.insert(data.journal, {text = entry, time = os.time()})
    RS.JournalUpdate:FireClient(player, entry)
end

-- ============================================
-- ENDING SYSTEM
-- ============================================
local function checkAndTriggerEnding(player)
    local data = getPlayerData(player)
    local quizCount = 0
    for _ in pairs(data.completedQuizzes) do
        quizCount = quizCount + 1
    end

    local endingId, endingData

    if quizCount >= 4 and data.xp >= 500 then
        endingId = "budayawan"
        endingData = ENDINGS.budayawan
    elseif quizCount >= 2 and data.xp >= 200 then
        endingId = "penjelajah"
        endingData = ENDINGS.penjelajah
    else
        endingId = "pemula"
        endingData = ENDINGS.pemula
    end

    data.currentEnding = endingId
    RS.EndingTriggered:FireClient(player, endingId, endingData)
    addJournalEntry(player, "🎬 Perjalanan berakhir! Gelar: " .. endingData.title)
    savePlayerData(player)
    print("[Ending] " .. endingId .. " for " .. player.Name)
end

-- ============================================
-- PORTAL UNLOCK HELPER
-- ============================================
local function unlockNextPortal(player, completedQuizId)
    local data = getPlayerData(player)
    -- Find which quiz was just completed and unlock the next one
    for i, entry in ipairs(PORTAL_ORDER) do
        if entry.quizId == completedQuizId and i < #PORTAL_ORDER then
            local nextEntry = PORTAL_ORDER[i + 1]
            if not data.unlockedPortals[nextEntry.quizId] then
                data.unlockedPortals[nextEntry.quizId] = true
                local quiz = QUIZZES[nextEntry.quizId]
                RS.ShowNotification:FireClient(player, "🔓 Portal baru terbuka: " .. quiz.title)
                RS.LevelUnlocked:FireClient(player, nextEntry.quizId)
                addJournalEntry(player, "🔓 Portal terbuka: " .. quiz.title)
            end
            break
        end
    end
end

-- ============================================
-- NPC CREATION FUNCTION
-- ============================================
local function createNPC(name, position, dialogueId, bodyColor, shirtColor)
    local npc = Instance.new("Model")
    npc.Name = name

    -- Torso
    local torso = Instance.new("Part")
    torso.Name = "HumanoidRootPart"
    torso.Size = Vector3.new(2, 2, 1)
    torso.Position = position
    torso.Anchored = true
    torso.CanCollide = false
    torso.Color = shirtColor or Color3.fromRGB(50, 50, 150)
    torso.Parent = npc

    -- Head
    local head = Instance.new("Part")
    head.Name = "Head"
    head.Size = Vector3.new(2, 2, 2)
    head.Position = position + Vector3.new(0, 2, 0)
    head.Anchored = true
    head.CanCollide = false
    head.Color = bodyColor or Color3.fromRGB(200, 150, 100)
    head.Parent = npc

    -- Face
    local face = Instance.new("Decal")
    face.Name = "Face"
    face.Face = Enum.NormalId.Front
    face.Texture = "rbxassetid://7074739"
    face.Parent = head

    -- Hair for Dosen
    if name == "Pak Dosen" then
        local hair = Instance.new("Part")
        hair.Name = "Hair"
        hair.Size = Vector3.new(2.1, 0.5, 2.1)
        hair.Position = position + Vector3.new(0, 3.2, 0)
        hair.Anchored = true
        hair.CanCollide = false
        hair.Color = Color3.fromRGB(50, 50, 50)
        hair.Parent = npc
    end

    -- Left Arm
    local leftArm = Instance.new("Part")
    leftArm.Name = "Left Arm"
    leftArm.Size = Vector3.new(1, 2, 1)
    leftArm.Position = position + Vector3.new(-1.5, 1, 0)
    leftArm.Anchored = true
    leftArm.CanCollide = false
    leftArm.Color = bodyColor or Color3.fromRGB(200, 150, 100)
    leftArm.Parent = npc

    -- Right Arm
    local rightArm = Instance.new("Part")
    rightArm.Name = "Right Arm"
    rightArm.Size = Vector3.new(1, 2, 1)
    rightArm.Position = position + Vector3.new(1.5, 1, 0)
    rightArm.Anchored = true
    rightArm.CanCollide = false
    rightArm.Color = bodyColor or Color3.fromRGB(200, 150, 100)
    rightArm.Parent = npc

    -- Left Leg
    local leftLeg = Instance.new("Part")
    leftLeg.Name = "Left Leg"
    leftLeg.Size = Vector3.new(1, 2, 1)
    leftLeg.Position = position + Vector3.new(-0.5, -1, 0)
    leftLeg.Anchored = true
    leftLeg.CanCollide = false
    leftLeg.Color = Color3.fromRGB(50, 50, 100)
    leftLeg.Parent = npc

    -- Right Leg
    local rightLeg = Instance.new("Part")
    rightLeg.Name = "Right Leg"
    rightLeg.Size = Vector3.new(1, 2, 1)
    rightLeg.Position = position + Vector3.new(0.5, -1, 0)
    rightLeg.Anchored = true
    rightLeg.CanCollide = false
    rightLeg.Color = Color3.fromRGB(50, 50, 100)
    rightLeg.Parent = npc

    -- Name tag
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "NameTag"
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 4, 0)
    billboard.Parent = head

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 1, 0)
    nameLabel.BackgroundTransparency = 0.5
    nameLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.Text = name
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Parent = billboard

    -- ProximityPrompt
    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = "Bicara"
    prompt.ObjectText = name
    prompt.MaxActivationDistance = 15
    prompt.HoldDuration = 0
    prompt.Parent = torso

    prompt.Triggered:Connect(function(player)
        -- Bug #1 fix: prevent re-trigger while in dialogue
        if playerActiveNPC[player.UserId] then return end

        local data = getPlayerData(player)
        data.talkCount = (data.talkCount or 0) + 1

        -- Bug #1 fix: track active NPC
        playerActiveNPC[player.UserId] = dialogueId
        playerDialogueLine[player.UserId] = 1

        local dialogue = DIALOGUES[dialogueId]
        if dialogue then
            -- Send full dialogue table + dialogueId so client can navigate
            RS.DialogueStart:FireClient(player, dialogue, dialogueId)
            addJournalEntry(player, "💬 Berbicara dengan " .. dialogue.name)
        end
    end)

    npc.Parent = workspace
    print("[NPC] Created: " .. name .. " at " .. tostring(position))
    return npc
end

-- ============================================
-- PORTAL CREATION FUNCTION
-- ============================================
local function createPortal(name, position, destination, color, label, quizId)
    local portal = Instance.new("Part")
    portal.Name = name
    portal.Size = Vector3.new(8, 10, 2)
    portal.Position = position
    portal.Anchored = true
    portal.CanCollide = false
    portal.Color = color
    portal.Material = Enum.Material.Neon
    portal.Transparency = 0.3

    -- Portal frame
    local frame = Instance.new("Part")
    frame.Name = "Frame"
    frame.Size = Vector3.new(10, 12, 1)
    frame.Position = position
    frame.Anchored = true
    frame.CanCollide = true
    frame.Color = Color3.fromRGB(139, 90, 43)
    frame.Material = Enum.Material.Wood
    frame.Parent = portal

    -- Label
    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0, 200, 0, 60)
    billboard.StudsOffset = Vector3.new(0, 8, 0)
    billboard.Parent = portal

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 0.5
    textLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    textLabel.Text = label
    textLabel.TextScaled = true
    textLabel.Font = Enum.Font.GothamBold
    textLabel.Parent = billboard

    -- ProximityPrompt
    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = "Masuk"
    prompt.ObjectText = label
    prompt.MaxActivationDistance = 15
    prompt.HoldDuration = 0
    prompt.Parent = portal

    prompt.Triggered:Connect(function(player)
        local data = getPlayerData(player)

        -- Level gating: check if portal is unlocked
        if not data.unlockedPortals[quizId] then
            RS.ShowNotification:FireClient(player, "🔒 Portal ini belum terbuka! Selesaikan quiz sebelumnya.")
            return
        end

        -- Already completed?
        if data.completedQuizzes[quizId] then
            RS.ShowNotification:FireClient(player, "✅ Quiz ini sudah diselesaikan!")
            return
        end

        -- Teleport
        local character = player.Character
        if character then
            local hrp = character:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.CFrame = CFrame.new(destination)
            end
        end

        -- Bug #2 fix: send quizId along with quizData
        local quizData = QUIZZES[quizId]
        if quizData then
            RS.QuizStart:FireClient(player, quizData, quizId, 1)
            addJournalEntry(player, "📝 Memasuki quiz: " .. quizData.title)
            print("[Portal] " .. player.Name .. " entered " .. name)
        end
    end)

    portal.Parent = workspace
    print("[Portal] Created: " .. name)
    return portal
end

-- ============================================
-- WORLD CREATION
-- ============================================

-- Helper: build a simple house/building
local function buildHouse(parent, pos, w, h, d, wallColor, roofColor, name)
    local model = Instance.new("Model")
    model.Name = name or "Building"

    -- Floor
    local floor = Instance.new("Part")
    floor.Name = "Floor"
    floor.Size = Vector3.new(w, 0.5, d)
    floor.Position = pos + Vector3.new(0, 0.25, 0)
    floor.Anchored = true
    floor.Color = Color3.fromRGB(120, 90, 50)
    floor.Material = Enum.Material.Wood
    floor.Parent = model

    -- 4 Walls
    local walls = {
        {Vector3.new(0, h/2, d/2), Vector3.new(w, h, 1)},   -- Front
        {Vector3.new(0, h/2, -d/2), Vector3.new(w, h, 1)},  -- Back
        {Vector3.new(-w/2, h/2, 0), Vector3.new(1, h, d)},  -- Left
        {Vector3.new(w/2, h/2, 0), Vector3.new(1, h, d)},   -- Right
    }
    for i, wdata in ipairs(walls) do
        local wall = Instance.new("Part")
        wall.Name = "Wall" .. i
        wall.Size = wdata[2]
        wall.Position = pos + wdata[1]
        wall.Anchored = true
        wall.Color = wallColor
        wall.Material = Enum.Material.Wood
        wall.Parent = model
    end

    -- Door opening (front wall, remove middle)
    local door = Instance.new("Part")
    door.Name = "Door"
    door.Size = Vector3.new(3, 5, 1.2)
    door.Position = pos + Vector3.new(0, 2.5, d/2)
    door.Anchored = true
    door.Color = Color3.fromRGB(60, 35, 15)
    door.Material = Enum.Material.Wood
    door.Transparency = 0.3
    door.Parent = model

    -- Roof
    local roof = Instance.new("Part")
    roof.Name = "Roof"
    roof.Size = Vector3.new(w + 3, 1, d + 3)
    roof.Position = pos + Vector3.new(0, h + 0.5, 0)
    roof.Anchored = true
    roof.Color = roofColor
    roof.Material = Enum.Material.Slate
    roof.Parent = model

    -- Roof peak
    local peak = Instance.new("Part")
    peak.Name = "RoofPeak"
    peak.Size = Vector3.new(w * 0.3, 2, d * 0.3)
    peak.Position = pos + Vector3.new(0, h + 2, 0)
    peak.Anchored = true
    peak.Color = roofColor
    peak.Material = Enum.Material.Slate
    peak.Parent = model

    model.Parent = parent or workspace
    return model
end

-- Helper: build a tree
local function buildTree(parent, pos, height)
    local h = height or math.random(8, 14)
    local trunk = Instance.new("Part")
    trunk.Name = "Trunk"
    trunk.Size = Vector3.new(1.5, h, 1.5)
    trunk.Position = pos + Vector3.new(0, h/2, 0)
    trunk.Anchored = true
    trunk.Color = Color3.fromRGB(100, 70, 30)
    trunk.Material = Enum.Material.Wood
    trunk.Parent = parent

    for i = 0, 2 do
        local s = 8 - i * 2
        local canopy = Instance.new("Part")
        canopy.Name = "Canopy" .. i
        canopy.Size = Vector3.new(s, 3, s)
        canopy.Position = pos + Vector3.new(0, h + i * 2, 0)
        canopy.Anchored = true
        canopy.Color = Color3.fromRGB(40 + i*10, 120 + i*20, 40)
        canopy.Material = Enum.Material.Grass
        canopy.Parent = parent
    end
end

-- Helper: build water pond
local function buildWater(parent, pos, size)
    local water = Instance.new("Part")
    water.Name = "Water"
    water.Size = size or Vector3.new(20, 0.3, 20)
    water.Position = pos
    water.Anchored = true
    water.Color = Color3.fromRGB(50, 130, 200)
    water.Material = Enum.Material.Glass
    water.Transparency = 0.4
    water.CanCollide = false
    water.Parent = parent
end

-- Helper: build a candi/temple (tiered structure)
local function buildTemple(parent, pos, height)
    local h = height or 12
    local model = Instance.new("Model")
    model.Name = "Candi"

    for i = 0, 3 do
        local s = 14 - i * 3
        local tier = Instance.new("Part")
        tier.Name = "Tier" .. i
        tier.Size = Vector3.new(s, 3, s)
        tier.Position = pos + Vector3.new(0, i * 3 + 1.5, 0)
        tier.Anchored = true
        tier.Color = Color3.fromRGB(180, 170, 140)
        tier.Material = Enum.Material.Slate
        tier.Parent = model

        -- Stairs on each tier
        if i < 3 then
            local stair = Instance.new("Part")
            stair.Name = "Stairs" .. i
            stair.Size = Vector3.new(3, 1, 3)
            stair.Position = pos + Vector3.new(0, i * 3 + 0.5, s/2 + 1)
            stair.Anchored = true
            stair.Color = Color3.fromRGB(200, 180, 100)
            stair.Material = Enum.Material.SmoothPlastic
            stair.Parent = model
        end
    end

    -- Top stupa
    local stupa = Instance.new("Part")
    stupa.Name = "Stupa"
    stupa.Size = Vector3.new(4, 6, 4)
    stupa.Position = pos + Vector3.new(0, 15, 0)
    stupa.Anchored = true
    stupa.Color = Color3.fromRGB(200, 180, 100)
    stupa.Material = Enum.Material.Neon
    stupa.Transparency = 0.2
    stupa.Shape = Enum.PartType.Ball
    stupa.Parent = model

    model.Parent = parent or workspace
end

-- Helper: build a gate/portal frame
local function buildPortalFrame(parent, pos, color)
    local model = Instance.new("Model")
    model.Name = "PortalFrame"

    -- Left pillar
    local left = Instance.new("Part")
    left.Name = "LeftPillar"
    left.Size = Vector3.new(2, 14, 2)
    left.Position = pos + Vector3.new(-5, 7, 0)
    left.Anchored = true
    left.Color = Color3.fromRGB(139, 90, 43)
    left.Material = Enum.Material.Wood
    left.Parent = model

    -- Right pillar
    local right = Instance.new("Part")
    right.Name = "RightPillar"
    right.Size = Vector3.new(2, 14, 2)
    right.Position = pos + Vector3.new(5, 7, 0)
    right.Anchored = true
    right.Color = Color3.fromRGB(139, 90, 43)
    right.Material = Enum.Material.Wood
    right.Parent = model

    -- Top beam
    local beam = Instance.new("Part")
    beam.Name = "TopBeam"
    beam.Size = Vector3.new(12, 2, 2)
    beam.Position = pos + Vector3.new(0, 14, 0)
    beam.Anchored = true
    beam.Color = Color3.fromRGB(139, 90, 43)
    beam.Material = Enum.Material.Wood
    beam.Parent = model

    -- Portal glow
    local glow = Instance.new("Part")
    glow.Name = "Glow"
    glow.Size = Vector3.new(8, 12, 1)
    glow.Position = pos + Vector3.new(0, 7, 0)
    glow.Anchored = true
    glow.CanCollide = false
    glow.Color = color
    glow.Material = Enum.Material.Neon
    glow.Transparency = 0.3
    glow.Parent = model

    model.Parent = parent or workspace
end

-- Helper: build market stall
local function buildStall(parent, pos, roofColor, name)
    local model = Instance.new("Model")
    model.Name = name or "Stall"

    -- Table
    local table_ = Instance.new("Part")
    table_.Name = "Table"
    table_.Size = Vector3.new(8, 1, 5)
    table_.Position = pos + Vector3.new(0, 2, 0)
    table_.Anchored = true
    table_.Color = Color3.fromRGB(140, 100, 50)
    table_.Material = Enum.Material.Wood
    table_.Parent = model

    -- Roof
    local roof = Instance.new("Part")
    roof.Name = "Roof"
    roof.Size = Vector3.new(10, 0.5, 7)
    roof.Position = pos + Vector3.new(0, 5, 0)
    roof.Anchored = true
    roof.Color = roofColor
    roof.Material = Enum.Material.Slate
    roof.Parent = model

    -- 4 Poles
    for _, xOff in ipairs({-4, 4}) do
        for _, zOff in ipairs({-2.5, 2.5}) do
            local pole = Instance.new("Part")
            pole.Name = "Pole"
            pole.Size = Vector3.new(0.5, 4, 0.5)
            pole.Position = pos + Vector3.new(xOff, 3.5, zOff)
            pole.Anchored = true
            pole.Color = Color3.fromRGB(120, 80, 30)
            pole.Material = Enum.Material.Wood
            pole.Parent = model
        end
    end

    model.Parent = parent or workspace
end

-- Helper: add a floating region label
local function addLabel(text, pos)
    local adornee = Instance.new("Part")
    adornee.Name = "Label_" .. text
    adornee.Size = Vector3.new(1, 1, 1)
    adornee.Position = pos
    adornee.Anchored = true
    adornee.CanCollide = false
    adornee.Transparency = 1
    adornee.Parent = workspace

    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.new(0, 300, 0, 60)
    bb.StudsOffset = Vector3.new(0, 0, 0)
    bb.AlwaysOnTop = false
    bb.Adornee = adornee
    bb.Parent = workspace

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 0.5
    lbl.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    lbl.Text = text
    lbl.TextScaled = true
    lbl.Font = Enum.Font.GothamBold
    lbl.Parent = bb
end

local function createWorld()
    print("🌍 Creating world...")

    -- ==========================================
    -- GROUND PLATFORMS (5 areas)
    -- ==========================================
    -- Main ground (green grass)
    local ground = Instance.new("Part")
    ground.Name = "Ground"
    ground.Size = Vector3.new(500, 1, 500)
    ground.Position = Vector3.new(0, 0.5, 0)
    ground.Anchored = true
    ground.Color = Color3.fromRGB(90, 160, 70)
    ground.Material = Enum.Material.Grass
    ground.Parent = workspace

    -- Kampus platform (white stone)
    local kampus = Instance.new("Part")
    kampus.Name = "KampusPlatform"
    kampus.Size = Vector3.new(60, 1, 60)
    kampus.Position = Vector3.new(0, 0.5, 0)
    kampus.Anchored = true
    kampus.Color = Color3.fromRGB(220, 220, 210)
    kampus.Material = Enum.Material.Concrete
    kampus.Parent = workspace

    -- Jawa platform (warm sand)
    local jawaP = Instance.new("Part")
    jawaP.Name = "JawaPlatform"
    jawaP.Size = Vector3.new(80, 1, 80)
    jawaP.Position = Vector3.new(-120, 0.5, -120)
    jawaP.Anchored = true
    jawaP.Color = Color3.fromRGB(180, 150, 100)
    jawaP.Material = Enum.Material.Sand
    jawaP.Parent = workspace

    -- Sumatra platform (dark earth)
    local sumatraP = Instance.new("Part")
    sumatraP.Name = "SumatraPlatform"
    sumatraP.Size = Vector3.new(80, 1, 80)
    sumatraP.Position = Vector3.new(120, 0.5, -120)
    sumatraP.Anchored = true
    sumatraP.Color = Color3.fromRGB(140, 120, 80)
    sumatraP.Material = Enum.Material.Slate
    sumatraP.Parent = workspace

    -- Bali platform (light stone)
    local baliP = Instance.new("Part")
    baliP.Name = "BaliPlatform"
    baliP.Size = Vector3.new(80, 1, 80)
    baliP.Position = Vector3.new(-120, 0.5, 120)
    baliP.Anchored = true
    baliP.Color = Color3.fromRGB(200, 190, 170)
    baliP.Material = Enum.Material.Limestone
    baliP.Parent = workspace

    -- Papua platform (dark green)
    local papuaP = Instance.new("Part")
    papuaP.Name = "PapuaPlatform"
    papuaP.Size = Vector3.new(80, 1, 80)
    papuaP.Position = Vector3.new(120, 0.5, 120)
    papuaP.Anchored = true
    papuaP.Color = Color3.fromRGB(60, 100, 50)
    papuaP.Material = Enum.Material.Grass
    papuaP.Parent = workspace

    -- ==========================================
    -- PATHS connecting areas
    -- ==========================================
    local paths = {
        {Vector3.new(0, 0.6, -30), Vector3.new(60, 0.3, 6)},   -- Kampus → Jawa
        {Vector3.new(30, 0.6, 0), Vector3.new(6, 0.3, 60)},    -- Kampus → Sumatra (right)
        {Vector3.new(-30, 0.6, 0), Vector3.new(6, 0.3, 60)},   -- Kampus → Bali (left)
        {Vector3.new(0, 0.6, 30), Vector3.new(60, 0.3, 6)},    -- Kampus → Papua
    }
    for i, pdata in ipairs(paths) do
        local path = Instance.new("Part")
        path.Name = "Path" .. i
        path.Size = pdata[2]
        path.Position = pdata[1]
        path.Anchored = true
        path.Color = Color3.fromRGB(180, 160, 120)
        path.Material = Enum.Material.Cobblestone
        path.Parent = workspace
    end

    -- ==========================================
    -- KAMPUS AREA (spawn)
    -- ==========================================
    -- Main building
    buildHouse(workspace, Vector3.new(0, 0, -15), 20, 10, 14,
        Color3.fromRGB(200, 190, 170), Color3.fromRGB(150, 60, 30), "Gedung_Kampus")

    -- Welcome sign
    local sign = Instance.new("Part")
    sign.Name = "WelcomeSign"
    sign.Size = Vector3.new(14, 3, 0.5)
    sign.Position = Vector3.new(0, 8, 0)
    sign.Anchored = true
    sign.Color = Color3.fromRGB(60, 40, 20)
    sign.Material = Enum.Material.Wood
    sign.Parent = workspace

    local signGui = Instance.new("SurfaceGui")
    signGui.Face = Enum.NormalId.Front
    signGui.Parent = sign
    local signTxt = Instance.new("TextLabel")
    signTxt.Size = UDim2.new(1, 0, 1, 0)
    signTxt.BackgroundTransparency = 1
    signTxt.Text = "🇮🇩 JEJAK NUSANTARA 🇮🇩\nPetualangan Budaya Indonesia"
    signTxt.TextColor3 = Color3.fromRGB(255, 248, 230)
    signTxt.TextScaled = true
    signTxt.Font = Enum.Font.GothamBold
    signTxt.Parent = signGui

    -- Spawn
    local spawn = Instance.new("SpawnLocation")
    spawn.Name = "SpawnPoint"
    spawn.Size = Vector3.new(10, 1, 10)
    spawn.Position = Vector3.new(0, 1, 8)
    spawn.Anchored = true
    spawn.Color = Color3.fromRGB(218, 165, 32)
    spawn.Material = Enum.Material.Neon
    spawn.Transparency = 0.3
    spawn.Parent = workspace

    -- Kampus trees
    for _, tpos in ipairs({
        Vector3.new(-25, 0, -25), Vector3.new(25, 0, -25),
        Vector3.new(-25, 0, 25), Vector3.new(25, 0, 25),
    }) do buildTree(workspace, tpos, 10) end

    -- ==========================================
    -- JAWA AREA (Rumah Joglo + Gamelan)
    -- ==========================================
    -- Rumah Joglo (traditional Javanese house)
    buildHouse(workspace, Vector3.new(-130, 0, -140), 18, 10, 14,
        Color3.fromRGB(160, 120, 60), Color3.fromRGB(100, 50, 20), "Rumah_Joglo")

    -- Pendopo (open pavilion)
    buildHouse(workspace, Vector3.new(-110, 0, -120), 14, 8, 14,
        Color3.fromRGB(180, 140, 80), Color3.fromRGB(120, 60, 25), "Pendopo")

    -- Gamelan stage
    local stage = Instance.new("Part")
    stage.Name = "GamelanStage"
    stage.Size = Vector3.new(16, 1, 10)
    stage.Position = Vector3.new(-100, 0.5, -100)
    stage.Anchored = true
    stage.Color = Color3.fromRGB(140, 90, 40)
    stage.Material = Enum.Material.Wood
    stage.Parent = workspace

    -- Sawah (rice field - green flat)
    local sawah = Instance.new("Part")
    sawah.Name = "Sawah"
    sawah.Size = Vector3.new(30, 0.3, 20)
    sawah.Position = Vector3.new(-140, 0.15, -100)
    sawah.Anchored = true
    sawah.Color = Color3.fromRGB(100, 180, 60)
    sawah.Material = Enum.Material.Grass
    sawah.Parent = workspace

    -- Jawa trees (bamboo-like)
    for _, tpos in ipairs({
        Vector3.new(-150, 0, -150), Vector3.new(-90, 0, -150),
        Vector3.new(-150, 0, -90), Vector3.new(-90, 0, -90),
        Vector3.new(-140, 0, -130), Vector3.new(-100, 0, -140),
    }) do buildTree(workspace, tpos, 12) end

    -- Jawa water
    buildWater(workspace, Vector3.new(-100, 0.15, -140), Vector3.new(15, 0.3, 15))

    -- ==========================================
    -- SUMATRA AREA (Rumah Gadang + Market)
    -- ==========================================
    -- Rumah Gadang (Minangkabau house with horn-like roof)
    buildHouse(workspace, Vector3.new(130, 0, -140), 20, 10, 14,
        Color3.fromRGB(170, 130, 70), Color3.fromRGB(180, 50, 30), "Rumah_Gadang")

    -- Additional house
    buildHouse(workspace, Vector3.new(110, 0, -120), 12, 8, 10,
        Color3.fromRGB(150, 110, 60), Color3.fromRGB(160, 60, 30), "Rumah_Minang")

    -- Market stalls
    buildStall(workspace, Vector3.new(140, 0, -100), Color3.fromRGB(200, 80, 30), "Kios_Rendang")
    buildStall(workspace, Vector3.new(140, 0, -115), Color3.fromRGB(30, 150, 200), "Kios_Batik")

    -- Sumatra trees
    for _, tpos in ipairs({
        Vector3.new(100, 0, -150), Vector3.new(150, 0, -150),
        Vector3.new(100, 0, -90), Vector3.new(150, 0, -90),
    }) do buildTree(workspace, tpos, 11) end

    -- ==========================================
    -- BALI AREA (Pura + Sanggar)
    -- ==========================================
    -- Pura (temple)
    buildTemple(workspace, Vector3.new(-120, 0, 110), 14)

    -- Sanggar tari (dance studio)
    buildHouse(workspace, Vector3.new(-100, 0, 140), 16, 10, 12,
        Color3.fromRGB(200, 180, 140), Color3.fromRGB(100, 40, 20), "Sanggar_Tari")

    -- Bale (open pavilion)
    buildHouse(workspace, Vector3.new(-140, 0, 130), 10, 7, 10,
        Color3.fromRGB(190, 170, 130), Color3.fromRGB(80, 35, 15), "Bale_Bali")

    -- Bali water garden
    buildWater(workspace, Vector3.new(-130, 0.15, 150), Vector3.new(18, 0.3, 12))

    -- Bali trees
    for _, tpos in ipairs({
        Vector3.new(-150, 0, 100), Vector3.new(-90, 0, 100),
        Vector3.new(-150, 0, 155), Vector3.new(-90, 0, 155),
    }) do buildTree(workspace, tpos, 9) end

    -- ==========================================
    -- PAPUA AREA (Honai + Jungle)
    -- ==========================================
    -- Honai (round traditional house - approximated with cylinder)
    local honai = Instance.new("Model")
    honai.Name = "Honai"

    local honaiBase = Instance.new("Part")
    honaiBase.Name = "Base"
    honaiBase.Size = Vector3.new(10, 6, 10)
    honaiBase.Position = Vector3.new(120, 3, 120)
    honaiBase.Anchored = true
    honaiBase.Color = Color3.fromRGB(120, 80, 40)
    honaiBase.Material = Enum.Material.Wood
    honaiBase.Shape = Enum.PartType.Cylinder
    honaiBase.Parent = honai

    local honaiRoof = Instance.new("Part")
    honaiRoof.Name = "Roof"
    honaiRoof.Size = Vector3.new(12, 3, 12)
    honaiRoof.Position = Vector3.new(120, 7.5, 120)
    honaiRoof.Anchored = true
    honaiRoof.Color = Color3.fromRGB(80, 60, 30)
    honaiRoof.Material = Enum.Material.Slate
    honaiRoof.Shape = Enum.PartType.Cylinder
    honaiRoof.Parent = honai

    honai.Parent = workspace

    -- Second honai
    local honai2 = Instance.new("Model")
    honai2.Name = "Honai2"

    local h2Base = Instance.new("Part")
    h2Base.Name = "Base"
    h2Base.Size = Vector3.new(8, 5, 8)
    h2Base.Position = Vector3.new(140, 2.5, 130)
    h2Base.Anchored = true
    h2Base.Color = Color3.fromRGB(100, 70, 35)
    h2Base.Material = Enum.Material.Wood
    h2Base.Shape = Enum.PartType.Cylinder
    h2Base.Parent = honai2

    local h2Roof = Instance.new("Part")
    h2Roof.Name = "Roof"
    h2Roof.Size = Vector3.new(10, 2.5, 10)
    h2Roof.Position = Vector3.new(140, 6.25, 130)
    h2Roof.Anchored = true
    h2Roof.Color = Color3.fromRGB(70, 50, 25)
    h2Roof.Material = Enum.Material.Slate
    h2Roof.Shape = Enum.PartType.Cylinder
    h2Roof.Parent = honai2

    honai2.Parent = workspace

    -- Papua dense jungle (more trees)
    for _, tpos in ipairs({
        Vector3.new(100, 0, 100), Vector3.new(150, 0, 100),
        Vector3.new(100, 0, 150), Vector3.new(150, 0, 150),
        Vector3.new(110, 0, 130), Vector3.new(140, 0, 110),
        Vector3.new(130, 0, 145), Vector3.new(105, 0, 115),
    }) do buildTree(workspace, tpos, 14) end

    -- Papua pond
    buildWater(workspace, Vector3.new(140, 0.15, 110), Vector3.new(12, 0.3, 12))

    -- ==========================================
    -- PORTALS (with visible gate frames)
    -- ==========================================
    buildPortalFrame(workspace, Vector3.new(-80, 0, -80), Color3.fromRGB(255, 215, 0))
    createPortal("PortalJawa", Vector3.new(-80, 7, -80), Vector3.new(-120, 2, -120),
        Color3.fromRGB(255, 215, 0), "🟡 Wilayah Jawa", "quiz_jawa")

    buildPortalFrame(workspace, Vector3.new(80, 0, -80), Color3.fromRGB(0, 200, 0))
    createPortal("PortalSumatra", Vector3.new(80, 7, -80), Vector3.new(120, 2, -120),
        Color3.fromRGB(0, 200, 0), "🟢 Wilayah Sumatra", "quiz_sumatra")

    buildPortalFrame(workspace, Vector3.new(-80, 0, 80), Color3.fromRGB(0, 150, 255))
    createPortal("PortalBali", Vector3.new(-80, 7, 80), Vector3.new(-120, 2, 120),
        Color3.fromRGB(0, 150, 255), "🔵 Wilayah Bali", "quiz_bali")

    buildPortalFrame(workspace, Vector3.new(80, 0, 80), Color3.fromRGB(150, 0, 200))
    createPortal("PortalPapua", Vector3.new(80, 7, 80), Vector3.new(120, 2, 120),
        Color3.fromRGB(150, 0, 200), "🟣 Wilayah Papua", "quiz_papua")

    -- ==========================================
    -- NPCs
    -- ==========================================
    createNPC("Pak Dosen", Vector3.new(0, 2, 5), "Dosen",
        Color3.fromRGB(200, 150, 100), Color3.fromRGB(50, 50, 150))
    createNPC("Pak Karso", Vector3.new(-120, 2, -130), "Karso",
        Color3.fromRGB(200, 150, 100), Color3.fromRGB(200, 50, 50))
    createNPC("Ibu Ratna", Vector3.new(120, 2, -130), "Ratna",
        Color3.fromRGB(200, 150, 100), Color3.fromRGB(200, 100, 150))
    createNPC("Mang Wayan", Vector3.new(-110, 2, 130), "Wayan",
        Color3.fromRGB(200, 150, 100), Color3.fromRGB(255, 200, 100))
    createNPC("Bapak Yanu", Vector3.new(130, 2, 130), "Yanu",
        Color3.fromRGB(200, 150, 100), Color3.fromRGB(100, 50, 0))

    -- ==========================================
    -- REGION LABELS
    -- ==========================================
    addLabel("🏫 KAMPUS (Spawn)", Vector3.new(0, 12, 0))
    addLabel("🟡 Wilayah Jawa", Vector3.new(-120, 12, -120))
    addLabel("🟢 Wilayah Sumatra", Vector3.new(120, 12, -120))
    addLabel("🔵 Wilayah Bali", Vector3.new(-120, 12, 120))
    addLabel("🟣 Wilayah Papua", Vector3.new(120, 12, 120))

    -- ==========================================
    -- DECORATIVE TREES (scattered around main area)
    -- ==========================================
    for _, tpos in ipairs({
        Vector3.new(-40, 0, -40), Vector3.new(40, 0, -40),
        Vector3.new(-40, 0, 40), Vector3.new(40, 0, 40),
        Vector3.new(-60, 0, 0), Vector3.new(60, 0, 0),
        Vector3.new(0, 0, -60), Vector3.new(0, 0, 60),
    }) do buildTree(workspace, tpos, 10) end

    print("✅ World created!")
end

-- ============================================
-- DIALOGUE HANDLER (Bug #3 fix: proper state machine)
-- ============================================
RS.DialogueChoice.OnServerEvent:Connect(function(player, choiceIndex)
    local dialogueId = playerActiveNPC[player.UserId]
    if not dialogueId then
        warn("[Dialogue] No active NPC for " .. player.Name)
        return
    end

    local dialogue = DIALOGUES[dialogueId]
    if not dialogue then
        warn("[Dialogue] No dialogue data for " .. dialogueId)
        return
    end

    local currentLine = playerDialogueLine[player.UserId] or 1
    local line = dialogue.lines[currentLine]
    if not line then
        warn("[Dialogue] No line at index " .. tostring(currentLine))
        return
    end

    local choice = line.choices[choiceIndex]
    if not choice then
        warn("[Dialogue] No choice at index " .. tostring(choiceIndex))
        return
    end

    if choice.action == "end" then
        -- End dialogue
        playerActiveNPC[player.UserId] = nil
        playerDialogueLine[player.UserId] = nil
        RS.DialogueEnd:FireClient(player)
        addJournalEntry(player, "💬 Selesai bicara dengan " .. dialogue.name)
    elseif choice.next then
        -- Navigate to next line
        playerDialogueLine[player.UserId] = choice.next
        local nextLine = dialogue.lines[choice.next]
        if nextLine then
            -- Send the next line data to the client
            -- The client will handle displaying it (recursive)
            RS.DialogueStart:FireClient(player, {
                name = dialogue.name,
                lines = dialogue.lines,
                startLine = choice.next,
            }, dialogueId)
        else
            -- Invalid next, end dialogue
            playerActiveNPC[player.UserId] = nil
            playerDialogueLine[player.UserId] = nil
            RS.DialogueEnd:FireClient(player)
        end
    end
end)

-- ============================================
-- QUIZ HANDLER (Bug #2 fix: use quizId param)
-- ============================================
RS.QuizAnswer.OnServerEvent:Connect(function(player, questionIndex, answerIndex, quizId)
    local quiz = QUIZZES[quizId]
    if not quiz then
        warn("[Quiz] Invalid quizId: " .. tostring(quizId))
        return
    end

    local question = quiz.questions[questionIndex]
    if not question then
        warn("[Quiz] Invalid question index: " .. tostring(questionIndex))
        return
    end

    local isCorrect = (answerIndex == question.correct)
    local results = {
        quizId = quizId,
        questionIndex = questionIndex,
        isCorrect = isCorrect,
        correctAnswer = question.correct,
    }

    if isCorrect then
        addXP(player, 50)
        addCoins(player, 25)
        RS.ShowNotification:FireClient(player, "✅ Jawaban Benar!")
        addJournalEntry(player, "✅ Benar: " .. question.q)
    else
        RS.ShowNotification:FireClient(player, "❌ Jawaban Salah!")
        addJournalEntry(player, "❌ Salah: " .. question.q)
    end

    -- Next question or end quiz
    if questionIndex < #quiz.questions then
        -- Bug #2 fix: send quizId with QuizStart
        RS.QuizStart:FireClient(player, quiz, quizId, questionIndex + 1)
    else
        -- Quiz completed
        local data = getPlayerData(player)
        if not data.completedQuizzes[quizId] then
            data.completedQuizzes[quizId] = true
            addXP(player, 100)
            addCoins(player, 50)
            addJournalEntry(player, "🎉 Quiz selesai: " .. quiz.title)
            unlockNextPortal(player, quizId)

            -- Check if all 4 quizzes are done -> trigger ending
            local quizCount = 0
            for _ in pairs(data.completedQuizzes) do
                quizCount = quizCount + 1
            end
            if quizCount >= 4 then
                task.delay(3, function()
                    checkAndTriggerEnding(player)
                end)
            end
        end
        RS.QuizEnd:FireClient(player, quizId, results)
    end
end)

-- ============================================
-- GAME START HANDLER
-- ============================================
RS.GameStart.OnServerEvent:Connect(function(player)
    local data = getPlayerData(player)
    data.gameStarted = true
    addJournalEntry(player, "🎮 Petualangan dimulai!")
    RS.ShowNotification:FireClient(player, "Selamat datang di Jejak Nusantara!")
    print("[GameManager] Game started for: " .. player.Name)
end)

-- ============================================
-- PLAYER LIFECYCLE
-- ============================================
Players.PlayerAdded:Connect(function(player)
    print("[GameManager] Player joined: " .. player.Name)

    -- Load saved data
    local saved = loadPlayerData(player)
    if saved then
        playerData[player.UserId] = saved
        print("[GameManager] Loaded data for: " .. player.Name)
    else
        playerData[player.UserId] = createDefaultData()
    end

    playerActiveNPC[player.UserId] = nil
    playerDialogueLine[player.UserId] = nil

    player.CharacterAdded:Connect(function(character)
        local hrp = character:WaitForChild("HumanoidRootPart")
        hrp.CFrame = CFrame.new(Vector3.new(0, 3, 0))
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    savePlayerData(player)
    playerData[player.UserId] = nil
    playerActiveNPC[player.UserId] = nil
    playerDialogueLine[player.UserId] = nil
    print("[GameManager] Player leaving: " .. player.Name)
end)

-- Auto-save every 60 seconds
task.spawn(function()
    while true do
        task.wait(60)
        for _, player in ipairs(Players:GetPlayers()) do
            savePlayerData(player)
        end
    end
end)

-- ============================================
-- CREATE WORLD
-- ============================================
local ok, err = pcall(createWorld)
if not ok then
    warn("⚠️ createWorld error: " .. tostring(err))
    warn("⚠️ Game will still run but world may be incomplete")
end

print("✅ All systems ready!")
print("🎮 ============================================")
print("🎮 JEJAK NUSANTARA v4.0 - READY!")
print("🎮 Click ▶ PLAY untuk mulai!")
print("🎮 ============================================")
