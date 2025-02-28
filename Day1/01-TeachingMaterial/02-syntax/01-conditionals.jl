# =============================================================================
# Julia Control Flow Tutorial - Part 1: Conditional Statements
# =============================================================================
#
# Conditional statements allow programs to make decisions and execute different
# code blocks based on boolean conditions. Julia provides several elegant ways
# to express conditional logic.

# -----------------------------------------------------------------------------
# 1. BASIC IF-ELSE STRUCTURE
# -----------------------------------------------------------------------------

# Initialize variables for demonstration
x = 1
y = 2

# Basic if-elseif-else structure
if x < y                        # Condition 1: Is x less than y?
    println("x is less than y") # Execute if condition 1 is true
elseif x > y                    # Condition 2: Is x greater than y?
    println("x is greater than y") # Execute if condition 2 is true
else                           # No conditions were true
    println("x is equal to y")  # Execute if all conditions were false
end                            # Required to close the conditional block

# -----------------------------------------------------------------------------
# 2. MODIFYING VALUES AND TESTING CONDITIONS
# -----------------------------------------------------------------------------

# Try different values to see different outcomes
x = 3    # Now x > y
x = 2    # Now x = y

# -----------------------------------------------------------------------------
# 3. MULTIPLE ELSEIF BRANCHES
# -----------------------------------------------------------------------------

# Example with multiple conditions and value ranges
a = 12.5    # Test value

if a < 5
    # Local variable assignment within conditional block
    message = "a is less than 5"
elseif a < 10    # This is checked only if a ≥ 5
    message = "a is less than 10, but greater than 5"
elseif a < 15    # This is checked only if a ≥ 10
    message = "a is less than 15, but greater than 10"
    # Note: else branch is optional
end

# Display the result
println(message)

# -----------------------------------------------------------------------------
# 4. TERNARY OPERATOR
# -----------------------------------------------------------------------------
# Compact single-line conditional expression
# Syntax: condition ? value_if_true : value_if_false

# Example 1: Basic ternary operation
b = 8
c = b < 10 ? 2b : b    # If b < 10, set c = 2b; otherwise set c = b
                       # Here, c will be 16 (since 8 < 10, c = 2*8)

# Example 2: Change the input to see different result
b = 12
c = b < 10 ? 2b : b    # Now c will be 12 (since 12 ≥ 10, c = b)

# -----------------------------------------------------------------------------
# TIPS AND BEST PRACTICES
# -----------------------------------------------------------------------------
# 1. Always use end to close conditional blocks
# 2. Indent code blocks for readability
# 3. Use elseif instead of nested if-else when possible
# 4. Use ternary operator for simple, single-line conditions
# 5. Consider using && and || for compound conditions
# 6. Remember that conditions must evaluate to Bool

# Common Patterns:
# - Guarding against invalid values:
#   if x < 0 error("x must be positive") end
#
# - Setting default values:
#   result = isempty(arr) ? 0 : first(arr)
#
# - Chaining conditions:
#   if 0 ≤ x < 10 println("single digit") end

# Try in the REPL:
# - Test with different values and conditions
# - Combine with boolean operators (&& and ||)
# - Use with functions that return Bool
# - Experiment with nested conditionals

# Examples to try:
# age = 20
# status = age < 18 ? "minor" : "adult"
#
# x = -5
# abs_x = x < 0 ? -x : x    # Implementation of abs()
#
# grade = 85
# if grade ≥ 90 println("A")
# elseif grade ≥ 80 println("B")
# elseif grade ≥ 70 println("C")
# else println("F")
# end
