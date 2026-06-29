--[[
	LevelDesign.lua
	Jejak Nusantara Final - Level Design & Narrative Module
	
	4 Levels:
	1. Desa Budaya (Jawa Barat)
	2. Sanggar Seni
	3. Pasar Tradisional
	4. Tempat Bersejarah
	
	Each level: goals, mini-games, obstacles, rewards, mysteries, NPCs, narrative
]]

local LevelDesign = {}

------------------------------------------------------------
-- TYPES & STRUCTURES
------------------------------------------------------------

--[[
	LevelSchema = {
		id: number,
		name: string,
		subtitle: string,
		description: string,
		region: string,
		goal: { primary: string, secondary: string },
		miniGame: { name: string, type: string, description: string, mechanics: {...} },
		obstacle: { name: string, trigger: string, consequence: string },
		reward: { items: {...}, unlocks: {...}, narrative: string },
		mystery: { name: string, hint: string, discovery: string, reward: string },
		npcs: {...},
		dialogue: {...},
		environment: {...},
		narrative: { intro: string, mid: string, outro: string },
		culturalInsight: string,
		estimatedDuration: number (minutes),
		difficulty: number (1-5),
	}
]]

------------------------------------------------------------
-- LEVEL 1: DESA BUDAYA (JAWA BARAT)
------------------------------------------------------------

