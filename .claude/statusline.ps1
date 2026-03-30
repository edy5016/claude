$data = [Console]::In.ReadToEnd()

$json = $data | ConvertFrom-Json

$cwd = $json.workspace.current_dir
$model = $json.model.display_name
$used = $json.context_window.used_percentage

$git_branch = ''
try {
    Push-Location $cwd -ErrorAction SilentlyContinue
    $git_branch = git branch --show-current 2>$null
    Pop-Location
} catch {}

$esc = [char]27

$git_info = ''
if ($git_branch) {
    $git_info = " | $esc[35m$git_branch$esc[0m"
}

$ctx_info = ''
if ($null -ne $used) {
    $used_rounded = [math]::Round($used, 0)
    $ctx_info = " | $esc[33mCTX $used_rounded%$esc[0m"
}


Write-Host "$esc[36m$cwd$esc[0m$git_info | $esc[32m$model$esc[0m$ctx_info" -NoNewline