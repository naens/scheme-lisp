function Make-BuiltIn($name, $env) {
    $function = New-Object Exp -ArgumentList ([ExpType]::BuiltIn)
    $function.defEnv = $env
    $env.Declare($name, $function)
}

function Make-Global-Environment() {
    $globEnv = New-Object Environment
    Make-BuiltIn "+" $globEnv
    Make-BuiltIn "DISPLAY" $globEnv
    return $globEnv
}

function Call-BuiltIn($name, $a) {
    switch ($name.value) {
        "+" {
            return SysPlus($a)
        }
        "DISPLAY" {
            return SysDisplay($a)
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

function SysDisplay($a) {
    $e = New-Object Exp -ArgumentList ([ExpType]::Symbol), "NIL"
    foreach ($exp in $a) {
        Write-Host [SYS] $exp
    }
    return $e
}
