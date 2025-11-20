# ===================================================================
# Dead Man Switch - GUI Control Panel
# ===================================================================
# Zweck: Grafisches Control Panel zur Konfiguration des 
#        Dead Man Switch Systems
# ===================================================================

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ===================================================================
# Globale Variablen
# ===================================================================
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Split-Path -Parent $scriptDir
$configPath = Join-Path $root "config\config.json"
$script:config = $null
$script:allItems = @()

# ===================================================================
# Config laden/erstellen
# ===================================================================
function Load-Config {
    if (Test-Path $configPath) {
        try {
            $script:config = Get-Content $configPath -Raw | ConvertFrom-Json
            
            # Items in Array konvertieren falls nötig
            if ($script:config.Items -is [System.Array]) {
                $script:allItems = @($script:config.Items)
            }
            else {
                $script:allItems = @()
            }
            
            return $true
        }
        catch {
            [System.Windows.Forms.MessageBox]::Show(
                "Fehler beim Laden der Config: $_",
                "Fehler",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Error
            )
            return $false
        }
    }
    else {
        # Default-Config erstellen
        $script:config = [PSCustomObject]@{
            DaysWithoutLogin = 30
            SafeMode         = $true
            Executed         = $false
            ExecutedAt       = $null
            Items            = @()
        }
        $script:allItems = @()
        return $true
    }
}

