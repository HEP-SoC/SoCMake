# Color definitions
def colors:
    {
        reset: "\u001b[0m",
        bold: "\u001b[1m",
        cyan: "\u001b[36m",
        green: "\u001b[32m",
        blue: "\u001b[34m",
        yellow: "\u001b[33m"
    };

# Function to pad or truncate text to a specific width
def pad(width):
    if length > width then 
        .[0:width-3] + "..." 
    else 
        . + (" " * (width - length)) 
    end;
