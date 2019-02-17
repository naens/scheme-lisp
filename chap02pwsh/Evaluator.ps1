class EvaluatorException: System.Exception{
    $msg
    EvaluatorException($msg){
        $this.msg=$msg
    }
}

function LookUp($name, $env, $denv) {
    $val = $env.LookUp($name)
    if ($val -eq $null) {
        return $denv.LookUp($name)
    }
    return $val
}

function Update($name, $value, $env, $denv) {
    if (!$env.Update($name, $value)) {
        return $denv.Update($name, $value)
    }
    return $true
}

function Is-True($exp) {
    return $exp.type -eq "Boolean" -and $exp.value
}

function Eval-If($ifTail, $env, $denv) {
    $cond = Evaluate $ifTail.car $env $denv
    if (Is-True $cond) {
        return Evaluate $ifTail.cdr.car $env $denv
    } elseif ($ifTail.cdr.cdr.type -eq "Cons") {
        return Evaluate $ifTail.cdr.cdr.car $env $denv
    } else {
        return New-Object Exp -ArgumentList ([ExpType]::Symbol), "NIL"
    }
}

function Eval-Cond($condTail, $env, $denv) {
    $c = $condTail
    while ($c.type -eq "Cons" -and $c.car.type -eq "Cons") {
        $pair = $c.car     # (cons <cond> . <body>)
        $cond = $pair.car
        $body = $pair.cdr
        if ($cond.type -eq "Symbol" -and $cond.value -eq "ELSE") {
            return Eval-Body $body $env $denv
        }
        $condValue = Evaluate $cond $env $denv
        if (Is-True($condValue)) {
            return Eval-Body $body $env $denv
        }
        $c = $c.cdr
    }
    return New-Object Exp -ArgumentList ([ExpType]::Symbol), "NIL"
}

function Eval-And($tail, $env, $denv) {
    $c = $tail
    while ($c.type -eq "Cons") {
        $car = Evaluate $c.car $env $denv
        if (!(Is-True $car)) {
            return New-Object Exp -ArgumentList ([ExpType]::Boolean), $false
        }
        $c = $c.cdr
    }
    return New-Object Exp -ArgumentList ([ExpType]::Boolean), $true
}

function Eval-Or($tail, $env, $denv) {
    $c = $tail
    while ($c.type -eq "Cons") {
        $car = Evaluate $c.car $env $denv
        if (Is-True $car) {
            return New-Object Exp -ArgumentList ([ExpType]::Boolean), $true
        }
        $c = $c.cdr
    }
    return New-Object Exp -ArgumentList ([ExpType]::Boolean), $false
}

function Eval-Case($caseTail, $env, $denv) {
    $val = Evaluate $caseTail.car $env $denv
    Write-Host EVAL-CASE val=$val
    $c = $caseTail.cdr
    while ($c.type -eq "Cons" -and $c.car.type -eq "Cons") {
        $pair = $c.car     # (cons ({<datum>}) . <body>)
        $body = $pair.cdr
        if ($pair.car.type -eq "Symbol" -and $pair.car.value -eq "ELSE") {
            return Eval-Body $body $env $denv
        }
        $datumList = $pair.car
        while ($datumList.type -eq "Cons") {
            $datum = $datumList.car     # !! datum is not evaluated here
            Write-Host EVAL-CASE datum=$datum val=$val
            if (IsEqual $val  $datum) {
                return Eval-Body $body $env $denv
            }
            $datumList = $datumList.cdr
        }
        $c = $c.cdr
    }
    return New-Object Exp -ArgumentList ([ExpType]::Symbol), "NIL"
}

function Eval-Body($body, $env, $denv) {
    $cons = $body
    $result = New-Object Exp -ArgumentList ([ExpType]::Symbol), "NIL"
    while ($cons.type -eq "Cons") {
        $result = Evaluate $cons.car $env $denv
        $cons = $cons.cdr
    }
    return $result
}

