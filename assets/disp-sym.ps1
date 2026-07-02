#    Display Symbols
#    Copyright (C) 2025 Noverse
#
#    This program is proprietary software: you may not copy, redistribute, or modify
#    it in any way without prior written permission from Noverse.
#
#    Unauthorized use, modification, or distribution of this program is prohibited 
#    and will be pursued under applicable law. This software is provided "as is," 
#    without warranty of any kind, express or implied, including but not limited to 
#    the warranties of merchantability, fitness for a particular purpose, and 
#    non-infringement.
#
#    For permissions or inquiries, contact: https://discord.noverse.dev

$erroractionpreference = "silentlycontinue"
$progresspreference = "silentlycontinue"

if (!(Test-Path "$env:temp\Noverse.ico")) {iwr -uri "https://github.com/nohuto/nohuto/releases/download/Logo/Noverse.ico" -out "$env:temp\Noverse.ico"}
$dumpdir = "$env:localappdata\Noverse\Symbols"
if (!(Test-Path $dumpdir)) {New-Item -ItemType Directory -Path $dumpdir -Force | Out-Null}

function log {
    param ([string]$HighlightMessage, [string]$Message, [string]$Sequence = '',[ConsoleColor]$TimeColor = 'DarkGray', [ConsoleColor]$HighlightColor = 'White', [ConsoleColor]$MessageColor = 'White', [ConsoleColor]$SequenceColor = 'White')
    $timestamp = "[{0:HH:mm:ss}]" -f (Get-Date)

    function color($text, $color) {
        $logs.SelectionStart = $logs.Text.Length
        $logs.SelectionColor = [Drawing.Color]::$color
        $logs.AppendText($text)
    }

    color "$timestamp " $TimeColor
    color "$HighlightMessage " $HighlightColor
    color "$Message " $MessageColor
    color "$Sequence`r`n" $SequenceColor
    $logs.SelectionStart = $logs.Text.Length
    $logs.ScrollToCaret()
}

Add-Type -AssemblyName System.Windows.Forms, System.Drawing
Add-Type -TypeDefinition 'using System;using System.Runtime.InteropServices;public class WinAPI{[DllImport("user32.dll")]public static extern bool ShowWindow(IntPtr hWnd,int nCmdShow);}'

$inputf = [Drawing.Font]::new('Segoe UI', 10, [Drawing.FontStyle]::Regular)
$blue = [Drawing.Color]::CornflowerBlue
$gray = [Drawing.Color]::FromArgb(40,40,40)
$white = [Drawing.Color]::White
$boxempty = [Drawing.Color]::Transparent

$nvmain = [Windows.Forms.Form]@{
    Text = 'Noverse Symbols'
    Size = [Drawing.Size]::new(1305, 800)
    StartPosition = 'CenterScreen'
    BackColor = [Drawing.Color]::FromArgb(28, 28, 28)
    FormBorderStyle = 'Sizable'
    Icon = [Drawing.Icon]::ExtractAssociatedIcon("$env:temp\Noverse.ico")
    MinimumSize = [Drawing.Size]::new(600, 200)
}

$modulepanel = [Windows.Forms.Panel]@{
    Location = [Drawing.Point]::new(5, 35)
    Size = [Drawing.Size]::new(850, 721)
    BackColor = $gray
    BorderStyle = 'FixedSingle'
    AutoScroll = $true
}
$nvmain.Controls.Add($modulepanel)


$logspanel = [Windows.Forms.Panel]@{
    Location = [Drawing.Point]::new(860, 35)
    Size = [Drawing.Size]::new(425, 721)
    BackColor = [Drawing.Color]::FromArgb(40, 40, 40)
    BorderStyle = 'FixedSingle'
}
$nvmain.Controls.Add($logspanel)

$logs = [Windows.Forms.RichTextBox]@{
    Multiline = $true
    ReadOnly = $true
    ScrollBars = [Windows.Forms.RichTextBoxScrollBars]::Vertical
    BackColor = [Drawing.Color]::FromArgb(40, 40, 40)
    ForeColor = $white
    Font = [Drawing.Font]::new('Consolas', 9)
    BorderStyle = 'None'
    Location = [Drawing.Point]::new(1, 1)
    Size = [Drawing.Size]::new(423, 714)
}
$logspanel.Controls.Add($logs)

