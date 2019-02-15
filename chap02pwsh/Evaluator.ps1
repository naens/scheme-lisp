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
            $car = $Exp.Value[0]
            $cdr = $Exp.Value[1]
            if ($car.Type -eq "Symbol") {
                switch ($car.Value) {
                    "QUOTE" {
                        return $cdr.Value[0]
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
                        if ($cdr.Value[0].Type -eq "Symbol") {
                            $name = $cdr.Value[0].Value
                            $value = Evaluate $cdr.Value[1].Value[0] $env $denv
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
                        if ($cdr.Value[0].Type -eq "Symbol") {
                            $name = $cdr.Value[0].Value
                            $value = Evaluate $cdr.Value[1].Value[0] $env $denv
                            $denv.Declare($name, $value)
                            return $value
                        } else {
                            # no functions for dynamic scope
                            return New-Object PSObject -Property @{ Type = [ExpType]::Symbol; Value = "NIL"}
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
