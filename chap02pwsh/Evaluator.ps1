function LookUp($name, $env, $denv) {
    Write-Host LOOKUP $name env=$env denv=$denv
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

function Eval-Args($argCons, $env, $denv) {
    $args = @()
    $cons = $argCons
    while ($cons.type -eq "Cons") {
        $arg = $cons.car
        $val = Evaluate $arg $env $denv
        $args += $val
        $cons = $cons.cdr
    }
    return $args
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

function Invoke($function, $defEnv, $denv) {
    # TODO: evaluate function body and return the value
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
                                $args = Eval-Args $cdr $env $denv
                                return Call-BuiltIn $car $args
                            } elseif ($function.type -eq "[ExpType]::Function") {
                                $args = Eval-Args $car.cdr.car $env $denv
                                $params = $function.params
                                $defEnv = $function.defEnv
                                $defEnv.EnterScope

                                # set params
                                $i = 0
                                foreach ($param in $params) {
                                    $arg = $args[$i]
                                    $i++
                                }
                                if ($args.length -ge $i) {
                                    $function.dotParam = $args[$i..($args.Length-1)]
                                }

                                Invoke $function $defEnv $denv
                                $defEnv.LeaveScope
                            }
                        }
                        # TODO: not a function throw error!!!
                        return $null
                    }
                }
                return Evaluate $car.Value
            } else {
                if ($car.Type -eq "Cons") {
                    $function = Evaluate $car $env $denv
                    # TODO: invoke function with arguments
                    return $function
                } else {
                    # TODO: throw here, catch in PwScheme loop
                    return Evaluate $car $env $denv
                }
            }
        }
    }
}
