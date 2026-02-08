include "utils";

# Get group from named args with default
($ARGS.named.group // "*") as $group |
.group = $group |

colors as $c |

# Define column widths
80 as $w_name | 60 as $w_desc |

# Print Header
"\($c.bold)\($c.yellow)\("Target" | pad($w_name)) \("Description" | pad($w_desc))\($c.reset)",
  
# Print separator
("-" * 150),

# Print options
(.targets[] | select($group == "*" or (.groups | index($group))) |
    "\($c.cyan)\(.name | pad($w_name))\($c.reset) " +
    "\(.description | pad($w_desc))"
),

# Print separator
("-" * 150)
