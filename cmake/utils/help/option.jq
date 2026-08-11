include "utils";

($ARGS.named.group // "*") as $group |
($ARGS.named.termwidth // 150 | tonumber) as $termwidth |

colors as $c |

# Calculate column widths as percentages of terminal width
($termwidth * 0.27 | floor) as $w_name |
($termwidth * 0.07 | floor) as $w_type |
($termwidth * 0.11 | floor) as $w_curr |
($termwidth * 0.25 | floor) as $w_vals |
($termwidth * 0.28 | floor) as $w_desc |
($termwidth * 0.8 | floor) as $w_sep |

# Print Header
"\($c.bold)\($c.yellow)\("Option" | pad($w_name)) \("Type" | pad($w_type)) \("Value" | pad($w_curr)) \("Values" | pad($w_vals)) \("Description" | pad($w_desc))\($c.reset)",

("-" * $termwidth),

(.options[] | select(.advanced == "FALSE") | select($group == "*" or (.groups | index($group))) |
    "\($c.cyan)\(.name | pad($w_name))\($c.reset) " +
    "\(.type | pad($w_type)) " +
    "\(.current | pad($w_curr)) " +
    "\((if .values | length > 0 then "[" + (.values | join(",")) + "]" else "" end) | pad($w_vals)) " +
    "\(.description | pad($w_desc))"
),

("-" * $termwidth)