if (-not (Get-Variable memDisplay -Scope Script -ErrorAction SilentlyContinue)) { $script:memDisplay = 'dd' }
if (-not (Get-Variable memLength  -Scope Script -ErrorAction SilentlyContinue)) { $script:memLength = 1 }

$cmbMemDisp = [Windows.Forms.ComboBox]@{
    DropDownStyle = 'DropDownList'
    Location = [Drawing.Point]::new($nvmain.Right - 835, 5)
    BackColor = [Drawing.Color]::FromArgb(50,50,50)
    ForeColor = $white
    FlatStyle = 'Flat'
    Font = [Drawing.Font]::new('Segoe UI', 10, [Drawing.FontStyle]::Regular)
    Size = [Drawing.Size]::new(80, 25)
}

$cmbMemDisp.Items.AddRange(@('d','da','db','dc','dd','dD','df','dp','dq','du','dw'))
$cmbMemDisp.SelectedItem = $script:memDisplay

$cmbMemDisp.Add_SelectedIndexChanged({
    $script:memDisplay = $cmbMemDisp.SelectedItem
    log "[~]" "Changed d* command to $script:memDisplay" -HighlightColor Gray
})

$lenpanel = [Windows.Forms.Panel]@{
    Location = [Drawing.Point]::new($nvmain.Right - 750, 5)
    Size = [Drawing.Size]::new(80, 25)
    BackColor = [Drawing.Color]::FromArgb(50,50,50)
    BorderStyle = 'FixedSingle'
}
$nvmain.Controls.Add($lenpanel)

$lenminus = [Windows.Forms.Label]@{
    Text = '-'
    Location = [Drawing.Point]::new(2, 0)
    ForeColor = 'Tomato'
    AutoSize = $true
    BackColor = $lenpanel.BackColor
    Font = [Drawing.Font]::new('Segoe UI', 11)
}
$lenpanel.Controls.Add($lenminus)

$lenbox = [Windows.Forms.TextBox]@{
    BorderStyle = 'None'
    BackColor = $lenpanel.BackColor
    ForeColor = $white
    Font = $inputf
    Location = [Drawing.Point]::new(18, 2)
    Size = [Drawing.Size]::new(40, 21)
    Text = "$script:memLength"
    TextAlign = 'Center'
}

$lenbox.Add_KeyPress({
    if (![char]::IsControl($_.KeyChar) -and ![char]::IsDigit($_.KeyChar)) {
        $_.Handled = $true
    }
})

$lenbox.Add_TextChanged({
    if ([int]::TryParse($lenbox.Text, [ref]([int]$null)) -and [int]$lenbox.Text -gt 0) {
        $script:memLength = [int]$lenbox.Text
    } else {
        $lenbox.Text = "1"
        $script:memLength = 1
    }
})
$lenpanel.Controls.Add($lenbox)

$lenplus = [Windows.Forms.Label]@{
    Text = '+'
    Location = [Drawing.Point]::new(62, 0)
    ForeColor = 'DarkSeaGreen'
    AutoSize = $true
    BackColor = $lenpanel.BackColor
    Font = [Drawing.Font]::new('Segoe UI', 11)
}
$lenpanel.Controls.Add($lenplus)

$lenminus.Add_Click({
    if ([int]::TryParse($lenbox.Text, [ref]$null)) {
        $value = [int]$lenbox.Text
        $lenbox.Text = [Math]::Max(1, $value - 1).ToString()
    } else {
        $lenbox.Text = '1'
    }
})

$lenplus.Add_Click({
    if ([int]::TryParse($lenbox.Text, [ref]$null)) {
        $value = [int]$lenbox.Text
        $lenbox.Text = [Math]::Min(1000, $value + 1).ToString()
    } else {
        $lenbox.Text = '1'
    }
})

