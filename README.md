# 💀 Dead Man v1.1 💀

> **For the truly paranoid among us** 🕵️  
> *Because sometimes you need a fail-safe that doesn't require trust in anyone but yourself.*

A Windows-based automatic data destruction system that triggers after X days without login.

**✨ NEW in v1.1:**
- 🚀 **Smart Launcher (`DeadMan.exe`)** - Interactive menu with auto-installation
- 🔄 **Update Checker** - Compare local version with GitHub releases
- 💾 **Config Backup/Restore** - Save and restore your configuration
- 📂 **Custom Install Path** - Choose where to install Dead Man
- 🛡️ **Enhanced Security** - Hardened validation and error handling

![Dead Man Control Panel](media/screenshot.png)

## 🚀 Two Ways to Use

**🎯 For Regular Users** → Use `DeadMan.exe` (simpler, interactive menu)  
**👨‍💻 For Developers/Purists** → Use PowerShell scripts directly (`DeadMan.ps1` or `.bat` files)

**[Deutsche Version / German Version](README_DE.md)**

## ⚠️ WARNING

**USE AT YOUR OWN RISK!** This tool can permanently delete your data. **ALWAYS** test in Safe Mode first and create backups of important data!

## 🎯 Features

### Core Features
- **Automatic Trigger**: Activates after X days without login
- **Safe Mode**: Test the system without actual deletion (simulation)
- **Multiple Deletion Types**:
  - Plain files and folders
  - VeraCrypt containers and keyfiles
  - BitLocker recovery keys
- **GUI Control Panel**: Easy-to-use configuration interface
- **Windows Tasks**: Automatic monitoring on system startup and login

### v1.1 Features
- **Smart Launcher Menu**: Interactive menu with installation detection
- **Auto-Update Checker**: Compare your version with latest GitHub releases
- **Config Backup/Restore**: Export and import your configuration with validation
- **Custom Installation Path**: Install anywhere, not just C:\DeadMan
- **Enhanced Security**: Comprehensive input validation and error handling
- **About Dialog**: With dancing Bart! 🕺

## 🕵️ Who is this for?

This tool is for the **truly paranoid** - people who:
- Need a fail-safe in case of emergencies
- Don't trust cloud services with sensitive data
- Want full control over their data destruction
- Need plausible deniability (Safe Mode looks like the real thing)
- Understand the responsibility that comes with such power

**Not recommended for:**
- People who forget their passwords regularly
- Casual users who just want "some security"
- Anyone who doesn't fully understand what this does

## 📁 Project Structure

```
DeadMan/
├── config/               # Configuration files (auto-created)
│   ├── config.json
│   └── last_login.txt
├── logs/                 # Log files (auto-created)
│   └── log.txt
├── media/                # Media files
│   ├── bart.gif          # Our dancing Bart! 🎭
│   └── screenshot.png    # GUI screenshot
├── scripts/              # PowerShell scripts
│   ├── gui-config.ps1
│   ├── setup-tasks.ps1
│   ├── selfdestruct-check.ps1
│   └── update-last-login.ps1
├── setup/                # Installation & utility scripts
│   ├── installer.ps1
│   ├── uninstaller.ps1
│   ├── check-updates.ps1
│   ├── config-backup.ps1
│   ├── install.bat
│   ├── start.bat
│   └── create-shortcut.ps1
├── run.bat               # ⭐ Smart launcher (auto-install + start)
├── uninstall.bat         # Uninstaller
├── check-updates.bat     # Update checker
├── backup-config.bat     # Config backup/restore
├── DeadMan.exe           # Main launcher executable
├── DeadMan.ps1           # PowerShell launcher
├── .gitignore
├── LICENSE
└── README.md
```

## 🚀 Installation

### Prerequisites
- Windows 10/11
- PowerShell 5.1 or higher
- Administrator rights for installation

### Quick Install (Recommended) 🎯

