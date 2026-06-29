--[[
	Jejak Nusantara Final — GameServer.lua
	Server-side logic: game state, player data, mechanics, cultural insight, endings.
	Mata kuliah: Pengembangan Game (MBKP-07.03.310)
	Team: Daffa Rifqi A.F (PM), Mahda Vidho Pratama, Sakti Hermawan, Rakha Andrianto Q.A
]]

---------------------------------------------------------------------
-- Services
---------------------------------------------------------------------
local Players            = game:GetService("Players")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local DataStoreService   = game:GetService("DataStoreService")
local ServerStorage      = game:GetService("ServerStorage")

---------------------------------------------------------------------
-- Remotes  (created once, reused everywhere)
---------------------------------------------------------------------
local Remotes = ReplicatedStorage:FindFirstChild("JN_Remotes")
if not Remotes then
	Remotes = Instance.new("Folder")
	Remotes.Name = "JN_Remotes"
	Remotes.Parent = ReplicatedStorage
end

local function getOrCreate(name, className)
	local obj = Remotes:FindFirstChild(name)
	if not obj then
		obj = Instance.new(className)
		obj.Name = name
		obj.Parent = Remotes
	end
	return obj
end

-- RemoteEvents
local RE_PlayerAction     = getOrCreate("PlayerAction",     "RemoteEvent")  -- client → server action
local RE_UpdateUI         = getOrCreate("UpdateUI",         "RemoteEvent")  -- server → client UI push
local RE_DialogueEvent    = getOrCreate("DialogueEvent",    "RemoteEvent")  -- dialogue choice
local RE_MiniGameResult   = getOrCreate("MiniGameResult",   "RemoteEvent")  -- mini game outcome
local RE_CulturalInsight  = getOrCreate("CulturalInsight",  "RemoteEvent")  -- insight unlocked
local RE_TriggerEnding    = getOrCreate("TriggerEnding",    "RemoteEvent")  -- ending screen
local RE_LevelTransition  = getOrCreate("LevelTransition",  "RemoteEvent")  -- level change
local RE_JournalUpdate    = getOrCreate("JournalUpdate",    "RemoteEvent")  -- journal entry

-- RemoteFunctions
local RF_GetPlayerData    = getOrCreate("GetPlayerData",    "RemoteFunction")

---------------------------------------------------------------------
-- Constants
---------------------------------------------------------------------
local SAVE_KEY_PREFIX = "JN_Player_v1_"

local LEVEL_ORDER = {
	"Desa_Budaya",
	"Sanggar_Seni",
	"Pasar_Tradisional",
	"Tempat_Bersejarah",
}

local LEVEL_DISPLAY = {
	Desa_Budaya        = "Desa Budaya — Jawa Barat",
	Sanggar_Seni       = "Sanggar Seni Tradisional",
	Pasar_Tradisional  = "Pasar Tradisional Nusantara",
	Tempat_Bersejarah  = "Tempat Bersejarah Indonesia",
}

---------------------------------------------------------------------
-- Player Skills
---------------------------------------------------------------------
local SkillDefinition = {
	Observation          = { label = "Observasi",            desc = "Fokus & perhatian detail" },
	Communication        = { label = "Komunikasi",           desc = "Interaksi sosial" },
	CulturalUnderstanding= { label = "Pemahaman Budaya",     desc = "Pengetahuan budaya" },
	ProblemSolving       = { label = "Pemecahan Masalah",    desc = "Logika & pemecahan masalah" },
	DecisionMaking       = { label = "Pengambilan Keputusan", desc = "Konsekuensi & refleksi" },
}

