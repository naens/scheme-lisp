Enum ExpType {
    Number
    Symbol
    String
    Character
    Boolean
    Cons
    Function
    BuiltIn
}

class Exp {
    $type
    $value
    $car
    $cdr
    $defEnv
    $params
    $dotParam

    Exp($type) {
        $this.type = $type
        [ExpType]$t = $this.type
        if ($t -eq "[ExpType]::BuiltIn") {
            throw "Exp: BuiltIn creation bad arguments"
        }
    }

    Exp($type, $value) {
        $this.type = $type
        [ExpType]$t = $this.type
        if ($t -eq "Cons") {
            throw "Exp: Cons creation bad arguments"
        }
        $this.value = $value
    }

    Exp($type, $car, $cdr) {
        $this.type = $type
        [ExpType]$t = $this.type
        if ($t -ne "Cons") {
            throw "Exp: Cons creation bad type " + $type
        }
        $this.car = $car
        $this.cdr = $cdr
    }

    [string] ToString0() {
        [ExpType]$t = $this.type
        switch ($t) {
            "Number" {
                return "num:"+$this.value
            }
            "Symbol" {
                return "sym:"+$this.value
            }
            "String" {
                return "str:"+$this.value
            }
            "Character" {
                return "chr:"+$this.value
            }
            "Boolean" {
                return "bool:" + $this.value
            }
            "Cons" {
                return "cons:{$($this.car),$($this.cdr)}"
            }
            default {
                return "{$t}"
            }
        }
        return "<unknown-expr>: " + $this.type
    }

    [string] MakeSublistString($cons) {
        if ($cons.cdr.type -eq "Cons") {
            $restString = $this.MakeSublistString($cons.cdr)
            return $cons.car.ToString() + " " + $restString
        } if ($cons.cdr.type -eq "Symbol" -and $cons.cdr.value -eq "NIL") {
            return $cons.car.ToString()
        } else {
            return $cons.car.ToString() + " . " + $cons.cdr.ToString()
        }
    }

    [string] ToString() {
        [ExpType]$t = $this.type
        switch ($t) {
            "Number" {
                return $this.value
            }
            "Symbol" {
                return $this.value
            }
            "String" {
                return """$($this.value)"""
            }
            "Character" {
                return "#\$($this.value)"
            }
            "Boolean" {
                if ($this.value) {
                    return "#t"
                } else {
                    return "#f"
                }
            }
            "Cons" {
                $subList = $this.MakeSublistString($this)
                return "($subList)"
            }
            default {
                return "<<<$t>>>"
            }
        }
        return "<<<unknown-expr:" + $this.type + ">>>"
    }
}

function Parse-List($Tokens, $length, $i) {
    $token = $Tokens[$i]
    $prev = $null
    $first = $null
    while ($i -lt $length) {
        switch ("[TokenType]::$($token.type)") {
            "[TokenType]::Dot" {
                $i++
                $exp, $i = Parse-Exp $Tokens $length $i
                if ($Tokens[$i].Type -eq "ParClose" -and $prev -ne $null) {
                    $i++
                    $prev.cdr = $exp
                    return $first, $i
                } else {
                    return $null, $null
                }
            }
            "[TokenType]::ParClose" {
                $i++
                return $first, $i
            }
            default {
                $exp, $i = Parse-Exp $Tokens $length $i
                $nil = New-Object Exp -ArgumentList ([ExpType]::Symbol), "NIL"
                $cons = New-Object Exp -ArgumentList ([ExpType]::Cons), $exp, $nil
                if ($prev -ne $null) {
                    $prev.cdr = $cons
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
    switch ("[TokenType]::$($token.type)") {
        "[TokenType]::Number" {
            $exp = New-Object Exp -ArgumentList ([ExpType]::Number), $token.value
            return $exp, ($i+1)
        }
        "[TokenType]::Symbol" {
            $exp = New-Object Exp -ArgumentList ([ExpType]::Symbol), $token.value
            return $exp, ($i+1)
        }
        "[TokenType]::String" {
            $exp = New-Object Exp -ArgumentList ([ExpType]::String), $token.value
            return $exp, ($i+1)
        }
        "[TokenType]::Character" {
            $exp = New-Object Exp -ArgumentList ([ExpType]::Character), $token.value
            return $exp, ($i+1)
        }
        "[TokenType]::Boolean" {
            $exp = New-Object Exp -ArgumentList ([ExpType]::Boolean), $token.value
            return $exp, ($i+1)
        }
        "[TokenType]::ParOpen" {
            $exp, $i = Parse-List $Tokens $length ($i+1)
            return $exp, $i
        }
        "[TokenType]::ParClose" {
            return $null, $null
        }
        "[TokenType]::Dot" {
            return $null, $null
        }
        "[TokenType]::Quote" {
            $car = New-Object Exp -ArgumentList ([ExpType]::Symbol), "QUOTE"
            $nil = New-Object Exp -ArgumentList ([ExpType]::Symbol), "NIL"
            $subexp, $i = Parse-Exp $Tokens $length ($i+1)
            $cdr = New-Object Exp -ArgumentList ([ExpType]::Cons), $subexp, $nil
            $exp = New-Object Exp -ArgumentList ([ExpType]::Cons), $car, $cdr
            return $exp, $i
        }
    }
    $exp = New-Object Exp -ArgumentList ([ExpType]::Number), -1
    return $exp, ($i+1)
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
