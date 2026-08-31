# fix_all_headers.ps1 — Insert section break before CHAPITRE IV + set all headers
$ErrorActionPreference = "Stop"
Get-Process WINWORD -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
$resPath = "HKCU:\Software\Microsoft\Office\16.0\Word\Resiliency"
if (Test-Path $resPath) { Remove-Item $resPath -Recurse -Force -ErrorAction SilentlyContinue }

$filePath = "C:\Users\loulou\Downloads\Memoir_AT_Reservations_V7.docx"
$word = $null

try {
    $word = New-Object -ComObject Word.Application
    $word.Visible = $false
    $word.DisplayAlerts = 0
    $word.AutomationSecurity = 3

    $doc = $word.Documents.Open($filePath, $false, $false, $false)
    Write-Output "Opened. Sections before: $($doc.Sections.Count)"

    $blue  = 10763008
    $green = 5285376
    $em = [char]0x2014

    # ── Step 1: Insert section break before CHAPITRE IV ──
    $rng = $doc.Content
    $f = $rng.Find
    $f.ClearFormatting()
    $f.Text = "CHAPITRE IV"
    $f.Forward = $true
    $f.Wrap = 0
    $f.MatchCase = $true
    $f.MatchWholeWord = $true
    if ($f.Execute()) {
        $rng.Collapse(1)  # collapse to start
        $rng.InsertBreak(2)  # wdSectionBreakNextPage = 2
        Write-Output "Section break inserted before CHAPITRE IV"
    } else {
        Write-Output "WARNING: CHAPITRE IV not found for section break"
    }

    Write-Output "Sections after break: $($doc.Sections.Count)"

    # ── Step 2: Set headers for all chapter sections ──
    $chapterMap = @{
        "CHAPITRE I"   = "Chapitre I $em $([char]0xC9)tude Pr$([char]0xE9)alable"
        "CHAPITRE II"  = "Chapitre II $em Analyse et Sp$([char]0xE9)cification des Besoins"
        "CHAPITRE III" = "Chapitre III $em Conception de l'application"
        "CHAPITRE IV"  = "Chapitre IV $em R$([char]0xE9)alisation"
    }

    for ($s = 1; $s -le $doc.Sections.Count; $s++) {
        $sec = $doc.Sections.Item($s)
        $len = [Math]::Min(50, $sec.Range.Text.Length)
        $first = $sec.Range.Text.Substring(0, $len).Trim() -replace "`r","" -replace "`n"," "

        $matchedKey = $null
        foreach ($k in $chapterMap.Keys) {
            if ($first.StartsWith($k)) {
                # Make sure it's an exact match (CHAPITRE I should not match CHAPITRE II)
                if ($k -eq "CHAPITRE I" -and ($first.StartsWith("CHAPITRE II") -or $first.StartsWith("CHAPITRE III") -or $first.StartsWith("CHAPITRE IV"))) {
                    continue
                }
                $matchedKey = $k
                break
            }
        }

        if ($matchedKey) {
            $hdr = $sec.Headers.Item(1)
            $hdr.LinkToPrevious = $false
            $r = $hdr.Range
            $r.Text = $chapterMap[$matchedKey]
            $r.Font.Name = "Times New Roman"
            $r.Font.Size = 10
            $r.Font.Bold = $true
            $r.Font.Color = $blue
            $r.ParagraphFormat.Alignment = 1
            $b = $r.ParagraphFormat.Borders.Item(-3)
            $b.LineStyle = 1
            $b.LineWidth = 6
            $b.Color = $green
            $sec.Footers.Item(1).LinkToPrevious = $true
            Write-Output "  Header SET: section $s = $matchedKey"
        }

        if ($first.StartsWith("Conclusion G")) {
            $hdr = $sec.Headers.Item(1)
            $hdr.LinkToPrevious = $false
            $hdr.Range.Text = ""
            Write-Output "  Header CLEARED: section $s (Conclusion)"
        }
    }

    # ── Step 3: Clear headers on pre-content sections (page de garde, TOC, etc.) ──
    # Section 1 is page de garde — should have NO header
    $sec1 = $doc.Sections.Item(1)
    $sec1.Headers.Item(1).LinkToPrevious = $false
    $sec1.Headers.Item(1).Range.Text = ""

    # Sommaire section (around section 5) — should have NO header
    for ($s = 2; $s -le [Math]::Min(6, $doc.Sections.Count); $s++) {
        $sec = $doc.Sections.Item($s)
        $len = [Math]::Min(30, $sec.Range.Text.Length)
        $first = $sec.Range.Text.Substring(0, $len).Trim() -replace "`r","" -replace "`n"," "
        if ($first.StartsWith("Sommaire") -or $first.StartsWith("[Actualiser") -or $first.StartsWith("Liste des")) {
            $sec.Headers.Item(1).LinkToPrevious = $false
            $sec.Headers.Item(1).Range.Text = ""
            Write-Output "  Header CLEARED: section $s (TOC/Lists)"
        }
    }

    $doc.Save()
    $pages = $doc.ComputeStatistics(2)
    Write-Output "`nSaved. Pages: $pages"

    # Final diagnostic
    Write-Output "`n=== FINAL HEADERS ==="
    for ($s = 1; $s -le $doc.Sections.Count; $s++) {
        $sec = $doc.Sections.Item($s)
        $hdr = $sec.Headers.Item(1)
        $hdrText = ""
        try { $hdrText = $hdr.Range.Text.Trim() } catch {}
        $linked = $hdr.LinkToPrevious
        Write-Output "  SEC $s : linked=$linked hdr='$hdrText'"
    }

    $doc.Close($false)
    Write-Output "Done"
} catch {
    Write-Error "FAILED: $_"
} finally {
    if ($word) { try { $word.Quit() } catch {} }
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($word) | Out-Null
    [GC]::Collect(); [GC]::WaitForPendingFinalizers()
}
