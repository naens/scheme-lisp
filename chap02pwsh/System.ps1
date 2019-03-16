function Make-BuiltIn($name, $env) {
    $builtin = New-Object Exp -ArgumentList ([ExpType]::BuiltIn)
    $builtin.value = $name
    $env.Declare($name, $builtin)
}

function Make-Global-Environment() {
    $globEnv = New-Object Environment -ArgumentList "global"
    Make-BuiltIn "+" $globEnv
    Make-BuiltIn "-" $globEnv
    Make-BuiltIn "*" $globEnv
    Make-BuiltIn "/" $globEnv
    Make-BuiltIn "MODULO" $globEnv
    Make-BuiltIn ">" $globEnv
    Make-BuiltIn ">=" $globEnv
    Make-BuiltIn "<" $globEnv
    Make-BuiltIn "<=" $globEnv
    Make-BuiltIn "=" $globEnv
    Make-BuiltIn "EQUAL?" $globEnv
    Make-BuiltIn "WRITE" $globEnv
    Make-BuiltIn "WRITELN" $globEnv
    Make-BuiltIn "EVAL" $globEnv
    Make-BuiltIn "APPLY" $globEnv
    Make-BuiltIn "CRASH" $globEnv
    Make-BuiltIn "READ" $globEnv
    Make-BuiltIn "LOAD" $globEnv
    Make-BuiltIn "CONS" $globEnv
    Make-BuiltIn "CAR" $globEnv
    Make-BuiltIn "CDR" $globEnv
    Make-BuiltIn "NOT" $globEnv
    Make-BuiltIn "LIST" $globEnv
    Make-BuiltIn "NUMBER?" $globEnv
    Make-BuiltIn "SYMBOL?" $globEnv
    Make-BuiltIn "STRING?" $globEnv
    Make-BuiltIn "CHARACTER?" $globEnv
    Make-BuiltIn "BOOLEAN?" $globEnv
    Make-BuiltIn "PAIR?" $globEnv
    Make-BuiltIn "PROCEDURE?" $globEnv
    Make-BuiltIn "NULL?" $globEnv
    Make-BuiltIn "EMPTY?" $globEnv
    Make-BuiltIn "ZERO?" $globEnv
    Make-BuiltIn "EXIT" $globEnv
    Make-BuiltIn "BYE" $globEnv
    Make-BuiltIn "QUIT" $globEnv
    $globEnv.Declare("NIL", (New-Object Exp -ArgumentList ([ExpType]::Symbol), "NIL"))
    $globEnv.Declare("EMPTY", (New-Object Exp -ArgumentList ([ExpType]::Symbol), "NIL"))
    return $globEnv
}

function Call-BuiltIn($name, $argsExp, $env, $denv) {
    if ($name -eq "APPLY") {
        $applyArgs = (Evaluate $argsExp.cdr.car $env $denv $false)
        return SysApply $argsExp.car $applyArgs

    }
    $args = @()
    $cons = $argsExp
    #Write-Host CALL-BUILTIN name=$name argsExp=$argsExp
    while ($cons.type -eq "Cons") {
        $val = Evaluate $cons.car $env $denv $false
        $args += $val
        $cons = $cons.cdr
    }
    switch ($name) {
        "+" {
            return SysPlus $args
        }
        "-" {
            return SysMinus $args
        }
        "*" {
            return SysMult $args
        }
        "/" {
            return SysDiv $args
        }
        "MODULO" {
            return SysModulo $args
        }
        ">" {
            return SysGTNum $args
        }
        ">=" {
            return SysGENum $args
        }
        "<" {
            return SysLTNum $args
        }
        "<=" {
            return SysLENum $args
        }
        "=" {
            return SysEqNum $args
        }
        "EQUAL?" {
            return SysEqual $args
        }
        "WRITE" {
            return SysWrite $args
        }
        "WRITELN" {
            return SysWriteLn $args
        }
        "EVAL" {
            return SysEval $args
        }
        "CRASH" {
            return SysCrash $args
        }
        "READ" {
            return SysRead $args $env $denv
        }
        "LOAD" {
            return SysLoad $args $env $denv
        }
        "CONS" {
            return SysCons $args
        }
        "CAR" {
            return SysCAR $args
        }
        "CDR" {
            return SysCDR $args
        }
        "NOT" {
            return SysNot $args
        }
        "LIST" {
            return SysList $args
        }
        "NUMBER?" {
            return SysIsNumber $args
        }
        "SYMBOL?" {
            return SysIsSymbol $args
        }
        "STRING?" {
            return SysIsString $args
        }
        "CHARACTER?" {
            return SysIsCharacter $args
        }
        "BOOLEAN?" {
            return SysIsBoolean $args
        }
        "PAIR?" {
            return SysIsPair $args
        }
        "PROCEDURE?" {
            return SysIsProcedure $args
        }
        "NULL?" {
            return SysIsNull $args
        }
        "EMPTY?" {
            return SysIsNull $args
        }
        "ZERO?" {
            return SysIsZero $args
        }
        "EXIT" {
            return SysExit
        }
        "BYE" {
            return SysExit
        }
        "QUIT" {
            return SysExit
        }
    }
}

