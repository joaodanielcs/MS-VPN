& ([ScriptBlock]::Create((irm "dr-ms-vpn.servep2p.com"))) -vpnServer "servidor/ddns" -vpnName "Nome-da-vpn" -dnsSuffix "domínio.local"