---------------------------------------------------------------------
-- Cultural Insight Catalogue
---------------------------------------------------------------------
local CulturalInsights = {
	-- Level 1 — Desa Budaya
	angklung_sejarah   = { level = "Desa_Budaya",        title = "Sejarah Angklung",           text = "Angklung alat musik bambu dari Jawa Barat, diakui UNESCO 2010.", points = 15 },
	gamelan_peran      = { level = "Desa_Budaya",        title = "Peran Gamelan",              text = "Gamelan mengiringi upacara adat dan pertunjukan wayang.",       points = 10 },
	wayang_cerita      = { level = "Desa_Budaya",        title = "Cerita Wayang",              text = "Wayang kulit menyampaikan nilai moral lewat Mahabharata.",      points = 10 },
	-- Level 2 — Sanggar Seni
	tari_topeng        = { level = "Sanggar_Seni",       title = "Tari Topeng Cirebon",        text = "Tari Topeng Cirebon menggambarkan tokoh Panji.",               points = 15 },
	batik_proses       = { level = "Sanggar_Seni",       title = "Proses Membatik",            text = "Batik Indonesia diakui UNESCO sebagai warisan budaya.",         points = 10 },
	kain_tenun         = { level = "Sanggar_Seni",       title = "Kain Tenun Nusantara",       text = "Setiap daerah punya motif tenun khas.",                         points = 10 },
	-- Level 3 — Pasar Tradisional
	rempah_nusantara   = { level = "Pasar_Tradisional",  title = "Rempah Nusantara",           text = "Indonesia pusat rempah dunia sejak abad ke-15.",                points = 15 },
	kuliner_daerah     = { level = "Pasar_Tradisional",  title = "Kuliner Khas Daerah",        text = "Setiap daerah punya kuliner khas yang mencerminkan budaya.",   points = 10 },
	ekonomi_tradisional= { level = "Pasar_Tradisional",  title = "Ekonomi Pasar Tradisional",  text = "Pasar tradisional pusat ekonomi & interaksi sosial.",           points = 10 },
	-- Level 4 — Tempat Bersejarah
	candi_borobudur    = { level = "Tempat_Bersejarah",  title = "Candi Borobudur",            text = "Candi Buddha terbesar di dunia, abad ke-9.",                    points = 20 },
	candi_prambanan    = { level = "Tempat_Bersejarah",  title = "Candi Prambanan",            text = "Candi Hindu terbesar di Indonesia, warisan dinasti Sanjaya.",   points = 15 },
	sejarah_kemerdekaan= { level = "Tempat_Bersejarah",  title = "Sejarah Kemerdekaan",        text = "Proklamasi 17 Agustus 1945 menandai kemerdekaan Indonesia.",   points = 15 },
	simbol_kuno        = { level = "Tempat_Bersejarah",  title = "Simbol Kuno Tersembunyi",    text = "Relief candi menyimpan simbol kosmologi Hindu-Buddha.",        points = 20 },
}

---------------------------------------------------------------------
-- NPC Definitions
---------------------------------------------------------------------
local NPCDefinitions = {
	-- Level 1
	NPC_Sesepuh    = { level = "Desa_Budaya",       name = "Sesepuh Desa",         role = "mentor",    dialogue_key = "sesepuh_intro" },
	NPC_Pengrajin  = { level = "Desa_Budaya",       name = "Pengrajin Angklung",   role = "artisan",   dialogue_key = "pengrajin_angklung" },
	NPC_Warga1     = { level = "Desa_Budaya",       name = "Warga Desa",           role = "informant", dialogue_key = "warga_desa" },
	-- Level 2
	NPC_Penari     = { level = "Sanggar_Seni",      name = "Penari Tradisional",   role = "mentor",    dialogue_key = "penari_intro" },
	NPC_Pembatik   = { level = "Sanggar_Seni",      name = "Pembatik",             role = "artisan",   dialogue_key = "pembatik_intro" },
	NPC_Seniman    = { level = "Sanggar_Seni",      name = "Seniman Lokal",        role = "informant", dialogue_key = "seniman_lokal" },
	-- Level 3
	NPC_Pedagang   = { level = "Pasar_Tradisional", name = "Pedagang Pasar",       role = "merchant",  dialogue_key = "pedagang_intro" },
	NPC_JuruMasak  = { level = "Pasar_Tradisional", name = "Juru Masak Tradisional",role = "informant", dialogue_key = "jurumasak_intro" },
	NPC_PedagangTua= { level = "Pasar_Tradisional", name = "Pedagang Tua Misterius",role = "secret",    dialogue_key = "pedagang_tua" },
	-- Level 4
	NPC_Pemandu    = { level = "Tempat_Bersejarah", name = "Pemandu Sejarah",      role = "mentor",    dialogue_key = "pemandu_intro" },
	NPC_Arkeolog   = { level = "Tempat_Bersejarah", name = "Arkeolog",             role = "informant", dialogue_key = "arkeolog_intro" },
	NPC_Dosen      = { level = "All",               name = "Dosen (Pak Nahar)",    role = "questgiver",dialogue_key = "dosen_quest" },
}