LevelDesign.Level1 = {
	id = 1,
	name = "Desa Budaya",
	subtitle = "Kampung Seni Jawa Barat",
	description = "Pemain tiba di desa budaya Sunda. Warga sedang mempersiapkan upacara adat. Pemain harus wawancara warga dan belajar angklung untuk mendapat kepercayaan mereka.",
	region = "Jawa Barat",

	goal = {
		primary = "Wawancara 5 warga desa dan pelajari sejarah angklung",
		secondary = "Temukan NPC rahasia di balik sawah",
	},

	miniGame = {
		name = "Mengikuti Nada Angklung",
		type = "rhythm_matching",
		description = "Pemain harus mengikuti pola nada angklung yang dimainkan oleh tetua desa. Setiap level kesulitan naik dengan pola yang lebih kompleks.",
		mechanics = {
			patternLength = { start = 3, max = 8 },
			tempo = { start = 80, max = 140 },  -- BPM
			notes = {"do", "re", "mi", "fa", "sol", "la", "si"},
			visualCues = true,  -- tombol berwarna sesuai nada
			auditoryCues = true, -- suara angklung asli
			penaltyPerMiss = -10,  -- poin dikurangi
			perfectBonus = 15,
			thresholds = {
				bronze = 60,   -- poin minimum lolos
				silver = 80,
				gold = 95,
			},
		},
	},

	obstacle = {
		name = "Salah Nada",
		trigger = "Pemain salah memilih nada 3x berturut-turut",
		consequence = "Ulang latihan dari awal pola yang sedang dikerjakan. NPC pembimbing memberikan petunjuk ekstra setelah kegagalan ke-2.",
		retryLimit = 5,
		afterMaxRetry = "NPC memberikan mode mudah dengan pola yang lebih pendek",
	},

	reward = {
		items = {
			{ name = "Angklung Mini", description = "Angklung kecil sebagai kenang-kenangan dari tetua desa", icon = "angklung_mini", rarity = "common" },
			{ name = "Peta Budaya Jawa Barat", description = "Peta yang menunjukkan lokasi penting di desa", icon = "map_west_java", rarity = "common" },
		},
		unlocks = {
			"Level 2: Sanggar Seni",
			"Sistem Cultural Insight",
			"Kamus Sunda Dasar (in-game)",
		},
		narrative = "Tetua desa terkesan dengan keinginanmu belajar. 'Angklung bukan sekadar alat musik,' katanya. 'Ini jiwa masyarakat Sunda.' Ia memberimu angklung mini dan petunjuk menuju sanggar seni.",
	},

	mystery = {
		name = "NPC Rahasia — Eyang Surya",
		hint = "Warga menyebut 'orang tua yang tinggal di balik sawah, jarang terlihat tapi tahu semua cerita.'",
		discovery = "Pemain harus berjalan ke area tersembunyi di balik sawah (bukan jalur utama). Di sana ada rumah kecil dengan Eyang Surya yang menceritakan legenda angklung yang tidak ada di buku.",
		reward = "Cerita Legenda Angklung (hidden lore entry) + item 'Gelang Kayu Eyang' yang membuka dialog rahasia di level selanjutnya",
	},

	npcs = {
		{
			name = "Pak Dharma",
			role = "Tetua Desa",
			personality = "Bijak, sabar, suka bercerita",
			location = "Balai Desa",
			dialogueSet = "tutorial_angklung",
			questGiver = true,
		},
		{
			name = "Ibu Ratna",
			role = "Penjual Kue Tradisional",
			personality = "Ramah, ceria, suka berbagi resep",
			location = "Pasar Kecil Desa",
			dialogueSet = "info_kuliner",
			givesItem = "Kue Serabi (health restore)",
		},
		{
			name = "Kang Asep",
			role = "Petani Merangkap Pemain Angklung",
			personality = "Santai, humoris, puitis",
			location = "Sawah",
			dialogueSet = "kehidupan_desa",
			givesHint = "Petunjuk NPC rahasia",
		},
		{
			name = "Neng Lestari",
			role = "Guru Seni Desa",
			personality = "Tegas tapi supportive",
			location = "Sanggar Kecil",
			dialogueSet = "pengantar_level2",
			givesQuest = "Antar surat ke Sanggar Seni",
		},
		{
			name = "Eyang Surya",
			role = "Penjaga Legenda (NPC Rahasia)",
			personality = "Misterius, bijak, berbicara dalam bahasa puitis",
			location = "Rumah tersembunyi di balik sawah",
			dialogueSet = "hidden_lore_angklung",
			isHidden = true,
		},
	},

	dialogue = {
		intro = {
			speaker = "Narator",
			lines = {
				"Kamu baru tiba di sebuah desa di Jawa Barat.",
				"Udara segar menyambutmu. Dari kejauhan terdengar suara angklung.",
				"Warga berkumpul di balai desa — mereka sedang mempersiapkan upacara.",
				"Tugasmu: belajar budaya mereka, dan mereka akan mempercayaimu.",
			},
		},
		tutorial_angklung = {
			speaker = "Pak Dharma",
			lines = {
				"Selamat datang, anak muda. Mau belajar angklung?",
				"Angklung sudah diakui UNESCO sejak 2010.",
				"Setiap bambu punya suara. Setiap suara punya makna.",
				"Ikuti nadaku. Jangan takut salah — yang penting mau belajar.",
			},
		},
		mid_level = {
			speaker = "Narator",
			lines = {
				"Latihanmu berjalan baik. Warga mulai mengenalmu.",
				"Ada satu orang yang belum kamu temui... seseorang yang tinggal jauh dari keramaian.",
			},
		},
		outro = {
			speaker = "Pak Dharma",
			lines = {
				"Kamu sudah belajar dengan baik. Ambil angklung ini.",
				"Di ujung jalan ada sanggar seni. Katakan aku yang mengutusmu.",
				"Dan ingat — seni bukan hanya tentang suara. Seni tentang perasaan.",
			},
		},
	},

	environment = {
		theme = "Tropical Village",
		timeOfDay = "Pagi - Siang",
		weather = "Cerah, sesekali awan mendung",
		ambientSound = {"suara_angklung", "kicau_burung", "gemericik_air"},
		assets = {
			"rumah_adat_sunda",
			"sawah_padi",
			"balai_desa",
			"jalan_tanah",
			"pohon_bambu",
			"kandang_ayam",
		},
		spawnPoint = { x = 0, y = 5, z = 0 },
		boundaries = {
			min = { x = -200, y = 0, z = -200 },
			max = { x = 200, y = 50, z = 200 },
		},
	},

	narrative = {
		intro = "Kamu tiba di Desa Budaya Jawa Barat. Suara angklung terdengar dari balai desa. Warga sedang bersiap untuk upacara adat tahunan. Tapi mereka tidak mudah percaya pada orang asing — kamu harus membuktikan niat baikmu.",
		mid = "Setelah berbicara dengan beberapa warga, kamu mulai memahami kehidupan desa. Ada cerita yang tidak tertulis di mana pun — tentang seorang tua yang menyimpan rahasia angklung generasi.",
		outro = "Pak Dharma tersenyum. 'Kamu sudah layak disebut teman,' katanya. Angklung kecil kini ada di tanganmu. Perjalananmu belum selesai — ada sanggar seni menunggumu.",
	},

	culturalInsight = "Angklung adalah alat musik tradisional Sunda dari bambu yang dimainkan dengan cara digoyangkan. Setiap angklung menghasilkan satu nada, sehingga dimainkan secara ensemble. UNESCO mengakui angklung sebagai Warisan Budaya Tak Benda pada 3 November 2010.",

	estimatedDuration = 15,  -- menit
	difficulty = 1,  -- mudah
}


------------------------------------------------------------
-- LEVEL 2: SANGGAR SENI
------------------------------------------------------------

