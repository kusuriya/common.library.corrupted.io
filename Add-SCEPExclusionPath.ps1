<#
Copyright 2017 Jason Barbier (jason@corrupted.io)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), 
to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, 
and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, 
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#>

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
        [Parameter(
            HelpMessage='A string array of computers to run this on, defaults to the local machine',
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true,
            Position=0)]
        [ValidateNotNullOrEmpty()]
        [string[]]$ComputerName = $env:COMPUTERNAME,

        [Parameter(
            HelpMessage='This is a string array of paths to add to the exclusion list',
            Position=1)]
        [ValidateNotNullOrEmpty()]
        [string[]]$ExclusionPathToAdd = '',

        [Parameter(
            HelpMessage='This is a cimsessionoption to deal with cim sessions. the default is protocol=DCOM',
            Position=2)]
        [ValidateNotNullOrEmpty()]
        [CimSessionOptions]$CimSessionOptions = (New-CimSessionOption -Protocol Dcom)
    )
    process 
    {
        try 
        {
            Write-Progress -Activity 'Setting Exclusion Path' -Status $ComputerName
            Write-Verbose -Message "Starting work on $ComputerName"

            if ($CimSessionOptions) {
                $SessionArguments = @{
                    'SessionOption' = $CimSessionOptions
                    'ComputerName' = $ComputerName
                }
            }
            else {
                $SessionArguments = @{
                    'ComputerName' = $ComputerName
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
        catch 
        {
            write-error $_
            break
        }
    }
}