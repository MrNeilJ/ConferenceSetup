Function WaitForKey {
	Write-Host
	Write-Host "Press any key to continue..." -ForegroundColor Black -BackgroundColor White
	[Console]::ReadKey($true) | Out-Null
}

Function Set-ScreenResolution { 
 
<# 
    .Synopsis 
        Sets the Screen Resolution of the primary monitor 
    .Description 
        Uses Pinvoke and ChangeDisplaySettings Win32API to make the change 
    .Example 
        Set-ScreenResolution -Width 1024 -Height 768         
    #> 
param ( 
[Parameter(Mandatory=$true, 
           Position = 0)] 
[int] 
$Width, 
 
[Parameter(Mandatory=$true, 
           Position = 1)] 
[int] 
$Height 
) 
 
$pinvokeCode = @" 
 
using System; 
using System.Runtime.InteropServices; 
 
namespace Resolution 
{ 
 
    [StructLayout(LayoutKind.Sequential)] 
    public struct DEVMODE1 
    { 
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] 
        public string dmDeviceName; 
        public short dmSpecVersion; 
        public short dmDriverVersion; 
        public short dmSize; 
        public short dmDriverExtra; 
        public int dmFields; 
 
        public short dmOrientation; 
        public short dmPaperSize; 
        public short dmPaperLength; 
        public short dmPaperWidth; 
 
        public short dmScale; 
        public short dmCopies; 
        public short dmDefaultSource; 
        public short dmPrintQuality; 
        public short dmColor; 
        public short dmDuplex; 
        public short dmYResolution; 
        public short dmTTOption; 
        public short dmCollate; 
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] 
        public string dmFormName; 
        public short dmLogPixels; 
        public short dmBitsPerPel; 
        public int dmPelsWidth; 
        public int dmPelsHeight; 
 
        public int dmDisplayFlags; 
        public int dmDisplayFrequency; 
 
        public int dmICMMethod; 
        public int dmICMIntent; 
        public int dmMediaType; 
        public int dmDitherType; 
        public int dmReserved1; 
        public int dmReserved2; 
 
        public int dmPanningWidth; 
        public int dmPanningHeight; 
    }; 
 
 
 
    class User_32 
    { 
        [DllImport("user32.dll")] 
        public static extern int EnumDisplaySettings(string deviceName, int modeNum, ref DEVMODE1 devMode); 
        [DllImport("user32.dll")] 
        public static extern int ChangeDisplaySettings(ref DEVMODE1 devMode, int flags); 
 
        public const int ENUM_CURRENT_SETTINGS = -1; 
        public const int CDS_UPDATEREGISTRY = 0x01; 
        public const int CDS_TEST = 0x02; 
        public const int DISP_CHANGE_SUCCESSFUL = 0; 
        public const int DISP_CHANGE_RESTART = 1; 
        public const int DISP_CHANGE_FAILED = -1; 
    } 
 
 
 
    public class PrmaryScreenResolution 
    { 
        static public string ChangeResolution(int width, int height) 
        { 
 
            DEVMODE1 dm = GetDevMode1(); 
 
            if (0 != User_32.EnumDisplaySettings(null, User_32.ENUM_CURRENT_SETTINGS, ref dm)) 
            { 
 
                dm.dmPelsWidth = width; 
                dm.dmPelsHeight = height; 
 
                int iRet = User_32.ChangeDisplaySettings(ref dm, User_32.CDS_TEST); 
 
                if (iRet == User_32.DISP_CHANGE_FAILED) 
                { 
                    return "Unable To Process Your Request. Sorry For This Inconvenience."; 
                } 
                else 
                { 
                    iRet = User_32.ChangeDisplaySettings(ref dm, User_32.CDS_UPDATEREGISTRY); 
                    switch (iRet) 
                    { 
                        case User_32.DISP_CHANGE_SUCCESSFUL: 
                            { 
                                return "Success"; 
                            } 
                        case User_32.DISP_CHANGE_RESTART: 
                            { 
                                return "You Need To Reboot For The Change To Happen.\n If You Feel Any Problem After Rebooting Your Machine\nThen Try To Change Resolution In Safe Mode."; 
                            } 
                        default: 
                            { 
                                return "Failed To Change The Resolution"; 
                            } 
                    } 
 
                } 
 
 
            } 
            else 
            { 
                return "Failed To Change The Resolution."; 
            } 
        } 
 
        private static DEVMODE1 GetDevMode1() 
        { 
            DEVMODE1 dm = new DEVMODE1(); 
            dm.dmDeviceName = new String(new char[32]); 
            dm.dmFormName = new String(new char[32]); 
            dm.dmSize = (short)Marshal.SizeOf(dm); 
            return dm; 
        } 
    } 
} 
 
"@ 
 
