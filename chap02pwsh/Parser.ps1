Enum ExpType {
    Number
    Symbol
    String
    Character
    Boolean
    Cons
}

function Parse-List($Tokens, $length, $i) {
    $token = $Tokens[$i]
    $prev = $null
    $first = $null
    while ($i -lt $length) {
        switch ($token.Type) {
            "Dot" {
                $i++
                $exp, $i = Parse-Exp $Tokens $length $i
                if ($Tokens[$i].Type -eq "ParClose" -and $prev -ne $null) {
                    $i++
                    $prev.Value = @($prev.Value[0], $exp)
                    return $first, $i
                } else {
                    return $null, $null
                }
            }
            "ParClose" {
                $i++
                return $first, $i
            }
            default {
                $exp, $i = Parse-Exp $Tokens $length $i
                $nil = New-Object PSObject -Property @{ Type = [ExpType]::Symbol; Value = "NIL"}
                $cons = New-Object PSObject -Property @{ Type = [ExpType]::Cons; Value = @($exp, $nil)}
                if ($prev -ne $null) {
                    $prev.Value = @($prev.Value[0], $cons)
                }
                if ($first -eq $null) {
                    $first = $cons
                }
                $prev = $cons
            }
        }
        $token = $Tokens[$i]
    }
    return $null, $null
}

function Parse-Exp($Tokens, $length, $i) {
    $token = $Tokens[$i]
    switch ($token.Type) {
        "Number" {
            $exp = New-Object PSObject -Property @{ Type = [ExpType]::Number; Value = $token.Value}
            return $exp, ($i+1)
        }
        "Symbol" {
            $exp = New-Object PSObject -Property @{ Type = [ExpType]::Symbol; Value = $token.Value}
            return $exp, ($i+1)
        }
        "String" {
            $exp = New-Object PSObject -Property @{ Type = [ExpType]::String; Value = $token.Value}
            return $exp, ($i+1)
        }
        "Character" {
            $exp = New-Object PSObject -Property @{ Type = [ExpType]::Character; Value = $token.Value}
            return $exp, ($i+1)
        }
        "Boolean" {
            $exp = New-Object PSObject -Property @{ Type = [ExpType]::Boolean; Value = $token.Value}
            return $exp, ($i+1)
        }
        "ParOpen" {
            $exp, $i = Parse-List $Tokens $length ($i+1)
            return $exp, $i
        }
        "ParClose" {
            return $null, $null
        }
        "Dot" {
            return $null, $null
        }
        "Quote" {
            $car = New-Object PSObject -Property @{ Type = [ExpType]::Symbol; Value = "QUOTE"}
            $nil = New-Object PSObject -Property @{ Type = [ExpType]::Symbol; Value = "NIL"}
            $subexp, $i = Parse-Exp $Tokens $length ($i+1)
            $cdr = New-Object PSObject -Property @{ Type = [ExpType]::Cons; Value = @($subexp, $nil)}
            $exp = New-Object PSObject -Property @{ Type = [ExpType]::Cons; Value = @($car, $cdr)}
            return $exp, $i
        }
    }
    $exp = New-Object PSObject -Property @{ Type = [ExpType]::Number; Value = -1}
    return $exp, ($i+1)
}

function Exp-To-String($Exp) {
    switch ($Exp.Type) {
        "Number" {
            return "num:"+$Exp.Value
        }
        "Symbol" {
            return "sym:"+$Exp.Value
        }
        "String" {
            return "str:"+$Exp.Value
        }
        "Character" {
            return "chr:"+$Exp.Value
        }
        "Boolean" {
            return "bool:" + $Exp.Value
        }
        "Cons" {
            $car = Exp-To-String $Exp.Value[0]
            $cdr = Exp-To-String $Exp.Value[1]
            return "cons:{"+$car+","+$cdr+"}"
        }
    }
}

function Parse-Tokens($Tokens) {
    $i = 0
    $Exps = @()
    $length = $Tokens.length
    while ($i -lt $length) {
        $exp, $i = Parse-Exp $Tokens $length $i
        if ($exp) {
            $Exps += $exp
        }
        else {
            break
        }
    }
    $Exps
}
