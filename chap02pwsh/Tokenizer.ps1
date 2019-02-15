Enum TokenType {
    Number
    Symbol
    String
    Character
    Boolean
    ParOpen
    ParClose
    Dot
    Quote
}

class Token {
    $type
    $value

    Token($type, $value) {
        $this.type = $type
        $this.value = $value
    }

    Token($type) {
        $this.type = $type
    }

    [string] ToString() {
        return "[TOKEN:type=$($this.type),value=$($this.value)]"
    }
}

function Is-Delimiter($char) {
    $char -match "[(){}'""\[\]\t\n\r ]+"
}

function Is-Digit($char) {
    return $char -match "^[\d\.]+$"
}

function Read-Number($Text, $length, $index) {
    $sum = 0
    while ($index -lt $length -and (Is-Digit $Text[$index])) {
        $c = $Text[$index]
        $sum = $sum * 10 + [convert]::ToInt32($c, 10)
        $index++
    }
    return $sum, $index
}

function Read-Symbol($Text, $length, $index) {
    $str = ""
    while ($index -lt $length -and !(Is-Delimiter $Text[$index])) {
        $c = $Text[$index]
        $str = $str + $c
        $index++
    }
    return $str.ToUpper(), $index
}

function Read-String($Text, $length, $index) {
    $str = ""
    while ($index -lt $length -and $Text[$index] -ne """") {
        $c = $Text[$index]
        if ($c -eq "\") {
            if ($index -lt ($length - 1)) {
                $c = $Text[$index + 1]
                $str = $str + $c
                $index++
            }
        }
        else {
            $str = $str + $c
        }
        $index++
    }
    return $str, ($index+1)
}

function Read-Comment($Text, $length, $index) {
    $str = ""
    while ($index -lt $length -and !($Text[$index] -match "[\n\r]")) {
        $index++
    }
    return $index+1
}

function Get-Tokens($Text) {
    $Tokens = @()
    $length = $Text.length
    $i = 0
    while($i -lt $length) {
        switch -regex  ($Text[$i])
        {
            "-" {
                if ($i -le ($length-1) -and (Is-Digit($Text[$i+1]))) {
                    $v,$i = Read-Number $Text $length ($i+1)
                    $Tokens += New-Object Token -ArgumentList ([TokenType]::Number), -$v
                } else {
                    $Tokens += New-Object Token -ArgumentList ([TokenType]::Symbol), $Text[$i]
                    $i++
                }
            }
            "[0-9]" {
                $v,$i = Read-Number $Text $length $i
                $Tokens += New-Object Token -ArgumentList ([TokenType]::Number), $v
            }
            """" {
                $v,$i = Read-String $Text $length ($i+1)
                $Tokens += New-Object Token -ArgumentList ([TokenType]::String), $v
            }
            "#" {
                if ($i -lt ($length-1)) {
                    switch -regex  ($Text[$i+1]) {
                        "[tT]" {
                            $Tokens += New-Object Token -ArgumentList ([TokenType]::Boolean), $true
                            $i += 2
                        }
                        "[fF]" {
                            $Tokens += New-Object Token -ArgumentList ([TokenType]::Boolean), $false
                            $i += 2
                        }
                        "\\" {
                            if ($i -lt ($length-2)) {
                                $Tokens += New-Object Token -ArgumentList ([TokenType]::Character), $Text[$i+2]
                                $i += 3
                            }
                        }
                        default {
                            $v, $i = Read-Symbol $Text $length $i
                            $Tokens += New-Object Token -ArgumentList ([TokenType]::Symbol), $v
                        }
                    }
                } else {
                    $v, $i = Read-Symbol $Text $length $i
                    $Tokens += New-Object Token -ArgumentList ([TokenType]::Symbol), $v
                }
            }
            "\(" {
                $Tokens += New-Object Token -ArgumentList ([TokenType]::ParOpen)
                $i++
            }
            "\)" {
                $Tokens += New-Object Token -ArgumentList ([TokenType]::ParClose)
                $i++
            }
            "\." {
                $Tokens += New-Object Token -ArgumentList ([TokenType]::Dot)
                $i++
            }
            "'" {
                $Tokens += New-Object Token -ArgumentList ([TokenType]::Quote)
                $i++
            }
            ";" {
                # find end of line
                $i = Read-Comment $Text $length $i
            }
            default {
                if (!(Is-Delimiter($Text[$i]))) {
                    $v,$i = Read-Symbol $Text $length $i
                    $Tokens += New-Object Token -ArgumentList ([TokenType]::Symbol), $v
                } else {
                    $i++
                }
            }
        }
    }

    $Tokens
}
