# export_pdf_v7.ps1 — Export V7 to PDF via Word COM
$ErrorActionPreference = "Stop"
Get-Process WINWORD -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
$resPath = "HKCU:\Software\Microsoft\Office\16.0\Word\Resiliency"
if (Test-Path $resPath) { Remove-Item $resPath -Recurse -Force -ErrorAction SilentlyContinue }

$docPath = "C:\Users\loulou\Downloads\Memoir_AT_Reservations_V7.docx"
$pdfPath = "C:\Users\loulou\Downloads\Memoir_AT_Reservations_V7.pdf"

$word = $null
try {
    $word = New-Object -ComObject Word.Application
    $word.Visible = $false
    $word.DisplayAlerts = 0
    $word.AutomationSecurity = 3

    $doc = $word.Documents.Open($docPath, $false, $true, $false)
    Write-Output "Opened. Pages: $($doc.ComputeStatistics(2))"

    # Verify headers on chapter separator pages
    Write-Output "`n=== Header verification ==="
    $targets = @("CHAPITRE I", "CHAPITRE II", "CHAPITRE III", "CHAPITRE IV")
    foreach ($t in $targets) {
        $rng = $doc.Content
        $f = $rng.Find
        $f.ClearFormatting()
        $f.Text = $t
        $f.Forward = $true
        $f.Wrap = 0
        $f.MatchCase = $true
        $f.MatchWholeWord = $true
        if ($f.Execute()) {
            $pageNum = $rng.Information(3) # wdActiveEndPageNumber
            $secNum = $rng.Information(10) # wdActiveEndSectionNumber
            # Get the header of this section's first page
            $sec = $doc.Sections.Item($secNum)
            $firstHdr = ""
            try {
                $firstHdr = $sec.Headers.Item(3).Range.Text.Trim() # wdHeaderFooterFirstPage = 3
            } catch {
                $firstHdr = "(no first page header)"
            }
            $defHdr = $sec.Headers.Item(1).Range.Text.Trim() # wdHeaderFooterPrimary = 1
            Write-Output "  $t : page $pageNum, section $secNum"
            Write-Output "    First page header: '$firstHdr'"
            Write-Output "    Default header:    '$defHdr'"
        }
    }

    # Export to PDF
    $doc.ExportAsFixedFormat($pdfPath, 17, $false, 0, 0, 1, 1, 0, $false, $true, 0, $true, $true, $false)
    Write-Output "`nPDF exported: $pdfPath"
    Write-Output "PDF size: $((Get-Item $pdfPath).Length) bytes"

    $doc.Close($false)
    Write-Output "Done"
} catch {
    Write-Error "FAILED: $_"
} finally {
    if ($word) { try { $word.Quit() } catch {} }
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($word) | Out-Null
    [GC]::Collect(); [GC]::WaitForPendingFinalizers()
}
