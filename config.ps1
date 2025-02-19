param (
    [string]$vpnServer,
    [string]$vpnName,
    [string]$dnsSuffix,
    [string]$dnsServer1,
    [string]$dnsServer2
)
$vpnUserName = Read-Host -Prompt 'Digite o nome de usuário da VPN sem @domínio'
$vpnPassword = Read-Host -Prompt 'Digite a senha da VPN' -AsSecureString

#if (Get-VpnConnection -Name $vpnName -ErrorAction SilentlyContinue) { Remove-VpnConnection -Name $vpnName -Force ; remove-item "C:\ProgramData\Microsoft\Network\Connections\Pbk\rasphone.pbk" -force ; remove-item "%userprofile%\AppData\Roaming\Microsoft\Network\Connections\Pbk\rasphone.pbk" -force ; remove-item "%userprofile%\AppData\Roaming\Microsoft\Network\Connections\Pbk\Pbk\_hiddenPbk\rasphone.pbk" -force }
Remove-VpnConnection -Name $vpnName -Force -ErrorAction SilentlyContinue
Remove-Item "C:\ProgramData\Microsoft\Network\Connections\Pbk\rasphone.pbk" -force -ErrorAction SilentlyContinue
Remove-Item "$env:APPDATA\Microsoft\Network\Connections\Pbk\rasphone.pbk" -force -ErrorAction SilentlyContinue
Remove-Item "$env:APPDATA\Microsoft\Network\Connections\Pbk\Pbk\_hiddenPbk\rasphone.pbk" -force -ErrorAction SilentlyContinue

Write-Host "Configurando $vpnName"
sleep 10
Add-VpnConnection -Name $vpnName -ServerAddress $vpnServer -TunnelType Automatic -AuthenticationMethod MSChapv2 -EncryptionLevel Required -SplitTunneling $false -DnsSuffix $dnsSuffix -Force

$rasPhoneConfig = @"
[$vpnName]
Encoding=1
PBVersion=8
Type=2
AutoLogon=0
UseRasCredentials=1
LowDateTime=-1630143456
HighDateTime=31162960
DialParamsUID=7004953
Guid=D578A632DAF16F41A285CBB0D4AFB373
VpnStrategy=0
ExcludedProtocols=8
LcpExtensions=1
DataEncryption=8
SwCompression=0
NegotiateMultilinkAlways=0
SkipDoubleDialDialog=0
DialMode=0
OverridePref=15
RedialAttempts=3
RedialSeconds=60
IdleDisconnectSeconds=0
RedialOnLinkFailure=1
CallbackMode=0
ForceSecureCompartment=0
DisableIKENameEkuCheck=0
AuthenticateServer=0
ShareMsFilePrint=1
BindMsNetClient=1
SharedPhoneNumbers=0
GlobalDeviceSettings=0
PreferredPort=VPN2-0
PreferredDevice=WAN Miniport (IKEv2)
PreferredBps=0
PreferredHwFlow=1
PreferredProtocol=1
PreferredCompression=1
PreferredSpeaker=1
PreferredMdmProtocol=0
PreviewUserPw=1
PreviewDomain=1
PreviewPhoneNumber=0
ShowDialingProgress=1
ShowMonitorIconInTaskBar=0
CustomAuthKey=0
AuthRestrictions=552
IpPrioritizeRemote=1
IpInterfaceMetric=0
IpHeaderCompression=0
IpAddress=0.0.0.0
IpDnsAddress=$dnsServer1
IpDns2Address=$dnsServer2
IpWinsAddress=0.0.0.0
IpWins2Address=0.0.0.0
IpAssign=1
IpNameAssign=2
IpDnsFlags=3
IpNBTFlags=1
TcpWindowSize=0
UseFlags=2
IpSecFlags=0
IpDnsSuffix=$dnsSuffix
Ipv6Assign=1
Ipv6Address=::
Ipv6PrefixLength=0
Ipv6PrioritizeRemote=1
Ipv6InterfaceMetric=0
Ipv6NameAssign=1
Ipv6DnsAddress=::
Ipv6Dns2Address=::
Ipv6Prefix=0000000000000000
Ipv6InterfaceId=0000000000000000
DisableClassBasedDefaultRoute=0
DisableMobility=0
NetworkOutageTime=1800
ImsConfig=0
IdiType=0
IdrType=0
ProvisionType=0
CacheCredentials=1
NumCustomPolicy=0
NumEku=0
UseMachineRootCert=0
Disable_IKEv2_Fragmentation=0
PlumbIKEv2TSAsRoutes=0
NumServers=0
RouteVersion=1
NumRoutes=0
NumNrptRules=0
AutoTiggerCapable=0
NumAppIds=0
NumClassicAppIds=0
ApnInfoAuthentication=1
ApnInfoCompression=0
DeviceComplianceEnabled=0
DeviceComplianceSsoEnabled=0
FlagsSet=0
Options=0
DisableDefaultDnsSuffixes=0
NumTrustedNetworks=0
NumDnsSearchSuffixes=0
PowershellCreatedProfile=0
ProxyFlags=0
ProxySettingsModified=0
AuthTypeOTP=0
GREKeyDefined=0
NumPerAppTrafficFilters=0
AlwaysOnCapable=0
DeviceTunnel=0
PrivateNetwork=0

ms_msclient=1
ms_server=1

MEDIA=rastapi
Port=VPN2-0
Device=WAN Miniport (IKEv2)

DEVICE=vpn
PhoneNumber=$vpnServer
CountryCode=0
CountryID=0
UseDialingRules=0
LastSelectedPhone=0
PromoteAlternates=0
TryNextAlternateOnFail=1
"@

$rasPhonePath = "$env:APPDATA\Microsoft\Network\Connections\Pbk\rasphone.pbk"
Add-Content -Path $rasPhonePath -Value $rasPhoneConfig
$rasPhonePath = "C:\ProgramData\Microsoft\Network\Connections\Pbk\rasphone.pbk"
Add-Content -Path $rasPhonePath -Value $rasPhoneConfig
$rasPhonePath = "$env:APPDATA\Microsoft\Network\Connections\Pbk\Pbk\_hiddenPbk\rasphone.pbk"
Add-Content -Path $rasPhonePath -Value $rasPhoneConfig
# Adiciona a credencial do Windows para a VPN
$credential = New-Object System.Management.Automation.PSCredential ("$vpnUserName@$dnsSuffix", $vpnPassword)
$target = $dnsSuffix
$username = "$vpnUserName@$dnsSuffix"
$credentials = New-Object -TypeName PSCredential -ArgumentList $username, $vpnPassword
cmdkey /add:$target /user:$username /pass:$vpnPassword
Get-NetConnectionProfile | ForEach-Object {
    if ($_.NetworkCategory -ne "Private") {
        Set-NetConnectionProfile -InputObject $_ -NetworkCategory Private
    }
}
Remove-Item (Get-PSReadlineOption).HistorySavePath -Force

