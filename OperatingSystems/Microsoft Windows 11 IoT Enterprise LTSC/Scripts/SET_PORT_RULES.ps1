# SET_PORT_RULES.ps1 - Subscript for YUNA (Yielding Universal Node Automation)

# This script is responsible for:
# - Creating firewall rules to block specific ports (135, 445, 63105)
# - Logging each step of the process for tracking and debugging

# Define the script name dynamically
$scriptName = $MyInvocation.MyCommand.Name

# Log the start of the script execution
Write-Log "Script '$scriptName' started." "INFO"

# Define the ports and directions to block
$rules = @(
    @{ Name = "Block Port 135 Inbound";   Port = 135;   Direction = "Inbound"  },
    @{ Name = "Block Port 135 Outbound";  Port = 135;   Direction = "Outbound" },
    @{ Name = "Block Port 445 Inbound";   Port = 445;   Direction = "Inbound"  },
    @{ Name = "Block Port 445 Outbound";  Port = 445;   Direction = "Outbound" },
    @{ Name = "Block Port 63105 Inbound"; Port = 63105; Direction = "Inbound"  },
    @{ Name = "Block Port 63105 Outbound";Port = 63105; Direction = "Outbound" }
)

# Create each rule and log the result
foreach ($rule in $rules) {
    try {
        New-NetFirewallRule -DisplayName $rule.Name -Direction $rule.Direction -LocalPort $rule.Port -Protocol TCP -Action Block
        Write-Log "Firewall rule created: $($rule.Name)" "OK"
    } catch {
        Write-Log "Failed to create firewall rule '$($rule.Name)'. Error: $($_.Exception.Message)" "ERROR"
    }
}

# Log the completion of the script execution
Write-Log "Script '$scriptName' execution completed." "INFO"
