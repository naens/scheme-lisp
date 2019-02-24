class Environment {

    $level = 0

    $array = @{}

    [Environment] Duplicate() {
        $result = New-Object Environment
        $result.level = $this.level
        $result.array = $this.array.Clone()
        return $result
    }

    [void] EnterScope() {
        #Write-Host Enter Scope ($this.level) -> ($this.level+1)
        $this.level++
    }

    [void] LeaveScope() {
        #Write-Host Leave Scope ($this.level) -> ($this.level-1)
        foreach ($name in $($this.array.Keys)) {
            # TODO: if name becomes empty, remove?
            $cell = $this.array[$name]
            if ($cell.level -eq $this.level) {
                $this.array[$name] = $cell.next
            }
        }
        $this.level--
    }

    # declares a new variable, but can also update if it already exists
    [void] Declare($name, $value) {
        #Write-Host name=$name value=$value
        if ($this.array.containsKey("$name")) {
            $cell = $this.array["$name"]
            if ($cell.level -lt $this.level) {
                $newcell = New-Object Cell -ArgumentList $this.level, $value, $cell
                $this.array[$name] = $newcell
            } else {
                $cell.value = $value    # illegal, not sure what to do ?throw an error?
            }
        } else {
            $this.array[$name] = New-Object Cell -ArgumentList $this.level, $value, $null
        }
    }

    [Exp] LookUp($name) {
        if ($this.array.containsKey("$name")) {
            $cell = $this.array["$name"]
            if ($cell -ne $null) {
                return $cell.value
            }
        }
        return $null
    }

    [boolean] Update($name, $value) {
        if ($this.array.containsKey("$name")) {
            $cell = $this.array["$name"]
            $cell.value = $value
            return $true
        }
        return $false
    }

    [void] PrintEnv() {
        Write-Host "---BEGIN-ENV---" level=$($this.level)
        foreach ($k in 1..$this.level) {
            Write-Host -NoNewline "$k."
            foreach ($key in $this.array.Keys) {
                $cell = $this.array["$key"]
                if ($cell.level -gt 0) {
                    $value = $cell.valueAt($k)
                    if ($value -eq $null) {
                        Write-Host -NoNewline $(" ".PadLeft(8,' '))":"$(" ".PadRight(8,' '))
                    } else {
                        if ($cell.value.type -eq "Function") {
                            $cellString = "#<fun:$($cell.value.value)>"
                        } elseif ($cell.value.type -eq "BuiltIn") {
                            $cellString = "#<bin:$($cell.value.value)>"
                        } else {
                            $cellString = $cell.valueAt($k).ToString()
                        }
                        Write-Host -NoNewline $($key.PadLeft(8,' '))":"$($cellString.PadRight(8,' '))
                    }
                }
            }
            Write-Host
        }
        Write-Host "----END-ENV----"
        Write-Host
    }

    [boolean] UpdateDynamic($name, $value) {
        if ($this.array.containsKey("$name")) {
            $cell = $this.array["$name"]
            if ($cell.level -eq $this.level) {
                $cell.value = $value
            } else {
                $newcell = New-Object Cell -ArgumentList $this.level, $value, $cell
                $this.array[$name] = $newcell
            }
            return $true
        }
        return $false
    }

    [string] ToString() {
        $str = ""
        $this.array.Keys | foreach-object {
            if ($this.array.containsKey("$_")) {
                $cell = $this.array["$_"]
                $value = "$($cell.level):$($cell.value)"
            } else {
                $value = "null"
            }
            $str += "[$($_):$value]"
        }
        return "{env:level=$($this.level),array=$str}"
    }
}

class Cell {
    $level
    $value
    $next

    [Exp] valueAt($k) {
        if ($k -eq $this.level) {
            return $this.value
        }
        if ($this.next -ne $null) {
            return $this.next.valueAt($k)
        }
        return $null
    }

    Cell($level, $value, $next) {
        $this.level = $level
        $this.value = $value
        $this.next = $next
    }
}
