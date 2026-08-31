# headers_v7.ps1 — Set chapter-specific headers on Memoir V7
# Uses Word COM Range.Find (no Selection, no hanging)
$ErrorActionPreference = "Stop"

# Kill any lingering Word processes
Get-Process WINWORD -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

# Clear Word crash recovery
$resPath = "HKCU:\Software\Microsoft\Office\16.0\Word\Resiliency"
if (Test-Path $resPath) {
    Remove-Item $resPath -Recurse -Force -ErrorAction SilentlyContinue
    Write-Output "Cleared Word crash recovery registry"
}

# Clean lock files
Get-ChildItem "C:\Users\loulou\Downloads\~$*" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue

$filePath = "C:\Users\loulou\Downloads\Memoir_AT_Reservations_V7.docx"
$word = $null

try {
    $word = New-Object -ComObject Word.Application
    $word.Visible = $false
    $word.DisplayAlerts = 0
    $word.AutomationSecurity = 3
    Write-Output "Word COM started"

    $doc = $word.Documents.Open($filePath, $false, $false, $false)
    Write-Output "Document opened, sections: $($doc.Sections.Count)"

    $blue  = 10763008    # BGR for #003DA5
    $green = 5285376     # BGR for #00A650
    $em = [char]0x2014   # em dash

    # Map of chapter text prefixes to their header text
    $chapterHeaders = @{
        "CHAPITRE II"  = "Chapitre II $em Analyse et Sp$([char]0xE9)cification des Besoins"
        "CHAPITRE III" = "Chapitre III $em Conception de l'application"
        "CHAPITRE IV"  = "Chapitre IV $em R$([char]0xE9)alisation"
    }

    # Identify which section each chapter starts in
    for ($s = 1; $s -le $doc.Sections.Count; $s++) {
        $sec = $doc.Sections.Item($s)
        $len = [Math]::Min(60, $sec.Range.Text.Length)
        $first = $sec.Range.Text.Substring(0, $len).Trim()

        $matchedKey = $null
        foreach ($k in $chapterHeaders.Keys) {
            if ($first.StartsWith($k)) {
                $matchedKey = $k
                break
            }
        }

        if ($matchedKey) {
            # This section starts with a chapter separator — set header for this section
            $hdr = $sec.Headers.Item(1)  # wdHeaderFooterPrimary
            $hdr.LinkToPrevious = $false
            $r = $hdr.Range
            $r.Text = $chapterHeaders[$matchedKey]
            $r.Font.Name = "Times New Roman"
            $r.Font.Size = 10
            $r.Font.Bold = $true
            $r.Font.Color = $blue
            $r.ParagraphFormat.Alignment = 1  # center

            # Green bottom border
            $b = $r.ParagraphFormat.Borders.Item(-3)  # wdBorderBottom
            $b.LineStyle = 1  # single
            $b.LineWidth = 6
            $b.Color = $green

            $sec.Footers.Item(1).LinkToPrevious = $true
            Write-Output "Header set: section $s = $matchedKey"
        }

        # Conclusion — empty header
        if ($first.StartsWith("Conclusion G")) {
            $hdr = $sec.Headers.Item(1)
            $hdr.LinkToPrevious = $false
            $hdr.Range.Text = ""
            Write-Output "Header cleared: section $s (Conclusion)"
        }

        # Bibliographie — empty header
        if ($first.StartsWith("Bibliographie")) {
            $hdr = $sec.Headers.Item(1)
            $hdr.LinkToPrevious = $false
            $hdr.Range.Text = ""
            Write-Output "Header cleared: section $s (Bibliographie)"
        }
    }

    $doc.Save()
    Write-Output "Saved. Pages: $($doc.ComputeStatistics(2))"
    $doc.Close($false)
    Write-Output "Done"
} catch {
    Write-Error "FAILED: $_"
} finally {
    if ($word) {
        try { $word.Quit() } catch {}
    }
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($word) | Out-Null
    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
}