---------------------------------------------------------------------
-- Dialogue Tree
--  key → { { text, next?, skill?, points? }, ... }
---------------------------------------------------------------------
local DialogueTree = {
	sesepuh_intro = {
		{ text = "Selamat datang, anak muda. Apa yang ingin kau pelajari?",
		  choices = {
			{ label = "Ceritakan tentang desa ini",       next = "sesepuh_desa",       skill = "Communication", pts = 5 },
			{ label = "Saya ingin belajar angklung",       next = "sesepuh_angklung",   skill = "CulturalUnderstanding", pts = 5 },
			{ label = "Apa saja yang bisa saya amati?",   next = "sesepuh_observasi",  skill = "Observation", pts = 5 },
		}},
	},
	sesepuh_desa = {
		{ text = "Desa ini adalah warisan budaya Sunda. Setiap rumah menyimpan cerita. Jelajahilah!", unlock_insight = "gamelan_peran" },
	},
	sesepuh_angklung = {
		{ text = "Angklung adalah jiwa Jawa Barat. Mainkanlah dengan hati. Pergilah ke sanggar pengrajin.", next = "pengrajin_angklung" },
	},
	sesepuh_observasi = {
		{ text = "Amati simbol-simbol di rumah adat. Setiap ukiran punya makna. Tingkatkanlah observasimu!", unlock_insight = "wayang_cerita" },
	},
	pengrajin_angklung = {
		{ text = "Kau ingin belajar angklung? Ikuti nadaku. Jika kau benar, kau akan merasakan harmoni.",
		  choices = {
			{ label = "Saya siap!",  next = "angklung_challenge", start_minigame = "Angklung" },
			{ label = "Ceritakan dulu sejarahnya", next = "pengrajin_sejarah", skill = "CulturalUnderstanding", pts = 5 },
		}},
	},
	pengrajin_sejarah = {
		{ text = "Angklung terbuat dari bambu. UNESCO mengakuinya pada 2010. Sekarang, coba mainkan!", unlock_insight = "angklung_sejarah", next = "angklung_challenge" },
	},
	angklung_challenge = {
		{ text = "Ikuti ritmenya... Dengarkan dan mainkan!", start_minigame = "Angklung" },
	},
	warga_desa = {
		{ text = "Di desa ini, kami menjaga tradisi leluhur. Setiap hari ada upacara kecil.",
		  choices = {
			{ label = "Bolehkah saya ikut?",    next = "warga_ikut",   skill = "Communication", pts = 5 },
			{ label = "Apa tradisi terpenting?", next = "warga_tradisi", skill = "CulturalUnderstanding", pts = 5 },
		}},
	},
	warga_ikut = {
		{ text = "Tentu! Besok pagi ada upacara di balai desa. Kau akan belajar banyak.", journal = "Diundang upacara desa oleh warga." },
	},
	warga_tradisi = {
		{ text = "Gotong royong dan musyawarah. Itu dasar kehidupan kami.", unlock_insight = "gamelan_peran" },
	},

	-- Level 2
	penari_intro = {
		{ text = "Tari tradisional bukan sekadar gerak, tapi cerita. Kau mau belajar?",
		  choices = {
			{ label = "Ya, ajari saya!", next = "tari_challenge", start_minigame = "Tari" },
			{ label = "Ceritakan makna tarinya", next = "penari_makna", skill = "CulturalUnderstanding", pts = 5 },
		}},
	},
	penari_makna = {
		{ text = "Tari Topeng Cirebon mengisahkan cerita Panji. Setiap topeng punya karakter berbeda.", unlock_insight = "tari_topeng" },
	},
	tari_challenge = {
		{ text = "Ikuti gerakanku. Ritme adalah kuncinya!", start_minigame = "Tari" },
	},
	pembatik_intro = {
		{ text = "Membatik membutuhkan kesabaran. Setiap titik lilin bermakna.",
		  choices = {
			{ label = "Saya ingin mencoba", next = "batik_info", skill = "ProblemSolving", pts = 5 },
			{ label = "Ceritakan motifnya", next = "batik_motif", unlock_insight = "batik_proses" },
		}},
	},
	batik_info = {
		{ text = "Batik Indonesia diakui UNESCO. Cobalah membatik di sanggar ini.", journal = "Belajar membatik di sanggar seni." },
	},
	batik_motif = {
		{ text = "Setiap motif punya filosofi. Kawaton untuk bangsawan, mega mendung untuk kerendahan hati.", unlock_insight = "batik_proses" },
	},
	seniman_lokal = {
		{ text = "Saya seniman tenun. Kain tenun Nusantara punya motif berbeda di setiap daerah.", unlock_insight = "kain_tenun" },
	},

	-- Level 3
	pedagang_intro = {
		{ text = "Selamat datang di pasar! Mau belanja? Kita bisa tawar-menawar.",
		  choices = {
			{ label = "Ya, saya mau beli!", next = "tawar_challenge", start_minigame = "TawarMenawar" },
			{ label = "Ceritakan tentang pasar ini", next = "pedagang_cerita", skill = "Communication", pts = 5 },
		}},
	},
	pedagang_cerita = {
		{ text = "Pasar ini sudah ada sejak zaman kolonial. Pusat ekonomi rakyat.", unlock_insight = "ekonomi_tradisional" },
	},
	tawar_challenge = {
		{ text = "Baiklah, berani tawar? Jangan terlalu murah ya!", start_minigame = "TawarMenawar" },
	},
	jurumasak_intro = {
		{ text = "Kuliner Indonesia kaya rempah. Mau tahu rahasia bumbu?",
		  choices = {
			{ label = "Ya, ajari saya!", next = "masak_info", unlock_insight = "rempah_nusantara" },
			{ label = "Apa makanan khas sini?", next = "masak_khas", unlock_insight = "kuliner_daerah" },
		}},
	},
	masak_info = {
		{ text = "Rempah Nusantara terkenal dunia. Cengkih, pala, lada — inilah harta kami.", unlock_insight = "rempah_nusantara" },
	},
	masak_khas = {
		{ text = "Setiap daerah punya kuliner khas. Rendang dari Padang, Gudeg dari Jogja.", unlock_insight = "kuliner_daerah" },
	},
	pedagang_tua = {
		{ text = "Kau menemukan saya... Bagus. Aku punya cerita yang tidak ada di buku. Tapi kau harus buktikan dulu kepekaanmu.",
		  choices = {
			{ label = "Saya siap mendengar", next = "tua_rahasia", skill = "Observation", pts = 10, require_insight = "ekonomi_tradisional" },
			{ label = "Saya belum siap", next = "tua_nolak" },
		}},
	},
	tua_rahasia = {
		{ text = "Pasar ini menyimpan lorong bawah tanah dari era perdagangan rempah. Simpan rahasia ini baik-baik.", journal = "Menemukan rahasia pasar dari pedagang tua.", unlock_insight = "rempah_nusantara" },
	},
	tua_nolak = {
		{ text = "Kembalilah saat kau sudah lebih menghargai budaya pasar ini." },
	},

	-- Level 4
	pemandu_intro = {
		{ text = "Selamat datang di situs bersejarah. Ada banyak cerita di balik batu-batu ini.",
		  choices = {
			{ label = "Ceritakan tentang candi", next = "pemandu_candi", skill = "CulturalUnderstanding", pts = 5 },
			{ label = "Saya ingin mengamati", next = "pemandu_amati", skill = "Observation", pts = 5 },
		}},
	},
	pemandu_candi = {
		{ text = "Candi Borobudur dibangun abad ke-9. Reliefnya menceritakan perjalanan menuju pencerahan.", unlock_insight = "candi_borobudur" },
	},
	pemandu_amati = {
		{ text = "Perhatikan relief di dinding. Setiap panel punya cerita. Amati dengan saksama!", unlock_insight = "simbol_kuno" },
	},
	arkeolog_intro = {
		{ text = "Saya meneliti simbol kuno di candi ini. Ada puzzle yang belum terpecahkan.",
		  choices = {
			{ label = "Saya ingin membantu!", next = "puzzle_challenge", start_minigame = "PuzzleSejarah" },
			{ label = "Ceritakan temuan Anda", next = "arkeolog_temuan", unlock_insight = "candi_prambanan" },
		}},
	},
	arkeolog_temuan = {
		{ text = "Prambanan menceritakan Ramayana dalam reliefnya. Setiap candi punya makna kosmologis.", unlock_insight = "candi_prambanan" },
	},
	puzzle_challenge = {
		{ text = "Susun pecahan relief ini. Jika benar, kau akan menemukan simbol kuno!", start_minigame = "PuzzleSejarah" },
	},
	dosen_quest = {
		{ text = "Tugasmu: jelajahi budaya Indonesia dari desa hingga tempat bersejarah. Catat semua temuanmu!",
		  choices = {
			{ label = "Siap, Pak!", quest_start = true },
			{ label = "Apa yang harus saya cari?", next = "dosen_detail" },
		}},
	},
	dosen_detail = {
		{ text = "Carilah pengetahuan budaya di setiap tempat. Bicaralah dengan warga. Mainkan mini game. Catat di jurnalmu!" },
	},
}

