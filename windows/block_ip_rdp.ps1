#Requires -RunAsAdministrator
#建议保存编码为：bom头 + utf8
#--------------用户输入------------------
$存盘盘符 = 'e:\'
#--------------脚本开始------------------
$输入ip黑名单点txt = $存盘盘符 + '3389ip黑名单.txt'
$msg =
@'
本脚本屏蔽ip文本里面的ip
'@
Write-Host $msg



if (Test-Path $输入ip黑名单点txt)
{
}
else
{
	Write-Error '找不到 输入ip黑名单文件，脚本无法工作！'
	exit 1
}

#禁用系统默认防火墙规则。
#RemoteDesktop-UserMode-In-TCP,RemoteDesktop-UserMode-In-UDP
# Get-NetFirewallPortFilter |
# 	Where-Object LocalPort -EQ 12918 |
# 	Get-NetFirewallRule |
# 	Where-Object { $_.Direction -eq "Inbound" -and $_.Enabled -eq $true } |
# 	Set-NetFirewallRule -Enabled false


#删除旧黑名单
Remove-NetFirewallRule -Name 'ban3389'
Start-Sleep -Seconds 2


#应用新黑名单。
New-NetFirewallRule `
	-Name 'ban3389' `
	-DisplayName '远程桌面_ip黑名单' `
	-Enabled True `
	-Direction Inbound `
	-Protocol TCP `
	-Action Block `
	-LocalPort 12839

$黑名单 = Get-Content -LiteralPath $输入ip黑名单点txt -ReadCount 0
try
{
  Write-Host '屏蔽IP：' + $黑名单
  Set-NetFirewallRule -Name 'ban3389' -RemoteAddress $黑名单
}
catch
{

}
finally
{
  Enable-NetFirewallRule -Name 'ban3389'
}

if ((Get-Service mpssvc).status -ne 'Running')
{
	Write-Error 'win防火墙服务，没运行！'
}
Write-Host '管理员powershell运行下列命令，即可删除黑名单规则：Remove-NetFirewallRule -Name ban3389'
Write-Host '完成'
Start-Sleep -Seconds 3