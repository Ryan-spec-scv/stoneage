# Stone Age Client Data Files

## Current Status

### ✅ Available Files
- **Source Code**: Complete client source code in `stoneage-client/` folder
- **Compiled Executable**: `sa25.exe` (Windows x86)
- **Required DLLs**: OpenSSL, Lua, VMProtect (all provided in `dll/` folder)
- **Lua Scripts**: UI and map scripts in `lua/` folder

### ❌ Missing Files (Critical - Required for Client to Start)

**Essential .bin Files** (defined in system/main.cpp:72-75):
- ✅ **real_136.bin** - Main graphics binary (REQUIRED)
- ✅ **adrn_136.bin** - Address data binary (REQUIRED)
- ✅ **spr_115.bin** - Sprite graphics binary (REQUIRED)
- ✅ **spradrn_115.bin** - Sprite address binary (REQUIRED)

**Additional Resources** (needed for full gameplay):
- **Game Graphics**: Character sprites, item icons, map tiles, UI textures
- **Sound Files**: Background music, sound effects (BGM, SE folders)
- **Map Data**: Game world maps and zones (mapdata folder)
- **Configuration Files**: Game settings, item database
- **Other Resources**: Fonts, cursors, animations

**Without these files**: Client will show "开启Real.bin失败!" or "开启Spr.bin失败!" error (displayed as garbled text on some systems)

## Why Data Files Are Missing

Stone Age client data files are **very large** (typically 500MB - 2GB) and contain:
- Thousands of sprite images
- Map data for entire game world
- Sound and music files
- Other game resources

These files are **NOT included in the source code** and must be obtained separately.

## How to Obtain Client Data

### Option 1: Download Complete Client Package

Search for "石器时代8.5客户端" (Stone Age 8.5 Client) online. You need the full game client installer, not just the source code.

**Warning**: Make sure to download from trusted sources only.

### Option 2: Extract from Existing Installation

If you have Stone Age 8.5 installed elsewhere:
1. Locate the installation folder
2. Copy the `data/` folder
3. Copy all resource files (.pak, .dat, .bin, etc.)
4. Place them in the same directory as `sa25.exe`

### Option 3: Contact Original Developers

Reach out to the Stone Age 8.5 community or original developers for legitimate data files.

## Installation Instructions

Once you have the client data files:

1. **On Windows PC**, copy all data files to:
   ```
   C:\Users\admin\Desktop\sa2\stoneage-new\client\stoneage-client\Win32\VER25_RELEASE\
   ```

2. **Expected folder structure**:
   ```
   Win32\VER25_RELEASE\
   ├── sa25.exe
   ├── libeay32.dll
   ├── ssleay32.dll
   ├── lua51.dll
   ├── VMProtectSDK32.dll
   ├── data\
   │   ├── chardata\      (character sprites)
   │   ├── mapdata\       (map files)
   │   ├── sounddata\     (audio files)
   │   └── ... (other resources)
   ├── lua\
   │   ├── list.lua
   │   ├── title.lua
   │   ├── map\
   │   └── win\
   └── ... (configuration files)
   ```

3. **Run the client**:
   ```cmd
   cd C:\Users\admin\Desktop\sa2\stoneage-new\client\stoneage-client\Win32\VER25_RELEASE
   sa25.exe
   ```

## Current Error

### Error Analysis (Confirmed)

**Error Message**: Chinese characters displayed as corrupted/garbled text

**Actual Error Messages** (from source code):
- "开启Real.bin失败！" (Failed to open Real.bin!)
- "开启Spr.bin失败！" (Failed to open Spr.bin!)

**Root Cause** (system/gamemain.cpp:1180-1188):
```cpp
if (initRealbinFileOpen(realBinName, adrnBinName) == FALSE) {
    MessageBoxNew(hWnd, "开启Real.bin失败！", "确定", MB_OK | MB_ICONSTOP);
    return FALSE;
}
if (InitSprBinFileOpen(sprBinName, sprAdrnBinName) == FALSE){
    MessageBoxNew(hWnd, "开启Spr.bin失败！", "确定", MB_OK | MB_ICONSTOP);
    return FALSE;
}
```

**What's Happening**:
1. Client starts successfully (sa25.exe runs)
2. All DLLs load properly (OpenSSL, Lua, VMProtect)
3. Client attempts to load required .bin files from `data\` folder
4. **real_136.bin** or **spr_115.bin** not found
5. Error dialog appears with Chinese text (显示为乱码 on some Windows systems)
6. Client exits before attempting server connection

**Conclusion**: The encoding error is NOT a server connection issue. It's a **missing game data files** error. The client cannot proceed to server connection without these essential files.

## Server Connection

After the client loads successfully, you'll need to configure it to connect to your server:
- **Server IP**: 52.65.189.156
- **Server Port**: 9065

Configuration method depends on the client version (config file, registry, or built-in settings).

## Next Steps

### Immediate Priority: Obtain Required .bin Files

**You MUST have these 4 files for the client to start**:
1. `data\real_136.bin`
2. `data\adrn_136.bin`
3. `data\spr_115.bin`
4. `data\spradrn_115.bin`

**Search Keywords** (try multiple languages):
- English: "Stone Age 8.5 client download", "Stone Age complete client"
- Chinese: "石器时代8.5完整客户端下载", "石器客户端数据文件"
- Japanese: "ストーンエイジ 8.5 クライアント"
- Korean: "스톤에이지 8.5 클라이언트 다운로드"

**Where to look**:
- Private server communities and forums
- Chinese game archive sites (baidu云, 百度网盘)
- Game preservation archives
- Other Stone Age 8.5 server operators

### After Obtaining Files

1. Copy all data files to Windows PC
2. Place in: `C:\Users\admin\Desktop\sa2\stoneage-new\client\stoneage-client\Win32\VER25_RELEASE\data\`
3. Verify the 4 essential .bin files exist
4. Run `sa25.exe` - should proceed past the loading screen
5. Configure server connection (see SERVER_CONFIG.md)
6. Test server connection and gameplay

## Need Help?

If you're unable to find the client data files, consider:
- Searching Stone Age community forums
- Checking GitHub for complete client packages
- Contacting other Stone Age private server operators
- Looking for archived versions on game preservation sites
