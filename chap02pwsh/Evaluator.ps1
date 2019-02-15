function Evaluate($exp, $env, $denv) {
    switch ($Exp.Type) {
        "Number" {
            return $exp
        }
        "Symbol" {
            return $exp
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
                        return $cdr
                    }
                    "COND" {
                        return $cdr
                    }
                    "CASE" {
                        return $cdr
                    }
                    "AND" {
                        return $cdr
                    }
                    "OR" {
                        return $cdr
                    }
                    "SET!" {
                        return $cdr
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
                        # TODO: is a name of a function => find and invoke
                        return $car
                    }
                }
                return Evaluate $car.Value
            } else {
                if ($car.Type -eq "Cons") {
                    $function = Evaluate $car $env $denv
                    # TODO: invoke function with arguments
                    return $function
                } else {
                    # TODO: Don't know what to do, probably error
                    return Evaluate $car $env $denv
                }
            }
        }
    }
}
