param(
    [Parameter(Mandatory = $true)]
    [string]$InputDocx,
    [Parameter(Mandatory = $true)]
    [string]$OutputPdf
)

$resolvedInput = (Resolve-Path -LiteralPath $InputDocx).Path
$resolvedOutput = [System.IO.Path]::GetFullPath($OutputPdf)
$outputParent = Split-Path -Parent $resolvedOutput
if (-not (Test-Path -LiteralPath $outputParent)) {
    New-Item -ItemType Directory -Path $outputParent | Out-Null
}

$word = $null
$document = $null
try {
    $word = New-Object -ComObject Word.Application
    $word.Visible = $false
    $word.DisplayAlerts = 0
    $document = $word.Documents.Open($resolvedInput, $false, $true)

    foreach ($tableOfContents in $document.TablesOfContents) {
        $tableOfContents.Update()
    }
    foreach ($field in $document.Fields) {
        $field.Update() | Out-Null
    }
    foreach ($section in $document.Sections) {
        foreach ($header in $section.Headers) {
            foreach ($field in $header.Range.Fields) {
                $field.Update() | Out-Null
            }
        }
        foreach ($footer in $section.Footers) {
            foreach ($field in $footer.Range.Fields) {
                $field.Update() | Out-Null
            }
        }
    }

    # 17 = wdExportFormatPDF, 0 = wdExportOptimizeForPrint.
    $document.ExportAsFixedFormat($resolvedOutput, 17, $false, 0)
    Write-Output $resolvedOutput
}
finally {
    if ($document -ne $null) {
        $document.Close($false)
        [void][System.Runtime.InteropServices.Marshal]::ReleaseComObject($document)
    }
    if ($word -ne $null) {
        $word.Quit()
        [void][System.Runtime.InteropServices.Marshal]::ReleaseComObject($word)
    }
    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
}