LevelDesign.Level2 = {
	id = 2,
	name = "Sanggar Seni",
	subtitle = "Tarian Warisan Nusantara",
	description = "Pemain tiba di sanggar seni tradisional. Para penari sedang berlatih untuk pertunjukan besar. Pemain harus mempelajari gerakan tari dan menemukan ruangan latihan rahasia.",
	region = "Jawa Tengah / Yogyakarta",

	goal = {
		primary = "Pelajari 5 gerakan dasar tari tradisional dan tampilkan dalam mini-game ritme",
		secondary = "Temukan ruangan latihan rahasia di lantai bawah tanah",
	},

	miniGame = {
		name = "Ritme Gerakan Tari",
		type = "rhythm_movement",
		description = "Pemain harus meniru rangkaian gerakan tari yang ditampilkan oleh penari utama. Gerakan harus sesuai ritme musik gamelan. Setiap gerakan memiliki timing window yang ketat.",
		mechanics = {
			movements = {
				"Sembah (penghormatan)",
				"Ngelayang (gerakan tangan anggun)",
			 "Ngeseh (langkah kaki)",
				"Tancep (pose akhir)",
				"Lenggak-lenggok (gerakan tubuh)",
			},
			timingWindow = { easy = 1.0, normal = 0.7, hard = 0.4 },  -- detik
			comboMultiplier = { x2 = 3, x3 = 5, x5 = 10 },
			gamelanTempo = 90,  -- BPM
			visualOverlay = true,  -- siluet gerakan di layar
			hapticFeedback = true,  -- getaran controller saat benar
			penaltyPerMiss = -15,
			thresholds = {
				bronze = 50,
				silver = 75,
				gold = 90,
			},
		},
	},

	obstacle = {
		name = "Gerakan Tidak Sesuai",
		trigger = "Akurasi gerakan di bawah 50% dalam satu rangkaian",
		consequence = "Skor dikurangi dan rangkaian harus diulang. Penari pembimbing menunjukkan gerakan yang salah secara perlahan.",
		retryLimit = 4,
		afterMaxRetry = "Penari utama melakukan gerakan bersama pemain (mode bimbingan)",
	},

	reward = {
		items = {
			{ name = "Kain Batik Penari", description = "Kain batik bermotif khusus dari sanggar", icon = "batik_penari", rarity = "uncommon" },
			{ name = "Buku Gerakan Tari", description = "Referensi gerakan dasar tari Nusantara", icon = "book_tari", rarity = "common" },
		},
		unlocks = {
			"Level 3: Pasar Tradisional",
			"Emote Tari (gerakan tari untuk karakter pemain)",
			"Galeri Seni (akses ke koleksi seni rupa)",
		},
		narrative = "Penari utama, Mbak Ayu, tersenyum bangga. 'Kamu punya bakat,' katanya. 'Tari bukan soal sempurna — soal jiwa yang masuk ke setiap gerakan.' Ia memberimu kain batik dan surat rekomendasi untuk Pasar Tradisional.",
	},

	mystery = {
		name = "Ruangan Latihan Rahasia",
		hint = "Suara gamelan terdengar dari bawah lantai sanggar. Lihat ada lantai yang berbeda teksturnya di pojok ruangan.",
		discovery = "Pemain harus menemukan panel lantai tersembunyi di pojok sanggar. Di bawahnya ada ruangan latihan kuno dengan gamelan tua dan mural dinding yang menceritakan sejarah tari Jawa.",
		reward = "Mural Sejarah Tari Jawa (lore entry) + item 'Gamelan Miniature' yang bisa digunakan di level Pasar Tradisional untuk diskon khusus",
	},

	npcs = {
		{
			name = "Mbak Ayu",
			role = "Penari Utama Sanggar",
			personality = "Anggun, sabar, perfeksionis tapi hangat",
			location = "Panggung Utama Sanggar",
			dialogueSet = "tutorial_tari",
			questGiver = true,
		},
		{
			name = "Mas Brama",
			role = "Penabuh Gamelan",
			personality = "Tenang, filosofis, sedikit misterius",
			location = "Area Gamelan",
			dialogueSet = "musik_gamelan",
			givesHint = "Petunjuk ruangan rahasia",
		},
		{
			name = "Dewi",
			role = "Penari Muda (Murid)",
			personality = "Antusias, cerewet, suka membantu",
			location = "Ruang Ganti",
			dialogueSet = "tips_tari",
			givesItem = "Hairpin Penari (cosmetic)",
		},
		{
			name = "Pak Tua Sanggar",
			role = "Penjaga Sanggar (NPC Rahasia di ruangan bawah)",
			personality = "Sunyi, bijak, hanya berbicara saat ditemui",
			location = "Ruangan Latihan Rahasia",
			dialogueSet = "hidden_lore_tari",
			isHidden = true,
		},
	},

	dialogue = {
		intro = {
			speaker = "Narator",
			lines = {
				"Sanggar seni ini sudah berdiri sejak 3 generasi.",
				"Suara gamelan mengisi setiap sudut. Aroma dupa dan bunga menyambutmu.",
				"Para penari sedang latihan untuk pertunjukan wayang malam ini.",
				"Ikuti gerakan mereka. Biarkan tubuhmu mengikuti irama.",
			},
		},
		tutorial_tari = {
			speaker = "Mbak Ayu",
			lines = {
				"Selamat datang di sanggar kami. Saya Mbak Ayu.",
				"Tari tradisional bukan sekadar gerakan — ini bahasa tanpa kata.",
				"Setiap gerakan punya makna. Sembah = hormat. Ngelayang = kebebasan.",
				"Ikuti aku. Pelan-pelan saja. Yang penting hatimu ikut menari.",
			},
		},
		mid_level = {
			speaker = "Mas Brama",
			lines = {
				"Kamu dengar itu? Gamelan di bawah sana...",
				"Orang bilang itu cuma gema. Tapi ada cerita lain...",
				"Coba cari lantai yang beda. Mungkin kamu menemukan sesuatu.",
			},
		},
		outro = {
			speaker = "Mbak Ayu",
			lines = {
				"Kamu sudah belajar dengan sepenuh hati. Ambil kain batik ini.",
				"Di ujung kota ada pasar tradisional. Di sana kamu akan belajar hal berbeda.",
				"Seni ada di mana-mana — bahkan di tawar-menawar.",
			},
		},
	},

	environment = {
		theme = "Traditional Art Studio",
		timeOfDay = "Siang - Sore",
		weather = "Hangat, cahaya masuk dari jendela kayu",
		ambientSound = {"gamelan_pelog", "tepukan_tangan", "langkah_kaki_tari"},
		assets = {
			"sanggar_kayu",
			"panggung_bambu",
			"cermin_besar",
			"gamelan_set",
			"kain_batik_dekorasi",
			"lilin_dan_bunga",
		},
		spawnPoint = { x = 0, y = 3, z = -50 },
		secretArea = {
			name = "Ruang Bawah Tanah",
			location = { x = 45, y = -5, z = 30 },
			entryType = "hidden_panel",
		},
	},

	narrative = {
		intro = "Sanggar seni ini adalah jantung budaya tari Jawa. Di sini, gerakan bukan sekadar tontonan — ia adalah cerita yang hidup dari generasi ke generasi.",
		mid = "Mas Brama bicara tentang gamelan yang terdengar dari bawah. Ada sesuatu yang tersembunyi di sanggar ini — rahasia yang tidak semua orang tahu.",
		outro = "Mbak Ayu mengenalmu sebagai penari sejati. 'Bukan karena sempurna, tapi karena jujur,' katamu. Kain batik di tangan, kamu siap melangkah ke kehidupan pasar yang ramai.",
	},

	culturalInsight = "Tari tradisional Indonesia memiliki ratusan bentuk di setiap daerah. Di Jawa, tari sering dikaitkan dengan upacara keraton dan pertunjukan wayang. Setiap gerakan memiliki makna filosofis — misalnya gerakan tangan ke atas melambangkan doa, sementara gerakan melingkar melambangkan siklus kehidupan.",

	estimatedDuration = 20,  -- menit
	difficulty = 2,  -- sedang
}


