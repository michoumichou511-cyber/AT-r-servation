# fix_header_chap4.ps1 — Diagnose and fix Chapter IV header
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
    Write-Output "Sections: $($doc.Sections.Count)"

    $blue  = 10763008
    $green = 5285376
    $em = [char]0x2014

    # Diagnose all sections
    for ($s = 1; $s -le $doc.Sections.Count; $s++) {
        $sec = $doc.Sections.Item($s)
        $len = [Math]::Min(80, $sec.Range.Text.Length)
        $first = $sec.Range.Text.Substring(0, $len).Trim() -replace "`r",""  -replace "`n"," "
        $hdr = $sec.Headers.Item(1)
        $hdrText = $hdr.Range.Text.Trim()
        $linked = $hdr.LinkToPrevious
        Write-Output "  SEC $s : linked=$linked hdr='$hdrText' | start='$($first.Substring(0, [Math]::Min(60, $first.Length)))'"
    }

    # Now find section that contains CHAPITRE IV using Range.Find
    $rng = $doc.Content
    $f = $rng.Find
    $f.ClearFormatting()
    $f.Text = "CHAPITRE IV"
    $f.Forward = $true
    $f.Wrap = 0
    $f.MatchCase = $true
    if ($f.Execute()) {
        $secIndex = $rng.Information(10) # wdActiveEndSectionNumber
        Write-Output "`nCHAPITRE IV found in section $secIndex"

        $sec = $doc.Sections.Item($secIndex)
        $hdr = $sec.Headers.Item(1)
        $hdr.LinkToPrevious = $false
        $r = $hdr.Range
        $r.Text = "Chapitre IV $em R$([char]0xE9)alisation"
        $r.Font.Name = "Times New Roman"
        $r.Font.Size = 10
        $r.Font.Bold = $true
        $r.Font.Color = $blue
        $r.ParagraphFormat.Alignment = 1

        $b = $r.ParagraphFormat.Borders.Item(-3)
        $b.LineStyle = 1
        $b.LineWidth = 6
        $b.Color = $green

        Write-Output "Header set for CHAPITRE IV in section $secIndex"
    } else {
        Write-Output "CHAPITRE IV not found!"
    }

    # Also set Chapter I header (should be "Chapitre I — Étude Préalable")
    $rng2 = $doc.Content
    $f2 = $rng2.Find
    $f2.ClearFormatting()
    $f2.Text = "CHAPITRE I"
    $f2.Forward = $true
    $f2.Wrap = 0
    $f2.MatchCase = $true
    if ($f2.Execute()) {
        # Move past "CHAPITRE I" to avoid matching "CHAPITRE II/III/IV"
        $txt = $rng2.Text
        if ($txt -eq "CHAPITRE I") {
            $secIdx = $rng2.Information(10)
            Write-Output "`nCHAPITRE I found in section $secIdx"

            $sec1 = $doc.Sections.Item($secIdx)
            $hdr1 = $sec1.Headers.Item(1)
            $hdr1.LinkToPrevious = $false
            $r1 = $hdr1.Range
            $r1.Text = "Chapitre I $em $([char]0xC9)tude Pr$([char]0xE9)alable"
            $r1.Font.Name = "Times New Roman"
            $r1.Font.Size = 10
            $r1.Font.Bold = $true
            $r1.Font.Color = $blue
            $r1.ParagraphFormat.Alignment = 1

            $b1 = $r1.ParagraphFormat.Borders.Item(-3)
            $b1.LineStyle = 1
            $b1.LineWidth = 6
            $b1.Color = $green

            Write-Output "Header set for CHAPITRE I in section $secIdx"
        }
    }

    # Make sure separator pages (sections with just the chapter title) have empty headers
    # We need sections 0-16 (first pages, page de garde, TOC, intro) to have empty headers
    # Sections 1-5 should have empty header (page de garde, dedication, etc.)
    $firstSec = $doc.Sections.Item(1)
    $firstSec.Headers.Item(1).LinkToPrevious = $false
    $firstSec.Headers.Item(1).Range.Text = ""
    Write-Output "`nSection 1 header cleared (page de garde)"

    $doc.Save()
    Write-Output "`nSaved. Pages: $($doc.ComputeStatistics(2))"
    $doc.Close($false)
} catch {
    Write-Error "FAILED: $_"
} finally {
    if ($word) { try { $word.Quit() } catch {} }
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($word) | Out-Null
    [GC]::Collect(); [GC]::WaitForPendingFinalizers()
}
