#unwrapPoSh
#20181020:zG

param (
[string]$encodedBlob,
[string]$infile
)

if($encodedBlob) {
    $encodedBlob > zGtempUnwraposh
    $infile=".\zGtempUnwraposh"
}

foreach($line in Get-Content $infile) {

if ($infile) {
$encodedBlob=$line
$c++
Write-debug "`nscript #$c`n"
$encbytecode=$str64decoded=$matches=$deflated=$inflated=$outstr=$x=$final=$null
}

#start building an object 
     $outObj = New-Object -TypeName psobject    
     $outObj | Add-Member -MemberType NoteProperty -Name item  -value $c -PassThru |
             Add-Member -MemberType NoteProperty -Name startBlob -Value $encodedBlob -PassThru |
             Add-Member -MemberType NoteProperty -Name startLength -Value $encodedBlob.Length

#First we undo the base64 encoding
try {
    $str64decoded=[System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($encodedBlob))
   # [Byte[]]$b64dec = [System.Convert]::FromBase64String($encodedBlob)  <== in case we need a byte stream
} catch {
    write-warning "does not seem to be base64"
}

$x = $str64decoded -match '::FromBase64String\([''"](?<content>.*)[''"]'

if  ($x) {  #only change $encodedBlob (input) if it contains data marked as needing base64decode
    $encodedBlob=$matches['content']
}
else {
    write-debug "there's not a base64-encoded blob embedded"
# ToDo:  consider setting $encodedBlob to the output of the first decoding, $str64decoded 
#    if ($encodedBlob.substring(0,4) -eq "H4sI") {write-host "probably base64-encoded gzipped data";exit}
}

try {  #we expect to be undoing base64(gzip(data)) here
    $deflated=New-Object IO.MemoryStream(,[Convert]::FromBase64String($encodedBlob))
    $inflated=(New-Object IO.StreamReader(New-Object IO.Compression.GzipStream($deflated,[IO.Compression.CompressionMode]::Decompress))).ReadToEnd()
} catch {
    Write-debug "The encoded blob does not seem to derive from gzipped data"
}

$x = $inflated -match '::FromBase64String\([''"](?<content>.*)[''"]'
if ($x) {
    $encbytecode=$matches['content']
} else {
    write-debug "`nno additional embedded base64 code; this is as far as we got:`n $str64decoded "
    # ToDo:  note ln44 & here we should use $encodedBlob
    }

# add to the object
     $outObj |  Add-Member -MemberType NoteProperty -Name str64decoded  -value $str64decoded -PassThru |
                Add-Member -MemberType NoteProperty -Name inflated  -value $inflated -PassThru |
                Add-Member -MemberType NoteProperty -Name encodedbytecode -Value $encbytecode

#Write-debug "`nbase64-encoded bytecode: `n"$encbytecode
$final = [System.Convert]::FromBase64String($encbytecode)
$outStr="{0}" -f [string]($final | ForEach-Object ToString X2)
$outstr=$outstr -replace " ",""
#Write-debug "`nbytecode, as hex: `n" $outstr
# here's how to get an xxd-style hexdump
#($final | Format-Hex  )

# add last bits to the object
     $outObj |  Add-Member -MemberType NoteProperty -Name decodedHex -Value $outstr -PassThru |
                Add-Member -MemberType NoteProperty -Name final -Value $final -PassThru |
                Add-Member -MemberType NoteProperty -Name endlength -Value $final.Length
Write-Output $outObj
}

if ($infile -eq ".\zGtempUnwraposh") {
    # only necessary if no $infile at commandline
    remove-item ".\zGtempUnwraposh"
}