------------------------------------------------------------
-- LEVEL 3: PASAR TRADISIONAL
------------------------------------------------------------

LevelDesign.Level3 = {
	id = 3,
	name = "Pasar Tradisional",
	subtitle = "Tawar-Menawar & Kuliner Nusantara",
	description = "Pemain masuk ke pasar tradisional yang ramai. Harus mengenal kuliner khas dan belajar seni tawar-menawar dengan pedagang. Ada pedagang tua rahasia yang menjual item langka.",
	region = "Multi-daerah (komposit kuliner Nusantara)",

	goal = {
		primary = "Kenali 6 kuliner khas dan berhasil tawar-menawar dengan minimal 4 pedagang",
		secondary = "Temukan pedagang tua rahasia di ujung pasar",
	},

	miniGame = {
		name = "Negosiasi Harga",
		type = "dialogue_negotiation",
		description = "Pemain berdialog dengan pedagang. Setiap dialog memiliki pilihan respons yang mempengaruhi harga akhir. Pemain harus membaca situasi dan memilih kata yang tepat.",
		mechanics = {
			dialogueTree = true,  -- branching conversation
			factors = {
				"senyuman (emoji feedback)",
				"pengetahuan_budaya (dari level sebelumnya)",
				"item_bantuan (Gamelan Miniature = diskon)",
				"bahasa_daerah (kamus Sunda = bonus)",
			},
			priceRange = {
				base = 100,  -- harga awal
				minimum = 40,  -- harga terendah mungkin
				maximum = 150,  -- harga jika gagal total
			},
			dialogueOptions = 3,  -- pilihan per percakapan
			timePerChoice = 15,  -- detik
			favorabilityMeter = true,  -- menampilkan mood pedagang
			thresholds = {
				bronze = "Harga 70-100 (diskon kecil)",
				silver = "Harga 50-69 (diskon besar)",
				gold = "Harga 40-49 (harga sahabat)",
			},
		},
	},

	obstacle = {
		name = "Dialog Salah",
		trigger = "Memilih respons yang tidak sopan atau tidak relevan 2x",
		consequence = "Harga naik dan pedagang tidak mau lagi berbicara. Pemain harus cari pedagang lain atau tunggu cooldown waktu.",
		retryLimit = 3,
		afterMaxRetry = "NPC teman (Dewi dari level 2) datang membantu negosiasi",
	},

	reward = {
		items = {
			{ name = "Rendang Padang", description = "Masakan khas Sumatera Barat, restore health penuh", icon = "rendang", rarity = "uncommon" },
			{ name = "Kerak Betor", description = "Makanan khas Betawi, restore stamina", icon = "kerak_betor", rarity = "common" },
			{ name = "Papeda", description = "Makanan khas Papua, buff kecepatan", icon = "papeda", rarity = "uncommon" },
			{ name = "Resep Nenek", description = "Buku resep kuliner Nusantara dari pedagang tua", icon = "recipe_book", rarity = "rare" },
		},
		unlocks = {
			"Level 4: Tempat Bersejarah",
			"Kuliner Codex (encyclopedia makanan in-game)",
			"Resep Masak (mini-game crafting di level akhir)",
		},
		narrative = "Setelah tawar-menawar, pedagang-pedagang menceritakan asal-usul makanan mereka. 'Rendang bukan sekadar masakan,' kata seorang pedagang Minang. 'Ini filosofi kesabaran.' Kamu mendapat resep dan cerita yang tak ternilai.",
	},

	mystery = {
		name = "Pedagang Tua Rahasia",
		hint = "Di ujung pasar, ada lapak kecil yang hanya buka saat senja. Pedagangnya berbicara bahasa yang campuran dari berbagai daerah.",
		discovery = "Pemain harus menunggu sampai waktu senja (in-game) dan berjalan ke ujung pasar. Di sana ada pedagang tua yang menjual 'Resep Nenek' — buku resep kuliner langka yang membuka crafting system.",
		reward = "Resep Nenek + info lore tentang sejarah kuliner Nusantara + item 'Uang Kuno' yang bisa digunakan di level 4",
	},

	npcs = {
		{
			name = "Mak Nyak",
			role = "Pedagang Rendang",
			personality = "Tegas tapi hangat, suka bercerita masa muda",
			location = "Lapak Rendang",
			dialogueSet = "negosiasi_rendang",
			teachesItem = "Rendang Padang",
		},
		{
			name = "Kang Ujang",
			role = "Pedagang Kerak Betor",
			personality = "Lucu, ceplas-ceplos, jagoan tawar-menawar",
			location = "Lapak Betawi",
			dialogueSet = "negosiasi_kerak",
			teachesItem = "Kerak Betor",
		},
		{
			name = "Bapak Yanto",
			role = "Pedagang Papeda",
			personality = "Tenang, sabar, filosofis",
			location = "Lapak Indonesia Timur",
			dialogueSet = "negosiasi_papeda",
			teachesItem = "Papeda",
		},
		{
			name = "Nenek Sari",
			role = "Pedagang Jamu & Kue",
			personality = "Ramah, ibu-ibu, suka ngasih bonus",
			location = "Lapak Jamu",
			dialogueSet = "negosiasi_jamu",
			teachesItem = "Jamu Kunyit Asam",
		},
		{
			name = "Bang Hasan",
			role = "Pedagang Sate Madura",
			personality = "Ekspresif, penuh semangat, jago marketing",
			location = "Lapak Sate",
			dialogueSet = "negosiasi_sate",
			teachesItem = "Sate Madura",
		},
		{
			name = "Opa Frans",
			role = "Pedagang Kue Lapis Surabaya",
			personality = "Lembut, nostalgia, suka cerita masa kecil",
			location = "Lapak Kue",
			dialogueSet = "negosiasi_kue",
			teachesItem = "Kue Lapis",
		},
		{
			name = "Pedagang Tua Misterius",
			role = "Penjaga Resep Nenek (NPC Rahasia)",
			personality = "Bicara campuran bahasa, sangat tua, misterius",
			location = "Ujung pasar (hanya muncul saat senja)",
			dialogueSet = "hidden_pedagang_tua",
			isHidden = true,
		},
	},

	dialogue = {
		intro = {
			speaker = "Narator",
			lines = {
				"Pasar tradisional. Aneka warna, aroma, dan suara menyambutmu.",
				"Penjual berteriak menawarkan dagangan. Pembeli tawar-menawar riuh.",
				"Di sini kamu bukan sekadar belanja — kamu belajar budaya melalui rasa.",
				"Tapi hati-hati: pedagang ini sudah ratusan kali tawar-menawar. Mereka jago.",
			},
		},
		negosiasi_rendang = {
			speaker = "Mak Nyak",
			lines = {
				"Eh, mau rendang? Ini rendang asli Padang, turun-temurun!",
				"Tapi jangan main ambil dulu. Harganya? Tergantung kamu bisa bikin aku tersenyum.",
				"Kalau sopan, bisa diskon. Kalau sok tahu? Harga naik!",
			},
		},
		mid_level = {
			speaker = "Narator",
			lines = {
				"Kamu sudah berkeliling pasar. Perutmu kenyang, tapi ada satu tempat belum kamu kunjungi.",
				"Di ujung sana... ada lapak yang hanya muncul saat senja.",
			},
		},
		outro = {
			speaker = "Mak Nyak",
			lines = {
				"Kamu ini anak yang baik. Tadi sopan, sekarang dapat harga bagus.",
				"Ke sana, ke tempat bersejarah. Bawa uang kuno itu — mungkin berguna.",
				"Dan jangan lupa: makanan itu cerita. Setiap resep punya sejarah.",
			},
		},
	},

	environment = {
		theme = "Traditional Market",
		timeOfDay = "Pagi - Senja",
		weather = "Cerah, ramai, sedikit berdebu",
		ambientSound = {"pedagang_berteriak", "kerumunan", "musik_dangdut_jarak_jauh", "gerobak_dorong"},
		assets = {
			"los_pasar",
			"gerobak_makanan",
			"tenda_warna_warni",
			"karung_rempah",
			"etalase_kaca",
			"kursi_meja_makan",
		},
		spawnPoint = { x = 0, y = 2, z = -100 },
		secretArea = {
			name = "Lapak Ujung Pasar",
			location = { x = 90, y = 0, z = 90 },
			entryType = "time_gated",  -- hanya muncul saat senja
			appearTime = "17:00",  -- in-game time
		},
	},

	narrative = {
		intro = "Pasar tradisional — jantung ekonomi rakyat. Di sini setiap transaksi adalah interaksi budaya. Pedagang bukan hanya penjual — mereka storyteller.",
		mid = "Kamu sudah mencicipi banyak makanan dan mendengar banyak cerita. Tapi ada satu lapak yang belum kamu temui. Di ujung pasar, seorang pedagang tua menunggu pembeli yang tepat.",
		outro = "Tas penuh oleh-oleh dan cerita. Resep Nenek di tangan, kamu siap melangkah ke tempat terakhir: situs bersejarah yang menyimpan puzzle masa lalu.",
	},

	culturalInsight = "Kuliner Indonesia adalah cerminan keragaman budaya. Setiap daerah punya masakan khas yang dibentuk oleh sejarah, geografi, dan filosofi hidup. Rendang dari Minangkabau melambangkan kesabaran (dimasak berjam-jam). Papeda dari Papua melambangkan kebersahajaan. Tawar-menawar di pasar adalah seni komunikasi yang diwariskan turun-temurun.",

	estimatedDuration = 25,  -- menit
	difficulty = 3,  -- menengah-sulit (dialog kompleks)
}


