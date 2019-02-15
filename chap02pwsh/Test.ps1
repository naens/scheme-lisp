
class A {
    $val

    [string] ToString() {
        return "{A:val=" + $this.val + "}"
    }
}

$a1 = New-Object A
$a1.val = 7
Write-Host $a1.val
$a2 = $a1
$a2.val = 8
Write-Host $a1.val
Write-Host $a2.val

$a = @{}
$a[1] = $a1
$a[2] = $a2

$a.Keys | ForEach-Object {
    Write-Host key=$_ "value=$($a[$_])"
}

$a

foreach ($x in $a.Keys) {
    Write-Host "a: ${x}: $($a[$x])"
}

Write-Host "=== CLONE A TO B ==="
$b = $a.Clone()

foreach ($x in $b.Keys) {
    Write-Host "b[${x}]:  $($b[$x])"
}

Write-Host "=== MODIFY B ==="
foreach($x in $($b.keys)){
    $b[$x] = 5
}
$b["qqq"] = 31

foreach ($x in $b.Keys) {
    Write-Host "b[${x}]:  $($b[$x])"
}

foreach ($x in $a.Keys) {
    Write-Host "a[${x}]:  $($a[$x])"
}