$nvmain.Controls.AddRange(@($cmbMemDisp, $tbLen))

$searchbox = [Windows.Forms.TextBox]@{
    BorderStyle = 'FixedSingle'
    Multiline = $true
    Font = $inputf
    Location = [Drawing.Point]::new(5, 5)
    Size = [Drawing.Size]::new($modulepanel.Width / 4.25, 25)
    BackColor = [Drawing.Color]::FromArgb(50, 50, 50)
    ForeColor = $white
}
$nvmain.Controls.Add($searchbox)

$dump = [Windows.Forms.Button]@{
    Text = "Dump"
    Location = [Drawing.Point]::new($nvmain.Right - 100, 5)
    BackColor = [Drawing.Color]::FromArgb(50, 50, 50)
    ForeColor = $white
    FlatStyle = 'Flat'
    Size = [Drawing.Size]::new(80, 25)
    Font = $inputf
}
$dump.FlatAppearance.BorderColor = [Drawing.Color]::Gray
$dump.FlatAppearance.BorderSize = 1
$dump.Add_Click({
    if (-not $global:selectedBoxName) { log "[-]" "Select a module" -HighlightColor Red; return }
    $mod = $global:selectedBoxName
    log "[+]" "Using module $mod" -HighlightColor Green
    $moduledir = "$env:localappdata\Noverse\Symbols\${mod}"
    if (!(Test-Path $moduledir)) {New-Item -ItemType Directory -Path $moduledir -Force | Out-Null}

    $outsym = "$env:localappdata\Noverse\Symbols\${mod}\${mod}-Symbols.txt"

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    log "[~]" "Searching symbol names" -HighlightColor Gray
    & $kd -kl -c ".reload /f; .logopen `"$outsym`"; x /1 ${mod}!*; .logclose; q"
    if (-not (Test-Path $outsym)) { log "[!]" "No output file" -HighlightColor Red; return }

    $in = $outsym
    $out = "$env:localappdata\Noverse\Symbols\${mod}\${mod}-Filtered.txt"

    log "[~]" "First filter phase" -HighlightColor Gray
    $regsym = [regex]'(\S+![^\s(]+)'
    $regparen = [regex]'\s+\(.*$'
    $lines = [IO.File]::ReadAllLines($in)
    $lines = $lines[1..($lines.Length-2)]

    $sb = [Text.StringBuilder]::new()
    for ($i = 0; $i -lt $lines.Length; $i++) {
        $line = $lines[$i]

        if ($line -match '$mod!(?:_xmm|write_char|write_string|write_multi_char|chunkset_core|ReadString|\s\?\?)') { continue }

        $line = $line.Replace(' = <no type information>', '')
        $line = $regparen.Replace($line, '')

        $m = $regsym.Match($line)
        if (-not $m.Success) { continue }

        $sym = $m.Groups[1].Value
        $null = $sb.Append($script:memDisplay).Append(' ').Append($sym).Append(' l').AppendLine($script:memLength.ToString())
    }
    [IO.File]::WriteAllText($out, $sb.ToString())

    $outkd = "$env:localappdata\Noverse\Symbols\${mod}\${mod}-KD.txt"
    $kdcmd = '.reload /f;.logopen "{0}"; $$< "{1}"; .logclose; q' -f $outkd, $out
    $pscmd = "& '$kd' -kl -c '$kdcmd'"
    log "[*]" "KD output window minimized" -HighlightColor DarkCyan
    Start-Process powershell.exe -ArgumentList @('-Command', $pscmd) -WindowStyle Minimized -Wait

    log "[~]" "Second filter phase" -HighlightColor Gray
    $outfin = "$env:localappdata\Noverse\Symbols\${mod}\${mod}-Dump.txt"

    $regerror = [regex]'\berror\b'
    $readdr = [regex]'^[0-9A-Fa-f]{8}`[0-9A-Fa-f]{8}\s+'
    $regparen = [regex]' \([^)]*\)'
    $reglkd = [regex]('lkd> {0} {1}!' -f [regex]::Escape($script:memDisplay), [regex]::Escape($mod))
    $reglength = [regex]("(?i)\s+l{0}$" -f [regex]::Escape($script:memLength.ToString()))
    $regmatch = [regex]'^Matched:'
    $regendp = [regex]'\)+$'

    function Get-HexChunkWidth([string]$cmd) {
        switch -Regex ($cmd) {
            '^(db)$' { return 2 }
            '^(dw)$' { return 4 }
            '^(dd|dD|dc|d)$' { return 8 }
            '^(dq|dp)$' { return 16 }
            default { return 0 }
        }
    }

    $chunkWidth = Get-HexChunkWidth $script:memDisplay

    if ($chunkWidth -gt 0) {
        $chunkPattern = "[0-9A-Fa-f?]{$chunkWidth}"
        $regHexLine = [regex]("^(?:$chunkPattern)(?:\s+$chunkPattern){0,3}$")
        function Get-ChunkCount([string]$line, [string]$chunk) {
            return ([regex]::Matches($line, $chunk)).Count
        }
    } else {
        $regHexLine = [regex]"^\b$"
        function Get-ChunkCount([string]$line, [string]$chunk) { return 0 }
    }

    $lines = [IO.File]::ReadAllLines($outkd)
    $lines = $lines[1..($lines.Length-2)]

    $lstout = [System.Collections.Generic.List[string]]::new()
    $prev = $null
    $chunksCollected = 0
    $chunksNeeded = [Math]::Max(1, $script:memLength)

    $lstout = [System.Collections.Generic.List[string]]::new()
    $prev = $null
    $chunksCollected = 0
    $chunksNeeded = [Math]::Max(1, $script:memLength)
    $haveSep = $false

    foreach ($raw in $lines) {
        $clean = $readdr.Replace($raw, '')
        $clean = $regparen.Replace($clean, '')
        $clean = $reglkd.Replace($clean, '')
        $clean = $reglength.Replace($clean, '')
        $clean = $regendp.Replace($clean, '')

        if ($regerror.IsMatch($clean) -or $regmatch.IsMatch($clean)) {
            $prev = $null
            $chunksCollected = 0
            $haveSep = $false
            continue
        }

        if ($null -ne $prev -and $chunkWidth -gt 0 -and $regHexLine.IsMatch($clean) -and $chunksCollected -lt $chunksNeeded) {
            if (-not $haveSep) {
                $prev = "$prev <> $clean"
                $haveSep = $true
            } else {
                $prev = "$prev $clean"
            }
            $chunksCollected += Get-ChunkCount $clean $chunkPattern
            continue
        }

        if ($null -ne $prev) { $lstout.Add($prev) }

        $prev = $clean
        $chunksCollected = 0
        $haveSep = $false
        if ($chunkWidth -gt 0 -and $regHexLine.IsMatch($clean)) {
            $chunksCollected = Get-ChunkCount $clean $chunkPattern
        }
    }

    if ($null -ne $prev) { $lstout.Add($prev) }



    $sortdump = $lstout | Sort-Object
    [IO.File]::WriteAllLines($outfin, $sortdump)

    $sw.Stop()
    log "[+]" "$($sw.Elapsed.TotalSeconds) seconds" -HighlightColor Green
})


