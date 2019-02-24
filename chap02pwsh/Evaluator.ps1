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
        return $denv.UpdateDynamic($name, $value)
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
        #Write-Host tco=$tco
        $result = Evaluate $cons.car $env $denv $tco
        $cons = $cons.cdr
    }
    return $result
}


function List-To-Cons($list) {
    $prev = $null
    $nil = New-Object Exp -ArgumentList ([ExpType]::Symbol), "NIL"
    $first = $nil
    foreach ($exp in $list) {
        $car = $exp
        $cons = New-Object Exp -ArgumentList ([ExpType]::Cons), $car, $nil
        if ($prev -eq $null) {
            $first = $cons
        } else {
            $prev.cdr = $cons
        }
        $prev = $cons
    }
    return $first
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
        $val = Evaluate $varval.cdr.car $env $denv $false
        $args += $val
        $varvalList = $varvalList.cdr
    }
    $argsExp = List-To-Cons $args
    $paramsExp = List-To-Cons $params
    $function = Make-Function $env $paramsExp $body
    return Invoke $function  $argsExp $env $denv $tco
}

function Make-Thunk($exp, $env) {
    $function = New-Object Fun
    $function.defEnv = $env
    $function.params = @()
    $function.isThunk = $true
    $nil = New-Object Exp -ArgumentList ([ExpType]::Symbol), "NIL"
    $cons = New-Object Exp -ArgumentList ([ExpType]::Cons), $exp, $nil
    $function.body = $cons
    return New-Object Exp -ArgumentList ([ExpType]::Function), $function
}

function Eval-LetRec($letTail, $env, $denv, $tco) {
    # (letrec ({<var-val>}) . <body>)
    $varvalList = $letTail.car
    $body = $letTail.cdr

    $env.EnterScope()
    $params = @()
    $exps = @()
    $nil = New-Object Exp -ArgumentList ([ExpType]::Symbol), "NIL"
    while ($varvalList.type -eq "Cons") {
        $varval = $varvalList.car
        $param = $varval.car.value
        $exp = $varval.cdr.car
        $env.Declare($param, $nil)
        $params += $param
        $exps += $exp
        $varvalList = $varvalList.cdr
    }
    $len = $params.length
    $i = 0
    while ($i -lt $len) {
        $param = $params[$i]
        $exp = $exps[$i]
        if ($exp.type -eq "Cons" -and $exp.car.type -eq "Symbol" -and $exp.car.value -eq "LAMBDA") {
            $val = Evaluate $exp $env $denv $false
        } else {
            $val = Make-Thunk $exp $env
        }
        $t = Update $param $val $env $denv
        $i++
    }
    $result = Eval-Body $body $env $denv $true
    $env.LeaveScope()
    return $result
}

# $number: number of parameters before dot (or before nil)
# after dot: assign cons to dotParam, evaluate car's inside
function Eval-Args($argCons, $number, $env, $denv, $tco) {
    $values = @()
    $i = 0
    $cons = $argCons
    while ($i -lt $number) {
        if ($cons.type -ne "Cons") {
            throw [EvaluatorException] "EVAL-ARGS: Not enough arguments"
        }
        $arg = $cons.car
        $val = (Evaluate $arg $env $denv $false)
        $values += $val
        $cons = $cons.cdr
        $i++
    }

    # evaluate after dot
    if ($cons.type -eq "Cons") {
        $dotParam = $cons
        while ($cons.type -eq "Cons") {
            $cons.car = (Evaluate $cons.car $env $denv $false)
            $cons = $cons.cdr
        }
        return @($values, $dotParam)
    }
    return @($values, $cons)        # set to dotParam whatever is left in the last cdr...
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

function Invoke($function, $argsExp, $env, $denv, $tco) {
    $funVal = $function.value
    $params = $funVal.params
    $defEnv = $funVal.defEnv
    #Write-Host INVOKE: TCO=$tco
    #$tco = $false

    $denv.EnterScope()
    $argList, $dotValue = Eval-Args $argsExp $params.length $defEnv $denv
    if (!$tco) {
        $defEnv.EnterScope()
        Extend-With-Args $argList $dotValue $function $defEnv $denv
        $result = Eval-Body $function.value.body $defEnv $denv $true
        $defEnv.LeaveScope()
    } else {
        # do not invoke enter/leave scope here
        Extend-With-Args $argList $dotValue $function $defEnv $denv
        $result = Eval-Body $function.value.body $defEnv $denv $true
    }
    $denv.LeaveScope()

    return $result
}

function Make-Function($env, $paramsExp, $body) {
    $function = New-Object Fun
    $function.defEnv = $env
    $function.isThunk = $false
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
    #Write-Host EVALUATE: $exp
    switch ($Exp.Type) {
        "Number" {
            return $exp
        }
        "Symbol" {
            $result =  LookUp $exp.value $env $denv
            if ($result.type -eq "Function" -and $result.value.isThunk) {
                $noArgs = New-Object Exp -ArgumentList ([ExpType]::Symbol), "NIL"
                $result = Invoke $result $noArgs $env $denv $false
                Update $exp.value $result $env $denv
            }
            return $result
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
        "Function" {
            return $exp
        }
        "BuiltIn" {
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
                        return Update $cdr.car.value (Evaluate $cdr.cdr.car $env $denv $false) $env $denv
                    }
                    "DEFINE" {
                        if ($cdr.car.Type -eq "Symbol") {
                            $name = $cdr.car.Value
                            $value = Evaluate $cdr.cdr.car $env $denv $false
                            $env.Declare($name, $value)
                            return $null
                        } else {
                            # (define (<name> . <params>) <body>)
                            $name = $cdr.car.car.value
                            $params = $cdr.car.cdr
                            $body = $cdr.cdr
                            $function = (Make-Function $env $params $body)
                            $env.Declare($name, $function)
                            return $null
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
                        return Eval-LetRec $cdr $env $denv $tco
                    }
                    "DYNAMIC" {
                        if ($cdr.car.Type -eq "Symbol") {
                            $name = $cdr.car.Value
                            $value = Evaluate $cdr.cdr.car $env $denv $false
                            $denv.Declare($name, $value)
                            return $value
                        } else {
                            # no functions for dynamic scope
                            return New-Object Exp -ArgumentList [ExpType]::Symbol, "NIL"
                        }
                    }
                    default {
                        $function = LookUp ($car.value) $env $denv
                        if ($function -ne $null) {
                            if ($function.type -eq "BuiltIn") {
                                return Call-BuiltIn $car.value $cdr $env $denv $tco
                            } elseif ($function.type -eq "Function") {
                                return Invoke $function $cdr $env $denv $tco
                            }
                        }
                        throw [EvaluatorException] "EVALUATE: Unknown Function $($car.value)"
                    }
                }
                throw [EvaluatorException] "EVALUATE: Unknown Error in $exp"
            } else {
                if ($car.Type -eq "Cons") {
                    $function = Evaluate $car $env $denv $false
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