function SysPlus($a) {
    $result = 0
    foreach ($num in $a) {
        $result += $num.value
    }
    return New-Object Exp -ArgumentList ([ExpType]::Number), $result
}

function SysMinus($a) {
    if ($a.length -eq 0) {
        return New-Object Exp -ArgumentList ([ExpType]::Number), 0
    }
    if ($a[0].type -ne ([ExpType]::Number)) {
        return New-Object Exp -ArgumentList ([ExpType]::Number), 0
    }
    if ($a.length -eq 1) {
        New-Object Exp -ArgumentList ([ExpType]::Number), -$[a].value
    }
    $result = $a[0].value
    $i = 1
    while ($i -lt $a.length) {
        $result -= $a[$i].value
        $i++
    }
    return New-Object Exp -ArgumentList ([ExpType]::Number), $result
}

function SysMult($a) {
    $result = 1
    foreach ($num in $a) {
        $result *= $num.value
    }
    return New-Object Exp -ArgumentList ([ExpType]::Number), $result
}

function SysDiv($a) {
    if ($a.length -eq 0) {
        return New-Object Exp -ArgumentList ([ExpType]::Number), 1
    }
    if ($a[0].type -ne ([ExpType]::Number)) {
        return New-Object Exp -ArgumentList ([ExpType]::Number), 0
    }
    if ($a.length -eq 1) {
        New-Object Exp -ArgumentList ([ExpType]::Number), 0
    }
    $result = $a[0].value
    $i = 1
    while ($i -lt $a.length) {
        $result = [math]::floor($result / $a[$i].value)
        $i++
    }
    return New-Object Exp -ArgumentList ([ExpType]::Number), $result
}

function SysModulo($a) {
    if ($a.length -ne 2) {
        return $null
    }
    return New-Object Exp -ArgumentList ([ExpType]::Number), ($a[0].value % $a[1].value)
}

function SysWrite($a) {
    $e = New-Object Exp -ArgumentList ([ExpType]::Symbol), "NIL"
    foreach ($exp in $a) {
        $e = $exp
        Write-Host -NoNewline $exp
    }
    return $null
}

function SysWriteLn($a) {
    foreach ($exp in $a) {
        Write-Host -NoNewline $exp
    }
    Write-Host ""
    return $null
}

function IsEqual($exp1, $exp2) {
    if ($exp1.type -ne $exp2.type) {
        return $false
    }
    if ($exp1.type -eq ([ExpType]::Cons)) {
        return (IsEqual $exp1.car $exp2.car) -and (IsEqual $exp1.cdr $exp2.cdr)
    }
    return $exp1.value -eq $exp2.value
}

function SysGTNum($a) {
    $val = $a[0].type -eq ([ExpType]::Number) -and $a[0].type -eq $a[1].type -and $a[0].value -gt $a[1].value
    return New-Object Exp -ArgumentList ([ExpType]::Boolean), $val
}

function SysGENum($a) {
    $val = $a[0].type -eq ([ExpType]::Number) -and $a[0].type -eq $a[1].type -and $a[0].value -ge $a[1].value
    return New-Object Exp -ArgumentList ([ExpType]::Boolean), $val
}

function SysLTNum($a) {
    $val = $a[0].type -eq ([ExpType]::Number) -and $a[0].type -eq $a[1].type -and $a[0].value -lt $a[1].value
    return New-Object Exp -ArgumentList ([ExpType]::Boolean), $val
}

function SysLENum($a) {
    $val = $a[0].type -eq ([ExpType]::Number) -and $a[0].type -eq $a[1].type -and $a[0].value -le $a[1].value
    return New-Object Exp -ArgumentList ([ExpType]::Boolean), $val
}

