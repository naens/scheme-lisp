# PowerScheme, Scheme interpreter written in PowerShell

$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition

. "$scriptPath\Tokenizer.ps1"
. "$scriptPath\Parser.ps1"
. "$scriptPath\Evaluator.ps1"
. "$scriptPath\Environment.ps1"
. "$scriptPath\System.ps1"
. "$scriptPath\Bag.ps1"

$env = Make-Global-Environment
$denv = New-Object Environment

if ($args.length -eq 1) {
    $Path = $args[0]
    $Text = [System.IO.File]::ReadAllText( (Resolve-Path $Path) )
    $Tokens = Get-Tokens $Text
    $Exps = Parse-Tokens $Tokens
    $exp = $null
    $Exps | ForEach-Object {
        try {
            $exp = Evaluate $_ $env $denv $false
        } catch [EvaluatorException] {
            Write-Output ("EvaluatorException in PwScheme loop: " + $($_.Exception.msg))
        }
    }
    if ($exp -ne $null) {
        Write-Host $exp
    }
} else {

    $exit = $false
    $bag = New-Object Bag
    while (-not $exit) {
        if ($bag.level -ne 0) {
            Write-Host -NoNewline "[$($bag.level)]"
        } else {
            Write-Host -NoNewline "PowerScheme>"
        }
        $text = Read-Host
        $tokens = Get-Tokens $text
        $bag.addTokens($tokens)
        while (-not $bag.isEmpty()) {
            $expTokens = $bag.takeExp()
            $exp = Parse-Tokens $expTokens
            #Write-Host exp = $exp
            try {
                $result = Evaluate $exp $env $denv $false
            } catch [ExitException1] {
                $exit = $true
                $result = $null
            } catch [EvaluatorException] {
                Write-Output ("EvaluatorException in PwScheme loop: " + $($_.Exception.msg))
            }
            if ($result -ne $null) {
                Write-Host $result
            }
        }
    }
}