------------------------------------------------------------
-- LEVEL 4: TEMPAT BERSEJARAH
------------------------------------------------------------

LevelDesign.Level4 = {
	id = 4,
	name = "Tempat Bersejarah",
	subtitle = "Puzzle Warisan Masa Lalu",
	description = "Pemain tiba di situs bersejarah kuno. Ada puzzle sejarah yang harus dipecahkan untuk membuka rahasia terakhir. Setiap puzzle menguji pengetahuan yang didapat dari level sebelumnya.",
	region = "Multi-situs (komposit candi & situs bersejarah)",

	goal = {
		primary = "Susun 4 puzzle sejarah dan temukan simbol kuno tersembunyi",
		secondary = "Gunakan semua item dari level sebelumnya untuk membuka secret ending",
	},

	miniGame = {
		name = "Puzzle Sejarah",
		type = "logic_puzzle",
		description = "Pemain menyusun puzzle yang merepresentasikan artefak sejarah. Setiap puzzle membutuhkan pengetahuan dari level sebelumnya. Puzzle menjadi semakin kompleks dan menghubungkan cerita budaya Indonesia.",
		mechanics = {
			puzzles = {
				{
					name = "Puzzle Candi Borobudur",
					type = "jigsaw_rotation",
					pieces = 12,
					theme = "Arsitektur Buddha",
					requiredKnowledge = "Level 1: Pengetahuan budaya dari angklung",
				},
				{
					name = "Puzzle Prasasti Kuno",
					type = "cipher_decode",
					pieces = 8,
					theme = "Aksara kuno Nusantara",
					requiredKnowledge = "Level 2: Wawasan seni dari tari",
				},
				{
					name = "Puzzle Peta Nusantara Kuno",
					type = "map_assembly",
					pieces = 15,
					theme = "Perdagangan maritim Nusantara",
					requiredKnowledge = "Level 3: Info kuliner & sejarah perdagangan",
				},
				{
					name = "Puzzle Simbol Kuno",
					type = "pattern_matching",
					pieces = 10,
					theme = "Simbol spiritual Nusantara",
					requiredKnowledge = "Semua level + item rahasia",
				},
			},
			hintSystem = {
				baseHints = 3,
				hintPenalty = -20,  -- poin per hint
				bonusFromItems = true,  -- item dari level sebelumnya = hint gratis
			},
			timeLimit = {
				puzzle1 = 180,  -- detik
				puzzle2 = 150,
				puzzle3 = 200,
				puzzle4 = 120,
			},
			thresholds = {
				bronze = "3 dari 4 puzzle selesai",
				silver = "4 puzzle selesai dengan 1+ hint",
				gold = "4 puzzle selesai tanpa hint",
			},
		},
	},

	obstacle = {
		name = "Salah Puzzle",
		trigger = "Memasang puzzle piece di posisi salah 3x",
		consequence = "Petunjuk berkurang 1. Setelah petunjuk habis, puzzle di-reset tapi progress tersimpan sebagian.",
		retryLimit = 5,
		afterMaxRetry = "NPC guide muncul dan memberikan solusi parsial",
	},

	reward = {
		items = {
			{ name = "Artefak Kuno", description = "Simbol pengetahuan Nusantara yang tersembunyi selama berabad-abad", icon = "artefak_kuno", rarity = "legendary" },
			{ name = "Buku Sejarah Lengkap", description = "Kompilasi semua cerita dan pengetahuan dari perjalanan", icon = "book_sejarah", rarity = "epic" },
			{ name = "Medali Penjelajah Budaya", description = "Penghargaan atas dedikasi melestarikan budaya", icon = "medali_budaya", rarity = "legendary" },
		},
		unlocks = {
			"Ending: Penjaga Budaya",
			"New Game+ dengan konten bonus",
			"Gallery Lengkap (semua cultural insight)",
			"Costume Eksklusif 'Penjelajah Nusantara'",
		},
		narrative = "Simbol kuno terungkap. Dinding-dinding candi menyala dengan cahaya keemasan. 'Kamu telah mengumpulkan semua pengetahuan,' suara gaib bergema. 'Kamu bukan lagi pengunjung — kamu adalah Penjaga Budaya Nusantara.'",
	},

	mystery = {
		name = "Simbol Kuno Tersembunyi",
		hint = "Di balik puzzle terakhir, ada simbol yang cocok dengan Gelang Kayu Eyang (Level 1), Gamelan Miniature (Level 2), dan Uang Kuno (Level 3).",
		discovery = "Pemain harus menggunakan ketiga item rahasia dari level sebelumnya di altar kuno. Ini membuka puzzle bonus yang mengungkap cerita lengkap Nusantara dan secret ending.",
		reward = "Secret Ending: 'Warisan Abadi' + title eksklusif 'Penjaga Nusantara' + unlock semua cultural insight",
	},

	npcs = {
		{
			name = "Prof. Wirya",
			role = "Arkeolog & Guide",
			personality = "Antusias, cerdas, suka trivia sejarah",
			location = "Pintu Masuk Situs",
			dialogueSet = "intro_situs",
			questGiver = true,
		},
		{
			name = "Siti",
			role = "Penjaga Situs Muda",
			personality = "Serius, passionate tentang sejarah, sedikit keras kepala",
			location = "Area Puzzle Candi",
			dialogueSet = "bantuan_puzzle",
			givesHint = true,
		},
		{
			name = "Raden",
			role = "Sejarawan Freelance",
			personality = "Santai, suka bercanda, tapi sangat tahu sejarah",
			location = "Perpustakaan Mini Situs",
			dialogueSet = "lore_tambahan",
			givesItem = "Catatan Sejarawan (extra hints)",
		},
		{
			name = "Suara Gaib",
			role = "Pengawas Spiritual Situs",
			personality = "Abstract, berbicara dalam pantun dan metafora",
			location = "Altar Kuno (hanya muncul setelah semua puzzle selesai)",
			dialogueSet = "final_dialogue",
			isHidden = true,
		},
	},

	dialogue = {
		intro = {
			speaker = "Prof. Wirya",
			lines = {
				"Selamat datang di situs bersejarah Nusantara!",
				"Di sini kamu akan menguji semua yang sudah kamu pelajari.",
				"Setiap puzzle punya cerita. Setiap cerita punya makna.",
				"Gunakan semua yang kamu punya. Jangan takut gagal.",
			},
		},
		puzzle_guidance = {
			speaker = "Siti",
			lines = {
				"Puzzle ini susunannya dari kiri ke kanan, atas ke bawah.",
				"Perhatikan simbol di setiap piece. Ada polanya.",
				"Kalau buntu, coba hubungkan dengan apa yang kamu pelajari di level sebelumnya.",
			},
		},
		mid_level = {
			speaker = "Narator",
			lines = {
				"Tiga puzzle sudah selesai. Satu lagi menunggumu.",
				"Tapi perhatikan — di balik puzzle terakhir ada sesuatu yang lebih dalam.",
				"Apakah kamu punya semua yang kamu butuhkan?",
			},
		},
		final_dialogue = {
			speaker = "Suara Gaib",
			lines = {
				"Kamu datang. Seperti yang sudah tertulis.",
				"Gelang kayu... gamelan tua... uang kuno...",
				"Semua itu bukan sekadar benda. Itu jejak perjalananmu.",
				"Sekarang susun. Dan lihat apa yang tersembunyi selama berabad-abad.",
			},
		},
		outro = {
			speaker = "Prof. Wirya",
			lines = {
				"Kamu... kamu berhasil? Semua puzzle?",
				"Bahkan simbol tersembunyi itu! Ini luar biasa!",
				"Kamu bukan sekadar mahasiswa. Kamu Penjaga Budaya.",
				"Terima kasih sudah mengingatkan kami tentang warisan kita.",
			},
		},
	},

	environment = {
		theme = "Ancient Temple Complex",
		timeOfDay = "Sore - Malam (progressive)",
		weather = "Mendung, dramatis, cahaya bulan saat malam",
		ambientSound = {"angin_dingin", "air_mengalir", "suara_serangga_malam", "gema_langkah"},
		assets = {
			"candi_batu",
			"relief_dinding",
			"altar_kuno",
			"lentera_batu",
			"akar_pohon_tua",
			"kolam_refleksi",
			"tangga_batu",
		},
		spawnPoint = { x = 0, y = 5, z = -80 },
		secretArea = {
			name = "Altar Kuno Tersembunyi",
			location = { x = 0, y = -10, z = 0 },
			entryType = "item_gated",  -- butuh 3 item rahasia
			requiredItems = {"Gelang Kayu Eyang", "Gamelan Miniature", "Uang Kuno"},
		},
	},

	narrative = {
		intro = "Situs bersejarah ini menyimpan puzzle masa lalu Nusantara. Di sini kamu akan menghubungkan semua yang sudah kamu pelajari — musik, tari, kuliner — menjadi satu cerita utuh.",
		mid = "Tiga puzzle selesai. Tapi yang terakhir berbeda. Simbol-simbolnya... seperti pernah kamu lihat. Di gelang Eyang Surya, di gamelan sanggar, di uang kuno pedagang tua.",
		outro = "Dinding candi menyala. Suara gaib bergema: 'Kamu Penjaga Budaya.' Perjalananmu di dunia ini selesai, tapi tugasmu dimulai — melestarikan cerita yang kamu bawa.",
	},

	culturalInsight = "Situs bersejarah Indonesia adalah saksi bisu peradaban Nusantara. Dari Candi Borobudur (Buddha, abad ke-9) hingga Prambanan (Hindu, abad ke-9), dari situs megalitikum Sulawesi hingga candi-candi kecil Jawa Timur — setiap batu menyimpan cerita. Puzzle-puzzle di level ini merepresentasikan tantangan nyata dalam pelestarian budaya: menyatukan potongan-potongan sejarah yang tersebar.",

	estimatedDuration = 30,  -- menit
	difficulty = 4,  -- sulit
}


