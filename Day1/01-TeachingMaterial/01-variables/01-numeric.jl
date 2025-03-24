# =============================================================================
# Julia Numeric Types Tutorial
# =============================================================================
#
# This tutorial covers the fundamental numeric types in Julia and their operations.
# Julia is dynamically typed but has a rich type system that makes it both flexible
# and performant for numerical computing.

# -----------------------------------------------------------------------------
# 1. INTEGER TYPES
# -----------------------------------------------------------------------------
# Julia integers are signed by default and their size depends on your system
# (typically Int64 on 64-bit systems)

one = 1    # Basic integer assignment
two = 2    # Another integer
A = 267    # Integers can be any size within their type limits

# For readability with large numbers, use underscore (_) as a separator
# This doesn't affect the value but makes it more readable for humans
large_number = 1_234_567    # Same as 1234567

# -----------------------------------------------------------------------------
# 2. FLOATING-POINT NUMBERS
# -----------------------------------------------------------------------------
# Floating-point numbers represent real numbers and follow IEEE 754 standard
# By default, Julia uses Float64 (double precision)

x = 3.14    # Basic float assignment
y = 2.72    # Another float

# Integers can be explicitly converted to floats by adding .0
one_float = 1.0    # This is a Float64, not an Int64
two_float = 2.0    # Another Float64

# Type checking is fundamental in Julia
# Use typeof() to inspect a variable's type
typeof(one)        # Will show Int64 on 64-bit systems
typeof(one_float)  # Will show Float64

# Scientific Notation
# Julia supports 'e' notation for scientific notation
1e3     # Equivalent to 1*10^3 or 1000
5.67e6  # Equivalent to 5.67*10^6 or 5_670_000

# -----------------------------------------------------------------------------
# 3. BASIC ARITHMETIC OPERATIONS
# -----------------------------------------------------------------------------
# Julia supports all standard mathematical operations
# and follows standard operator precedence (PEMDAS)

x + y    # Addition: Combines two numbers
x - y    # Subtraction: Finds the difference
x + one  # Type promotion: Integer automatically promoted to float
x * y    # Multiplication: Products of numbers
x / 2    # Division: Always produces a float
x^2      # Exponentiation: Raises x to the power of 2

# Complex expression with precedence
(1 + 2)^3 * 2 + 1    # Parentheses first, then exponents, multiplication, addition

# -----------------------------------------------------------------------------
# 4. SPECIAL MATHEMATICAL FUNCTIONS
# -----------------------------------------------------------------------------
# Julia provides many mathematical functions and special syntax

# Square root can be written two ways:
sqrt(2)    # Traditional function call
√2         # Special Unicode syntax (type \sqrt + TAB)

# Note: Try these examples in the REPL to see their results!
# You can get more information about any type using the help mode
# Type ? followed by the type name in the REPL (e.g., ?Int64)