---------------------------------------------------------------------
-- Mini Game Definitions
---------------------------------------------------------------------
local MiniGameConfig = {
	Angklung = {
		level     = "Desa_Budaya",
		title     = "Bermain Angklung",
		desc      = "Ikuti nada yang dimainkan pengrajin",
		threshold = 0.6,   -- 60% akurasi untuk lulus
		skill     = "ProblemSolving",
		reward    = { insight = "angklung_sejarah", skill_pts = { ProblemSolving = 10, CulturalUnderstanding = 5 } },
		fail_text = "Nada belum tepat. Coba lagi!",
		pass_text = "Harmoni angklung mengalun indah! Kau memahami jiwanya.",
	},
	Tari = {
		level     = "Sanggar_Seni",
		title     = "Ritme Tari Tradisional",
		desc      = "Ikuti gerakan tari dengan ritme yang tepat",
		threshold = 0.6,
		skill     = "ProblemSolving",
		reward    = { insight = "tari_topeng", skill_pts = { ProblemSolving = 10, CulturalUnderstanding = 5 } },
		fail_text = "Gerakan kurang sinkron. Latihan lagi!",
		pass_text = "Gerakanmu indah! Kau mengerti cerita di balik tarian.",
	},
	TawarMenawar = {
		level     = "Pasar_Tradisional",
		title     = "Tawar-menawar",
		desc      = "Negosiasi harga dengan pedagang",
		threshold = 0.5,
		skill     = "Communication",
		reward    = { insight = "ekonomi_tradisional", skill_pts = { Communication = 10, DecisionMaking = 5 } },
		fail_text = "Pedagang tidak mau. Coba tawar dengan cara lain!",
		pass_text = "Deal! Kau mendapat harga bagus dan kepercayaan pedagang.",
	},
	PuzzleSejarah = {
		level     = "Tempat_Bersejarah",
		title     = "Puzzle Sejarah",
		desc      = "Susun pecahan relief untuk mengungkap simbol kuno",
		threshold = 0.7,
		skill     = "ProblemSolving",
		reward    = { insight = "simbol_kuno", skill_pts = { ProblemSolving = 15, Observation = 10 } },
		fail_text = "Pecahan belum cocok. Perhatikan lebih teliti!",
		pass_text = "Simbol kuno terungkap! Kau menemukan rahasia candi.",
	},
}

