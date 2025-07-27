using Test

@info """
Exercise 1: Basic Function Definition
----------------------------------
1. Create a function `calculate_clearance` that takes `volume` (L) and `elimination_rate` (/hr) as arguments
   and returns clearance (L/hr)
2. Create a function `calculate_half_life` that takes `elimination_rate` (/hr) as argument
   and returns the half-life (hr)
3. Create a function `calculate_auc` that takes `dose` (mg) and `clearance` (L/hr) as arguments
   and returns the AUC (mg*hr/L)
"""

# Your code here


@info """
Exercise 2: Multiple Dispatch
---------------------------
1. Create a function `calculate_dose` that works with both
   weight of a single subject and weights of a population of multiple subjects:
   - One method that takes `weight` (kg) of a single subject and `dose_per_kg` (mg/kg),
     and returns the total dose of that subject in mg.
   - Another method that takes a vector of `weights` (kg) of multiple subjects and
     `dose_per_kg` (mg/kg), and returns a vector of total doses in mg for each subject.
   Reuse the method for a single subject in the method for multiple subjects.
2. In this case, it is actually not necessary to define two different methods.
   Define a single method `calculate_dose_alt` that works for both cases,
   without using `if`/`else` statements on the input type.
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
1. Create a higher-order function `simulate_pk` that takes:
   - A dosing function (that calculates concentration vs time)
   - Time points array
   - PK parameters dictionary
2. The function should return concentrations at specified time points
3. Test it with both single-dose and multiple-dose scenarios
"""

# Your code here 