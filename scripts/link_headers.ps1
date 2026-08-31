# link_headers.ps1 — Link orphan section headers to their chapter header
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

    # Section 7 should link to section 6 (Chapter I header)
    $doc.Sections.Item(7).Headers.Item(1).LinkToPrevious = $true
    Write-Output "Section 7: linked to Chapter I header"

    # Sections 8-17 should all link (they are Chapter I content)
    for ($s = 8; $s -le 17; $s++) {
        $doc.Sections.Item($s).Headers.Item(1).LinkToPrevious = $true
    }
    Write-Output "Sections 8-17: linked (Chapter I content)"

    # Section 20 should link to section 19 (Chapter III header)
    $doc.Sections.Item(20).Headers.Item(1).LinkToPrevious = $true
    Write-Output "Section 20: linked to Chapter III header"

    $doc.Save()

    # Final check
    Write-Output "`n=== FINAL HEADERS ==="
    for ($s = 1; $s -le $doc.Sections.Count; $s++) {
        $hdr = $doc.Sections.Item($s).Headers.Item(1)
        $hdrText = ""
        try { $hdrText = $hdr.Range.Text.Trim() } catch {}
        Write-Output "  SEC $s : linked=$($hdr.LinkToPrevious) hdr='$hdrText'"
    }

    Write-Output "`nPages: $($doc.ComputeStatistics(2))"
    $doc.Close($false)
    Write-Output "Done"
} catch {
    Write-Error "FAILED: $_"
} finally {
    if ($word) { try { $word.Quit() } catch {} }
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($word) | Out-Null
    [GC]::Collect(); [GC]::WaitForPendingFinalizers()
}
