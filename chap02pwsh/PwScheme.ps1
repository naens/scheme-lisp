# PowerScheme, Scheme interpreter written in PowerShell

$Path = $args[0]
$Text = [System.IO.File]::ReadAllText( ( Resolve-Path $Path ) )

. ".\Tokenizer.ps1"
$Tokens = Get-Tokens($Text)
$Tokens | ForEach-Object {Write-Host $_}

. ".\Parser.ps1"
$Exps = Parse-Tokens($Tokens)
$Exps | ForEach-Object {
    Write-Host (Exp-To-String $_)
}