# ===================================================================
# Config speichern
# ===================================================================
function Save-Config {
    try {
        # Sicherstellen, dass config-Ordner existiert
        $configDir = Split-Path -Parent $configPath
        if (-not (Test-Path $configDir)) {
            New-Item -ItemType Directory -Path $configDir -Force | Out-Null
        }
        
        # Items aus allen ListViews sammeln
        $script:config.Items = $script:allItems
        
        # Als JSON speichern
        $script:config | ConvertTo-Json -Depth 5 | Set-Content $configPath -Force
        
        [System.Windows.Forms.MessageBox]::Show(
            "Konfiguration erfolgreich gespeichert!",
            "Erfolg",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
        return $true
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show(
            "Fehler beim Speichern der Config: $_",
            "Fehler",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
        return $false
    }
}

# ===================================================================
# ListView füllen
# ===================================================================
function Fill-ListView {
    param($listView, $itemType)
    
    $listView.Items.Clear()
    
    foreach ($item in $script:allItems) {
        $type = $item.Type
        
        # Prüfen ob Item zu diesem Tab gehört
        $matches = $false
        switch ($itemType) {
            "Plain" {
                $matches = ($type -eq "PlainFolder" -or $type -eq "PlainFile")
            }
            "VeraCrypt" {
                $matches = ($type -eq "VeraCryptContainer" -or $type -eq "VeraCryptKeyfile")
            }
            "BitLocker" {
                $matches = ($type -eq "BitLockerVolume")
            }
        }
        
        if ($matches) {
            $lvItem = New-Object System.Windows.Forms.ListViewItem($type)
            $lvItem.SubItems.Add($item.Path) | Out-Null
            # DeleteMode nur anzeigen wenn vorhanden
            $deleteMode = if ($item.PSObject.Properties['DeleteMode']) { $item.DeleteMode } else { "" }
            $lvItem.SubItems.Add($deleteMode) | Out-Null
            $lvItem.Tag = $item
            $listView.Items.Add($lvItem) | Out-Null
        }
    }
}

# ===================================================================
# Item hinzufügen
# ===================================================================
function Add-Item {
    param($type, $deleteMode, $path, $drive)
    
    $newItem = [PSCustomObject]@{
        Type       = $type
        DeleteMode = $deleteMode
        Path       = $path
    }
    
    if ($drive) {
        $newItem | Add-Member -NotePropertyName "Drive" -NotePropertyValue $drive
    }
    
    $script:allItems += $newItem
}

# ===================================================================
# Item entfernen
# ===================================================================
function Remove-Item-FromList {
    param($item)
    
    $script:allItems = @($script:allItems | Where-Object { 
        -not ($_.Type -eq $item.Type -and $_.Path -eq $item.Path) 
    })
}

# ===================================================================
# About Dialog mit tanzenden Barts
# ===================================================================
function Show-AboutDialog {
    $aboutForm = New-Object System.Windows.Forms.Form
    $aboutForm.Text = "About Dead Man - by iamrealguexoxo"
    $aboutForm.Size = New-Object System.Drawing.Size(500, 600)
    $aboutForm.StartPosition = "CenterParent"
    $aboutForm.FormBorderStyle = "FixedDialog"
    $aboutForm.MaximizeBox = $false
    $aboutForm.MinimizeBox = $false
    $aboutForm.BackColor = [System.Drawing.Color]::FromArgb(20, 20, 20)
    
    # Bart GIF PictureBox
    $picBart = New-Object System.Windows.Forms.PictureBox
    $picBart.Location = New-Object System.Drawing.Point(100, 20)
    $picBart.Size = New-Object System.Drawing.Size(300, 280)
    $picBart.SizeMode = "Zoom"
    $picBart.BackColor = [System.Drawing.Color]::Black
    
    $bartGifPath = Join-Path (Split-Path -Parent $scriptDir) "media\bart.gif"
    if (Test-Path $bartGifPath) {
        $picBart.Image = [System.Drawing.Image]::FromFile($bartGifPath)
    }
    $aboutForm.Controls.Add($picBart)
    
    # Fallback ASCII Art (falls GIF nicht gefunden)
    $bartFrames = @(
        @"
    _______________
   /               \
  |  ╔═══╗  ╔═══╗  |
  |  ║ ◉ ║  ║ ◉ ║  |
  |  ╚═══╝  ╚═══╝  |
  |                 |
  |    \______/    |
  |                 |
  |   {  BART  }   |
   \_______________ /
        |     |
        |     |
       /       \
      /         \
"@,
        @"
    _______________
   /               \
  |  ╔═══╗  ╔═══╗  |
  |  ║ ◉ ║  ║ ◉ ║  |
  |  ╚═══╝  ╚═══╝  |
  |                 |
  |    /‾‾‾‾‾‾\    |
  |                 |
  |   {  BART  }   |
   \_______________ /
        |     |
       /|     |\
      / |     | \
"@,
        @"
    _______________
   /               \
  |  ╔═══╗  ╔═══╗  |
  |  ║ ◉ ║  ║ ◉ ║  |
  |  ╚═══╝  ╚═══╝  |
  |                 |
  |    \_______/   |
  |                 |
  |   {  BART  }   |
   \_______________ /
       \|     |/
        |     |
        |     |
       /       \
"@
    )
    
    # Info Panel
    $panel = New-Object System.Windows.Forms.Panel
    $panel.Location = New-Object System.Drawing.Point(20, 310)
    $panel.Size = New-Object System.Drawing.Size(440, 200)
    $panel.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
    $aboutForm.Controls.Add($panel)
    
    # Title
    $lblTitle = New-Object System.Windows.Forms.Label
    $lblTitle.Text = "💀 DEAD MAN 💀"
    $lblTitle.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
    $lblTitle.ForeColor = [System.Drawing.Color]::Red
    $lblTitle.Location = New-Object System.Drawing.Point(10, 10)
    $lblTitle.Size = New-Object System.Drawing.Size(420, 30)
    $lblTitle.TextAlign = "MiddleCenter"
    $panel.Controls.Add($lblTitle)
    
    # Version
    $lblVersion = New-Object System.Windows.Forms.Label
    $lblVersion.Text = "Version 1.1 - GitHub Edition"
    $lblVersion.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $lblVersion.ForeColor = [System.Drawing.Color]::LightGray
    $lblVersion.Location = New-Object System.Drawing.Point(10, 45)
    $lblVersion.Size = New-Object System.Drawing.Size(420, 20)
    $lblVersion.TextAlign = "MiddleCenter"
    $panel.Controls.Add($lblVersion)
    
    # Description
    $lblDesc = New-Object System.Windows.Forms.Label
    $lblDesc.Text = "Automatic data destruction system`nthat triggers after X days without login.`n`n⚠️ USE AT YOUR OWN RISK! ⚠️"
    $lblDesc.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $lblDesc.ForeColor = [System.Drawing.Color]::White
    $lblDesc.Location = New-Object System.Drawing.Point(10, 70)
    $lblDesc.Size = New-Object System.Drawing.Size(420, 60)
    $lblDesc.TextAlign = "MiddleCenter"
    $panel.Controls.Add($lblDesc)
    
    # Creator
    $lblCreator = New-Object System.Windows.Forms.Label
    $lblCreator.Text = "Created by: iamrealguexoxo 🎭"
    $lblCreator.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $lblCreator.ForeColor = [System.Drawing.Color]::Cyan
    $lblCreator.Location = New-Object System.Drawing.Point(10, 135)
    $lblCreator.Size = New-Object System.Drawing.Size(420, 20)
    $lblCreator.TextAlign = "MiddleCenter"
    $panel.Controls.Add($lblCreator)
    
    # GitHub Link
    $linkGitHub = New-Object System.Windows.Forms.LinkLabel
    $linkGitHub.Text = "github.com/iamrealguexoxo"
    $linkGitHub.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $linkGitHub.LinkColor = [System.Drawing.Color]::DeepSkyBlue
    $linkGitHub.Location = New-Object System.Drawing.Point(10, 155)
    $linkGitHub.Size = New-Object System.Drawing.Size(420, 20)
    $linkGitHub.TextAlign = "MiddleCenter"
    $linkGitHub.Add_LinkClicked({
        Start-Process "https://github.com/iamrealguexoxo"
    })
    $panel.Controls.Add($linkGitHub)
    
    # Close Button
    $btnOK = New-Object System.Windows.Forms.Button
    $btnOK.Text = "OK"
    $btnOK.Location = New-Object System.Drawing.Point(175, 520)
    $btnOK.Size = New-Object System.Drawing.Size(150, 30)
    $btnOK.Add_Click({
        $aboutForm.Close()
    })
    $aboutForm.Controls.Add($btnOK)
    
    # Cleanup on close
    $aboutForm.Add_FormClosing({
        if ($picBart.Image) {
            $picBart.Image.Dispose()
        }
    })
    
    [void]$aboutForm.ShowDialog()
}

# ===================================================================
# GUI erstellen
# ===================================================================
function Show-GUI {
    # Main Form
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Dead Man - by iamrealguexoxo"
    $form.Size = New-Object System.Drawing.Size(720, 470)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = $false
    
    # -------------------------------------------------------------------
    # Oberer Bereich: Einstellungen
    # -------------------------------------------------------------------
    $lblDays = New-Object System.Windows.Forms.Label
    $lblDays.Text = "Days without login:"
    $lblDays.Location = New-Object System.Drawing.Point(20, 20)
    $lblDays.Size = New-Object System.Drawing.Size(150, 20)
    $form.Controls.Add($lblDays)
    
    $numDays = New-Object System.Windows.Forms.NumericUpDown
    $numDays.Location = New-Object System.Drawing.Point(180, 18)
    $numDays.Size = New-Object System.Drawing.Size(80, 20)
    $numDays.Minimum = 1
    $numDays.Maximum = 365
    $numDays.Value = $script:config.DaysWithoutLogin
    $form.Controls.Add($numDays)
    
    $chkSafeMode = New-Object System.Windows.Forms.CheckBox
    $chkSafeMode.Text = "Safe Mode (Simulation nur)"
    $chkSafeMode.Location = New-Object System.Drawing.Point(280, 18)
    $chkSafeMode.Size = New-Object System.Drawing.Size(200, 20)
    $chkSafeMode.Checked = $script:config.SafeMode
    $form.Controls.Add($chkSafeMode)
    
    # -------------------------------------------------------------------
    # TabControl
    # -------------------------------------------------------------------
    $tabControl = New-Object System.Windows.Forms.TabControl
    $tabControl.Location = New-Object System.Drawing.Point(10, 60)
    $tabControl.Size = New-Object System.Drawing.Size(680, 310)
    $form.Controls.Add($tabControl)
    
    # -------------------------------------------------------------------
    # Tab 1: Plain Data
    # -------------------------------------------------------------------
    $tabPlain = New-Object System.Windows.Forms.TabPage
    $tabPlain.Text = "Plain Data"
    $tabControl.TabPages.Add($tabPlain)
    
    $listViewPlain = New-Object System.Windows.Forms.ListView
    $listViewPlain.Location = New-Object System.Drawing.Point(10, 10)
    $listViewPlain.Size = New-Object System.Drawing.Size(660, 230)
    $listViewPlain.View = "Details"
    $listViewPlain.FullRowSelect = $true
    $listViewPlain.GridLines = $true
    $listViewPlain.Columns.Add("Typ", 150) | Out-Null
    $listViewPlain.Columns.Add("Pfad", 380) | Out-Null
    $listViewPlain.Columns.Add("DeleteMode", 110) | Out-Null
    $tabPlain.Controls.Add($listViewPlain)
    
    $btnAddPlainFolder = New-Object System.Windows.Forms.Button
    $btnAddPlainFolder.Text = "Add Folder..."
    $btnAddPlainFolder.Location = New-Object System.Drawing.Point(10, 250)
    $btnAddPlainFolder.Size = New-Object System.Drawing.Size(100, 30)
    $btnAddPlainFolder.Add_Click({
        $folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
        $folderDialog.Description = "Ordner zum Löschen auswählen"
        
        if ($folderDialog.ShowDialog() -eq "OK") {
            Add-Item -type "PlainFolder" -deleteMode "DeleteFolder" -path $folderDialog.SelectedPath
            Fill-ListView -listView $listViewPlain -itemType "Plain"
        }
    })
    $tabPlain.Controls.Add($btnAddPlainFolder)
    
    $btnAddPlainFile = New-Object System.Windows.Forms.Button
    $btnAddPlainFile.Text = "Add File..."
    $btnAddPlainFile.Location = New-Object System.Drawing.Point(120, 250)
    $btnAddPlainFile.Size = New-Object System.Drawing.Size(100, 30)
    $btnAddPlainFile.Add_Click({
        $fileDialog = New-Object System.Windows.Forms.OpenFileDialog
        $fileDialog.Title = "Datei zum Löschen auswählen"
        $fileDialog.Filter = "Alle Dateien (*.*)|*.*"
        
        if ($fileDialog.ShowDialog() -eq "OK") {
            Add-Item -type "PlainFile" -deleteMode "DeleteFile" -path $fileDialog.FileName
            Fill-ListView -listView $listViewPlain -itemType "Plain"
        }
    })
    $tabPlain.Controls.Add($btnAddPlainFile)
    
    $btnRemovePlain = New-Object System.Windows.Forms.Button
    $btnRemovePlain.Text = "Remove Selected"
    $btnRemovePlain.Location = New-Object System.Drawing.Point(230, 250)
    $btnRemovePlain.Size = New-Object System.Drawing.Size(120, 30)
    $btnRemovePlain.Add_Click({
        if ($listViewPlain.SelectedItems.Count -gt 0) {
            $selectedItem = $listViewPlain.SelectedItems[0]
            Remove-Item-FromList -item $selectedItem.Tag
            Fill-ListView -listView $listViewPlain -itemType "Plain"
        }
    })
    $tabPlain.Controls.Add($btnRemovePlain)
    
    # -------------------------------------------------------------------
    # Tab 2: VeraCrypt
    # -------------------------------------------------------------------
    $tabVeraCrypt = New-Object System.Windows.Forms.TabPage
    $tabVeraCrypt.Text = "VeraCrypt"
    $tabControl.TabPages.Add($tabVeraCrypt)
    
    $listViewVeraCrypt = New-Object System.Windows.Forms.ListView
    $listViewVeraCrypt.Location = New-Object System.Drawing.Point(10, 10)
    $listViewVeraCrypt.Size = New-Object System.Drawing.Size(660, 230)
    $listViewVeraCrypt.View = "Details"
    $listViewVeraCrypt.FullRowSelect = $true
    $listViewVeraCrypt.GridLines = $true
    $listViewVeraCrypt.Columns.Add("Typ", 150) | Out-Null
    $listViewVeraCrypt.Columns.Add("Pfad", 380) | Out-Null
    $listViewVeraCrypt.Columns.Add("DeleteMode", 110) | Out-Null
    $tabVeraCrypt.Controls.Add($listViewVeraCrypt)
    
    $btnAddVCContainer = New-Object System.Windows.Forms.Button
    $btnAddVCContainer.Text = "Add Container..."
    $btnAddVCContainer.Location = New-Object System.Drawing.Point(10, 250)
    $btnAddVCContainer.Size = New-Object System.Drawing.Size(120, 30)
    $btnAddVCContainer.Add_Click({
        $fileDialog = New-Object System.Windows.Forms.OpenFileDialog
        $fileDialog.Title = "VeraCrypt Container auswählen"
        $fileDialog.Filter = "VeraCrypt Container (*.hc;*.vc)|*.hc;*.vc|Alle Dateien (*.*)|*.*"
        
        if ($fileDialog.ShowDialog() -eq "OK") {
            Add-Item -type "VeraCryptContainer" -deleteMode "DeleteFile" -path $fileDialog.FileName
            Fill-ListView -listView $listViewVeraCrypt -itemType "VeraCrypt"
        }
    })
    $tabVeraCrypt.Controls.Add($btnAddVCContainer)
    
    $btnAddVCKeyfile = New-Object System.Windows.Forms.Button
    $btnAddVCKeyfile.Text = "Add Keyfile..."
    $btnAddVCKeyfile.Location = New-Object System.Drawing.Point(140, 250)
    $btnAddVCKeyfile.Size = New-Object System.Drawing.Size(120, 30)
    $btnAddVCKeyfile.Add_Click({
        $fileDialog = New-Object System.Windows.Forms.OpenFileDialog
        $fileDialog.Title = "VeraCrypt Keyfile auswählen"
        $fileDialog.Filter = "Alle Dateien (*.*)|*.*"
        
        if ($fileDialog.ShowDialog() -eq "OK") {
            Add-Item -type "VeraCryptKeyfile" -deleteMode "DeleteFile" -path $fileDialog.FileName
            Fill-ListView -listView $listViewVeraCrypt -itemType "VeraCrypt"
        }
    })
    $tabVeraCrypt.Controls.Add($btnAddVCKeyfile)
    
    $btnRemoveVC = New-Object System.Windows.Forms.Button
    $btnRemoveVC.Text = "Remove Selected"
    $btnRemoveVC.Location = New-Object System.Drawing.Point(270, 250)
    $btnRemoveVC.Size = New-Object System.Drawing.Size(120, 30)
    $btnRemoveVC.Add_Click({
        if ($listViewVeraCrypt.SelectedItems.Count -gt 0) {
            $selectedItem = $listViewVeraCrypt.SelectedItems[0]
            Remove-Item-FromList -item $selectedItem.Tag
            Fill-ListView -listView $listViewVeraCrypt -itemType "VeraCrypt"
        }
    })
    $tabVeraCrypt.Controls.Add($btnRemoveVC)
    
    # -------------------------------------------------------------------
    # Tab 3: BitLocker
    # -------------------------------------------------------------------
    $tabBitLocker = New-Object System.Windows.Forms.TabPage
    $tabBitLocker.Text = "BitLocker"
    $tabControl.TabPages.Add($tabBitLocker)
    
    $listViewBitLocker = New-Object System.Windows.Forms.ListView
    $listViewBitLocker.Location = New-Object System.Drawing.Point(10, 10)
    $listViewBitLocker.Size = New-Object System.Drawing.Size(660, 230)
    $listViewBitLocker.View = "Details"
    $listViewBitLocker.FullRowSelect = $true
    $listViewBitLocker.GridLines = $true
    $listViewBitLocker.Columns.Add("Typ", 150) | Out-Null
    $listViewBitLocker.Columns.Add("Laufwerk", 380) | Out-Null
    $listViewBitLocker.Columns.Add("DeleteMode", 110) | Out-Null
    $tabBitLocker.Controls.Add($listViewBitLocker)
    
    $lblBLDrive = New-Object System.Windows.Forms.Label
    $lblBLDrive.Text = "Laufwerk:"
    $lblBLDrive.Location = New-Object System.Drawing.Point(10, 255)
    $lblBLDrive.Size = New-Object System.Drawing.Size(70, 20)
    $tabBitLocker.Controls.Add($lblBLDrive)
    
    $txtBLDrive = New-Object System.Windows.Forms.TextBox
    $txtBLDrive.Location = New-Object System.Drawing.Point(80, 252)
    $txtBLDrive.Size = New-Object System.Drawing.Size(40, 20)
    $txtBLDrive.MaxLength = 2
    $txtBLDrive.Text = "D:"
    $tabBitLocker.Controls.Add($txtBLDrive)
    
    $btnAddBL = New-Object System.Windows.Forms.Button
    $btnAddBL.Text = "Add Volume"
    $btnAddBL.Location = New-Object System.Drawing.Point(130, 250)
    $btnAddBL.Size = New-Object System.Drawing.Size(100, 30)
    $btnAddBL.Add_Click({
        $drive = $txtBLDrive.Text.Trim()
        if ($drive -match "^[A-Z]:?$") {
            if ($drive -notmatch ":$") {
                $drive += ":"
            }
            Add-Item -type "BitLockerVolume" -deleteMode "DeleteRecoveryKeys" -path "" -drive $drive
            Fill-ListView -listView $listViewBitLocker -itemType "BitLocker"
            $txtBLDrive.Text = "D:"
        }
        else {
            [System.Windows.Forms.MessageBox]::Show(
                "Bitte geben Sie einen gültigen Laufwerksbuchstaben ein (z.B. D: oder E:)",
                "Ungültige Eingabe",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            )
        }
    })
    $tabBitLocker.Controls.Add($btnAddBL)
    
    $btnRemoveBL = New-Object System.Windows.Forms.Button
    $btnRemoveBL.Text = "Remove Selected"
    $btnRemoveBL.Location = New-Object System.Drawing.Point(240, 250)
    $btnRemoveBL.Size = New-Object System.Drawing.Size(120, 30)
    $btnRemoveBL.Add_Click({
        if ($listViewBitLocker.SelectedItems.Count -gt 0) {
            $selectedItem = $listViewBitLocker.SelectedItems[0]
            Remove-Item-FromList -item $selectedItem.Tag
            Fill-ListView -listView $listViewBitLocker -itemType "BitLocker"
        }
    })
    $tabBitLocker.Controls.Add($btnRemoveBL)
    
    # -------------------------------------------------------------------
    # Buttons unten
    # -------------------------------------------------------------------
    $btnSave = New-Object System.Windows.Forms.Button
    $btnSave.Text = "Save Configuration"
    $btnSave.Location = New-Object System.Drawing.Point(400, 385)
    $btnSave.Size = New-Object System.Drawing.Size(140, 35)
    $btnSave.Add_Click({
        $script:config.DaysWithoutLogin = $numDays.Value
        $script:config.SafeMode = $chkSafeMode.Checked
        Save-Config
    })
    $form.Controls.Add($btnSave)
    
    $btnAbout = New-Object System.Windows.Forms.Button
    $btnAbout.Text = "About"
    $btnAbout.Location = New-Object System.Drawing.Point(250, 385)
    $btnAbout.Size = New-Object System.Drawing.Size(140, 35)
    $btnAbout.Add_Click({
        Show-AboutDialog
    })
    $form.Controls.Add($btnAbout)
    
    $btnClose = New-Object System.Windows.Forms.Button
    $btnClose.Text = "Close"
    $btnClose.Location = New-Object System.Drawing.Point(550, 385)
    $btnClose.Size = New-Object System.Drawing.Size(140, 35)
    $btnClose.Add_Click({
        $form.Close()
    })
    $form.Controls.Add($btnClose)
    
    # ListViews mit Daten füllen
    Fill-ListView -listView $listViewPlain -itemType "Plain"
    Fill-ListView -listView $listViewVeraCrypt -itemType "VeraCrypt"
    Fill-ListView -listView $listViewBitLocker -itemType "BitLocker"
    
    # Form anzeigen
    $form.Add_Shown({$form.Activate()})
    [void]$form.ShowDialog()
}

# ===================================================================
# Hauptprogramm
# ===================================================================
if (Load-Config) {
    Show-GUI
}
