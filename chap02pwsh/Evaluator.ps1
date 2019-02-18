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

function Eval-If($ifTail, $env, $denv, $tco) {
    $cond = Evaluate $ifTail.car $env $denv
    if (Is-True $cond) {
        return Evaluate $ifTail.cdr.car $env $denv $tco
    } elseif ($ifTail.cdr.cdr.type -eq "Cons") {
        return Evaluate $ifTail.cdr.cdr.car $env $denv $tco
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

function Eval-Body($body, $env, $denv, $tco0) {
    $cons = $body
    $result = New-Object Exp -ArgumentList ([ExpType]::Symbol), "NIL"
    while ($cons.type -eq "Cons") {
        $tco = $tco0 -and ($cons.cdr.type -eq "Symbol")
        Write-Host tco=$tco
        $result = Evaluate $cons.car $env $denv $tco
        # TODO: implement TCO
        $cons = $cons.cdr
    }
    return $result
}


function List-To-Cons($list) {
    #TODO: create Cons list from list of Exp
}

function Eval-Let($letTail, $env, $denv, $tco) {
    # (let ({<var-val>}) . <body>)
    $varvalList = $letTail.car
    $body = $letTail.cdr
    $args = @()
    $params = @()
    while ($varvalList.type -eq "Cons") {
        $varval = $varvalList.car
        $var = $varval.car
        $params += $var
        $val = Evaluate $varval.cdr.car $env $denv
        $args += $val

        $varvalList = $varvalList.cdr
    }
    $argsExp = List-To-Cons $args
    $paramsExp = List-To-Cons $params
    $function = Make-Function $env $paramsExp $body
    return Invoke $function  $argsExpr $env $denv $tco
}

# $number: number of parameters before dot (or before nil)
# after dot: assign cons to dotParam, evaluate car's inside
function Eval-Args($argCons, $number, $env, $denv, $tco) {
    $values = @()
    $i = 0
    $cons = $argCons
    while ($i -lt $number) {
        if ($cons.type -ne "Cons") {
            throw [EvaluatorException] "EXTEND-WITH-ARGS: Not enough arguments"
        }
        $arg = $cons.car
        $val = Evaluate $arg $env $denv
        $values += $val
        $cons = $cons.cdr
        $i++
    }

    # evaluate after dot
    if ($cons.type -eq "Cons") {
        $dotParam = $cons
        while ($cons.type -eq "Cons") {
            $cons.car = Evaluate $cons.car $env $denv
            $cons = $cons.cdr
        }
    }
    return @($values, $dotValue)
}

function Extend-With-Args($argList, $dotValue, $function, $defEnv, $denv) {
    $funVal = $function.value
    $params = $funVal.params
    $dotParam = $funVal.dotParam
    $i = 0
    while ($i -lt $params.length) {
        $arg = $argList[$i]
        $param = $params[$i]
        $defEnv.Declare($param, $arg)
        $i++
    }
    if ($dotParam -ne $null) {
        $defEnv.Declare($dotParam, $dotValue)
    }
}

function Invoke($function, $argsExpr, $env, $denv, $tco) {
    $funVal = $function.value
    $params = $funVal.params
    $defEnv = $funVal.defEnv
    Write-Host INVOKE: TCO=$tco
    #$tco = $false

    if (!$tco) {
        $argList, $dotValue = Eval-Args $argsExpr $params.length $defEnv $denv
        $defEnv.EnterScope()
        Extend-With-Args $argList $dotValue $function $defEnv $denv
        $result = Eval-Body $function.value.body $defEnv $denv $true
        $defEnv.LeaveScope()
    } else {
        $argList, $dotValue = Eval-Args $argsExpr $params.length $defEnv $denv
        $defEnv.LeaveScope()
        $defEnv.EnterScope()
        Extend-With-Args $argList $dotValue $function $defEnv $denv
        $result = Eval-Body $function.value.body $defEnv $denv $true
    }

    return $result
}

function Make-Function($env, $paramsExp, $body) {
    $function = New-Object Fun
    $function.defEnv = $env
    $function.params = @()
    $paramsCons = $paramsExp
    while ($paramsCons.type -eq "Cons") {
        $function.params += $paramsCons.car.value
        $paramsCons = $paramsCons.cdr
    }
    if ($paramsCons.type -eq "Symbol" -and $paramsCons.value -ne "NIL") {
        $function.dotParam = $paramsCons.value
    }
    $function.body = $body
    return New-Object Exp -ArgumentList ([ExpType]::Function), $function
}

function Evaluate($exp, $env, $denv, $tco) {
    #Write-Host EVALUATE: $exp $env
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
                        return Eval-If $cdr $env $denv $tco
                    }
                    "COND" {
                        return Eval-Cond $cdr $env $denv $tco
                    }
                    "CASE" {
                        return Eval-Case $cdr $env $denv $tco
                    }
                    "AND" {
                        return Eval-And $cdr $env $denv $tco
                    }
                    "OR" {
                        return Eval-Or $cdr $env $denv $tco
                    }
                    "BEGIN" {
                        return Eval-Body $cdr $env $denv $tco
                    }
                    "SET!" {
                        return Update $cdr.car.value $cdr.cdr.car $env $denv
                    }
                    "DEFINE" {
                        if ($cdr.car.Type -eq "Symbol") {
                            $name = $cdr.car.Value
                            $value = Evaluate $cdr.cdr.car $env $denv
                            $env.Declare($name, $value)
                            return $value
                        } else {
                            # (define (<name> . <params>) <body>)
                            $name = $cdr.car.car.value
                            $params = $cdr.car.cdr
                            $body = $cdr.cdr
                            $function = (Make-Function $env $params $body)
                            $env.Declare($name, $function)
                            return $function
                        }
                    }
                    "LAMBDA" {
                        # (lambda <params> . <body>)
                        $params = $cdr.car
                        $body = $cdr.cdr
                        return Make-Function $env $params $body
                    }
                    "LET" {
                        return Eval-Let $cdr $env $denv $tco
                    }
                    "LETREC" {
                        # TODO
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
                        $function = LookUp $($car.value) $env $denv
                        if ($function -ne $null) {
                            if ($function.type -eq "BuiltIn") {
                                return Call-BuiltIn $car $cdr $env $denv
                            } elseif ($function.type -eq "Function") {
                                    return Invoke $function $cdr $env $denv $tco
                            }
                        }
                        throw [EvaluatorException] "EVALUATE: Unknown Function $($car.value)"
                    }
                }
                return Evaluate $car.Value
            } else {
                if ($car.Type -eq "Cons") {
                    $function = Evaluate $car $env $denv
                    if ($function.type -eq "Function") {
                        return Invoke $function $cdr $env $denv $tco
                    }
                    throw [EvaluatorException] "EVALUATE: Cannot evaluate to Function: $car"
                } else {
                    throw [EvaluatorException] "EVALUATE: Bad element at function position: $car"
                }
            }
        }
    }
}