$discord = [Windows.Forms.Button]@{
    Text = "Discord"
    Location = [Drawing.Point]::new($nvmain.Right - 665, 5)
    BackColor = [Drawing.Color]::FromArgb(50, 50, 50)
    ForeColor = $white
    FlatStyle = 'Flat'
    Size = [Drawing.Size]::new(80, 25)
    Font = $inputf
}
$discord.FlatAppearance.BorderColor = [Drawing.Color]::Gray
$discord.FlatAppearance.BorderSize = 1
$discord.Add_Click({ 
    log "[~]" "Opening link" -HighlightColor Gray
    Start-Process "https://discord.gg/E2ybG4j9jU" 
})

$phasefolder = [Windows.Forms.Button]@{
    Text = "Phase Folder"
    Location = [Drawing.Point]::new($nvmain.Right - 205, 5)
    BackColor = [Drawing.Color]::FromArgb(50, 50, 50)
    ForeColor = $white
    FlatStyle = 'Flat'
    Size = [Drawing.Size]::new(100, 25)
    Font = $inputf
}
$phasefolder.FlatAppearance.BorderColor = [Drawing.Color]::Gray
$phasefolder.FlatAppearance.BorderSize = 1
$phasefolder.Add_Click({
    log "[~]" "Opening folder" -HighlightColor Gray
    $dumpdir = "$env:localappdata\Noverse\Symbols"
    Start-Process $dumpdir
})

