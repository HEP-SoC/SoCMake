include "utils";
# Get group from named args with default
($ARGS.named.group // "*") as $group |
($ARGS.named.termwidth // 150 | tonumber) as $termwidth |

colors as $c |

# Calculate column widths as percentages of terminal width
($termwidth * 0.30 | floor) as $w_name |
($termwidth * 0.69 | floor) as $w_desc |

# Print Header
"\($c.bold)\($c.yellow)\("Target" | pad($w_name)) \("Description" | pad($w_desc))\($c.reset)",
  
# Print separator
("-" * $termwidth),

# Print options
(.targets[] | select($group == "*" or (.groups | index($group))) |
    "\($c.cyan)\(.name | pad($w_name))\($c.reset) " +
    "\(.description | pad($w_desc))"
),

# Print separator
("-" * $termwidth)