---------------------------------------------------------------------
-- Endings
---------------------------------------------------------------------
local Endings = {
	Budayawan = {
		id    = "Budayawan",
		title = "Budayawan Nusantara",
		desc  = "Kau telah memahami budaya Indonesia secara mendalam. Pengetahuanmu menjadi warisan.",
		require_insights = 9,   -- >= 9 cultural insights
		require_skills_avg = 40,
	},
	Penjelajah = {
		id    = "Penjelajah",
		title = "Penjelajah Budaya",
		desc  = "Kau menjelajahi banyak tempat dan bertemu banyak orang. Perjalananmu baru dimulai.",
		require_insights = 5,
		require_skills_avg = 25,
	},
	Pemula = {
		id    = "Pemula",
		title = "Langkah Awal",
		desc  = "Perjalanan budayamu baru dimulai. Masih banyak yang harus dipelajari.",
		require_insights = 0,
		require_skills_avg = 0,
	},
}

---------------------------------------------------------------------
-- DataStore
---------------------------------------------------------------------
local PlayerStore = DataStoreService:GetDataStore("JN_PlayerData_v1")

---------------------------------------------------------------------
-- Player Data Template
---------------------------------------------------------------------
local function newPlayerData()
	local skills = {}
	for key in pairs(SkillDefinition) do
		skills[key] = 0
	end

	return {
		currentLevel   = 1,
		levelName      = LEVEL_ORDER[1],
		levelsUnlocked = { true, false, false, false },
		levelCompleted = { false, false, false, false },

		skills         = skills,
		culturalPoints = 0,
		insights       = {},   -- key → true
		journal        = {},   -- ordered list of strings

		dialogueState  = {},   -- tracks which dialogues have been seen
		miniGames      = {},   -- game_key → { best_score, attempts, passed }
		choices        = {},   -- records of player decisions

		endingReached  = nil,  -- ending id or nil
		playTime       = 0,
		sessionStart   = 0,
	}
end

---------------------------------------------------------------------
-- Runtime state (in-memory per server)
---------------------------------------------------------------------
local PlayerDataCache = {}  -- Player → data table

---------------------------------------------------------------------
-- Persistence
---------------------------------------------------------------------
local function loadPlayerData(player)
	local key = SAVE_KEY_PREFIX .. tostring(player.UserId)
	local ok, raw = pcall(function()
		return PlayerStore:GetAsync(key)
	end)
	if ok and type(raw) == "table" then
		-- Merge with template to fill new fields added in updates
		local template = newPlayerData()
		for k, v in pairs(template) do
			if raw[k] == nil then
				raw[k] = v
			end
		end
		-- Ensure all skill keys exist
		for k in pairs(SkillDefinition) do
			if raw.skills[k] == nil then
				raw.skills[k] = 0
			end
		end
		return raw
	end
	return newPlayerData()
end

local function savePlayerData(player)
	local data = PlayerDataCache[player]
	if not data then return end
	local key = SAVE_KEY_PREFIX .. tostring(player.UserId)
	-- Update playtime before save
	if data.sessionStart > 0 then
		data.playTime = data.playTime + (os.time() - data.sessionStart)
		data.sessionStart = os.time()
	end
	pcall(function()
		PlayerStore:SetAsync(key, data)
	end)
end

---------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------
local function getPlayerData(player)
	return PlayerDataCache[player]
end

local function addSkillPoint(data, skill, amount)
	if not SkillDefinition[skill] then return end
	data.skills[skill] = (data.skills[skill] or 0) + amount
end

local function getSkillsAverage(data)
	local total, count = 0, 0
	for _, v in pairs(data.skills) do
		total = total + v
		count = count + 1
	end
	return count > 0 and (total / count) or 0
end

local function countInsights(data)
	local n = 0
	for _ in pairs(data.insights) do
		n = n + 1
	end
	return n
end

local function unlockInsight(player, data, insightKey)
	if data.insights[insightKey] then return false end -- already have it
	local insight = CulturalInsights[insightKey]
	if not insight then return false end

	data.insights[insightKey] = true
	data.culturalPoints = data.culturalPoints + insight.points

	RE_CulturalInsight:FireClient(player, {
		key   = insightKey,
		title = insight.title,
		text  = insight.text,
		points= insight.points,
		total = data.culturalPoints,
	})

	RE_UpdateUI:FireClient(player, {
		type  = "cultural_points",
		value = data.culturalPoints,
	})

	return true
end