------------------------------------------------------------
-- CROSS-LEVEL SYSTEMS
------------------------------------------------------------

LevelDesign.CulturalInsightSystem = {
	description = "Sistem yang mengumpulkan dan menampilkan informasi budaya yang dipelajari pemain di setiap level.",
	entries = {},  -- diisi dari setiap level
	displayType = "in-game encyclopedia",
	rewards = {
		full = "Title 'Penjaga Budaya' + semua ending terbuka",
		partial = "Title 'Pecinta Budaya'",
	},
}

LevelDesign.ProgressionSystem = {
	levelOrder = {1, 2, 3, 4},
	unlockCondition = {
		[2] = "Menyelesaikan mini-game angklung dengan minimal bronze",
		[3] = "Menyelesaikan mini-game tari dengan minimal bronze",
		[4] = "Menyelesaikan mini-game negosiasi dengan minimal bronze + menemukan pedagang tua",
	},
	savePoints = {
		[1] = "Setelah mini-game angklung selesai",
		[2] = "Setelah mini-game tari selesai",
		[3] = "Setelah mini-game negosiasi selesai",
		[4] = "Setelah setiap puzzle selesai",
	},
}

LevelDesign.EndingSystem = {
	endings = {
		{
			name = "Penjaga Budaya",
			type = "best",
			requirement = "Semua level gold + semua mystery terbuka + secret puzzle selesai",
			description = "Pemain diakui sebagai Penjaga Budaya Nusantara. Semua cerita terungkap. Secret ending dengan cutscene khusus.",
		},
		{
			name = "Sahabat Nusantara",
			type = "good",
			requirement = "Semua level selesai + minimal 2 mystery terbuka",
			description = "Pemain diterima sebagai sahabat budaya. Semua NPC mengenalmu. Good ending.",
		},
		{
			name = "Pengunjung Setia",
			type = "normal",
			requirement = "Semua level selesai tanpa mystery",
			description = "Pemain menyelesaikan perjalanan tapi tidak menemukan semua rahasia. Normal ending.",
		},
		{
			name = "Langkah Awal",
			type = "minimal",
			requirement = "Level 4 selesai dengan minimal skor",
			description = "Pemain menyelesaikan perjalanan dasar. Buka New Game+ untuk ending lebih baik.",
		},
	},
}


