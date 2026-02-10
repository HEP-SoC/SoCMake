include "utils";

($ARGS.named.group // "*") as $group |
($ARGS.named.termwidth // 150 | tonumber) as $termwidth |

colors as $c |

# Calculate column widths as percentages of terminal width
($termwidth * 0.20 | floor) as $w_name |      # 20%
($termwidth * 0.08 | floor) as $w_type |      # 8%
($termwidth * 0.12 | floor) as $w_curr |      # 12%
($termwidth * 0.25 | floor) as $w_vals |      # 25%
($termwidth * 0.34 | floor) as $w_desc |      # 34%
($termwidth * 0.8 | floor) as $w_sep |      # 80%

# Print Header
"\($c.bold)\($c.yellow)\("Option" | pad($w_name)) \("Type" | pad($w_type)) \("Value" | pad($w_curr)) \("Values" | pad($w_vals)) \("Description" | pad($w_desc))\($c.reset)",

("-" * $w_sep),

(.options[] | select(.advanced == "FALSE") | select($group == "*" or (.groups | index($group))) |
    "\($c.cyan)\(.name | pad($w_name))\($c.reset) " +
    "\(.type | pad($w_type)) " +
    "\(.current | pad($w_curr)) " +
    "\((if .values | length > 0 then "[" + (.values | join(",")) + "]" else "" end) | pad($w_vals)) " +
    "\(.description | pad($w_desc))"
),

("-" * $w_sep)
