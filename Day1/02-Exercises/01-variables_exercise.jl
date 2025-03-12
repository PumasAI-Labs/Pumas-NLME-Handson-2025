using Test

@info """
Exercise 1: Variable Declaration and Types
----------------------------------------
Declare variables for the following pharmacometric parameters:
1. Create a variable 'dose' with value 100 (mg)
2. Create a variable 'volume_of_distribution' with value 48.2 (L)
3. Create a variable 'half_life' with value 12.5 (hours)
4. Create a variable 'is_fasted' as a boolean indicating fasting state
5. Create a variable 'patient_id' as a string "SUBJ-001"

Use the most appropriate type for each variable!
"""

# Your code here


@info """
Exercise 2: Basic Calculations
----------------------------
Using the variables you created above:
1. Calculate the elimination rate constant (k) using the formula: k = ln(2)/half_life
2. Calculate the initial concentration (C0) using: C0 = dose/volume_of_distribution
3. Store both results in new variables
"""

# Your code here



@info """
Exercise 3: String Manipulation
-----------------------------
1. Create a string that combines the patient_id with their dose information
   Format: "Patient SUBJ-001 received 100 mg"
2. Create an array of three different patient IDs following the same format (SUBJ-001, SUBJ-002, SUBJ-003)
"""

# Your code here


# Bonus Challenge
@info """
Bonus Challenge: Type Conversions
-------------------------------
1. Convert the dose to a floating-point number in grams (instead of mg)
2. Create a dictionary that stores all patient parameters (dose, volume, half-life)
3. Add a new key-value pair to the dictionary for clearance (CL = volume_of_distribution * k)
"""

# Your code here 