Add-Type $pinvokeCode -ErrorAction SilentlyContinue 
[Resolution.PrmaryScreenResolution]::ChangeResolution($width,$height) 
} 
Write-Host "Setting Screen Resolution"
Invoke-Expression WaitForKey
set-screenresolution -width 1920 -height 1080

Write-Host "Install the Meraki client"
Invoke-Expression WaitForKey
$theAnswer = Read-Host -Prompt 'Do you want to install the Meraki client? [Y/N]'
If ($theAnswer -like 'Y'){
	Write-Host "Silently install Meraki Systems Manager."
	#Invoke-Expression WaitForKey      
	$spath = "$path\MerakiSM-Agent-systems-manager.msi"
	$args = "/quiet","/qn"
	If (Test-Path $spath){
		Start-Process -FilePath "$spath" -ArgumentList $args -Wait
		#Write-Host "Meraki Systems Manager Agent has been installed.  Next, open Workplace settings and enroll in device management."
		Write-Host "Meraki Systems Manager Agent has been installed." -ForegroundColor darkgreen -BackgroundColor white
		Write-Host "Press any key to complete MDM enrollment." -ForegroundColor darkgreen -BackgroundColor white
		Invoke-Expression WaitForKey
		#Start ms-settings:workplace
		$LOU = $env:username
		Start ms-device-enrollment:?mode=mdm"&"username=$LOU@thetradedesk.com"&"servername=n196.meraki.com
		$theAnswer = Read-Host -Prompt 'Did MDM enrollment error out? [Y/N]'
		If ($theAnswer -like 'Y'){
			Write-Host "Press any key to complete MDM enrollment." -ForegroundColor darkgreen -BackgroundColor white
			Invoke-Expression WaitForKey
			Start ms-device-enrollment:?mode=mdm"&"username=$LOU@thetradedesk.com"&"servername=n196.meraki.com
		}
	}
	Else {
		$spath = "$path\MerakiPCCAgent.msi"
		try {
			Invoke-WebRequest -Uri "https://n196.meraki.com/ci-downloads/2afb705e9bdac0f700c962ba6205c30be9235c62/MerakiPCCAgent.msi" -OutFile $spath -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
		} catch {
			$ErrorMsg = $_.Exception.Message
			Write-Host "Error: $ErrorMsg." -ForegroundColor red -BackgroundColor yellow
			Write-Host "Unable to download Meraki client.  Download it from Dropbox and manually install.  Skipping." -ForegroundColor red -BackgroundColor yellow
			Break
		}
		Start-Process -FilePath "$spath" -ArgumentList $args -Wait
	}
}
Else
{
	Write-Host "Skipping Meraki Systems Manager install."
}


Write-Host "Install the Sophos client"
Invoke-Expression WaitForKey
$theAnswer = Read-Host -Prompt 'Do you want to install the Sophos client? [Y/N]'
If ($theAnswer -like 'Y'){
    Write-Host "Install Sophos Endpoint Agent."
    Invoke-Expression WaitForKey
    $spath = "$path\SophosInstall.exe"
    $args = "--quiet" #Doesn't work yet as we need to find correct setup file.
    Invoke-WebRequest -Uri "https://dzr-api-amzn-us-west-2-fa88.api-upe.p.hmr.sophos.com/api/download/6ceb214b1bcbc3464fbf89ca7b2387f8/SophosInstall.exe" -OutFile $spath -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -ErrorVariable SophosDLError
    if ($SophosDLError) {
        Write-Host "Error: $SophosDLError." -ForegroundColor red -BackgroundColor yellow
        Write-Host "Unable to download Sophos installer.  Please install manually.  Skipping." -ForegroundColor red -BackgroundColor yellow
    } else {
        Start-Process -FilePath $spath -ArgumentList $args -Wait -NoNewWindow | Out-Null
        Write-Host "Sophos installation is finished." -ForegroundColor darkgreen -BackgroundColor white
    }
}
Else
{
	Write-Host "Skipping Sophos install."
}


Write-Host "Install the Zoom Rooms client"
Invoke-Expression WaitForKey
$theAnswer = Read-Host -Prompt 'Do you want to install the Zoom Rooms client? [Y/N]'
If ($theAnswer -like 'Y'){
	Write-Host "Launching Zoom Rooms Application Download / Setup"
    Invoke-Expression WaitForKey
    $spath = "$path\ZoomRooms.exe"
    Invoke-WebRequest -Uri "https://zoom.us/client/latest/ZoomRooms.exe" -OutFile $spath -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
    Start-Process -FilePath $spath
    Write-Host "Zoom Rooms Installation Finished." -ForegroundColor darkgreen -BackgroundColor white
}
Else
{
	Write-Host "Skipping Zoom Rooms install."
}

Write-Host "Disabling Wifi"
Invoke-Expression WaitForKey
Disable-NetAdapter -Name "Wi-Fi" -Confirm:$false

Write-Host "Setup completed, ending script"

exit


