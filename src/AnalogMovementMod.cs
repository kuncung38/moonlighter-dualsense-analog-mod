using BepInEx;
using HarmonyLib;
using System.Collections.Generic;
using System.Reflection.Emit;
using InControl;
using UnityEngine;
using DigitalSunGames.Platforms;

namespace AnalogMovementMod
{
    [BepInPlugin("com.bepinex.moonlighter.analogmovement", "Analog Movement Mod", "1.0.0")]
    public class AnalogMovementPlugin : BaseUnityPlugin
    {
        private void Awake()
        {
            var harmony = new Harmony("com.bepinex.moonlighter.analogmovement");
            harmony.PatchAll();
            Logger.LogInfo("AnalogMovementMod loaded! Replaced 8-way movement with 360-degree analog.");
        }
    }

    [HarmonyPatch(typeof(HeroMerchantController), "UpdateMoveAnimations")]
    public class Patch_UpdateMoveAnimations
    {
        public static float GetAnalogX(TwoAxisInputControl originalControl)
        {
            if (InputManager.ActiveDevice != null && InputManager.ActiveDevice.DeviceClass != InputDeviceClass.Keyboard && InputManager.ActiveDevice.DeviceClass != InputDeviceClass.Mouse)
            {
                return InputManager.ActiveDevice.LeftStick.X;
            }
            return originalControl.X;
        }

        public static float GetAnalogY(TwoAxisInputControl originalControl)
        {
            if (InputManager.ActiveDevice != null && InputManager.ActiveDevice.DeviceClass != InputDeviceClass.Keyboard && InputManager.ActiveDevice.DeviceClass != InputDeviceClass.Mouse)
            {
                return InputManager.ActiveDevice.LeftStick.Y;
            }
            return originalControl.Y;
        }

        static IEnumerable<CodeInstruction> Transpiler(IEnumerable<CodeInstruction> instructions)
        {
            var codes = new List<CodeInstruction>(instructions);
            var getXMethod = AccessTools.PropertyGetter(typeof(TwoAxisInputControl), "X");
            var getYMethod = AccessTools.PropertyGetter(typeof(TwoAxisInputControl), "Y");
            var myGetXMethod = AccessTools.Method(typeof(Patch_UpdateMoveAnimations), "GetAnalogX");
            var myGetYMethod = AccessTools.Method(typeof(Patch_UpdateMoveAnimations), "GetAnalogY");

            for (int i = 0; i < codes.Count; i++)
            {
                if (codes[i].opcode == OpCodes.Callvirt && codes[i].operand != null && codes[i].operand.Equals(getXMethod))
                {
                    codes[i].opcode = OpCodes.Call;
                    codes[i].operand = myGetXMethod;
                }
                else if (codes[i].opcode == OpCodes.Callvirt && codes[i].operand != null && codes[i].operand.Equals(getYMethod))
                {
                    codes[i].opcode = OpCodes.Call;
                    codes[i].operand = myGetYMethod;
                }
            }
            return codes;
        }
    }

    public static class HardwareDetector
    {
        [System.Runtime.InteropServices.StructLayout(System.Runtime.InteropServices.LayoutKind.Sequential)]
        struct RAWINPUTDEVICELIST
        {
            public System.IntPtr hDevice;
            public uint dwType;
        }

        [System.Runtime.InteropServices.DllImport("user32.dll", SetLastError = true, CharSet = System.Runtime.InteropServices.CharSet.Auto)]
        static extern uint GetRawInputDeviceList(System.IntPtr pRawInputDeviceList, ref uint puiNumDevices, uint cbSize);

        [System.Runtime.InteropServices.DllImport("user32.dll", SetLastError = true, CharSet = System.Runtime.InteropServices.CharSet.Auto)]
        static extern uint GetRawInputDeviceInfo(System.IntPtr hDevice, uint uiCommand, System.IntPtr pData, ref uint pcbSize);

        const uint RIDI_DEVICENAME = 0x20000007;

        private static int _lastCheckTick = 0;
        private static bool _isDualSenseCached = false;

        public static bool IsDualSenseConnected()
        {
            int currentTick = System.Environment.TickCount;
            // Only check every 60000 milliseconds (60 seconds) to completely eliminate any chance of P/Invoke micro-stutters
            if (System.Math.Abs(currentTick - _lastCheckTick) < 60000 && _lastCheckTick != 0)
            {
                return _isDualSenseCached;
            }
            _lastCheckTick = currentTick;

            try
            {
                uint deviceCount = 0;
                uint dwSize = (uint)System.Runtime.InteropServices.Marshal.SizeOf(typeof(RAWINPUTDEVICELIST));

                if (GetRawInputDeviceList(System.IntPtr.Zero, ref deviceCount, dwSize) != 0 || deviceCount == 0)
                    return _isDualSenseCached = false;

                System.IntPtr pRawInputDeviceList = System.Runtime.InteropServices.Marshal.AllocHGlobal((int)(dwSize * deviceCount));
                try
                {
                    GetRawInputDeviceList(pRawInputDeviceList, ref deviceCount, dwSize);

                    for (int i = 0; i < deviceCount; i++)
                    {
                        RAWINPUTDEVICELIST rid = (RAWINPUTDEVICELIST)System.Runtime.InteropServices.Marshal.PtrToStructure(
                            new System.IntPtr((pRawInputDeviceList.ToInt64() + (dwSize * i))), typeof(RAWINPUTDEVICELIST));

                        uint pcbSize = 0;
                        GetRawInputDeviceInfo(rid.hDevice, RIDI_DEVICENAME, System.IntPtr.Zero, ref pcbSize);

                        if (pcbSize > 0)
                        {
                            // pcbSize is the character count for RIDI_DEVICENAME, not byte count.
                            // We must multiply by 2 for Unicode characters to prevent heap corruption!
                            System.IntPtr pData = System.Runtime.InteropServices.Marshal.AllocHGlobal((int)pcbSize * 2);
                            try
                            {
                                GetRawInputDeviceInfo(rid.hDevice, RIDI_DEVICENAME, pData, ref pcbSize);
                                string deviceName = System.Runtime.InteropServices.Marshal.PtrToStringAuto(pData);

                                if (!string.IsNullOrEmpty(deviceName))
                                {
                                    deviceName = deviceName.ToUpper();
                                    // Sony VID = 054C, DualSense PID = 0CE6
                                    if (deviceName.Contains("054C") && deviceName.Contains("0CE6"))
                                    {
                                        return _isDualSenseCached = true;
                                    }
                                }
                            }
                            finally
                            {
                                System.Runtime.InteropServices.Marshal.FreeHGlobal(pData);
                            }
                        }
                    }
                }
                finally
                {
                    System.Runtime.InteropServices.Marshal.FreeHGlobal(pRawInputDeviceList);
                }
            }
            catch
            {
                // Ignore exceptions during teardown/Alt+F4
            }
            return _isDualSenseCached = false;
        }
    }

    [HarmonyPatch(typeof(ButtonPlatformIconManager), "GetPlatformByDeviceStyle")]
    public class Patch_GetPlatformByDeviceStyle
    {
        static void Postfix(ref SupportedControllerLayout __result, InputDeviceStyle style)
        {
            if (HardwareDetector.IsDualSenseConnected())
            {
                __result = SupportedControllerLayout.PLAYSTATION_4;
            }
        }
    }
}

