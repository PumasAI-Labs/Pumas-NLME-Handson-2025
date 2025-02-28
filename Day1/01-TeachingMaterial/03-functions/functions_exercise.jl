using Test

@info """
Exercise 1: Basic Function Definition
----------------------------------
1. Create a function calculate_clearance that takes volume (L) and elimination_rate (/hr) as arguments
   and returns clearance (L/hr)
2. Create a function calculate_half_life that takes elimination_rate (/hr) as argument
   and returns the half-life (hr)
3. Create a function calculate_auc that takes dose (mg) and clearance (L/hr) as arguments
   and returns the AUC (mg*hr/L)
"""

# Your code here


@info """
Exercise 2: Multiple Dispatch
---------------------------
1. Create a function calculate_dose that works with different units:
   - One method that takes weight (kg) and dose_per_kg (mg/kg)
   - Another method that takes BSA (m²) and dose_per_m2 (mg/m²)
   Both should return the total dose in mg
2. Add type annotations to make the function more robust
"""

# Your code here


@info """
Exercise 3: Anonymous Functions
-----------------------------
1. Create an anonymous function that calculates concentration at time t
   using C(t) = C0 * exp(-k * t)
2. Use this anonymous function with map() to calculate concentrations
   at times [0, 1, 2, 4, 8] hours (given C0 = 100 and k = 0.1)
"""

# Your code here


# Bonus Challenge
@info """
Bonus Challenge: Higher Order Functions
-----------------------------------
1. Create a higher-order function simulate_pk that takes:
   - A dosing function (that calculates concentration vs time)
   - Time points array
   - PK parameters dictionary
2. The function should return concentrations at specified time points
3. Test it with both single-dose and multiple-dose scenarios
"""

# Your code here 