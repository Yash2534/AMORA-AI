param(
    [Parameter(Mandatory = $true)]
    [string]$ApkPath
)

$ErrorActionPreference = 'Stop'
$resolvedApk = (Resolve-Path -LiteralPath $ApkPath).Path

Add-Type -AssemblyName System.IO.Compression

$patterns = [ordered]@{
    'private-key-material' = '-----BEGIN (?:RSA |EC |OPENSSH |DSA )?PRIVATE KEY-----'
    'aws-access-key' = '(?<![A-Z0-9])(?:AKIA|ASIA)[A-Z0-9]{16}(?![A-Z0-9])'
    'google-api-key' = '(?<![A-Za-z0-9_-])AIza[0-9A-Za-z_-]{35}(?![A-Za-z0-9_-])'
    'stripe-live-secret' = '(?<![A-Za-z0-9_])sk_live_[0-9A-Za-z]{16,}(?![A-Za-z0-9])'
    'github-token' = '(?<![A-Za-z0-9_])(?:ghp|gho|ghu|ghs|github_pat)_[0-9A-Za-z_]{20,}(?![A-Za-z0-9_])'
    'jwt-like-token' = '(?<![A-Za-z0-9_-])eyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}(?![A-Za-z0-9_-])'
}

$archive = [System.IO.Compression.ZipFile]::OpenRead($resolvedApk)
$findings = [System.Collections.Generic.List[object]]::new()
$entriesScanned = 0
$entriesSkippedForSize = 0

try {
    foreach ($entry in $archive.Entries) {
        if ($entry.Length -eq 0) { continue }
        if ($entry.Length -gt 67108864) {
            $entriesSkippedForSize++
            continue
        }

        $stream = $entry.Open()
        $memory = [System.IO.MemoryStream]::new()
        try {
            $stream.CopyTo($memory)
            $text = [System.Text.Encoding]::Latin1.GetString($memory.ToArray())
            $entriesScanned++
            foreach ($item in $patterns.GetEnumerator()) {
                if ([regex]::IsMatch($text, $item.Value)) {
                    $findings.Add([pscustomobject]@{
                        category = $item.Key
                        entry = $entry.FullName
                        value = 'REDACTED'
                    })
                }
            }
        }
        finally {
            $memory.Dispose()
            $stream.Dispose()
        }
    }
}
finally {
    $archive.Dispose()
}

[pscustomobject]@{
    artifact = $resolvedApk
    entriesScanned = $entriesScanned
    entriesSkippedForSize = $entriesSkippedForSize
    highConfidenceFindingCount = $findings.Count
    findings = $findings
} | ConvertTo-Json -Depth 5

