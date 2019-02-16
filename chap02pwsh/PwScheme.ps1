# PowerScheme, Scheme interpreter written in PowerShell

. ".\Tokenizer.ps1"
. ".\Parser.ps1"
. ".\Evaluator.ps1"
. ".\Environment.ps1"
. ".\System.ps1"

$Path = $args[0]

$Text = [System.IO.File]::ReadAllText( (Resolve-Path $Path) )

$Tokens = Get-Tokens $Text
#$Tokens | ForEach-Object {Write-Host $_}

$Exps = Parse-Tokens $Tokens
#$Exps | ForEach-Object { Write-Host EXP: $_ }

$env = Make-Global-Environment
$denv = New-Object Environment
$Exps | ForEach-Object {
    #Write-Host $_
    $exp = Evaluate $_ $env $denv
    Write-Host $exp
}
