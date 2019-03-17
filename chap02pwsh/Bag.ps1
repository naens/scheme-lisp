class Bag {

    [System.Collections.ArrayList]$queue
    [System.Collections.ArrayList]$tokens
    $level

    $is_quote
    Bag() {
        $this.queue = @()
        $this.tokens = @()
        $this.level = 0
        $this.is_quote = $false
    }

    [void] addTokens($list) {
        foreach ($token in $list) {
            if ($token.type -eq "Quote") {
                if ($this.is_quote -or $this.tokens.count -eq 0) {
                    $this.is_quote = $true
                }
            } else {
                $this.is_quote = $false
            }
            $this.tokens.Add($token)
            if ($token.type -eq "ParOpen") {
                $this.level++
            }
            if ($token.type -eq "ParClose") {
                $this.level--
            }
            if ($this.level -eq 0 -and -not $this.is_quote) {
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
