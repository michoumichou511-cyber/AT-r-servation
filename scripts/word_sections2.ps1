# Sections + en-tetes par chapitre via Word COM — version Range.Find (sans Selection)
$ErrorActionPreference = "Stop"
$word = New-Object -ComObject Word.Application
$word.Visible = $false
$word.DisplayAlerts = 0
$word.AutomationSecurity = 3

try {
  $doc = $word.Documents.Open("C:\Users\loulou\ProjetFinFormation\Memoir_MASTER.docx", $false, $false, $false)
  Write-Output "document ouvert"

  # ── 1. saut de section (page suivante) AVANT chaque titre ──
  $targets = @("CHAPITRE II", "CHAPITRE III", "CHAPITRE IV", "Conclusion G")
  foreach ($t in $targets) {
    $rng = $doc.Content
    $f = $rng.Find
    $f.ClearFormatting()
    $f.Text = $t
    $f.Forward = $true
    $f.Wrap = 0
    $f.MatchCase = $true
    if ($f.Execute()) {
      $rng.Collapse(1) | Out-Null
      $rng.InsertBreak(2)
      Write-Output "section inseree avant : $t"
    } else {
      Write-Output "INTROUVABLE : $t"
    }
  }
  Write-Output ("sections totales : " + $doc.Sections.Count)

  # ── 2. en-tetes par section ──
  $blue  = 10763008    # BGR #003DA5
  $green = 5285376     # BGR #00A650
  $em = [char]0x2014
  $ea = [char]0xE9
  $titles = @{
    "CHAPITRE II"  = "Chapitre II $em Analyse et Sp${ea}cification des Besoins"
    "CHAPITRE III" = "Chapitre III $em Conception de l'application"
    "CHAPITRE IV"  = "Chapitre IV $em R${ea}alisation"
  }
  for ($i = 1; $i -le $doc.Sections.Count; $i++) {
    $sec = $doc.Sections.Item($i)
    $len = [Math]::Min(40, $sec.Range.Text.Length)
    $first = $sec.Range.Text.Substring(0, $len).Trim()
    $key = $null
    foreach ($k in $titles.Keys) { if ($first.StartsWith($k)) { $key = $k } }
    if ($key) {
      $hdr = $sec.Headers.Item(1)
      $hdr.LinkToPrevious = $false
      $r = $hdr.Range
      $r.Text = $titles[$key]
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
      Write-Output "en-tete pose : section $i = $key"
    }
    if ($first.StartsWith("Conclusion G")) {
      $hdr = $sec.Headers.Item(1)
      $hdr.LinkToPrevious = $false
      $hdr.Range.Text = ""
      Write-Output "en-tete vide : section $i (Conclusion)"
    }
  }

  $doc.Save()
  Write-Output ("sauve, pages: " + $doc.ComputeStatistics(2))
  $doc.Close($false)
} finally {
  $word.Quit()
}