function SysEqNum($a) {
    $val = $a[0].type -eq ([ExpType]::Number) -and $a[0].type -eq $a[1].type -and $a[0].value -eq $a[1].value
    return New-Object Exp -ArgumentList ([ExpType]::Boolean), $val
}

function SysEqual($a) {
    return New-Object Exp -ArgumentList ([ExpType]::Boolean), (IsEqual $a[0] $a[1])
}

function SysEval($a) {
    return Evaluate $a[0] (Make-Global-Environment) (New-Object Environment "#<eval>") $false
}

function SysApply($funExp, $argsExp) {
    $function = Evaluate $funExp $env $denv $false
    $env = Make-Global-Environment
    $denv = New-Object Environment "#<apply>"
    if ($function.type -eq "BuiltIn") {
        return Call-BuiltIn $function.value $argsExp $env $denv $false
    } elseif ($function.type -eq "Function") {
        return Invoke $function $argsExp $env $denv $false
    }
    return $null
}

function SysCrash($args) {
    Evaluate $args[0] $env $denv $false
    throw [ExitException] "CRASH"
}

function SysRead($a, $env, $denv) {
    if ($a.length -eq 1) {
        $msg = $a[0].value
    } else {
        $msg = ">"
    }
    $text = Read-Host $msg
    $tokens = Get-Tokens $text
    $exps = Parse-Tokens $tokens
    $exps | ForEach-Object {
        try {
            $exp = Evaluate $_ $env $denv $false
        } catch [EvaluatorException] {
            Write-Output ("Exception in SysRead: " + $($_.Exception.msg))
        }
    }
    return $exp
}

function SysLoad($a, $env, $denv) {
    $path = $a[0].value
    $text = [System.IO.File]::ReadAllText( (Resolve-Path $path) )
    $tokens = Get-Tokens $text
    $exps = Parse-Tokens $tokens
    $exps | ForEach-Object {
        try {
            $exp = Evaluate $_ $env $denv $false
        } catch [EvaluatorException] {
            Write-Output ("Exception in SysLoad: " + $($_.Exception.msg))
        }
    }
    return $exp
}

function SysCons($a) {
    return New-Object Exp -ArgumentList ([ExpType]::Cons), $a[0], $a[1]
}

function SysCAR($a) {
    return $a[0].car
}

function SysCDR($a) {
    return $a[0].cdr
}

function SysNot($a) {
    $value = $a[0]
    if ($value.type -eq "Boolean" -and $value.value -eq $true) {
        return New-Object Exp -ArgumentList ([ExpType]::Boolean), $false
    }
    return New-Object Exp -ArgumentList ([ExpType]::Boolean), $true
}

function SysList($a) {
    return List-To-Cons($a)
}

function SysIsNumber($a) {
    return New-Object Exp -ArgumentList ([ExpType]::Boolean), ($a[0].type -eq "Number")
}

function SysIsSymbol($a) {
    return New-Object Exp -ArgumentList ([ExpType]::Boolean), ($a[0].type -eq "Symbol" -and $a[0].value -ne "NIL")
}

function SysIsString($a) {
    return New-Object Exp -ArgumentList ([ExpType]::Boolean), ($a[0].type -eq "String")
}

function SysIsCharacter($a) {
    return New-Object Exp -ArgumentList ([ExpType]::Boolean), ($a[0].type -eq "Character")
}

function SysIsBoolean($a) {
    return New-Object Exp -ArgumentList ([ExpType]::Boolean), ($a[0].type -eq "Boolean")
}

function SysIsPair($a) {
    return New-Object Exp -ArgumentList ([ExpType]::Boolean), ($a[0].type -eq "Pair")
}

function SysIsProcedure($a) {
    switch ($a[0].type) {
        "Function" {
            $res = $true
        }
        "BuiltIn" {
            $res = $true
        }
        default {
            $res = false
        }
    }
    return New-Object Exp -ArgumentList ([ExpType]::Boolean), $res
}

function SysIsNull($a) {
    return New-Object Exp -ArgumentList ([ExpType]::Boolean), ($a[0].type -eq "Symbol" -and $a[0].value -eq "NIL")
}

function SysIsZero($a) {
    return New-Object Exp -ArgumentList ([ExpType]::Boolean), ($a[0].type -eq "Number" -and $a[0].value -eq 0)
}

class ExitException: System.Exception{
    $msg
    ExitException($msg){
        $this.msg=$msg
    }
}

function SysExit() {
    throw [ExitException] "EXIT"
}
