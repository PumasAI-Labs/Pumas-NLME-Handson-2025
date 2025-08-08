using Pumas, Latexify, CairoMakie

@info """
Exercise 1: Two-Compartment Oral Absorption Model
---------------------------------------------
Create a two-compartment PK model with first-order oral absorption:

1. Model Structure:
   - Depot compartment (oral absorption)
   - Central compartment (distribution and elimination)
   - Peripheral compartment
   - First-order processes for all transfers

2. Required Model Components:
   @param block:
   - Population parameters (TVCL, TVV1, TVQ, TVV2, TVKA)
   - Random effects (ΩCL, ΩV1, ΩQ, ΩV2, ΩKA)
   - Error parameters (proportional and additive)
   
   @random block:
   - η parameters for all PK parameters
   - Include correlation between ηCL and ηV1
   
   @covariates block:
   - Weight (WT)
   - Sex
   
   @pre block:
   - Individual parameter calculations with covariate effects
   - Allometric scaling for clearances and volumes
   
   @dynamics block:
   - ODEs for all three compartments
   
   @derived block:
   - Concentration calculation (Central/V1)
   - Error model implementation
"""

# Your code here


@info """
Exercise 2: Model Visualization with Latexify
-----------------------------------------
Using the Latexify package, create visualizations for:

1. Model Equations:
   - Generate LaTeX equations for the ODEs
   - Show parameter relationships
   - Display covariate model equations
   - Display the residual error model equations
"""

# Your code here


# Bonus Challenge
@info """
Bonus Challenge: Model Extension
----------------------------
Extend the model to include:

1. Transit Compartment Absorption:
   - Add a chain of transit compartments
   - Parameterize mean absorption time
   - Implement variability in transit

2. Nonlinear Elimination:
   - Add Michaelis-Menten elimination
   - Include saturation parameters
   - Modify equations and Latexify output

3. Time-Varying Clearance:
   - Implement circadian rhythm on clearance
   - Add chronopharmacokinetic parameters
   - Visualize time-dependent changes
"""

# Your code here 