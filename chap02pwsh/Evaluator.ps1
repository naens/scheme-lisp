function LookUp($name, $env, $denv) {
    $val = $env.LookUp($name)
    if ($val -eq $null) {
        return $denv.Lookup($name)
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
                        # TODO
                        return $cdr
                    }
                    "COND" {
                        # TODO
                        return $cdr
                    }
                    "CASE" {
                        # TODO
                        return $cdr
                    }
                    "AND" {
                        # TODO
                        return $cdr
                    }
                    "OR" {
                        # TODO
                        return $cdr
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
