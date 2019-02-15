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
        if ($this.array.containsKey($name)) {
            $cell = $this.array.$name
            if ($cell.level -lt $this.level) {
                $this.array[$name] = New-Object Cell $this.level $value $cell
            } else {
                $cell.value = $value    # illegal, not sure what to do ?throw an error?
            }
        } else {
            $this.array[$name] = New-Object Cell $this.level $value $null
        }
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
