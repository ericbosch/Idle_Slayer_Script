# Idle Runner 3.5.9.0

This release adds a one-click Windows updater with explicit confirmation.

## Update safety

- Selects the x32 or x64 executable that matches the running build.
- Verifies the downloaded executable with SHA-256 before closing Idle Runner.
- Uses a temporary helper process to back up and replace the running executable.
- Waits for AutoThreadV3 workers to stop before replacement.
- Rolls back and relaunches the previous version if the update does not signal a successful startup.
- Preserves `IdleRunnerLogs`, `Settings.txt`, and existing logs.
- Keeps the GitHub Releases page as a manual fallback for network, permission, or antivirus errors.

The release publishes separate x32 and x64 executables, the traditional ZIP, and `SHA256SUMS.txt`.
