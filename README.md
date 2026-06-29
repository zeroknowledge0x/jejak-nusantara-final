# JEJAK NUSANTARA — Roblox Game

Game edukasi budaya Indonesia. Jelajahi 4 wilayah, bicara dengan NPC, selesaikan quiz, dan dapatkan ending!

## 🚀 Cara Install (2 Langkah!)

1. Buka **Roblox Studio** → buat Baseplate baru
2. Taruh file berikut:
   - `CompleteGame.lua` → **ServerScriptService** (Script)
   - `GameClient.lua` → **StarterPlayer > StarterPlayerScripts** (LocalScript)
3. Klik **▶ Play**!

## 🎮 Fitur

- **5 NPC** dengan dialogue branching (Pak Dosen, Pak Karso, Ibu Ratna, Mang Wayan, Bapak Yanu)
- **4 Wilayah** (Jawa, Sumatra, Bali, Papua) via portal
- **12 Soal Quiz** (3 per wilayah)
- **XP, Level, Koin** system
- **Journal** (tekan J)
- **DataStore** save/load otomatis
- **3 Ending** berdasarkan pencapaian:
  - 🏆 **Budayawan**: Semua quiz selesai + XP ≥ 500
  - 🗺️ **Penjelajah**: 2+ quiz selesai + XP ≥ 200
  - 📖 **Pemula**: Default

## 📁 Struktur

```
game/
├── ServerScriptService/
│   └── CompleteGame.lua (Script)
└── StarterPlayer/StarterPlayerScripts/
    └── GameClient.lua (LocalScript)
```
