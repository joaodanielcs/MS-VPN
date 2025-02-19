param (
    [string]$vpnServer,
    [string]$vpnName,
    [string]$dnsSuffix
)
$vpnUserName = Read-Host -Prompt 'Digite o nome de usuário da VPN sem @domínio'
$vpnPassword = Read-Host -Prompt 'Digite a senha da VPN' -AsSecureString
$plainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($vpnPassword))
$dnsServer1 = "192.168.6.254"
$dnsServer2 = "192.168.6.253"
$username = "$vpnUserName@$dnsSuffix"

Get-VpnConnection -AllUserConnection -ErrorAction SilentlyContinue | Remove-VpnConnection -force -ErrorAction SilentlyContinue
Get-VpnConnection -Name "VPN" -ErrorAction SilentlyContinue | Remove-VpnConnection -force -ErrorAction SilentlyContinue
Get-VpnConnection -Name "DrMonitora" -ErrorAction SilentlyContinue | Remove-VpnConnection -force -ErrorAction SilentlyContinue
Get-VpnConnection -Name "VPN-DrMonitora" -ErrorAction SilentlyContinue | Remove-VpnConnection -force -ErrorAction SilentlyContinue
Remove-VpnConnection -Name $vpnName -Force -ErrorAction SilentlyContinue
Remove-Item "C:\ProgramData\Microsoft\Network\Connections\Pbk\rasphone.pbk" -force -ErrorAction SilentlyContinue
Remove-Item "$env:AppData\Microsoft\Network\Connections\Pbk\rasphone.pbk" -force -ErrorAction SilentlyContinue
Remove-Item "$env:AppData\Microsoft\Network\Connections\Pbk\_hiddenPbk\rasphone.pbk" -force -ErrorAction SilentlyContinue
cmdkey /delete:$dnsSuffix
sleep 5
cmdkey /add:$dnsSuffix /user:$username /pass:$plainPassword
sleep 5
Write-Host "Configurando $vpnName"
Add-VpnConnection -Name $vpnName -ServerAddress $vpnServer -TunnelType Automatic -AuthenticationMethod MSChapv2 -EncryptionLevel Required -SplitTunneling $false -DnsSuffix $dnsSuffix -Force
$rasPhonePath = "$env:AppData\Microsoft\Network\Connections\Pbk\rasphone.pbk"
$contents = Get-Content -Path $rasphonePath
function Update-Value {
    param (
        [string]$line,
        [string]$key,
        [string]$newValue
    )
    if ($line -match "^\s*${key}=") {
        return "${key}=${newValue}"
    }
    return $line
}
$updatedContents = $contents | ForEach-Object {
    $_ = Update-Value -line $_ -key 'ExcludedProtocols' -newValue '8'
    $_ = Update-Value -line $_ -key 'DataEncryption' -newValue '8'
    $_ = Update-Value -line $_ -key 'PreferredHwFlow' -newValue '1'
    $_ = Update-Value -line $_ -key 'PreferredProtocol' -newValue '1'
    $_ = Update-Value -line $_ -key 'PreferredCompression' -newValue '1'
    $_ = Update-Value -line $_ -key 'PreferredSpeaker' -newValue '1'
    $_ = Update-Value -line $_ -key 'ShowMonitorIconInTaskBar' -newValue '0'
    $_ = Update-Value -line $_ -key 'AuthRestrictions' -newValue '552'
    $_ = Update-Value -line $_ -key 'IpPrioritizeRemote' -newValue '1'
    $_ = Update-Value -line $_ -key 'IpDnsAddress' -newValue $dnsServer1
    $_ = Update-Value -line $_ -key 'IpDns2Address' -newValue $dnsServer2
    $_ = Update-Value -line $_ -key 'IpNameAssign' -newValue '2'
    $_ = Update-Value -line $_ -key 'IpDnsFlags' -newValue '3'
    $_ = Update-Value -line $_ -key 'Ipv6PrioritizeRemote' -newValue '1'
    $_ = Update-Value -line $_ -key 'CacheCredentials' -newValue '1'
    $_ = Update-Value -line $_ -key 'PowershellCreatedProfile' -newValue '0'
    $_
}
Set-Content -Path $rasphonePath -Value $updatedContents
Get-NetConnectionProfile | ForEach-Object { 
    if ($_.NetworkCategory -ne "Private") { 
        Set-NetConnectionProfile -InputObject $_ -NetworkCategory Private 
    } 
}
rasdial $vpnName $vpnUserName $plainPassword
clear
sleep 10
net use t: \\$dnsSuffix\global
ls t:
net use t: /del
Write-Host "$vpnName Configurada com sucesso."
Remove-Item (Get-PSReadlineOption).HistorySavePath -Force
