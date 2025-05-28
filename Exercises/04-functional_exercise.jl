using Test

@info """
Exercise 1: Map and Filter
------------------------
Given an array of patient data (weight in kg):
weights = [62.5, 75.0, 58.2, 91.4, 68.7, 83.2, 55.8, 77.3]

1. Use map() to calculate BSA for each patient using the formula:
   BSA = 0.007184 * weight^0.425 * height^0.725
   (assume height = 170cm for all patients)
2. Use filter() to identify patients with BSA > 1.8m²
"""

# Your code here


@info """
Exercise 2: Reduce and Fold
-------------------------
Given concentration-time data for a drug:
times = [0, 0.5, 1, 2, 4, 8, 12]
concs = [100.0, 85.2, 72.5, 52.4, 27.5, 7.6, 2.1]

1. Use reduce() to calculate the total drug exposure (AUC)
   using the trapezoidal rule: AUC = Σ((c1 + c2) * (t2 - t1) / 2)
2. Use foldr() to create a cumulative concentration array
   (each element is the sum of all following concentrations)
"""

# Your code here


@info """
Exercise 3: Broadcasting
----------------------
Given PK parameters for multiple patients:
volumes = [45.2, 52.8, 48.7, 55.3, 50.1]  # L
clearances = [4.5, 5.2, 4.8, 5.5, 5.0]    # L/hr
doses = [100.0, 150.0, 125.0, 175.0, 150.0] # mg

1. Calculate initial concentrations (C0 = dose/volume) using broadcasting
2. Calculate elimination rates (k = CL/V) using broadcasting
3. Create a function that calculates concentration at time t
   and broadcast it over multiple time points
"""

# Your code here


# Bonus Challenge
@info """
Bonus Challenge: Composition and Pipelines
---------------------------------------
Create a data processing pipeline that:
1. Takes raw PK data (time and concentration)
2. Filters out concentrations below LLOQ (0.1 ng/mL)
3. Calculates log-transformed concentrations
4. Computes the elimination rate using linear regression
   on the terminal phase (last 3 points)
Use function composition (∘) and the pipeline operator (|>)
"""

# Your code here 