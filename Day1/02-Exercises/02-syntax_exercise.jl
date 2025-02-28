using Test

@info """
Exercise 1: Conditional Statements
--------------------------------
Write conditional statements to:
1. Check if a drug concentration (conc = 15.5 μg/mL) is within therapeutic range (10-20 μg/mL)
2. Classify the drug exposure as:
   - "Low" if < 10 μg/mL
   - "Therapeutic" if between 10-20 μg/mL
   - "High" if > 20 μg/mL
"""

# Your code here


@info """
Exercise 2: Loops
----------------
1. Create an array of hourly time points from 0 to 24 hours
2. Calculate drug concentrations at each time point using the formula:
   C(t) = C0 * exp(-k * t)
   where C0 = 100 μg/mL and k = 0.1 /hour
3. Store results in a new array
"""

# Your code here


@info """
Exercise 3: Array Comprehension
-----------------------------
1. Create an array of doses for 5 patients using array comprehension
   (doses should increase by 50mg each time, starting from 100mg)
2. Calculate the expected peak concentrations for each dose
   assuming volume of distribution = 48.2 L
"""

# Your code here


# Bonus Challenge
@info """
Bonus Challenge: Nested Loops and Conditionals
-------------------------------------------
Create a dosing recommendation system that:
1. Takes an array of weights [60, 70, 80, 90] kg
2. For each weight, calculate doses for three dose levels (1, 2, 3 mg/kg)
3. Flag any resulting doses that exceed 200mg with a warning message
"""

# Your code here 