1. **Download and extract**
   - Download `DeadMan-v1.1-Installer.zip` from [Releases](https://github.com/iamrealguexoxo/DeadMan/releases)
   - Extract to any folder

2. **Double-click `run.bat`**
   - That's it! The script will:
     - ✅ Check if already installed
     - ✅ If not: Auto-install to `C:\DeadMan` + create desktop shortcut
     - ✅ If yes: Launch directly
   
3. **Configure**
   - Select **[1] GUI** from menu
   - Add items and test in Safe Mode!

### Manual Installation (Advanced)

**Clone from GitHub:**
```bash
git clone https://github.com/iamrealguexoxo/DeadMan.git C:\DeadMan
cd C:\DeadMan
```

**Install:**
- Double-click `run.bat` (auto-detects and installs)
- OR: `setup\install.bat` for manual installation

**Launch:**
- Double-click `run.bat` or `DeadMan.exe`

### Additional Tools

**Update Checker:**
- Double-click **`check-updates.bat`** or select [3] from menu
- Compares local version with latest GitHub release
- Opens release page if update available

**Config Backup/Restore:**
- Double-click **`backup-config.bat`** or select [4] from menu
- **Backup**: Exports configuration to Documents folder
- **Restore**: Imports configuration from backup file
- Useful before reinstalling or testing

### Uninstallation

- Double-click **`uninstall.bat`**
- Removes Windows Tasks and desktop shortcut
- Optionally deletes installation folder

## 🎮 Usage

### Initial Configuration

1. **Start Control Panel**
   - **With EXE**: Run `DeadMan.exe` → Select [1] GUI
   - **With Scripts**: Run `start.bat` or `DeadMan.ps1 -GUI`
2. **Set days**: Number of days without login (default: 30)
3. **Safe Mode**: ⚠️ **KEEP ENABLED** for testing!
4. **Add items**:
   - **Plain Data**: Regular files and folders
   - **VeraCrypt**: Encrypted containers and keyfiles
   - **BitLocker**: Drives (deletes recovery keys only)
5. **Save Configuration**: Click "Save Configuration"

### Tabs in Control Panel

#### 📄 Plain Data
- **Add Folder...**: Add folder to be deleted completely
- **Add File...**: Add individual files for deletion
- **Remove Selected**: Remove selected entry

#### 🔐 VeraCrypt
- **Add Container...**: VeraCrypt containers (.hc, .vc)
- **Add Keyfile...**: Keyfile files
- Will be deleted when triggered

#### 💾 BitLocker
- **Drive**: Enter drive letter (e.g., D:)
- **Add Volume**: Add drive
- Only deletes recovery keys, not the data!

### Testing in Safe Mode

1. Configure the system with **Safe Mode enabled**
2. Manual test (as Administrator):
   ```powershell
   cd C:\DeadMan
   .\scripts\selfdestruct-check.ps1 -ForceSafeMode
   ```
3. Check logs:
   ```powershell
   Get-Content .\logs\log.txt -Tail 50
   ```
4. In Safe Mode, **nothing is deleted**, only simulated!

### ⚠️ Disabling Safe Mode

**ONLY AFTER THOROUGH TESTING!**

1. Open Control Panel (`start.bat`)
2. Uncheck "Safe Mode (Simulation nur)"
3. Click "Save Configuration"
4. ⚠️ **System is now LIVE!**

## ⚙️ How It Works

### Scheduled Tasks

After installation, two Windows tasks run:

#### 1. DeadMan-UpdateLastLogin
- **Trigger**: On every user login
- **Action**: Updates `config\last_login.txt` with current date
- **Permissions**: User-level

#### 2. DeadMan-SelfDestructCheck
- **Trigger**: On every Windows startup
- **Action**: Checks if threshold exceeded → executes deletion if necessary
- **Permissions**: SYSTEM (highest privileges for deletion operations)

### Workflow

```
1. Windows starts
   ↓
2. Task "SelfDestructCheck" runs
   ↓
3. Reads last_login.txt
   ↓
4. Calculates difference to today
   ↓
5. If days >= threshold:
   ├─ Safe Mode: Simulation → Log
   └─ Live Mode: REAL DELETION!
```

## 📝 Configuration File

`config/config.json`:
```json
{
  "DaysWithoutLogin": 30,
  "SafeMode": true,
  "Executed": false,
  "ExecutedAt": null,
  "Items": [
    {
      "Type": "PlainFolder",
      "DeleteMode": "DeleteFolder",
      "Path": "C:\\SensitiveData"
    },
    {
      "Type": "VeraCryptContainer",
      "DeleteMode": "DeleteFile",
      "Path": "D:\\secret.hc"
    },
    {
      "Type": "BitLockerVolume",
      "DeleteMode": "DeleteRecoveryKeys",
      "Path": "",
      "Drive": "E:"
    }
  ]
}
```

## 🗑️ Deletion Modes

| Type | Description | Action |
|------|-------------|--------|
| `PlainFolder` | Regular folder | Deletes folder + contents recursively |
| `PlainFile` | Regular file | Deletes file |
| `VeraCryptContainer` | Encrypted container | Deletes container file |
| `VeraCryptKeyfile` | VeraCrypt keyfile | Deletes keyfile |
| `BitLockerVolume` | BitLocker drive | Deletes all recovery keys |

## 🔧 Manual Operations

### View Tasks
```powershell
# PowerShell
Get-ScheduledTask | Where-Object { $_.TaskName -like "DeadMan*" }

# Or open Task Scheduler
taskschd.msc
```
Tasks are in the **Root level** of Task Scheduler Library!

### Manual Test (Safe Mode)
```powershell
# As Administrator
cd C:\DeadMan
.\scripts\selfdestruct-check.ps1 -ForceSafeMode
```

### Check Last Login
```powershell
Get-Content C:\DeadMan\config\last_login.txt
```

### View Logs
```powershell
Get-Content C:\DeadMan\logs\log.txt -Tail 50
```

### Edit Config
```powershell
notepad C:\DeadMan\config\config.json
```

### Create Desktop Shortcut
```powershell
.\create-shortcut.ps1
```

## 🛡️ Security Considerations

- **Storage Location**: Keep this tool in a location only YOU can access
- **Encryption**: Use full-disk encryption (BitLocker/VeraCrypt) for maximum security
- **Config File**: Contains paths to sensitive data - protect it!
- **Admin Access**: Consider what happens if someone gains admin rights
- **Test Thoroughly**: Always test in Safe Mode before going live!
- **Backups**: Create backups of important data in secure locations
- **Plausible Deniability**: Safe Mode logs look convincing but don't actually delete

## 💡 Paranoia Tips

- **Multiple Layers**: Use this with full-disk encryption
- **Hidden Installation**: Install to a non-obvious location
- **Decoy Data**: Keep some "interesting" decoy files to make discovery less likely
- **Time-Delayed**: Set to 7-14 days for travel/emergencies
- **Test Runs**: Periodically test in Safe Mode to ensure it works
- **No Traces**: Consider what logs this leaves (Windows Event Log, etc.)
- **Offline Backups**: Keep important data on air-gapped offline storage

## ⚡ Uninstallation

### Via PowerShell (as Administrator)
```powershell
# Delete tasks
Unregister-ScheduledTask -TaskName "DeadMan-UpdateLastLogin" -Confirm:$false
Unregister-ScheduledTask -TaskName "DeadMan-SelfDestructCheck" -Confirm:$false

# Delete folder
Remove-Item -Path "C:\DeadMan" -Recurse -Force
```

### Manual
1. Open Task Scheduler (`taskschd.msc`)
2. Delete both tasks:
   - `DeadMan-UpdateLastLogin`
   - `DeadMan-SelfDestructCheck`
3. Delete the `C:\DeadMan` folder

## 🐛 Troubleshooting

### Task doesn't run
- Check Task Scheduler for errors
- Ensure script paths are correct
- Run PowerShell as Administrator

### GUI doesn't start
- Check PowerShell Execution Policy:
  ```powershell
  Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
  ```
- Right-click `start.bat` → "Run as administrator"

### Logs are empty
- Ensure `logs/` folder exists
- Check write permissions
- Run scripts as Administrator

### About dialog shows no GIF
- Ensure `bart.gif` is in root directory
- Check if file is corrupted
- Fallback: ASCII-Art Bart will be displayed

## 📜 License

MIT License - Use at your own risk!

## 🙏 Credits

- **Created by**: [iamrealguexoxo](https://github.com/iamrealguexoxo) 🎭
- **Inspiration**: BartsTOK and other projects
- **Dancing Bart**: The Simpsons © Fox

## 🤝 Contributing

Contributions are welcome! Please:
1. Test thoroughly
2. Keep Safe Mode as default
3. Document all changes
4. Consider security implications

## ⚠️ Legal Disclaimer

This tool is provided as-is without any warranty. The authors are not responsible for data loss or damage. Always test in Safe Mode and create backups of important data. Use responsibly and legally.

**This tool is for legitimate privacy and security purposes only.** Users are responsible for compliance with applicable laws.

---

**Enjoy Dead Man!** 💀🕺

*Remember: With great power comes great responsibility. Or something like that...* 😎

---

## 🌍 Languages

- **English**: This file
- **Deutsch**: [README_DE.md](README_DE.md)