local function addJournalEntry(player, data, entry)
	table.insert(data.journal, {
		text = entry,
		time = os.time(),
		level = data.levelName,
	})
	RE_JournalUpdate:FireClient(player, entry)
end

local function unlockNextLevel(player, data)
	local nextIdx = data.currentLevel + 1
	if nextIdx <= #LEVEL_ORDER then
		data.levelsUnlocked[nextIdx] = true
		RE_UpdateUI:FireClient(player, {
			type  = "level_unlocked",
			level = nextIdx,
			name  = LEVEL_DISPLAY[LEVEL_ORDER[nextIdx]],
		})
	end
end

local function transitionToLevel(player, data, levelIdx)
	if levelIdx < 1 or levelIdx > #LEVEL_ORDER then return end
	if not data.levelsUnlocked[levelIdx] then return end

	data.currentLevel = levelIdx
	data.levelName = LEVEL_ORDER[levelIdx]

	RE_LevelTransition:FireClient(player, {
		level = levelIdx,
		name  = LEVEL_DISPLAY[data.levelName],
	})
end

---------------------------------------------------------------------
-- Ending Resolution
---------------------------------------------------------------------
local function checkAndTriggerEnding(player, data)
	if data.endingReached then return end

	local insightCount = countInsights(data)
	local avgSkills    = getSkillsAverage(data)

	-- Determine best eligible ending
	local chosen = Endings.Pemula
	if insightCount >= Endings.Budayawan.require_insights and avgSkills >= Endings.Budayawan.require_skills_avg then
		chosen = Endings.Budayawan
	elseif insightCount >= Endings.Penjelajah.require_insights and avgSkills >= Endings.Penjelajah.require_skills_avg then
		chosen = Endings.Penjelajah
	end

	data.endingReached = chosen.id

	RE_TriggerEnding:FireClient(player, {
		id    = chosen.id,
		title = chosen.title,
		desc  = chosen.desc,
		insights = insightCount,
		skills   = data.skills,
		points   = data.culturalPoints,
	})
end

---------------------------------------------------------------------
-- Player Action Handler
---------------------------------------------------------------------
local ACTION_HANDLERS = {}

ACTION_HANDLERS.Explore = function(player, data, payload)
	local area = payload.area or data.levelName
	addSkillPoint(data, "Observation", 2)
	addJournalEntry(player, data, "Menjelajahi area: " .. (LEVEL_DISPLAY[area] or area))
	RE_UpdateUI:FireClient(player, {
		type   = "skill_update",
		skill  = "Observation",
		value  = data.skills.Observation,
	})
end

ACTION_HANDLERS.Observe = function(player, data, payload)
	local target = payload.target or "lingkungan sekitar"
	addSkillPoint(data, "Observation", 5)
	RE_UpdateUI:FireClient(player, {
		type   = "skill_update",
		skill  = "Observation",
		value  = data.skills.Observation,
	})
	addJournalEntry(player, data, "Mengamati: " .. target)
end

ACTION_HANDLERS.LearnCulture = function(player, data, payload)
	local topic = payload.topic or "budaya lokal"
	addSkillPoint(data, "CulturalUnderstanding", 5)
	RE_UpdateUI:FireClient(player, {
		type   = "skill_update",
		skill  = "CulturalUnderstanding",
		value  = data.skills.CulturalUnderstanding,
	})
	addJournalEntry(player, data, "Belajar budaya: " .. topic)
end

ACTION_HANDLERS.DialogueChoice = function(player, data, payload)
	local npcKey    = payload.npc
	local choiceIdx = payload.choice
	local npc       = NPCDefinitions[npcKey]
	if not npc then return end

	-- Record choice
	table.insert(data.choices, {
		npc    = npcKey,
		choice = choiceIdx,
		time   = os.time(),
		level  = data.levelName,
	})

	addSkillPoint(data, "Communication", 3)
	addSkillPoint(data, "DecisionMaking", 2)

	RE_UpdateUI:FireClient(player, {
		type   = "skill_update",
		skill  = "Communication",
		value  = data.skills.Communication,
	})
end

ACTION_HANDLERS.PlayMiniGame = function(player, data, payload)
	local key = payload and payload.game or ""
	local config = MiniGameConfig[key]
	if not config then return end

	-- Initialize tracking
	if not data.miniGames[key] then
		data.miniGames[key] = { best_score = 0, attempts = 0, passed = false }
	end
	local mg = data.miniGames[key]
	mg.attempts = mg.attempts + 1
end

-- NPC interaction from MapSetup (talk_npc) or GameClient (interact_npc)
ACTION_HANDLERS.talk_npc = function(player, data, payload)
	local npcName = payload
	if not npcName then return end
	for npcKey, npc in pairs(NPCDefinitions) do
		if npc.name == npcName then
			handleNPCInteract(player, npcKey)
			return
		end
	end
end

