# =============================================================================
# Julia Control Flow Tutorial - Part 2: Loops and Iteration
# =============================================================================
#
# Loops are fundamental programming constructs that allow repeated execution
# of code blocks. Julia provides several elegant ways to express iteration,
# each with its own strengths and use cases.

# -----------------------------------------------------------------------------
# 1. FOR LOOPS
# -----------------------------------------------------------------------------

# Create a range of numbers to iterate over
numbers = 1:10    # Range from 1 to 10 (inclusive)

# Basic for loop structure
println("Basic number iteration:")
for number in numbers    # 'in' keyword specifies what to iterate over
    println(number)      # Body of the loop - executed for each value
end                     # Required to close the loop block

# -----------------------------------------------------------------------------
# 2. COMBINING LOOPS WITH CONDITIONALS
# -----------------------------------------------------------------------------

println("\nCombining loops with conditionals:")
for number in numbers
    if iseven(number)                  # Check if number is even
        println("$number is even")     # String interpolation with $
    else
        println("$number is odd")
    end
end    # Note: nested blocks need their own 'end'

# -----------------------------------------------------------------------------
# 3. WHILE LOOPS
# -----------------------------------------------------------------------------
# While loops continue executing while a condition remains true

println("\nWhile loop example:")
counter = 1                     # Initialize counter
while counter <= 10             # Condition for continuation
    println(counter)            # Body of the loop
    global counter = counter + 1 # Update counter (global needed in REPL/global scope)
end

# -----------------------------------------------------------------------------
# 4. PRACTICAL EXAMPLE: SEARCHING IN COLLECTIONS
# -----------------------------------------------------------------------------

# Sample data
names_a = ["Peter", "Alice", "Juan", "Bob"]
friend = "Alice"

# Method 1: Using while loop for search
println("\nSearching with while loop:")
friend_index = 1
while names_a[friend_index] != friend  # Continue until we find the friend
    global friend_index += 1           # Increment index (shorthand for += 1)
end

println("$friend is in position number $friend_index of the list")

# Method 2: Using for loop with break
println("\nSearching with for loop and break:")
for index in eachindex(names_a)          # eachindex gets all valid indices
    if names_a[index] == friend
        println("$(names_a[index]) is in position number $index of the list")
        break                          # Exit loop early when found
    end
end

# -----------------------------------------------------------------------------
# 5. ARRAY COMPREHENSIONS
# -----------------------------------------------------------------------------
# Concise way to create arrays using loop-like syntax

# Basic comprehension
x = [i for i = 1:10]              # Create array with numbers 1 to 10
println("\nBasic comprehension: $x")

# Apply transformation
x2 = [2i for i = 1:10]            # Multiply each number by 2
println("Doubled values: $x2")

# String manipulation
greetings = ["Hello, $name" for name in names_a]
println("Greetings: $greetings")

# Filtering with conditional
even_numbers = [i for i = 1:10 if iseven(i)]
println("Even numbers: $even_numbers")

# -----------------------------------------------------------------------------
# TIPS AND BEST PRACTICES
# -----------------------------------------------------------------------------
# 1. Choose the right loop type:
#    - for: when you know the number of iterations
#    - while: when you don't know how many iterations needed
#    - comprehensions: for creating arrays with transformations
#
# 2. Loop Performance:
#    - Avoid changing array size inside loops
#    - Pre-allocate arrays when possible
#    - Use break to exit early when appropriate
#    - Consider using iterators for memory efficiency
#
# 3. Common Patterns:
#    - Accumulation: sum += value
#    - Filtering: if condition append!(result, value)
#    - Transformation: [f(x) for x in collection]
#    - Search: break when found
#
# 4. Watch out for:
#    - Infinite loops (while without proper exit condition)
#    - Off-by-one errors in array indexing
#    - Global variable modifications (use local when possible)

# Try in the REPL:
# - Nested loops (loops inside loops)
# - Different range notations (1:2:10 for steps of 2)
# - continue keyword to skip iterations
# - Multiple conditions in comprehensions
# - Iterating over different collection types (Dict, Set)

# Examples to try:
# # Multiplication table
# for i in 1:5, j in 1:5
#     print(i*j, "\t")
#     if j == 5 println() end
# end
#
# # Nested comprehension
# matrix = [i*j for i in 1:3, j in 1:3]
#
# # Filter and transform
# words = ["apple", "banana", "cherry"]
# long_upper = [uppercase(w) for w in words if length(w) > 5]
