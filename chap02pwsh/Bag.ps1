class Bag {

    [System.Collections.ArrayList]$queue
    [System.Collections.ArrayList]$tokens
    $level

    Bag() {
        $this.queue = @()
        $this.tokens = @()
        $this.level = 0
    }

    [void] addTokens($list) {
        foreach ($token in $list) {
            $this.tokens.Add($token)
            if ($token.type -eq "ParOpen") {
                $this.level++
            }
            if ($token.type -eq "ParClose") {
                $this.level--
            }
            if ($this.level -eq 0) {
                $this.queue.Add($this.tokens)
                $this.tokens = @()
            } elseif ($this.level -lt 0) {
                $this.tokens = @()
                $this.level = 0
            }

        }
    }

    [boolean] isEmpty()  {
        return $this.queue.count -eq 0
    }

    [Token[]] takeExp() {
        if ($this.queue.count -ne 0) {
            $result = $this.queue[0]
            $this.queue.RemoveAt(0)
            return $result
        }
        return $null
    }
}