------------------------------------------------------------
-- UTILITY FUNCTIONS
------------------------------------------------------------

function LevelDesign.getLevel(levelId)
	local key = "Level" .. tostring(levelId)
	return LevelDesign[key]
end

function LevelDesign.getAllLevels()
	return {
		LevelDesign.Level1,
		LevelDesign.Level2,
		LevelDesign.Level3,
		LevelDesign.Level4,
	}
end

function LevelDesign.getLevelCount()
	return 4
end

function LevelDesign.getDifficultyRating(levelId)
	local level = LevelDesign.getLevel(levelId)
	if level then
		return level.difficulty
	end
	return 0
end

function LevelDesign.getEstimatedTotalDuration()
	local total = 0
	for _, level in ipairs(LevelDesign.getAllLevels()) do
		total = total + level.estimatedDuration
	end
	return total
end

function LevelDesign.getCulturalInsights()
	local insights = {}
	for _, level in ipairs(LevelDesign.getAllLevels()) do
		table.insert(insights, {
			level = level.id,
			name = level.name,
			insight = level.culturalInsight,
		})
	end
	return insights
end

function LevelDesign.getNPCs()
	local allNpcs = {}
	for _, level in ipairs(LevelDesign.getAllLevels()) do
		for _, npc in ipairs(level.npcs) do
			npc.level = level.id
			npc.levelName = level.name
			table.insert(allNpcs, npc)
		end
	end
	return allNpcs
end

function LevelDesign.getHiddenNPCs()
	local hidden = {}
	for _, level in ipairs(LevelDesign.getAllLevels()) do
		for _, npc in ipairs(level.npcs) do
			if npc.isHidden then
				npc.level = level.id
				npc.levelName = level.name
				table.insert(hidden, npc)
			end
		end
	end
	return hidden
end

function LevelDesign.getSecretItems()
	return {
		{ level = 1, item = "Gelang Kayu Eyang", source = "Eyang Surya" },
		{ level = 2, item = "Gamelan Miniature", source = "Ruangan Latihan Rahasia" },
		{ level = 3, item = "Uang Kuno", source = "Pedagang Tua Misterius" },
	}
end


return LevelDesign
