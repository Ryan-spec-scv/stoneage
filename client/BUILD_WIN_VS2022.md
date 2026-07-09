# 客戶端 Windows 原生編譯指南（VS2022 / MSBuild）

本文件記錄在 **Windows 11 + Visual Studio 2022** 下，從 `client/stoneage-client` 源碼
編譯出可執行繁中客戶端 `sa25.exe` 的**可重現**步驟，並附上啟動所需但源碼庫未含的
大型資源盤點。（原 `BUILD.md` 為 macOS/Wine 韓文舊稿，僅供參考，未刪除。）

驗證環境：`石器源码.vcxproj`、`VER25_RELEASE|Win32`、MSVC v143(14.44)、Windows SDK 10.0.26100.0。
產物：`sa25.exe`（PE32 / machine 0x14C / x86），約 1.31 MB，`/MT` 靜態 CRT。

---

## 1. 前置需求

- Visual Studio 2022（Community/BuildTools 皆可），含 **「使用 C++ 的桌面開發」** 工作負載
  （提供 MSVC x86 工具鏈與 Windows SDK）。
- 專案原本鎖定 `PlatformToolset=v141` + `WindowsTargetPlatformVersion=10.0.17763.0`。
  若本機未安裝這兩者，於命令列以 `/p:` 覆寫成已安裝版本即可（見下方指令），**不需**修改專案檔。
- **不需要** 安裝 ATL/MFC；本專案唯一的 ATL 參考已改為條件式引入（見第 3 節）。
- 目標平台固定 **Win32（x86）**，不是 x64。`.\sdk` 內附的 `lua51.lib`、`caryime.lib`、
  `GetMacAddress.lib`、`ddraw.lib`、`VMProtectSDK32.lib` 等皆為 32 位。

---

## 2. 編譯指令

於 `client/stoneage-client` 目錄，用 PowerShell 執行（路徑依實機調整）：

```powershell
$msb = "C:\Program Files\Microsoft Visual Studio\2022\Community\Msbuild\Current\Bin\MSBuild.exe"
$proj = "石器源码.vcxproj"
$out  = "E:\build-out\VER25_RELEASE\"

& $msb $proj /t:Rebuild `
  /p:Configuration=VER25_RELEASE /p:Platform=Win32 `
  /p:PlatformToolset=v143 `
  /p:WindowsTargetPlatformVersion=10.0.26100.0 `
  /p:OutDir=$out `
  /p:IntDir="E:\build-out\obj\VER25_RELEASE\" `
  /m /v:minimal
```

- `PlatformToolset` / `WindowsTargetPlatformVersion`：本機無 v141 + SDK 17763，故覆寫為 v143 + 26100。
  若本機剛好裝了 v141/17763，可省略這兩個 `/p:`。
- `OutDir`：專案內原本硬編 `D:\stoneAge\client`，用 `/p:OutDir` 覆寫到本機可寫目錄。
- 成功結尾為 `石器源码.vcxproj -> ...\sa25.exe`，`EXIT 0`。
- 連結期會有 `zlib.lib` 的 `LNK4286`（_malloc/_free import）與 `LNK4099`（缺 zlib.pdb）警告，
  以及專案本身 `WarningLevel=TurnOffAllWarnings`，皆屬無害，不影響產物。

### 其他 configuration

| Configuration | TargetName | Toolset | 備註 |
|---|---|---|---|
| `VER25_RELEASE` | `sa25` | v141 | 主線、功能最全（含 `_SA_VERSION_25`、`_TRADITIONAL_LONG_` 繁體建角/登入），**建議** |
| `Release` | `sa` | v141 | `OutputFile` 本就用 `$(OutDir)`，功能較精簡（`_SA_VERSION_182`） |
| `VER_TW_Release` / `_TW_SERVER_RELEASE` | `sa`/`saex` | v120_xp | 台服/TW 專用；需另裝 XP 工具鏈(v120_xp)，本機未驗證 |

---

## 3. 為讓編譯通過所做的兩處源碼修正

兩者皆為「讓現成專案在**未裝 v141/ATL、無 D:/F: 磁碟**的乾淨機器上可重現編譯」的最小修改，
不改動任何遊戲邏輯：

1. `system/chat.cpp`
   - 原：無條件 `#include <atlconv.h>`（但全檔與全專案並未使用任何 ATL 符號）。
   - 改：以 `#if __has_include(<atlconv.h>) ... #endif` 包住。有裝 ATL 時行為不變；沒裝時可正常編譯。
   - 起因：未安裝 ATL 元件時 `C1083: Cannot open include file: 'atlconv.h'`。

