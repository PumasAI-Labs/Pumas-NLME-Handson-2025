# =============================================================================
# Julia Strings Tutorial
# =============================================================================
#
# Strings in Julia are immutable sequences of Unicode characters.
# They are versatile and support many operations for text manipulation.

include("02-booleans.jl")

# -----------------------------------------------------------------------------
# 1. STRING CREATION AND CHARACTER TYPES
# -----------------------------------------------------------------------------

# Double quotes create strings
str1 = "Hello, world!"    # Basic string creation

# Single quotes create characters (Char type)
char1 = 'A'              # Single character
char2 = 'B'              # Another character
# 'Hello, world!'        # This would cause an error - single quotes are for chars only

# Multi-line strings use triple quotes
text = """
Lorem ipsum dolor sit amet, consectetur adipiscing elit.
Quisque mollis suscipit tincidunt. Morbi vulputate libero ex,
quis maximus nunc rutrum non.
"""                      # Preserves all whitespace and newlines

# -----------------------------------------------------------------------------
# 2. STRING CONCATENATION
# -----------------------------------------------------------------------------
# Julia offers multiple ways to combine strings

greeting = "Hello"
name = "Jake"

# Method 1: Using string() function
string(greeting, ", ", name)    # Most flexible, can handle non-string types

# Method 2: Using * operator
greeting * ", " * name          # Efficient for string-only concatenation
# Note: + doesn't work for strings in Julia (unlike Python or JavaScript)

# -----------------------------------------------------------------------------
# 3. STRING INTERPOLATION
# -----------------------------------------------------------------------------
# Julia provides powerful string interpolation with $ and $()

# Simple variable interpolation
"$greeting, $name"             # Embeds variables directly

# Expression interpolation with $()
"One plus two is equal to $(1 + 2)"                                 # Basic arithmetic

"Absolute value of minus four minus one is equal to $(abs(-4) - 1)" # Function calls

# -----------------------------------------------------------------------------
# 4. PATTERN MATCHING AND SEARCHING
# -----------------------------------------------------------------------------
# Julia provides various functions for string searching

# Checking for substrings
contains("banana", "ana")       # Returns true (deprecated in newer versions)
occursin("ana", "banana")      # Modern way to check for substrings

# Checking string boundaries
startswith("banana", "ban")     # Check prefix
endswith("banana", "ana")       # Check suffix

# -----------------------------------------------------------------------------
# 5. STRING MANIPULATION AND FORMATTING
# -----------------------------------------------------------------------------
# Julia provides many built-in functions for string manipulation

sample_text = "This is an example"

# Case transformation
uppercase(sample_text)          # Convert to upper case
lowercase(sample_text)          # Convert to lower case
titlecase(sample_text)          # Capitalize first letter of each word

# String replacement
replace(sample_text,           # Replace multiple patterns
        "This is" => "That was",
        "an example" => "a comment")

# -----------------------------------------------------------------------------
# TIPS AND BEST PRACTICES
# -----------------------------------------------------------------------------
# 1. Use string() when mixing strings with other types
# 2. Prefer * over repeated string() calls for better performance
# 3. Use triple quotes for multi-line strings or strings with quotes
# 4. String interpolation with $() is powerful for complex expressions
# 5. Strings are immutable - operations create new strings

# Try these examples in the REPL!
# Type ?String in the REPL for more information about strings