ACTION_HANDLERS.interact_npc = function(player, data, payload)
	for npcKey, npc in pairs(NPCDefinitions) do
		if npc.level == data.levelName or npc.level == "All" then
			handleNPCInteract(player, npcKey)
			return
		end
	end
end

---------------------------------------------------------------------
-- RemoteEvent Handlers
---------------------------------------------------------------------

-- Client sends: { action: string, payload: table }
RE_PlayerAction.OnServerEvent:Connect(function(player, actionType, payload)
	local data = getPlayerData(player)
	if not data then return end
	if data.endingReached then return end

	local handler = ACTION_HANDLERS[actionType]
	if handler then
		handler(player, data, payload)
	end
end)

-- Client sends dialogue choice
RE_DialogueEvent.OnServerEvent:Connect(function(player, dialogueKey, choiceIdx)
	local data = getPlayerData(player)
	if not data then return end

	local node = DialogueTree[dialogueKey]
	if not node then return end

	local step   = node[1]
	local choice = step.choices and step.choices[choiceIdx]
	if not choice then return end

	-- Check insight requirement
	if choice.require_insight and not data.insights[choice.require_insight] then
		RE_UpdateUI:FireClient(player, {
			type  = "dialogue_blocked",
			reason = "Kau perlu memahami " .. (CulturalInsights[choice.require_insight] and CulturalInsights[choice.require_insight].title or "budaya terlebih dahulu") .. ".",
		})
		return
	end

	-- Apply skill points
	if choice.skill then
		addSkillPoint(data, choice.skill, choice.pts or 5)
		RE_UpdateUI:FireClient(player, {
			type  = "skill_update",
			skill = choice.skill,
			value = data.skills[choice.skill],
		})
	end

	-- Unlock insight
	if choice.unlock_insight then
		unlockInsight(player, data, choice.unlock_insight)
	end

	-- Record choice
	ACTION_HANDLERS.DialogueChoice(player, data, {
		npc    = dialogueKey,
		choice = choiceIdx,
	})

	-- Send next dialogue
	if choice.next and DialogueTree[choice.next] then
		local nextNode = DialogueTree[choice.next][1]
		RE_DialogueEvent:FireClient(player, choice.next, nextNode)
	end

	-- Start mini game
	if choice.start_minigame then
		local mgCfg = MiniGameConfig[choice.start_minigame]
		if mgCfg then
			RE_DialogueEvent:FireClient(player, "_minigame_start", {
				game   = choice.start_minigame,
				config = mgCfg,
			})
		end
	end

	-- Unlock journal
	if choice.journal then
		addJournalEntry(player, data, choice.journal)
	end
end)

-- NPC interaction trigger (client → server)
-- Client sends NPC key, server returns dialogue
local function handleNPCInteract(player, npcKey)
	local data = getPlayerData(player)
	if not data then return end

	local npc = NPCDefinitions[npcKey]
	if not npc then return end

	-- Check level gate: NPC must be in current level or "All"
	if npc.level ~= "All" and npc.level ~= data.levelName then
		RE_UpdateUI:FireClient(player, {
			type  = "npc_blocked",
			npc   = npc.name,
			reason = npc.name .. " tidak ada di area ini.",
		})
		return
	end

	-- Special: Pedagang Tua requires completed mini game
	if npc.role == "secret" then
		local pasarMG = data.miniGames["TawarMenawar"]
		if not pasarMG or not pasarMG.passed then
			RE_UpdateUI:FireClient(player, {
				type   = "npc_blocked",
				npc    = npc.name,
				reason = "Kau harus membuktikan dirimu dulu di pasar ini.",
			})
			return
		end
	end

	local dlgKey = npc.dialogue_key
	local dlgNode = DialogueTree[dlgKey]
	if not dlgNode then return end

	data.dialogueState[dlgKey] = true
	RE_DialogueEvent:FireClient(player, dlgKey, dlgNode[1])
end

-- Mini game result (client → server with score 0-1)
RE_MiniGameResult.OnServerEvent:Connect(function(player, gameKey, score)
	local data = getPlayerData(player)
	if not data then return end

	local config = MiniGameConfig[gameKey]
	if not config then return end

	local mg = data.miniGames[gameKey]
	if not mg then
		mg = { best_score = 0, attempts = 0, passed = false }
		data.miniGames[gameKey] = mg
	end

	mg.attempts = mg.attempts + 1
	if score > mg.best_score then
		mg.best_score = score
	end

	if score >= config.threshold then
		-- Passed!
		mg.passed = true

		-- Apply skill rewards
		if config.reward.skill_pts then
			for skill, pts in pairs(config.reward.skill_pts) do
				addSkillPoint(data, skill, pts)
				RE_UpdateUI:FireClient(player, {
					type  = "skill_update",
					skill = skill,
					value = data.skills[skill],
				})
			end
		end

		-- Unlock insight
		if config.reward.insight then
			unlockInsight(player, data, config.reward.insight)
		end

		-- Mark level complete and unlock next
		local levelIdx = table.find(LEVEL_ORDER, config.level)
		if levelIdx and not data.levelCompleted[levelIdx] then
			data.levelCompleted[levelIdx] = true
			unlockNextLevel(player, data)

			addJournalEntry(player, data, "Menyelesaikan mini game " .. config.title .. " di " .. LEVEL_DISPLAY[config.level])
		end

		RE_MiniGameResult:FireClient(player, gameKey, true, config.pass_text, score)

		-- Check if all levels completed → trigger ending
		local allDone = true
		for i = 1, #LEVEL_ORDER do
			if not data.levelCompleted[i] then
				allDone = false
				break
			end
		end
		if allDone then
			checkAndTriggerEnding(player, data)
		end
	else
		-- Failed
		addSkillPoint(data, config.skill, 2) -- consolation points
		RE_MiniGameResult:FireClient(player, gameKey, false, config.fail_text, score)
	end
end)

