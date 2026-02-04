This folder holds release builds for Idle Runner.

To create a release build:

1. Install AutoIt (full install + SciTE) if not already:
   https://www.autoitscript.com/site/autoit/downloads/

2. From the project root, run:
   build_release.bat

   This will:
   - Compile Idle Runner.au3 to Idle.Runner_x32.exe and Idle.Runner_x64.exe
     (if AutoIt3Wrapper is found)
   - Copy the exes and README/LICENSE into Release\3.5.7\
   - Create Idle.Runner_3.5.7.zip in the Release folder

3. If the script does not find AutoIt3Wrapper, compile manually:
   - Right-click "Idle Runner.au3" -> Compile with Options
   - Click "Compile Script"
   - Run build_release.bat again to package the exes.

4. For GitHub: create a new Release with tag 3.5.7, paste
   RELEASE_NOTES_3.5.7.md as the description, and attach
   Idle.Runner_3.5.7.zip (or the two exes).
