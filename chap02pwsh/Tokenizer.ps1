Enum TokenType {
    Number
    Symbol
    String
    Character
    ParOpen
    ParClose
    Dot
    Quote
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
    return $str, $index
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

function Read-Character($Text, $length, $index) {
    if ($index -lt ($length - 2) -and $Text[$index+1] -eq "\") {
        return $Text[$index + 2]
    }
    return -1
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
    Write-Host TEXT: $Text
    Write-Host length: $length
    $i = 0
    while($i -lt $length) {
        switch -regex  ($Text[$i])
        {
            "-" {
                if ($i -le ($length-1) -and (Is-Digit($Text[$i+1]))) {
                    $v,$i = Read-Number $Text $length ($i+1)
                    $Tokens += New-Object PSObject -Property @{ Type = [TokenType]::Number; Value = -$v }
                } else {
                    $Tokens += New-Object PSObject -Property @{ Type = [TokenType]::Symbol; Value = $Text[$i] }
                    $i++
                }
            }
            "[0-9]" {
                $v,$i = Read-Number $Text $length $i
                $Tokens += New-Object PSObject -Property @{ Type = [TokenType]::Number; Value = $v}
            }
            """" {
                $v,$i = Read-String $Text $length ($i+1)
                $Tokens += New-Object PSObject -Property @{ Type = [TokenType]::String; Value = $v}
            }
            "#" {
                $c = Read-Character $Text $length $i
                if ($c -eq -1) {
                    $v, $i = Read-Symbol $Text $length $i
                    $Tokens += New-Object PSObject -Property @{ Type = [TokenType]::Symbol; Value = $v }
                }
                else {
                    $Tokens += New-Object PSObject -Property @{ Type = [TokenType]::Character; Value = $c }
                    $i += 3
                }
            }
            "\(" {
                $Tokens += New-Object PSObject -Property @{ Type = [TokenType]::ParOpen }
                $i++
            }
            "\)" {
                $Tokens += New-Object PSObject -Property @{ Type = [TokenType]::ParClose }
                $i++
            }
            "\." {
                $Tokens += New-Object PSObject -Property @{ Type = [TokenType]::Dot }
                $i++
            }
            "'" {
                $Tokens += New-Object PSObject -Property @{ Type = [TokenType]::Quote }
                $i++
            }
            ";" {
                # find end of line
                $i = Read-Comment $Text $length $i
            }
            default {
                if (!(Is-Delimiter($Text[$i]))) {
                    $v,$i = Read-Symbol $Text $length $i
                    $Tokens += New-Object PSObject -Property @{ Type = [TokenType]::Symbol; Value = $v}
                } else {
                    $i++
                }
            }
        }
    }

    $Tokens
}