2. `石器源码.vcxproj`（`VER25_RELEASE|Win32`）
   - 原：`<OutputFile>F:\7-sa\sa25.exe</OutputFile>`（硬編到不存在的 F: 磁碟，`MSB3191`）。
   - 改：`<OutputFile>$(OutDir)$(TargetName)$(TargetExt)</OutputFile>`，與同專案 `Release` 設定一致，
     產物路徑改由可覆寫的 `OutDir` 決定。

> 註：`main.cpp` 的 `xcgui_115.lib` / `xcgui_115.dll` 依賴整段位於 `#ifdef _NEWDEBUG_` 內，
> `VER25_RELEASE` 未定義該巨集，故 **不需要** xcgui。

---

## 4. sa25.exe 執行期依賴（dumpbin /DEPENDENTS 實測）

- **OS 內建**：`DDRAW.dll`（DirectDraw，需 DirectX/相容元件）、`DSOUND.dll`、`WINMM.dll`、
  `DINPUT.dll`、`WSOCK32.dll`、`IMM32.dll`、`NETAPI32.dll` + `KERNEL32/USER32/GDI32/ADVAPI32/SHELL32`。
- **需隨包附帶的第三方 DLL**：`lua51.dll`、`VMProtectSDK32.dll`、`libeay32.dll`
  （另建議一併帶 `ssleay32.dll`）。以上皆已存在於 repo `client/stoneage-client/dll/` 或 `E:\石器時代\spsa\`。
- **CRT**：`/MT` 靜態連結，**不需** vcruntime/ucrt 執行期 DLL。
- `caryIme`、`GetMacAddress` 由 `.\sdk` 的 `.lib` 靜態連入，無額外 DLL。

---

## 5. 啟動所需但源碼庫未含的資源盤點（達到登入畫面）

客戶端啟動時（`system/main.cpp` 常數，可被設定檔 `addr` 的 `realbin:`/`adrnbin:`/`sprbin:`/`spradrnbin:`
鍵覆寫版本號）在 **`data\`** 讀取下列 `.bin`；缺檔會跳
「开启Real.bin失败！」/「开启Spr.bin失败！」後結束：

| 檔案（相對 exe） | 用途 | 編譯預設檔名 | repo 內 | 本機可用來源 |
|---|---|---|---|---|
| `data\real_136.bin` | 主圖形 | `REALBIN_DIR` | ❌ | `spsa\data\`(≈1.90 GB)、`石器時代 We Love SA\data\`、`華義主程式8.5...\` |
| `data\adrn_136.bin` | real 位址表 | `ADRNBIN_DIR` | ❌ | 同上（≈35 MB） |
| `data\spr_115.bin` | Sprite 圖形 | `SPRBIN_DIR` | ❌ | 同上（≈9.1 MB） |
| `data\spradrn_115.bin` | spr 位址表 | `SPRADRNBIN_DIR` | ❌ | 同上（≈21 KB） |
| `data\realtrue_13.bin` | 分離補丁(realtrue) | `REALTRUEBIN_DIR` | ❌ | `spsa\data\`(≈41 MB) |
| `data\adrntrue_5.bin` | 分離補丁(adrntrue) | `ADRNTRUEBIN_DIR` | ❌ | `spsa\data\`(≈34 KB) |

進一步遊玩還需 `spsa\data\` 內的完整資料包：`chardata\`、`map\`、`pal\`、`bgm\`、`se\`、`font\`、
`battle_2.bin`、`sound_3.bin` 等，以及 `client/lua`（repo 已含）。

> ⚠️ 版本相容性：本 baseline 編譯預設抓 `*_136 / *_115`（與 `spsa` 版本相符）。
> 現行 `sa_8018.exe` 舊服基準用的是 `realbin:138 / spradrnbin:116 / sprbin:116`（見 `E:\石器時代\findings.md`）。
> **不同版本號的 bin 不保證相容**；請確定 exe 讀取的版本號與所放 bin 檔一致（必要時用設定檔覆寫版本號，
> 或改放對應版本的 bin）。`spsa\data\` 的 136/115 與本 baseline 預設一致，是最直接的驗證來源。

### 組出可啟動目錄（最短路徑，用於驗證進到登入畫面）

```
<run>\
├── sa25.exe                    ← 本次產物
├── lua51.dll, VMProtectSDK32.dll, libeay32.dll, ssleay32.dll   ← repo dll\ 或 spsa\
├── data\                       ← 從 spsa\data\ 複製（含上表 6 個 bin 及 chardata/map/pal/...）
└── lua\                        ← client/lua
```

（GUI 實機啟動、登入 smoke 與 server IP/Port 設定屬 P0-4 後續子項，本次只交付「可編譯 + 資源盤點」。）