function Extend-With-Args($argCons, $function, $defEnv, $env, $denv) {
    $funVal = $function.value
    $params = $funVal.params
    $dotParam = $funVal.dotParam
    $cons = $argCons
    $i = 0
    while ($cons.type -eq "Cons") {
        $arg = $cons.car
        if ($i -ge $params.length) {
            throw [EvaluatorException] "EXTEND-WITH-ARGS: Too many arguments given"
        }
        $param = $params[$i]
        $val = Evaluate $arg $env $denv
        $defEnv.Declare($param, $val)
        $cons = $cons.cdr
        $i++
    }
    if ($dotParam -ne $null) {
        $defEnv.Declare($dotParam, $cons)
    }
}

function Invoke($function, $argsExpr, $env, $denv) {
    $defEnv = $function.value.defEnv
    $defEnv.EnterScope
    Extend-With-Args $argsExpr $function $defEnv $env $denv
    $result = Eval-Body $function.value.body $defEnv $denv
    $defEnv.LeaveScope
    return $result
}

function Evaluate($exp, $env, $denv) {
    switch ($Exp.Type) {
        "Number" {
            return $exp
        }
        "Symbol" {
            return LookUp $exp.value $env $denv
        }
        "String" {
            return $exp
        }
        "Character" {
            return $exp
        }
        "Boolean" {
            return $exp
        }
        "Cons" {
            $car = $Exp.car
            $cdr = $Exp.cdr
            if ($car.Type -eq "Symbol") {
                switch ($car.Value) {
                    "QUOTE" {
                        return $cdr.car
                    }
                    "IF" {
                        return Eval-If $cdr $env $denv
                    }
                    "COND" {
                        return Eval-Cond $cdr $env $denv
                    }
                    "CASE" {
                        return Eval-Case $cdr $env $denv
                    }
                    "AND" {
                        return Eval-And $cdr $env $denv
                    }
                    "OR" {
                        return Eval-Or $cdr $env $denv
                    }
                    "BEGIN" {
                        return Eval-Body $cdr $env $denv
                    }
                    "SET!" {
                        return Update $cdr.car.value $cdr.cdr.car $env $denv
                    }
                    "DEFINE" {
                        if ($cdr.car.Type -eq "Symbol") {
                            $name = $cdr.car.Value
                            $value = Evaluate $cdr.cdr.car $env $denv
                            $env.Declare($name, $value)
                            Write-Host Environment update: $env
                            return $value
                        } else {
                            # TODO: define new function
                            return $cdr
                        }
                    }
                    "LAMBDA" {
                        # TODO: define new function, function environment = current $env
                        return $cdr
                    }
                    "LET" {
                        return $cdr
                    }
                    "LETREC" {
                        return $cdr
                    }
                    "DYNAMIC" {
                        if ($cdr.car.Type -eq "Symbol") {
                            $name = $cdr.car.Value
                            $value = Evaluate $cdr.cdr.car $env $denv
                            $denv.Declare($name, $value)
                            return $value
                        } else {
                            # no functions for dynamic scope
                            return New-Object Exp -ArgumentList [ExpType]::Symbol, "NIL"
                        }
                    }
                    default {
                        $function = LookUp $car.value $env $denv
                        if ($function -ne $null) {
                            if ($function.type -eq "BuiltIn") {
                                return Call-BuiltIn $car $cdr $env $denv
                            } elseif ($function.type -eq "[ExpType]::Function") {
                                return Invoke $function $cdr $env $denv
                            }
                        }
                        throw [EvaluatorException] "EVALUATE: Unknown Function $($car.value)"
                    }
                }
                return Evaluate $car.Value
            } else {
                if ($car.Type -eq "Cons") {
                    $function = Evaluate $car $env $denv
                    if ($function.type -eq "[ExpType]::Function") {
                        Invoke $function $car.cdr $env $denv
                    }
                    return $function
                } else {
                    throw [EvaluatorException] "EVALUATE: Cannot evaluate to Function: $car"
                }
            }
        }
    }
}