$reload = [Windows.Forms.Button]@{
    Text = "Reload Modules"
    Location = [Drawing.Point]::new($nvmain.Right - 330, 5)
    BackColor = [Drawing.Color]::FromArgb(50, 50, 50)
    ForeColor = $white
    FlatStyle = 'Flat'
    Size = [Drawing.Size]::new(120, 25)
    Font = $inputf
}
$reload.FlatAppearance.BorderColor = [Drawing.Color]::Gray
$reload.FlatAppearance.BorderSize = 1
$reload.Add_Click({reload})

$remdumps = [Windows.Forms.Button]@{
    Text = "Remove Dumps"
    Location = [Drawing.Point]::new($nvmain.Right - 455, 5)
    BackColor = [Drawing.Color]::FromArgb(50, 50, 50)
    ForeColor = $white
    FlatStyle = 'Flat'
    Size = [Drawing.Size]::new(120, 25)
    Font = $inputf
}
$remdumps.FlatAppearance.BorderColor = [Drawing.Color]::Gray
$remdumps.FlatAppearance.BorderSize = 1
$remdumps.Add_Click({
    log "[~]" "Removing folders" -HighlightColor Gray
    Get-ChildItem -Path $dumpdir -Directory | Remove-Item -Recurse -Force
})

$kdsession = [Windows.Forms.Button]@{
    Text = "New KD Session"
    Location = [Drawing.Point]::new($nvmain.Right - 580, 5)
    BackColor = [Drawing.Color]::FromArgb(50, 50, 50)
    ForeColor = $white
    FlatStyle = 'Flat'
    Size = [Drawing.Size]::new(120, 25)
    Font = $inputf
}
$kdsession.FlatAppearance.BorderColor = [Drawing.Color]::Gray
$kdsession.FlatAppearance.BorderSize = 1
$kdsession.Add_Click({
    log "[~]" "Starting new kernel debugging session" -HighlightColor Gray
    Start-Process "$kd" -Verb RunAs -ArgumentList '-kl'
})

$nvmain.Controls.AddRange(@($dump,$discord,$phasefolder,$reload,$kdsession,$remdumps))

function kdpath {
    $roots = @(
        "$env:ProgramFiles\Windows Kits",
        "${env:ProgramFiles(x86)}\Windows Kits",
        "$env:ProgramFiles\WindowsApps\Microsoft.WinDbg_*_x64__8wekyb3d8bbwe"
    )
    $kd = foreach ($root in $roots) {
        Get-ChildItem -Path $root -Recurse -Filter kd.exe |
            Where-Object { $_.FullName -match '\\(x64|amd64)\\kd\.exe$' }
    }
    $kd | Sort-Object LastWriteTime -Descending | Select-Object -ExpandProperty FullName -First 1
}
$kd = kdpath

