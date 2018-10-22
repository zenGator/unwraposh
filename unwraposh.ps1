#unwrapPoSh
#20181020:zG

param (
[string]$encodedBlob,
[string]$infile
)

foreach($line in Get-Content $infile) {

if ($infile) {
$encodedBlob=$line
$c++
Write-debug "`nscript #$c`n"
$encbytecode=$b64dec=$str64dec=$matches=$deflated=$inflated=$outstr=$embedded= $x = $final = $null
}

#start building an object 

     $outObj = New-Object -TypeName psobject    

     $outObj | Add-Member -MemberType NoteProperty -Name item  -value $c -PassThru |
             Add-Member -MemberType NoteProperty -Name startBlob -Value $encodedBlob -PassThru |
             Add-Member -MemberType NoteProperty -Name startLength -Value $encodedBlob.Length


#Write-Host $encodedBlob
try {
    [Byte[]]$b64dec = [System.Convert]::FromBase64String($encodedBlob)
    $str64decoded=[System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($encodedBlob))
} catch {
    throw "does not seem to be base64"
    exit
}

#Write-Host "`nstr64decoded:`n"$str64decoded


$x = $str64decoded -match '::FromBase64String\([''"](?<content>.*)[''"]'

if  ($x) {
    $encodedBlob=$matches['content']
}
else {
    write-debug "there's not a base64-encoded-gzipped blob embedded"
#    if ($encodedBlob.substring(0,4) -eq "H4sI") {write-host "strings equal";exit}
}

try {
    #Write-Host "`nencodedBlob`n"$encodedBlob
    $deflated=New-Object IO.MemoryStream(,[Convert]::FromBase64String($encodedBlob))
    $inflated=(New-Object IO.StreamReader(New-Object IO.Compression.GzipStream($deflated,[IO.Compression.CompressionMode]::Decompress))).ReadToEnd()
} catch {
    Write-debug "The encoded blob does not seem to derive from gzipped data"
}
#Write-Host "`ninflated:`n"$inflated

$x = $inflated -match '::FromBase64String\([''"](?<content>.*)[''"]'
if ($x) {
    $encbytecode=$matches['content']
} else {
    write-debug "`nno additional embedded base64 code; this is as far as we got:`n $str64decoded "
    }

#add to the object
     $outObj | Add-Member -MemberType NoteProperty -Name str64decoded  -value $str64decoded -PassThru |
            Add-Member -MemberType NoteProperty -Name inflated  -value $inflated -PassThru |
             Add-Member -MemberType NoteProperty -Name encodedbytecode -Value $encbytecode

#Write-debug "`nbase64-encoded bytecode: `n"$encbytecode
$final = [System.Convert]::FromBase64String($encbytecode)
$outStr="{0}" -f [string]($final | ForEach-Object ToString X2)
$outstr=$outstr -replace " ",""
#Write-debug "`ndecoded, as hex: `n" $outstr
#($final | Format-Hex  )



#add to the object
     $outObj | Add-Member -MemberType NoteProperty -Name decodedHex -Value $outstr -PassThru |
             Add-Member -MemberType NoteProperty -Name final -Value $final -PassThru |
             Add-Member -MemberType NoteProperty -Name endlength -Value $final.Length

Write-Output $outObj
}

