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
        $this.level++
    }

    [void] LeaveScope() {
        foreach ($name in $($this.array.Keys)) {
            $cell = $this.array[$name]
            if ($cell.level = $this.level) {
                $this.array[$name] = $cell.next
            }
        }
        $this.level--
    }

    [void] Declare($name, $value) {
        Write-Host name=$name value=$value
        if ($this.array.containsKey($name)) {
            $cell = $this.array.$name
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

    [string] ToString() {
        $str = ""
        $this.array.Keys | foreach-object {
            if ($this.array.containsKey($_)) {
                $cell = $this.array[$_]
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

    Cell($level, $value, $next) {
        $this.level = $level
        $this.value = $value
        $this.next = $next
    }
}
