include "utils";

# Get group from named args with default
($ARGS.named.group // "*") as $group |
.group = $group |

colors as $c |

# Define column widths
30 as $w_name | 10 as $w_type | 15 as $w_curr | 15 as $w_def | 40 as $w_vals | 50 as $w_desc |

# Print Header
"\($c.bold)\($c.yellow)\("Option" | pad($w_name)) \("Type" | pad($w_type)) \("Value" | pad($w_curr)) \("Default" | pad($w_def)) \("Values" | pad($w_vals)) \("Description" | pad($w_desc))\($c.reset)",
  
# Print separator
("-" * 150),

# Print options
(.options[] | select(.advanced == "FALSE") | select($group == "*" or (.groups | index($group))) |
    "\($c.cyan)\(.name | pad($w_name))\($c.reset) " +
    "\(.type | pad($w_type)) " +
    "\(.current | pad($w_curr)) " +
    "\(.default | pad($w_def)) " +
    "\((if .values | length > 0 then "[" + (.values | join(",")) + "]" else "" end) | pad($w_vals)) " +
    "\(.description | pad($w_desc))"
),

# Print separator
("-" * 150)
