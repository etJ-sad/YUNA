# Block incoming connections on port 135
New-NetFirewallRule -DisplayName "Block Port 135 Inbound" -Direction Inbound -LocalPort 135 -Protocol TCP -Action Block

# Block outgoing connections on port 135
New-NetFirewallRule -DisplayName "Block Port 135 Outbound" -Direction Outbound -LocalPort 135 -Protocol TCP -Action Block

# Block incoming connections on port 445
New-NetFirewallRule -DisplayName "Block Port 445 Inbound" -Direction Inbound -LocalPort 445 -Protocol TCP -Action Block

# Block outgoing connections on port 445
New-NetFirewallRule -DisplayName "Block Port 445 Outbound" -Direction Outbound -LocalPort 445 -Protocol TCP -Action Block

# Block incoming connections on port 63105
New-NetFirewallRule -DisplayName "Block Port 63105 Inbound" -Direction Inbound -LocalPort 63105 -Protocol TCP -Action Block

# Block outgoing connections on port 63105
New-NetFirewallRule -DisplayName "Block Port 63105 Outbound" -Direction Outbound -LocalPort 63105 -Protocol TCP -Action Block
