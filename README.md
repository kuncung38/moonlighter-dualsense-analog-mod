# Moonlighter — DualSense & True 360° Analog Movement Mod

Fixes Moonlighter's clunky 8-directional controller movement and adds automatic PlayStation button prompts for DualSense controllers on PC (both USB and Bluetooth), even with Steam Input enabled.

---

## Features

1. **True 360° Analog Movement**
   - Moonlighter's default controller movement snaps the left stick to 8 cardinal/diagonal directions (`UpdateMoveAnimations`).
   - This mod patches `HeroMerchantController.UpdateMoveAnimations` via a Harmony Transpiler to read raw `LeftStick.X` and `LeftStick.Y` values directly, giving smooth 360° analog movement.
   - Keyboard & mouse controls remain completely unchanged.

2. **Automatic DualSense Icon Detection (USB & Bluetooth)**
   - Moonlighter uses an older input library (`InControl`) that requires Steam Input to recognize a PS5 DualSense controller, which normally disguises the controller as an Xbox controller and forces Xbox icons.
   - This mod uses Windows Raw Input (`GetRawInputDeviceList`) to detect physical DualSense hardware (`VID 054C`, `PID 0CE6`) over USB or Bluetooth and automatically displays PlayStation button prompts (`SupportedControllerLayout.PLAYSTATION_4`, as Moonlighter only ships PS4 icon assets).
   - Xbox and other controllers continue to show their normal icons.
   - Hardware detection is cached (60-second interval) with safe unmanaged memory handling so there is zero frame stutter and clean game shutdowns.

---

## 1-Click Install

### Option A: 1-Click PowerShell Installer (Recommended)
1. Press `Win + X` and open **Terminal** (or **PowerShell**).
2. Paste and run:
   ```powershell
   irm https://raw.githubusercontent.com/kuncung38/moonlighter-dualsense-analog-mod/main/install.ps1 | iex
   ```
3. The script automatically finds your Steam `Moonlighter` folder (or lets you pick it), installs BepInEx + `AnalogMovementMod.dll`, and you're ready to play!

### Option B: Download Release ZIP & Double-Click `Install.bat`
1. Download `Moonlighter-DualSense-Analog-Mod.zip` from the [**Latest Release**](https://github.com/kuncung38/moonlighter-dualsense-analog-mod/releases/latest).
2. Extract the ZIP anywhere.
3. Double-click **`Install.bat`** — it will automatically find Moonlighter and install everything for you.

*(Manual install: extract the release ZIP contents directly into your `Moonlighter` game folder where `Moonlighter.exe` is located.)*

### Option C: SteamOS / Steam Deck / Linux
1. Switch to **Desktop Mode** and open **Konsole**.
2. Paste and run:
   ```bash
   curl -fsSL https://raw.githubusercontent.com/kuncung38/moonlighter-dualsense-analog-mod/main/install.sh | bash
   ```
3. Add the **Launch Option** printed by the installer in Steam -> Moonlighter -> Properties -> General:
   - **If using Proton (recommended for DualSense icon detection):**
     ```
     WINEDLLOVERRIDES="winhttp=n,b" %command%
     ```
   - **If using the Native Linux build:**
     ```
     ./run_bepinex.sh %command%
     ```
   *(Note: Both 360° analog movement and automatic DualSense PlayStation icon detection work on Windows, Proton, and Native Linux/SteamOS!)*

---

## Controller Setup Tips

- **Keep Steam Input ENABLED** in Steam's controller settings for Moonlighter. Moonlighter's legacy `InControl` library cannot detect a DualSense natively without Steam Input, and this mod handles switching your UI icons back to PlayStation prompts automatically.
- **Optional — Instant Effortless Dodge (L2 Hair Trigger):**
  If you want dodging on L2 to feel like an instant click without pulling the trigger all the way down:
  1. Open Steam Overlay (`Shift + Tab`) in-game -> **Controller Layout** -> **Edit Layout**.
  2. Go to **Triggers** -> **Left Trigger** (gear icon).
  3. Set **Trigger Type** to **Hair Trigger**.

---

## Uninstall

- Double-click **`Uninstall.bat`** (included in the release ZIP), **or**
- Delete `BepInEx\plugins\AnalogMovementMod.dll` from your Moonlighter folder.

---

## Building from Source

Requires `.NET SDK` (`netstandard2.0`) and a local installation of Moonlighter with BepInEx 5.x installed:

```powershell
cd src
dotnet build -c Release -p:MoonlighterDir="C:\Program Files (x86)\Steam\steamapps\common\Moonlighter"
```

The compiled DLL will be output to `src\bin\Release\netstandard2.0\AnalogMovementMod.dll`.

---

## Credits

- Powered by [BepInEx 5](https://github.com/BepInEx/BepInEx) (LGPL-2.1) and [HarmonyX](https://github.com/BepInEx/HarmonyX).
- Mod source code licensed under the [MIT License](LICENSE).
