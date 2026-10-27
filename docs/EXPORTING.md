# Windows and Android export guide

Use **Godot 4.5.2 Standard** for the tested source baseline. Install the **4.5.2 export templates** using **Editor → Manage Export Templates**. Export templates must match the editor version. The included `export_presets.cfg` provides Windows Desktop and Android targets; platform binaries, Android SDK/JDK, signing keys, and export templates are not bundled.

## Windows

1. Open `project.godot`, let imports finish, and run the game with F5.
2. Create `builds/windows/` if it does not exist.
3. Open **Project → Export → Windows Desktop**.
4. Keep architecture **x86_64**. Select **Export Project** and save `builds/windows/PocketCrossing.exe`.
5. Turn off **Export With Debug** for a release build.
6. Keep the `.exe` and `.pck` together. Zip the entire exported folder to distribute it.

The preset keeps PCK embedding off and code signing off. A Windows signing certificate is not needed for local testing. Test on an actual Windows PC before distributing a build.

Command line, from the project directory after creating the destination folder:

```sh
godot --headless --path . --export-release "Windows Desktop" builds/windows/PocketCrossing.exe
```

Official reference: [Godot Windows export documentation](https://docs.godotengine.org/en/4.5/tutorials/export/exporting_for_windows.html).

## Android: local APK testing

1. Install **OpenJDK 17** and the Android SDK. Godot's versioned Android documentation specifies SDK Platform 35, Platform-Tools 35.0.0 or later, Build-Tools 35.0.0, command-line tools, CMake 3.10.2.4988404, and NDK 28.1.13356709 for the 4.5 toolchain.
2. In **Editor → Editor Settings → Export → Android**, set **Java SDK Path** and **Android SDK Path**.
3. Install the matching Godot export templates. The supplied APK preset uses the standard export workflow; custom Gradle builds are off.
4. Create `builds/android/` if it does not exist.
5. Open **Project → Export → Android**. The package ID is `org.pocketcrossing.game`; change it to your own unique ID before distributing the game.
6. Use **Export Project**, choose `builds/android/PocketCrossing.apk`, and leave **Export With Debug** enabled for your first device test.
7. Transfer and install the APK, or use Godot's Android deployment with USB debugging. Enable USB debugging on your test phone if using ADB.

The preset includes ARMv7 and ARM64. It does not include an x86 emulator build. For an x86_64 Android emulator, enable that architecture in the preset. The game requests vibration permission for hit feedback; it does not need Internet or external-storage permission.

Commands after your local SDK, templates, and debug signing are configured:

```sh
godot --headless --path . --export-debug "Android" builds/android/PocketCrossing.apk
adb install -r builds/android/PocketCrossing.apk
```

Official setup reference: [Godot 4.5 Android export documentation](https://docs.godotengine.org/en/4.5/tutorials/export/exporting_for_android.html). If you change Godot versions, follow that version's SDK requirements.

## Android release signing

For a release, create and retain your own signing key, enter its path/alias/password in the Android export settings, and export with debug disabled. Keep keystores and credentials outside source control. They are intentionally absent here. A Play Store release uses an Android App Bundle and additional store preparation; consult the current official publishing requirements when you reach that stage.

## Device acceptance checklist

- Launch, start, swipe in all four directions, and hold each arrow button.
- Check that a touch on Pause or Sound never moves Pip.
- Lose all three lives and retry; let the timer expire and retry; complete all four bays and replay.
- Background the app mid-hop and mid-respawn. Return and confirm that it remains paused.
- Press Android Back during play and while paused.
- Check landscape scaling, display cutouts, and reachability of controls on your particular device. This build preserves aspect ratio; it does not yet use device-specific safe-area inset layouts.
- Check frame pacing, sound, haptics, and saved best score after closing/reopening.

## Common setup problems

| Symptom | What to check |
| --- | --- |
| Assets missing on first terminal run | Open the editor once, or run the headless import command first |
| Export template not found | Editor and templates must both be 4.5.2 |
| Android export cannot locate Java/ADB | Set the two Editor Settings paths and install the required SDK packages |
| APK fails to install over an older build | Check whether the installed APK uses a different signing key; uninstall the old test app if appropriate |
| Windows build cannot find data | Distribute its `.pck` alongside the `.exe` |
| Screen differs from the editor preview | Keep Compatibility rendering and aspect-preserving canvas settings; test actual devices |
