#set-executionpolicy remotesigned

Write-Host ""
Write-Host ""
Write-Host "Beginning of script"
Write-Host ""
Write-Host ""

Write-Host " * Checking memory card for errors..."
echo "y"|chkdsk e: /f | Out-Null


$MemCardPath = "E:\DCIM\"
$MemStagingPath1 = "C:\MemCardStaging\"
$TargetPath1 = "C:\Temp\"


$Timestamp1 = Get-Date -Format "yyyy-MM-dd_HH.mm.ss"
$Timestamp1 = "Import_" + $Timestamp1

$MemStagingPath = $MemStagingPath1 + $Timestamp1 + "\"
$TargetPath = $TargetPath1 + $Timestamp1 + "\"



Function Rename-Pictures
{    
    Param ( 
        [Parameter(Mandatory=$FALSE)][string]$Path = (Get-Location), 
        [Parameter(Mandatory=$FALSE)][string]$BackupFileName = '_backupdata.csv'
    ) 
  
    Begin 
    { 
        [reflection.assembly]::LoadFile("C:\Windows\Microsoft.NET\Framework\v4.0.30319\System.Drawing.dll") 
        $Script:ErrorLogMsg = $Null
        $Script:CorrectPath = $Null
    } 
  
    Process 
    { 
        # Workaround for correct path from user 
        if ($Path.EndsWith('\\')) 
        { 
            $ImgsFound = Get-ChildItem ($Path + '*') -Include *.jpeg, *.png, *.gif, *.jpg, *.bmp, *.png | Select-Object -Property FullName, Name, BaseName, Extension 
        } 
        else
        { 
            $ImgsFound = Get-ChildItem ($Path + '\\*') -Include *.jpeg, *.png, *.gif, *.jpg, *.bmp, *.png | Select-Object -Property FullName, Name, BaseName, Extension 
        } 
          
        # If any file was found 
        If ($ImgsFound.Count -gt 0) {         
            # Print the number of images found to the user 
            # Write-Host -Object ("# of pictures suitable for renaming in " + $Path + ": " + $ImgsFound.Count + "`n") 
    
            # Loops through the images found 
            foreach ($Img in $ImgsFound)  
            { 
                # Gets image data 
                $ImgData = New-Object System.Drawing.Bitmap($Img.FullName) 
 
 
                $ImgDimensions =  $ImgData.Width.ToString() + $("x") + $ImgData.Height.ToString()
 
  
                try  
                { 
                    # Gets 'Date Taken' in bytes 
                    [byte[]]$ImgBytes = $ImgData.GetPropertyItem(36867).Value 
                } 
                catch [System.Exception], [System.IO.IOException]
                { 
                    [string]$ErrorMessage = ( 
                        (Get-Date).ToString('yyyyMMdd HH:mm:ss') + "`tERROR`tDid not change name for " + $Img.Name + ". Reason: " + $Error
                    ) 
                    $Script:ErrorLogMsg += $ErrorMessage + "`r`n"
                    Write-Host -ForegroundColor Red -Object $ErrorMessage
  
                    # Clears any error messages 
                    $Error.Clear() 
  
                    # No reason to continue. Move on to the next file 
                    continue
                } 
  
                # Gets the date and time from bytes 
                [string]$dateString = [System.Text.Encoding]::ASCII.GetString($ImgBytes) 
                # Formats the date to the desired format 
                [datetime]$extractedDateTime = [datetime]::ParseExact($dateString,"yyyy:MM:dd HH:mm:ss`0",$Null)
                [string]$dateTaken1 = $extractedDateTime.ToString('yyyy-MM-dd_HH.mm.ss')
                [int]$milliSeconds = $extractedDateTime.ToString('ms')
                [string]$dateTaken2 = '{0:d4}' -f $milliSeconds
                [string]$dateTaken = $dateTaken1 + "." + $dateTaken2
                # The new file name for the image 
                #[string]$NewFileName = $dateTaken + '-' + $Img.Name 
                [string]$NewFileName = $dateTaken + '-' + $Img.Name# + [System.IO.Path]::GetExtension($Img.Name)
                  
                $ImgData.Dispose() 
                try 
                {  
                    Move-Item -Path $Img.FullName -Destination ($TargetPath + $NewFileName) -ErrorAction Stop 
                    # Write-Host -Object ("Renamed " + $Img.Name + " to " + $NewFileName) 
                } 
                catch 
                { 
                    [string]$ErrorMessage = ( 
                        (Get-Date).ToString('yyyyMMdd HH:mm:ss') + "`tERROR`tDid not change name for "  + $Img.Name + ". Reason: " + $Error
                    ) 
                    $Script:ErrorLogMsg += $ErrorMessage + "`r`n"
                    Write-Host -ForegroundColor Red -Object $ErrorMessage
  
                    # Clears any previous error messages 
                    $Error.Clear() 
  
                    # No reason to continue. Move on to the next file 
                    continue
                } 

  
            } # foreach 
  

        } # if imgcount > 0 
        else { 
            #Write-Host -Object ("Found 0 image files at " + $Path) 
        } 
  

    } 
  
    End{} 
}

md $MemStagingPath | Out-Null
md $TargetPath | Out-Null

$RobocopyArgs1 = '$RECYCLE.BIN'

Write-Host " * Moving all files from memory card to staging area..."
robocopy $MemCardPath $MemStagingPath /e /ndl /move /xd $RobocopyArgs1 /xa:sh /np | Out-Null

Write-Host " * Double-checking memory card for errors..."
chkdsk e: /f | Out-Null

Write-Host ""
Write-Host ">>> YOU CAN 'EJECT' AND REMOVE THE MEMORY CARD NOW"
Write-Host ""
Write-Host ">>> You can also start the next memory card"
Write-Host ""


Write-Host " * Processing photos from staging area into Temp..."

$MemStagingFolders = Get-ChildItem -Path $MemStagingPath -Recurse -Directory -ErrorAction SilentlyContinue | Select-Object FullName

foreach($iterPath in $MemStagingFolders)
{
    Rename-Pictures -Path $iterPath.FullName | Out-Null
}

Rename-Pictures -Path $MemStagingPath | Out-Null

Write-Host " * Done processing photos from staging area into Temp"
Write-Host ""
Write-Host ""

Write-Host "End of script"
