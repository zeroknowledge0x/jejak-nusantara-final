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
-- DATA STORE
-- ============================================
local dataStore = DataStoreService:GetDataStore("JejakNusantara_v4")

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
        return dataStore:GetAsync("player_" .. player.UserId)
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
        dataStore:SetAsync("player_" .. player.UserId, data)
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
local function createWorld()
    print("🌍 Creating world...")

    -- Ground
    local ground = Instance.new("Part")
    ground.Name = "Ground"
    ground.Size = Vector3.new(400, 1, 400)
    ground.Position = Vector3.new(0, 0.5, 0)
    ground.Anchored = true
    ground.Color = Color3.fromRGB(100, 180, 80)
    ground.Material = Enum.Material.Grass
    ground.Parent = workspace

    -- Spawn point
    local spawn = Instance.new("SpawnLocation")
    spawn.Name = "SpawnPoint"
    spawn.Size = Vector3.new(10, 1, 10)
    spawn.Position = Vector3.new(0, 1, 0)
    spawn.Anchored = true
    spawn.Color = Color3.fromRGB(200, 200, 200)
    spawn.Material = Enum.Material.SmoothPlastic
    spawn.Parent = workspace

    -- Trees
    local treePositions = {
        Vector3.new(-20, 0, -20), Vector3.new(20, 0, -20),
        Vector3.new(-20, 0, 20), Vector3.new(20, 0, 20),
        Vector3.new(-60, 0, -60), Vector3.new(60, 0, -60),
        Vector3.new(-60, 0, 60), Vector3.new(60, 0, 60),
    }

    for _, pos in ipairs(treePositions) do
        local trunk = Instance.new("Part")
        trunk.Name = "Trunk"
        trunk.Size = Vector3.new(2, 8, 2)
        trunk.Position = pos + Vector3.new(0, 4, 0)
        trunk.Anchored = true
        trunk.Color = Color3.fromRGB(139, 90, 43)
        trunk.Material = Enum.Material.Wood
        trunk.Parent = workspace

        local leaves = Instance.new("Part")
        leaves.Name = "Leaves"
        leaves.Size = Vector3.new(8, 6, 8)
        leaves.Position = pos + Vector3.new(0, 10, 0)
        leaves.Anchored = true
        leaves.Color = Color3.fromRGB(50, 150, 50)
        leaves.Material = Enum.Material.Grass
        leaves.Parent = workspace
    end

    -- NPCs
    createNPC("Pak Dosen", Vector3.new(0, 2, 0), "Dosen", Color3.fromRGB(200, 150, 100), Color3.fromRGB(50, 50, 150))
    createNPC("Pak Karso", Vector3.new(-50, 2, -50), "Karso", Color3.fromRGB(200, 150, 100), Color3.fromRGB(200, 50, 50))
    createNPC("Ibu Ratna", Vector3.new(50, 2, -50), "Ratna", Color3.fromRGB(200, 150, 100), Color3.fromRGB(200, 100, 150))
    createNPC("Mang Wayan", Vector3.new(-50, 2, 50), "Wayan", Color3.fromRGB(200, 150, 100), Color3.fromRGB(255, 200, 100))
    createNPC("Bapak Yanu", Vector3.new(50, 2, 50), "Yanu", Color3.fromRGB(200, 150, 100), Color3.fromRGB(100, 50, 0))

    -- Portals (quiz_jawa unlocked by default)
    createPortal("PortalJawa", Vector3.new(-100, 6, -100), Vector3.new(-100, 2, -100), Color3.fromRGB(255, 215, 0), "🟡 Wilayah Jawa", "quiz_jawa")
    createPortal("PortalSumatra", Vector3.new(100, 6, -100), Vector3.new(100, 2, -100), Color3.fromRGB(0, 200, 0), "🟢 Wilayah Sumatra", "quiz_sumatra")
    createPortal("PortalBali", Vector3.new(-100, 6, 100), Vector3.new(-100, 2, 100), Color3.fromRGB(0, 150, 255), "🔵 Wilayah Bali", "quiz_bali")
    createPortal("PortalPapua", Vector3.new(100, 6, 100), Vector3.new(100, 2, 100), Color3.fromRGB(150, 0, 200), "🟣 Wilayah Papua", "quiz_papua")

    -- Region labels
    local regions = {
        {name = "🏫 KAMPUS (Spawn)", pos = Vector3.new(0, 10, 0)},
        {name = "🟡 JAWA", pos = Vector3.new(-100, 10, -100)},
        {name = "🟢 SUMATRA", pos = Vector3.new(100, 10, -100)},
        {name = "🔵 BALI", pos = Vector3.new(-100, 10, 100)},
        {name = "🟣 PAPUA", pos = Vector3.new(100, 10, 100)},
    }

    for _, region in ipairs(regions) do
        local billboard = Instance.new("BillboardGui")
        billboard.Size = UDim2.new(0, 300, 0, 60)
        billboard.StudsOffset = Vector3.new(0, 0, 0)
        billboard.Parent = workspace

        local part = Instance.new("Part")
        part.Name = "Label_" .. region.name
        part.Size = Vector3.new(1, 1, 1)
        part.Position = region.pos
        part.Anchored = true
        part.CanCollide = false
        part.Transparency = 1
        part.Parent = workspace
        billboard.Adornee = part

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 1, 0)
        lbl.BackgroundTransparency = 0.5
        lbl.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
        lbl.Text = region.name
        lbl.TextScaled = true
        lbl.Font = Enum.Font.GothamBold
        lbl.Parent = billboard
    end

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
createWorld()

print("✅ All systems ready!")
print("🎮 ============================================")
print("🎮 JEJAK NUSANTARA v4.0 - READY!")
print("🎮 Click ▶ PLAY untuk mulai!")
print("🎮 ============================================")
