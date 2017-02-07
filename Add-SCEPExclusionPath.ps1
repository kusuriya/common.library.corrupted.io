function Add-SCEPExclusionPath
{
    <#
        .DESCRIPTION
        This adds paths to the system center enpoint protection exclusion list on a list of machines, this is targeted toward machines that use Defender (8.1) or SCEP (2k8R2 or later)

        .PARAMETER ExclusionPathToAdd
        A string array of paths to add to the exclusion path

        .PARAMETER ComputerName
        A string array of computers that will be processed

        .PARAMETER CimSessionOptions
        This takes a CIM session option (New-CimSessionOption) by default it sets the protocol to dcom (New-CimSessionOption -Protocol Dcom)
    #>
    [cmdletbinding()]
    param
    (
        [Parameter(HelpMessage='This is a string array of paths to add to the exclusion list')]
        [ValidateNotNullOrEmpty()]
        [string[]]$ExclusionPathToAdd = '',

        [Parameter(HelpMessage='A string array of computers to run this on, defaults to the local machine')]
        [ValidateNotNullOrEmpty()]
        [string[]]$ComputerName = $env:COMPUTERNAME,

        [Parameter(HelpMessage='This is a cimsessionoption to deal with cim sessions. the default is protocol=DCOM')]
        [ValidateNotNullOrEmpty()]
        [CimSessionOptions]$CimSessionOptions = (New-CimSessionOption -Protocol Dcom)
    )
    try {
        $progress = 1
        foreach ($Computer in $ComputerName) {
            Write-Progress -Activity 'Setting Exclusion Path' -Status $Computer -PercentComplete ($progress/($ComputerName.count))
            Write-Verbose -Message "Starting work on $Computer"

            if ($CimSessionOptions) {
                $SessionArguments = @{
                    'SessionOption' = $CimSessionOptions
                    'ComputerName' = $Computer
                }
            }
            else {
                $SessionArguments = @{
                    'ComputerName' = $Computer
                }
            }

            # Check at protectionmanagement
            if ((Get-CimClass -Namespace 'ROOT\Microsoft\ProtectionManagement' -ClassName MSFT_MpPreference)) {
                Write-Verbose 'Found SCEP CIM Class at ROOT\Microsoft\ProtectionManagement'
                Invoke-CimMethod -CimSession (New-CimSession @SessionArguments) -ClassName MSFT_MpPreference -Namespace ROOT\Microsoft\ProtectionManagement -MethodName add -Arguments @{ ExclusionPath = $ExclusionPathToAdd }
            }
            # Check at the older defender namespace
            elseif ((Get-CimClass -Namespace 'ROOT\Microsoft\Windows\Defender' -ClassName MSFT_MpPreference)) {
                Write-Verbose 'Found SCEP CIM Class at ROOT\Microsoft\Windows\Defender'
                Invoke-CimMethod -CimSession (New-CimSession @SessionArguments) -ClassName MSFT_MpPreference -Namespace ROOT\Microsoft\Windows\Defender -MethodName add -Arguments @{ ExclusionPath = $ExclusionPathToAdd }
            }
            # NOOOOOOOOOOOOOOO
            else {
                Write-Error 'Could not find System Endpoint Protection'
            }
        }
        $progress++
    }
    catch {
        write-error $_
        break
    }
}