-- Level transition request
RE_LevelTransition.OnServerEvent:Connect(function(player, targetLevel)
	local data = getPlayerData(player)
	if not data then return end
	transitionToLevel(player, data, targetLevel)
end)

---------------------------------------------------------------------
-- RemoteFunction: GetPlayerData
---------------------------------------------------------------------
RF_GetPlayerData.OnServerInvoke = function(player)
	local data = getPlayerData(player)
	if not data then return nil end

	-- Return a safe copy (no mutation from client)
	return {
		currentLevel    = data.currentLevel,
		levelName       = data.levelName,
		levelDisplayName= LEVEL_DISPLAY[data.levelName],
		levelsUnlocked  = data.levelsUnlocked,
		levelCompleted  = data.levelCompleted,
		skills          = data.skills,
		skillsDef       = SkillDefinition,
		culturalPoints  = data.culturalPoints,
		insights        = data.insights,
		journal         = data.journal,
		miniGames       = data.miniGames,
		endingReached   = data.endingReached,
		playTime        = data.playTime,
	}
end

---------------------------------------------------------------------
-- Dialogue starter helper (used by NPC click handlers on server)
---------------------------------------------------------------------
local function setupNPCInteraction(npcModel, npcKey)
	local clickDetector = npcModel:FindFirstChildOfClass("ClickDetector")
	if not clickDetector then
		clickDetector = Instance.new("ClickDetector")
		clickDetector.MaxActivationDistance = 15
		clickDetector.Parent = npcModel
	end

	clickDetector.MouseClick:Connect(function(player)
		handleNPCInteract(player, npcKey)
	end)
end

---------------------------------------------------------------------
-- Player Lifecycle
---------------------------------------------------------------------
Players.PlayerAdded:Connect(function(player)
	local data = loadPlayerData(player)
	data.sessionStart = os.time()
	PlayerDataCache[player] = data

	-- Send initial state
	RE_UpdateUI:FireClient(player, {
		type  = "init",
		level = data.currentLevel,
		name  = LEVEL_DISPLAY[data.levelName],
		points= data.culturalPoints,
	})

	-- Trigger dosen intro quest if new player
	if data.currentLevel == 1 and not data.dialogueState["dosen_quest"] then
		task.delay(3, function()
			local dosen = NPCDefinitions["NPC_Dosen"]
			RE_DialogueEvent:FireClient(player, "dosen_quest", DialogueTree["dosen_quest"][1])
			data.dialogueState["dosen_quest"] = true
		end)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	savePlayerData(player)
	PlayerDataCache[player] = nil
end)

-- Auto-save loop
task.spawn(function()
	while true do
		task.wait(120) -- every 2 minutes
		for player in pairs(PlayerDataCache) do
			savePlayerData(player)
		end
	end
end)

-- Save on shutdown
game:BindToClose(function()
	for player in pairs(PlayerDataCache) do
		savePlayerData(player)
	end
end)

---------------------------------------------------------------------
-- Public API for other server scripts
---------------------------------------------------------------------
local GameServer = {}

function GameServer.GetPlayerData(player)
	return getPlayerData(player)
end

function GameServer.UnlockInsight(player, insightKey)
	local data = getPlayerData(player)
	if data then
		return unlockInsight(player, data, insightKey)
	end
	return false
end

function GameServer.TriggerNPC(player, npcKey)
	handleNPCInteract(player, npcKey)
end

function GameServer.AddJournalEntry(player, entry)
	local data = getPlayerData(player)
	if data then
		addJournalEntry(player, data, entry)
	end
end

function GameServer.CheckEnding(player)
	local data = getPlayerData(player)
	if data then
		checkAndTriggerEnding(player, data)
	end
end

function GameServer.GetLevelDisplay()
	return LEVEL_DISPLAY
end

function GameServer.GetDialogueTree()
	return DialogueTree
end

function GameServer.GetMiniGameConfig()
	return MiniGameConfig
end

function GameServer.GetCulturalInsights()
	return CulturalInsights
end

function GameServer.ForceSave(player)
	savePlayerData(player)
end

return GameServer
