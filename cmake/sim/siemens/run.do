run -all

# After simulation finishes, inspect status
set status [coverage attribute -name TESTSTATUS -concise]

# 0=ok, 1=warning, 2=error, 3=fatal
# Dont fail on warning or ok
if {$status >= 2} {
    quit -f -code $status
}

quit -f -code 0
