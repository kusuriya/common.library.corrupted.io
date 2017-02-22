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

function Start-UDPPacketGenerator 
{
	param
	(
		[Parameter(HelpMessage='Ip address you want to send UDP packets to')][ValidateNotNullOrEmpty()]
		[System.Net.IPaddress]$TargetIP = 255.255.255.255,

		[Parameter(HelpMessage='Port to send the packets to')][ValidateNotNullOrEmpty()]
		[int]$TargetPort = 2501,

		[Parameter(HelpMessage='How long do we want to generate packets for?')][ValidateNotNullOrEmpty()]
		[TimeSpan]$Duration = (New-Timespan -Seconds 5),

		[Parameter(HelpMessage='if you want any sort of delay between packets to help with rate limiting (int in miliseconds)')]
        [Int]$SleepDuration,

		[Parameter(HelpMessage='Are we trying to send a message?')]
		[string]$Message
	)
	begin
	{
		# Generage a byte payload, if there isnt a message specified make up some random garbage
		if (!$Message)
		{
			# Generate around a max udp packets worth of random data
			$set = 'azertyuiopqsdfghjklmwxcvbnAZERTYUIOPQSDFGHJKLMWXCVBN0123456789-_'
			$SendBuffer = 1..4 | ForEach-Object {
				$rndChars = $set | Get-Random -Count $set.Count
				$str = -join $rndChars
				# repeat random string 4096 times to get a 256KB string
				# this is roughly the max size of a UDP packet without fragmenting.
				$str * 4
			}
			# Make it bytes and store it for use
			$Payload = [System.Text.Encoding]::UTF8.GetBytes($SendBuffer)
		}
		# Otherwise just byte encode the message
		else 
		{
			$Payload = [System.Text.Encoding]::UTF8.GetBytes($Message)
		}
	}
	process
	{	
		# Set up the UDP send
		$ping = new-object System.Net.Sockets.UdpClient
		$ping.EnableBroadcast = $true
		$ping.Connect($targetip,$targetport)

		# Send for the duration in packets that was specified
		$Timer = [Diagnostics.Stopwatch]::StartNew()
		while ($Timer.Elapsed -lt $duration)
		{
			# Send() will always print out the amout of bytes sent
			# as such we just tell it to send that data to null,
			# We are really only worried about sending not what we sent.
			$null = $ping.Send($Payload,$Payload.count)
			if ($SleepDuration) {
				Start-Sleep -Milliseconds $SleepDuration
			}
		}
		$Timer.Stop()
	}
	end
	{
		$Ping.Close()
	}
}
