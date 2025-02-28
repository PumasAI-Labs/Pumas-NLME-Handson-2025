# =============================================================================
# Julia Syntax Tutorial - Part 5: Macros and Metaprogramming
# =============================================================================
#
# Macros are powerful metaprogramming tools in Julia that allow code manipulation
# before it's executed. They are denoted by the @ symbol and can transform code
# in ways that would be impossible or cumbersome with regular functions.

# -----------------------------------------------------------------------------
# 1. BASIC MACRO SYNTAX
# -----------------------------------------------------------------------------
# Macros are always prefixed with @ and can be called in two ways:
# 1. Space syntax: @macro arg1 arg2
# 2. Parenthesis syntax: @macro(arg1, arg2)

# Common built-in macros:
# @time        # Measures execution time and memory allocation
# @show        # Prints both the expression and its value
# @assert      # Checks if a condition is true, errors if false
# @doc         # Accesses documentation
# @macroexpand # Shows the expanded form of a macro

# -----------------------------------------------------------------------------
# 2. TIMING CODE WITH @time
# -----------------------------------------------------------------------------
# Basic usage - single expression
println("\nTiming a simple calculation:")
@time 3 + 2    # Shows execution time and memory allocation

# Multiple expressions using begin...end block
println("\nTiming multiple calculations:")
@time begin    # Time everything in this block
    3 + 2
    6 * 5
    4 + 2^6 - 10
end

# Alternative syntax with parentheses
println("\nUsing parenthesis syntax:")
@time(3 + 2)    # Same as @time 3 + 2

# -----------------------------------------------------------------------------
# 3. DOCUMENTATION WITH @doc
# -----------------------------------------------------------------------------
# View function documentation
println("\nViewing documentation:")
@doc println    # Shows documentation for println function

# Alternative syntax
@doc(println)   # Same as @doc println

# -----------------------------------------------------------------------------
# 4. MACRO EXPANSION WITH @macroexpand
# -----------------------------------------------------------------------------
# See how macros transform code
println("\nExpanding macro code:")
@macroexpand @time 3 + 2    # Shows what @time actually does

# More complex expansion
println("\nExpanding a block:")
@macroexpand @time begin
    x = 1
    y = 2
    x + y
end

# -----------------------------------------------------------------------------
# 5. OTHER USEFUL MACROS
# -----------------------------------------------------------------------------
# @show - Print expression and its value
x = 42
@show x    # Prints: x = 42
@show 2 + 2    # Prints: 2 + 2 = 4

# @assert - Runtime checking
@assert 2 + 2 == 4 "Math still works!"    # Passes silently
# @assert 2 + 2 == 5 "Math is broken!"    # Would error

# @warn - Issue warnings
@warn "This is a warning message"

# -----------------------------------------------------------------------------
# TIPS AND BEST PRACTICES
# -----------------------------------------------------------------------------
# 1. When to Use Macros:
#    - For compile-time code generation
#    - When you need to manipulate code itself
#    - For domain-specific languages (DSLs)
#    - For performance optimization
#
# 2. Common Use Cases:
#    - @time for performance profiling
#    - @assert for debugging and testing
#    - @show for quick debugging prints
#    - @doc for documentation lookup
#
# 3. Best Practices:
#    - Prefer functions over macros when possible
#    - Use @macroexpand to understand macro behavior
#    - Be careful with macro hygiene
#    - Document macro behavior clearly
#
# 4. Performance Considerations:
#    - @time may include compilation time on first run
#    - Use @btime (from BenchmarkTools.jl) for more accurate benchmarks
#    - Macros run at parse time, not runtime

# Try in the REPL:
# - Compare @time vs @elapsed
# - Experiment with @assert conditions
# - Use @show for debugging
# - Explore macro expansion with @macroexpand

# Examples to try:
# # Custom assertion with message
# x = 10
# @assert x > 0 "x must be positive"
#
# # Timing comparison
# @time sum(1:1000)
# @time sum(1:1000)    # Second run is faster (already compiled)
#
# # Complex macro expansion
# @macroexpand @assert x > 0 "x must be positive"
#
# # Multiple @show statements
# a, b = 1, 2
# @show a b a+b
