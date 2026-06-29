# 🇮🇩 Jejak Nusantara Final

**Game Edukasi Budaya Indonesia — Roblox Studio**

Mata kuliah: Pengembangan Game (MBKP-07.03.310)
Dosen: Nahar Mardiyantoro, M.Kom.
Kampus: TI UNSIQ

**Tim:**
- Daffa Rifqi A.F — Project Manager
- Mahda Vidho Pratama
- Sakti Hermawan
- Rakha Andrianto Q.A

---

## 📁 File Structure

```
JejakNusantaraFinal/
├── GameServer.lua      → ServerScriptService (Script)
├── GameClient.lua      → StarterPlayer > StarterPlayerScripts (LocalScript)
├── LevelDesign.lua     → ReplicatedStorage (ModuleScript)
├── MapSetup.lua        → ServerScriptService (Script)
└── README.md
```

## 🎮 Cara Setup (3 Langkah)

### Langkah 1: Buka Roblox Studio
1. Buka **Roblox Studio** (download di https://www.roblox.com/create jika belum ada)
2. Klik **"New"** → pilih **"Baseplate"**
3. Hapus semua part bawaan di Workspace (select all → Delete)

### Langkah 2: Import Script
Di **Explorer Panel** (kanan):

1. Klik kanan **ServerScriptService** → Insert Object → **Script**
   - Rename jadi `GameServer`
   - Copy-paste isi `GameServer.lua`

2. Klik kanan **ServerScriptService** → Insert Object → **Script**
   - Rename jadi `MapSetup`
   - Copy-paste isi `MapSetup.lua`

3. Klik kanan **ReplicatedStorage** → Insert Object → **ModuleScript**
   - Rename jadi `LevelDesign`
   - Copy-paste isi `LevelDesign.lua`

4. Klik kanan **StarterPlayer** → **StarterPlayerScripts** → Insert Object → **LocalScript**
   - Rename jadi `GameClient`
   - Copy-paste isi `GameClient.lua`

### Langkah 3: Play Test
- Tekan **F5** di Roblox Studio
- Game auto-generate: 4 level, 24 NPC, map, lighting

---

## 🎯 Fitur Game

### 4 Level Budaya
1. **Desa Budaya** — Jawa Barat (angklung, tari, kuliner)
2. **Sanggar Seni** — Seni tradisional (gamelan, batik, wayang)
3. **Pasar Tradisional** — Ekonomi & perdagangan (tawar-menawar)
4. **Tempat Bersejarah** — Candi & museum (puzzle sejarah)

### Sistem Gameplay
- **Dialogue System** — Bicara dengan NPC, pilih jawaban
- **Skill System** — 5 skill (Observasi, Komunikasi, Pemahaman Budaya, Pemecahan Masalah, Pengambilan Keputusan)
- **Cultural Insight** — Wawasan budaya terbuka saat eksplorasi
- **Journal** — Catatan perjalanan otomatis
- **Map** — Peta 4 level dengan status progress
- **3 Ending** — Berdasarkan skill & insight terkumpul

### 4 Mini-Game
1. **🎵 Angklung Rhythm** — Ikuti pola nada
2. **💃 Tari Topeng** — Ikuti gerakan arah
3. **🛒 Tawar-Menawar** — Tawar harga di pasar
4. **🧩 Puzzle Sejarah** — Kuis pengetahuan sejarah

### Controls
| Key | Fungsi |
|-----|--------|
| E | Bicara dengan NPC |
| J | Buka/tutup Journal |
| M | Buka/tutup Map |
| WASD | Bergerak |
| Space | Lompat |

### Map Auto-Generated
- 4 platform level (120x120 studs each)
- Rumah-rumah adat Sunda
- Sanggar seni dengan panggung
- Kios pasar (20+ stall)
- 3 candi (1 besar + 2 kecil)
- Museum
- 24+ NPC dengan dialog
- Pohon, air, dekorasi
- Lighting & atmosfer Indonesia

---

## 📊 Data Teknis

| File | Size | Lines | Fungsi |
|------|------|-------|--------|
| GameServer.lua | 36KB | 993 | Server logic, data, dialogue, mini-games |
| GameClient.lua | 49KB | 1706 | UI, input, visual, 4 mini-game interfaces |
| LevelDesign.lua | 34KB | 958 | Level data, NPC, quests, rewards |
| MapSetup.lua | 26KB | 600+ | Auto-generate world, NPC, lighting |

**Total: 145KB, 4000+ lines Lua**

---

## 📝 Catatan untuk Reviewer

- Semua kode ditulis dalam **Lua** (Roblox Luau)
- Menggunakan **RemoteEvent** dan **RemoteFunction** untuk komunikasi client-server
- **DataStore** untuk save/load progress player
- UI dibuat **programmatically** (tidak pakai plugin UI editor)
- Map auto-generated via script (konsisten setiap run)
- 24 NPC dengan dialog unik per level
- 4 mini-game terintegrasi dengan progression system
- 3 ending berdasarkan performa player