if (!($kd)) {
    $ans = [System.Windows.Forms.MessageBox]::Show("KD not found. Install KD (WinDbg) now via scoop/winget?", "KD not found", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)

    if ($ans -eq [System.Windows.Forms.DialogResult]::Yes) {

        if (!(Get-Command scoop)) {
            Write-Host "Installing Scoop"
            try {
                iwr get.scoop.sh -OutFile "$env:temp\Scoop.ps1"; powershell -File "$env:temp\Scoop.ps1" -RunAsAdmin -Wait
            } catch {
                [System.Windows.Forms.MessageBox]::Show("Could not install Scoop.", "Scoop Installer Failed", 'OK', 'Warning') | Out-Null
            }
        }

        if (!(Get-Command winget)) {
            Write-Host "Installing Winget"
            try {
                Start-Process powershell.exe -Verb RunAs -Wait -ArgumentList @('scoop install winget')
            } catch {
                [System.Windows.Forms.MessageBox]::Show("Could not install Winget.", "Winget Installer Failed", 'OK', 'Warning') | Out-Null
            }
        }

        if (Get-Command winget) {
            Write-Host "Installing WinDbg"
            try {
                Start-Process powershell.exe -Verb RunAs -Wait -ArgumentList @('winget install Microsoft.WinDbg --accept-package-agreements --accept-source-agreements')
            } catch {
                [System.Windows.Forms.MessageBox]::Show("Could not install WinDbg.", "WinDbg Installer Failed", 'OK', 'Warning') | Out-Null
            }
        }

        if (!($kd)) {
            [System.Windows.Forms.MessageBox]::Show("KD still not found", "KD not found", 'OK', 'Warning') | Out-Null
        }
    } else {
        exit
    }
}

$debugyes = $null -ne (bcdedit /enum | Select-String "debug" | Where-Object { $_ -match "Yes" })
if (!($debugyes)) {
    $ans = [System.Windows.Forms.MessageBox]::Show(
        "Kernel debugging is disabled. Enable kernel debugger for the current boot entry?",
        "Kernel Debugger",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    )
    if ($ans -eq [System.Windows.Forms.DialogResult]::Yes) {
        try {
            Start-Process bcdedit -Verb RunAs -Wait -ArgumentList '/debug','on'
            $restartans = [System.Windows.Forms.MessageBox]::Show(
                "Kernel debugger enabled. A system restart is required, restart now?",
                "Restart Required",
                [System.Windows.Forms.MessageBoxButtons]::YesNo,
                [System.Windows.Forms.MessageBoxIcon]::Question
            )
            if ($restartans -eq [System.Windows.Forms.DialogResult]::Yes) {
                Start-Process shutdown -ArgumentList '/r', '/t', '0' -Verb RunAs
            } else { exit }
        } catch {
            [System.Windows.Forms.MessageBox]::Show(
                "Failed to enable debugging: $($_.Exception.Message)",
                "Error",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Error
            ) | Out-Null
        }
    } else { exit }
}

