class Environment {

    $level = 0
    $local_array = @{}
    $global_array = @{}
    $name

    Environment($name) {
        $this.name = $name
    }

    [Environment] Duplicate($name) {
        $result = New-Object Environment -ArgumentList $name
        $result.level = $this.level
        #Write-Host Duplicate: name=$name
        $result.global_array = $this.global_array
        $result.local_array = $this.local_array.Clone()
        return $result
    }

    [void] EnterScope() {
        #Write-Host Enter Scope name=$($this.name) ($this.level) -> ($this.level+1)
        $this.level++
    }

    [void] LeaveScope() {
        #Write-Host Leave Scope name=$($this.name) ($this.level) -> ($this.level-1)
        $nullCells = @()
        #Write-Host A level=$($this.level) $this.ArrayToString($this.local_array)
        foreach ($name in $($this.local_array.Keys)) {
            $cell = $this.local_array[$name]
            if ($cell.level -eq $this.level) {
                $this.local_array[$name] = $cell.next
                if ($cell.next -eq $null) {
                    $nullCells += $name
                }
            }
        }
        # if name becomes empty, remove?
        foreach ($name in $nullCells) {
            $this.local_array.Remove($name)
            #Write-Host LEAVE-SCOPE: "NULL_CELL: $name"
            #$this.local_array[$name] = $null
        }
        $this.level--
        #Write-Host B level=$($this.level) $this.ArrayToString($this.local_array)
    }

    # declares a new variable, but can also update if it already exists
    [void] Declare($name, $value) {
        if ($this.level -eq 0) {
            $this.global_array[$name] = $value
        } elseif ( $this.local_array.containsKey("$name")) {
            $cell = $this.local_array["$name"]
            if ($cell.level -eq $this.level) {
                $cell.value = $value
            } else {
                $this.local_array[$name] = New-Object Cell -ArgumentList $this.level, $value, $cell
            }
        } else {
            $this.local_array[$name] = New-Object Cell -ArgumentList $this.level, $value, $null
        }
    }

    [Exp] LookUp($name) {
        if ($this.local_array.containsKey("$name")) {
            $cell = $this.local_array["$name"]
            if ($cell -ne $null) {
                return $cell.value
            }
        }
        if ($this.global_array.containsKey("$name")) {
            return $this.global_array["$name"]
        }
        return $null
    }

    [boolean] Update($name, $value) {
        if ($this.local_array.containsKey("$name")) {
            $cell = $this.local_array["$name"]
            $cell.value = $value
            return $true
        }
        if ($this.global_array.containsKey("$name")) {
            $this.global_array["$name"] = $value
            return $true
        }
        return $false
    }

    [void] PrintEnv() {
        Write-Host "---BEGIN-ENV--- name=$($this.name)" level=$($this.level)
        $k = 1
        while ($k -le $this.level) {
            Write-Host -NoNewline "$k."
            #Write-Host LEVEL $k
            foreach ($key in $this.local_array.Keys) {
                $cell = $this.local_array["$key"]
                if ($cell -ne $null -and $cell.level -gt 0) {
                    $value = $cell.valueAt($k)
                    if ($value -eq $null) {
                        Write-Host -NoNewline $(" ".PadLeft(8,' '))":"$(" ".PadRight(8,' '))
                    } else {
                        #Write-Host $key $value
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
            $k++
        }
        Write-Host "----END-ENV----"
        Write-Host
    }

    [string] ArrayToString($array) {
        $str = ""
        $array.Keys | foreach-object {
            if ($array.containsKey("$_")) {
                $cell = $array["$_"]
                if ($cell -eq $null) {
                    $s = "NULL"
                } else {
                    if ($cell.value -eq $null) {
                        $s = "$($cell.level):NULL-VALUE"
                    } else {
                        $s = "$($cell.level):<...>"
                        #$s = "$($cell.level):$($cell.value)"
                    }
                }
            } else {
                $s = "null"
            }
            $str += "[$($_):$s]"
        }
        return $str
    }

    [string] ToString() {
        $str = ""
        #$str += "`n`tGLOBAL_ARRAY"
        #$str += $this.ArrayToString($this.global_array)
        $str += "`tLOCAL_ARRAY"
        $str += $this.ArrayToString($this.local_array)
        return "{env:`"$($this.name)`":level=$($this.level)$str}"
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
