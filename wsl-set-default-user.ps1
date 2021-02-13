# function to get distros
function Get-Distros()
{
    # wsl seems to output Unicode always. When parsing results in PowerShell it will try to convert
    # to Unicode strings (again) assuming it's in the Console.OutputEncoding code page (437 in my case).
    # This causes incorrect results. We are forcing Console.OutputEncoding to be Unicode here
    # to avoid the unnecessary conversion.
    $consoleEncoding = [Console]::OutputEncoding;
    [Console]::OutputEncoding = [System.Text.Encoding]::Unicode;
    $result = wsl -l -q;
    [Console]::OutputEncoding = $consoleEncoding;

    return $result;
}

# get and make sure there are distros
Write-Host 'Getting distros...';
$distroList = @(Get-Distros);
if ($distroList.Length -le 0)
{
    Write-Error 'No distro found';
    Exit 1;
}

# prompt and get the distro to move
Write-Host "Select distro to change default user:";
$id = 0;
$distroList | ForEach-Object { Write-Host "$($id+1): $($distroList[$id])" -ForegroundColor Yellow; $id++; }
$selected = [int](Read-Host);
if (($selected -gt $distroList.Length) -or ($selected -le 0))
{
    Write-Error "Invalid selection. Select a distro from 1 to $($distroList.Length)";
    Exit 1;
}
$distro = $distroList[$selected - 1];



# get target directory
Write-Host 'Select user name:';
$userName = Read-Host;

# confirm
$confirm = Read-Host "change default user $($distro) to `"$($userName)`"? (y|n)";
if ($confirm -ne 'Y')
{
    Write-Error 'User canceled';
    Exit 1;
}

Write-Host "change $($distro) default user to $($userName)..."

Get-ItemProperty Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Lxss\*\ DistributionName | 
Where-Object -Property DistributionName -eq $distro | Set-ItemProperty -Name DefaultUid -Value ((wsl -d $distro -u $userName -e id -u) | 
Out-String); 


Write-Host "ok"