function modulelist {
    param([string]$filter)

    $filterstring = if ($null -ne $filter) { $filter.Trim() } else { "" }
    if ([string]::IsNullOrWhiteSpace($filterstring)) { $filterstring = "" }

    $names = if ($filterstring -eq "") { $script:modules } else { $script:modules | Where-Object { $_ -like "*$filterstring*" } }

    for ($i = $modulepanel.Controls.Count - 1; $i -ge 0; $i--) {
        $c = $modulepanel.Controls[$i]
        if ($c.Tag -and ($c.Tag.Kind -in @('mod','grid'))) { $modulepanel.Controls.RemoveAt($i); $c.Dispose() }
    }

    $padx = 10
    $pady = 8
    $rowh = 22
    $boxgap = 35
    $panelw = [Math]::Max(0, $modulepanel.ClientSize.Width)

    $mincolw = 180
    $maxcolw = 320
    $maxcols = 8
    $colamount = [Math]::Max(1, [Math]::Min($maxcols, [Math]::Floor( ($panelw - $padx) / ($mincolw + $padx))))
    if ($colamount -lt 1) { $colamount = 1 }

    $colw = if ($colamount -gt 0) { [Math]::Floor( ($panelw - (($colamount + 1) * $padx)) / $colamount ) } else { $panelw - (2 * $padx) }
    $colw = [Math]::Max($mincolw, [Math]::Min($maxcolw, $colw))
    $labelbw = [Math]::Max(10, $colw - $boxgap)

    $modulepanel.SuspendLayout()
    for ($i = 0; $i -lt $names.Count; $i++) {
        $name = $names[$i]
        $col = $i % $colamount
        $row = [math]::Floor($i / $colamount)

        $x = $padx + ($col * ($colw + $padx))
        $y = $pady + ($row * ($rowh + $pady))

        $box = New-Object Windows.Forms.Panel
        $box.Size = [Drawing.Size]::new(13,13)
        $box.Location = [Drawing.Point]::new($x, $y)
        $box.BackColor = $boxempty
        $box.BorderStyle = 'FixedSingle'
        $box.Tag = @{ Kind='mod'; Name=$name; Checked=$false }

        $label = New-Object Windows.Forms.Label
        $label.Text = $name
        $label.ForeColor = $white
        $label.BackColor = $boxempty
        $label.Location = [Drawing.Point]::new($x + 20, $y - 2)
        $label.AutoSize = $true
        if ($names.Count -eq 1) {
            $available = $modulepanel.ClientSize.Width - ($label.Location.X + $padx)
            $label.Width = [Math]::Max(10, $available)
        } else {
            $label.Width = $labelbw
        }
        $label.AutoEllipsis = $true
        $label.Font = [Drawing.Font]::new('Segoe UI', 9, [Drawing.FontStyle]::Regular)
        $label.Tag = @{ Kind='mod'; Name=$name }

        if ($global:selectedBoxName -and $name -eq $global:selectedBoxName) {
            $box.Tag.Checked = $true
            $box.BackColor = $blue
            $script:selectedBox = $box
        }

        $currentb = $box
        $panel = $modulepanel
        $cblue = $blue
        $cempty = $boxempty
        $click = {
            if ($panel -and -not $panel.IsDisposed) {
                foreach ($ctrl in $panel.Controls) {
                    if ($ctrl -is [System.Windows.Forms.Panel] -and $ctrl.Tag -and $ctrl.Tag.Kind -eq 'mod') {
                        $ctrl.Tag.Checked = $false
                        $ctrl.BackColor = $cempty
                    }
                }
            }
            $currentb.Tag.Checked = $true
            $currentb.BackColor = $cblue
            $script:selectedBox = $currentb
            $global:selectedBoxName = $currentb.Tag.Name
        }.GetNewClosure()

        $box.Add_Click($click)
        $label.Add_Click($click)
        $modulepanel.Controls.AddRange(@($box, $label))
    }

    $gridc = [Drawing.Color]::FromArgb(80,80,80)
    $totrows = [math]::Ceiling(($names.Count) / $colamount)
    $reqh = $pady + ($totrows * ($rowh + $pady)) + $pady
    $fullh = [Math]::Max($modulepanel.ClientSize.Height, $reqh)

    for ($c = 0; $c -le $colamount; $c++) {
        $vx = ($padx * $c) + ($colw * $c)
        $v = New-Object Windows.Forms.Panel
        $v.BackColor = $gridc
        $v.Tag = @{ Kind='grid'; Axis='V' }
        $v.Width = 1
        $v.Height = $fullh
        $v.Location = [Drawing.Point]::new($vx, 0)
        $modulepanel.Controls.Add($v)
        $v.BringToFront()
    }

    for ($r = 0; $r -le $totrows; $r++) {
        $hy = ($pady + ($r * ($rowh + $pady))) - 8
        if ($hy -lt 0) { $hy = 0 }
        $h = New-Object Windows.Forms.Panel
        $h.BackColor = $gridc
        $h.Tag = @{ Kind='grid'; Axis='H' }
        $h.Height = 1
        $h.Width = [Math]::Max(0, $modulepanel.ClientSize.Width)
        $h.Location = [Drawing.Point]::new(0, $hy)
        $modulepanel.Controls.Add($h)
        $h.BringToFront()
    }



    $modulepanel.ResumeLayout($true)
    $modulepanel.AutoScrollMinSize = New-Object Drawing.Size(0, $reqh)
}

$searchbox.Add_TextChanged({ modulelist -Filter $searchbox.Text })


