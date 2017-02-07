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

function Start-UDPPacketGenerator {
	param
	(
		[System.Net.IPaddress]$TargetIP = 255.255.255.255,
		[int]$TargetPort = 2501,
		[TimeSpan]$Duration = (New-Timespan -Seconds 5),
        [Int]$SleepDuration
	)
	# Generate around a max udp packets worth of random data
	$set = 'azertyuiopqsdfghjklmwxcvbnAZERTYUIOPQSDFGHJKLMWXCVBN0123456789-_'
	$SendBuffer = 1..4 | ForEach-Object {
		$rndChars = $set | Get-Random -Count $set.Count
		$str = -join $rndChars
		# repeat random string 4096 times to get a 256KB string
		$str * 4
	}
	# Make it bytes and store it for use
	$send = [System.Text.Encoding]::ASCII.GetBytes($SendBuffer)
	
	# Set up the UDP send
	$ping = new-object System.Net.Sockets.UdpClient
	$ping.EnableBroadcast = $true
	$ping.Connect($targetip,$targetport)

	# Send for the duration in packets that was specified
	$Timer = [Diagnostics.Stopwatch]::StartNew()
	while ($Timer.Elapsed -lt $duration)
	{
		$null = $ping.Send($send,$send.count)
        if ($SleepDuration) {
            Start-Sleep -Milliseconds $SleepDuration
        }
	}
	end
	{
		$Timer.stop()
		$Ping.Close()
		$Ping.Finalize()
		$Ping.Dispose()
	}
}
