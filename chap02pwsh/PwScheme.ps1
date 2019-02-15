# PowerScheme, Scheme interpreter written in PowerShell

. ".\Tokenizer.ps1"
. ".\Parser.ps1"
. ".\Environment.ps1"
. ".\Evaluator.ps1"

$Path = $args[0]

$Text = [System.IO.File]::ReadAllText( (Resolve-Path $Path) )

$Tokens = Get-Tokens $Text
#$Tokens | ForEach-Object {Write-Host $_}

$Exps = Parse-Tokens $Tokens
#$Exps | ForEach-Object { Write-Host (Exp-To-String $_) }

$env = New-Object Environment
$denv = New-Object Environment
$Exps | ForEach-Object {
    Write-Host (Exp-To-String $_)
    $exp = Evaluate $_ $env $denv
    Write-Host EXPRESSION: (Exp-To-String $exp $env $denv)
}