if (-not (Get-Variable loadertimer -Scope Script)) {
    $script:loadertimer = New-Object Windows.Forms.Timer
    $script:loadertimer.Interval = 400
    $script:loadertimer.Add_Tick({
        $job = $script:loadertimer.Tag
        if (-not $job) { return }

        if ($job.State -in @('Completed','Failed','Stopped')) {
            if ($job.State -eq 'Completed') {
                $result = Receive-Job $job
                $mods = @($result) | Where-Object { $_ -and $_ -ne '' }
                if ($mods.Count -gt 0) {
                    $script:modules = $mods
                    log "[+]" "Displaying loaded modules" -HighlightColor Green
                } else {
                    log "[-]" "No modules loaded" -HighlightColor Red
                }
            } else {
                log "[-]" "Module load job: $($job.State)" -HighlightColor Red
            }

            try { Remove-Job $job -Force } catch {}
            $script:loadertimer.Tag = $null
            $script:loadertimer.Stop()

            if (-not $nvmain.IsDisposed) { modulelist -Filter $searchbox.Text }
        }
    })
}

function reload {
    log "[~]" "Reloading modules" -HighlightColor Gray

    $job = Start-Job -ArgumentList $kd -ScriptBlock {
        param($kdPath)
        $modList = & "$kdPath" -kl -c ".reload /f; lm; q"
        $mods = $modList -split "`r?`n" | ForEach-Object { if ($_ -match '^\s*[0-9A-Fa-f`]+\s+[0-9A-Fa-f`]+\s+(\S+)') { $matches[1] } } | Sort-Object -Unique
        $mods
    }

    $script:loadertimer.Tag = $job
    $script:loadertimer.Stop()
    $script:loadertimer.Start()
}


$script:reflowtimer = New-Object Windows.Forms.Timer
$script:reflowtimer.Interval = 200
$script:reflowtimer.Add_Tick({
    $script:reflowtimer.Stop()
    if (-not $nvmain.IsDisposed) { modulelist -Filter $searchbox.Text }
})

$nvmain.Add_Resize({
    $m = 5
    $clientW = $nvmain.ClientSize.Width
    $clientH = $nvmain.ClientSize.Height

    $totalW = [Math]::Max(0, $clientW - (3 * $m))
    $logW = [Math]::Max(200, [Math]::Floor($totalW * 0.33))
    $chkW = [Math]::Max(200, $totalW - $logW)

    $dump.Left = $clientW - 85
    $phasefolder.Left = $clientW - 190
    $reload.Left = $clientW - 315
    $remdumps.Left = $clientW - 440
    $kdsession.Left = $clientW - 565
    $discord.Left = $clientW - 650
    $lenpanel.Left = $clientW - 735
    $cmbMemDisp.Left = $clientW - 820

    $dump.Top = $m
    $phasefolder.Top = $m
    $reload.Top = $m
    $remdumps.Top = $m
    $kdsession.Top = $m
    $discord.Top = $m
    $lenpanel.Top = $m
    $cmbMemDisp.Top = $m

    $searchbox.Left = $m
    $searchbox.Top = $m
    $searchbox.Width = $chkW / 4.25

    $modulepanel.Left = $m
    $modulepanel.Top = $searchbox.Bottom + $m
    $modulepanel.Width = $chkW
    $modulepanel.Height = [Math]::Max(100, $clientH - $modulepanel.Top - $m)

    $logspanel.Width = $logW
    $logspanel.Left = $clientW - $m - $logspanel.Width
    $logspanel.Top = 35
    $logspanel.Height = [Math]::Max(100, $clientH - $logspanel.Top - $m)

    $logs.Left = 1
    $logs.Top = 1
    $logs.Width = [Math]::Max(0, $logspanel.ClientSize.Width  - 2)
    $logs.Height = [Math]::Max(0, $logspanel.ClientSize.Height - 2)

    $script:reflowtimer.Stop()
    $script:reflowtimer.Start()
})

reload
[WinAPI]::ShowWindow((gps -Id $PID).MainWindowHandle, 0)
$nvmain.Add_FormClosed({ Stop-Process -Id $PID })
[Windows.Forms.Application]::Run($nvmain)