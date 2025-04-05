# Full tutorial at
#   https://tutorials.pumas.ai/html/LearningPaths/03-LP/09-Module/p3-mod9-covdef.html#module-introduction-and-objectives
# Other relevant tutorials are
#   https://tutorials.pumas.ai/html/introduction/covariate.html
#   https://tutorials.pumas.ai/html/accp/casestudy1.html
#   https://tutorials.pumas.ai/html/covariate_select/01-intro.html
#   https://tutorials.pumas.ai/html/covariate_select/02-forward_selection.html
#   https://tutorials.pumas.ai/html/covariate_select/03-backward_elimination.html
#   https://tutorials.pumas.ai/html/covariate_select/04-mixed.html

## Imports
using Pumas
using PharmaDatasets
using CSV, ReadStatTables
using Distributions, Random, StatsBase
using DataFrames, DataFramesMeta, Chain
using CategoricalArrays
using Dates
using CairoMakie, AlgebraOfGraphics, ColorSchemes, PairPlots
using PumasPlots
using SummaryTables

## Load the warfarin dataset from PharmaDatasets and modify so that it is ready for the examples
examp_df = @chain "paganz2024/warfarin_long" begin
  dataset
  # There are some observation's commented out "NONMEM-style"
  # Uncomment out those observations
  @rtransform :ID = occursin.("#", :ID) ? replace(:ID, "#" => "") : :ID
  # Add columns to specify dosing information for non-linear mixed effects modeling
  @rtransform begin
    # Set event ID variable (1 = dosing events, 0 = observations)
    :evid = :DVID == 0 ? 1 : 0
    # Set compartment variable for dosing events (1 = depot)
    :cmt = :DVID == 0 ? 1 : missing
  end
  # Check for duplicate records and a small number to their time to ensure they are unique
  @groupby :ID :TIME :evid :DVID
  @transform :SEQ = eachindex(:DV)
  @rtransform :TIME = :TIME + (:SEQ - 1) * 1e-6
  # Convert the DataFrame from long to wide format
  unstack(
    # Input DataFrame
    _,
    # rowkeys (i.e., variable that stores the identifier variables)
    :DVID,
    # colkeys (i.e., variable that stores the measurement variables)
    :DV;
    # Option to rename the new columns created for the measurement variables
    # Here an anonymous function is used to create a new column name based on
    # the identifier variable (DVID = x)
    renamecols=x -> Symbol(:DV_, x),
  )
  # Create descriptive labels for sex
  @transform @astable begin
    :SEX = recode(:SEX, 0 => "Female", 1 => "Male")
    :SEX = categorical(:SEX; ordered=true, levels=["Male", "Female"])
  end
  # Rename columns
  @rename begin
    :id = :ID
    :time = :TIME
    :amt = :AMOUNT
    :pkconc = :DV_1
    :pdpca = :DV_2
  end
  # Retain only necessary columns
  @select :id :time :amt :evid :cmt :pkconc :pdpca :WEIGHT :AGE :SEX
end

## The Warfarin Population Pharmacokinetic Model is a 1-compartment model with linear elimination and first-order absorption,
## log-normally distributed inter-individual variability on clearance (CL) and volume of distribution of the central compartment (VC),
## and a proportional residual error model.
mod_code = @model begin
  @param begin
    # Definition of fixed effect parameters
    θCL ∈ RealDomain(; lower=0.0)
    θVC ∈ RealDomain(; lower=0.0)
    θKA ∈ RealDomain(; lower=0.0)
    # Random effect parameters
    # Variance-covariance matrix for inter-individual variability
    Ω ∈ PSDDomain(2)
    # Residual unexplained variability
    σpro ∈ RealDomain(; lower=0.0)
  end
  @random begin
    # Sampling random effect parameters
    η ~ MvNormal(Ω)
  end
  @pre begin
    # Individual PK parameters
    CL = θCL * exp(η[1])
    VC = θVC * exp(η[2])
    KA = θKA
  end
  @init begin
    # Define initial conditions
    Depot = 0.0
    Central = 0.0
  end
  @vars begin
    # Concentrations in compartments
    centc := Central / VC
  end
  @dynamics begin
    # Differential equations
    Depot' = -KA * Depot
    Central' = KA * Depot - CL * centc
  end
  @derived begin
    # Definition of derived variables
    # Individual-predicted concentration
    ipre := @.(Central / VC)
    # Dependent variable
    """
    Warfarin Concentration (mg/L)
    """
    pkconc ~ @.Normal(ipre, sqrt((ipre * σpro)^2))
  end
end

## Fit the model
examp_df_pumas = read_pumas(examp_df; observations=[:pkconc])
init_params = (θCL=1, θVC=10, θKA=1, Ω=[0.09 0.01; 0.01 0.09], σpro=0.3)
mod_fit = fit(mod_code, examp_df_pumas, init_params, FOCE())

## Read covariates from the dataset into the Population
examp_df_pumas = read_pumas(examp_df; observations=[:pkconc], covariates=[:WEIGHT, :AGE, :SEX])

## Convert to a DataFrame
examp_df_pumas_df = DataFrame(examp_df_pumas)
# Print only the first ID
@rsubset examp_df_pumas_df :id == "1"

## Values of time-dependent covariates *do not* need to be time-matched
## with existing dosing and dependent variable observation records
timecov_df = DataFrame(
  id=1,
  time=0:1:8,
  evid=0,
  dv=[missing, rand(), rand(), rand(), rand(), missing, rand(), rand(), rand()],
  mdv=[1, 0, 0, 0, 0, 1, 0, 0, 0],
  weight=[70, missing, missing, missing, missing, 80, 85, missing, 70],
)

## Missing values for time-dependent covariates are interpolated when the `Population` is constructed via `read_pumas`.
## The behaviour is controlled by the `covariates_direction` keyword argument.

## `covariates_direction = :left` means the last observation is carried forward (default)
timecov_pumas_locf = read_pumas(
  timecov_df;
  observations=[:dv],
  mdv=:mdv,
  covariates=[:weight],
  covariates_direction=:left,
  event_data=false,
)
DataFrame(timecov_pumas_locf)

## `covariates_direction = :right` means the next observation is carried backward.
timecov_pumas_nocb = read_pumas(
  timecov_df;
  observations=[:dv],
  mdv=:mdv,
  covariates=[:weight],
  covariates_direction=:right,
  event_data=false,
)
DataFrame(timecov_pumas_nocb)

## Missing values for covariates are not handled by the `PumasModel`.
## If it is intended that `missing` values for covariate variables are to be imputed
## (e.g., with the median or mode for the individual *or* the analysis population)
## then this needs to be handled at the analysis dataset construction stage
## (i.e., prior to constructing the `Population` with `read_pumas`).

## To be used inside a `PumasModel`, covariate variables need to be specified in the `@covariates` block. 
## Not every variable defined as a covariate in the `Population` needs to be defined in `@covariates`.
mod_code_sex = @model begin
  @param begin
    # Definition of fixed effect parameters
    θCL ∈ RealDomain(; lower=0.0)
    θVC ∈ RealDomain(; lower=0.0)
    θKA ∈ RealDomain(; lower=0.0)
    θSEXCLF ∈ RealDomain(; lower=-0.999)
    # Random effect parameters
    # Variance-covariance matrix for inter-individual variability
    Ω ∈ PSDDomain(2)
    # Residual unexplained variability
    σpro ∈ RealDomain(; lower=0.0)
  end
  @random begin
    # Sampling random effect parameters
    η ~ MvNormal(Ω)
  end
  @covariates begin
    """
    Body Weight (kg)
    """
    WEIGHT
    """
    Age (years)
    """
    AGE
    """
    Sex
    """
    SEX
  end
  @pre begin
    # Effect of female sex on CL
    COVSEXCL = if SEX == "Female"
      # For SEX == "Female", estimate the effect
      1 + θSEXCLF
    elseif SEX == "Male"
      # For SEX == "Male", set to the reference value
      1
    else
      # Return error message if specified conditions are not met
      error("Expected SEX to be either \"Female\" or \"Male\" but the value was: $SEX")
    end
    # Identical model using ternary operator
    # COVSEXCL =
    #   SEX == "Female" ? 1 + θSEXCLF :
    #   (
    #     SEX == "Male" ? 1 :
    #     error(
    #       "Expected SEX to be either \"Female\" or \"Male\" but the value was: $SEX",
    #     )
    #   )

    # Individual PK parameters
    CL = θCL * exp(η[1]) * COVSEXCL
    VC = θVC * exp(η[2])
    KA = θKA
  end
  @init begin
    # Define initial conditions
    Depot = 0.0
    Central = 0.0
  end
  @vars begin
    # Concentrations in compartments
    centc := Central / VC
  end
  @dynamics begin
    # Differential equations
    Depot' = -KA * Depot
    Central' = KA * Depot - CL * centc
  end
  @derived begin
    # Definition of derived variables
    # Individual-predicted concentration
    ipre := @.(Central / VC)
    # Dependent variable
    """
    Warfarin Concentration (mg/L)
    """
    pkconc ~ @.Normal(ipre, sqrt((ipre * σpro)^2))
  end
end

## Fit the joint PK/covariate model
init_params_sex = (;
  θCL=1,
  θVC=10,
  θKA=1,
  θSEXCLF=0.01,
  Ω=[0.09 0.01; 0.01 0.09],
  σpro=0.3,
)
mod_fit_sex = fit(mod_code_sex, examp_df_pumas, init_params_sex, FOCE())

## A model using continous covariates
mod_code_wt = @model begin
  @param begin
    # Definition of fixed effect parameters
    θCL ∈ RealDomain(; lower=0.0)
    θVC ∈ RealDomain(; lower=0.0)
    θKA ∈ RealDomain(; lower=0.0)
    θWTCL ∈ RealDomain()
    θWTVC ∈ RealDomain()
    # Random effect parameters
    # Variance-covariance matrix for inter-individual variability
    Ω ∈ PSDDomain(2)
    # Residual unexplained variability
    σpro ∈ RealDomain(; lower=0.0)
  end
  @covariates begin
    """
    Body Weight (kg)
    """
    WEIGHT
    """
    Age (years)
    """
    AGE
    """
    Sex
    """
    SEX
  end
  @random begin
    # Sampling random effect parameters
    η ~ MvNormal(Ω)
  end
  @pre begin
    # Effect of body weight on CL
    COVWTCL = (WEIGHT / 70)^θWTCL

    # Effect of body weight on VC
    COVWTVC = (WEIGHT / 70)^θWTVC

    # Individual PK parameters
    CL = θCL * exp(η[1]) * COVWTCL
    VC = θVC * exp(η[2]) * COVWTVC
    KA = θKA
  end
  @init begin
    # Define initial conditions
    Depot = 0.0
    Central = 0.0
  end
  @vars begin
    # Concentrations in compartments
    centc := Central / VC
  end
  @dynamics begin
    # Differential equations
    Depot' = -KA * Depot
    Central' = KA * Depot - CL * centc
  end
  @derived begin
    # Definition of derived variables
    # Individual-predicted concentration
    ipre := @.(Central / VC)
    # Dependent variable
    """
    Warfarin Concentration (mg/L)
    """
    pkconc ~ @.Normal(ipre, sqrt((ipre * σpro)^2))
  end
end

## Fit the joint PK/covariate model
init_params_wt = (;
  θCL=1,
  θVC=10,
  θKA=1,
  θWTCL=0.75,
  θWTVC=1.0,
  Ω=[0.09 0.01; 0.01 0.09],
  σpro=0.3,
)
mod_fit_wt = fit(mod_code_wt, examp_df_pumas, init_params_wt, FOCE())

## Both continuous & discrete at the same time
mod_code_sexwt = @model begin
  @param begin
    # Definition of fixed effect parameters
    θCL ∈ RealDomain(; lower=0.0)
    θVC ∈ RealDomain(; lower=0.0)
    θKA ∈ RealDomain(; lower=0.0)
    θSEXCLF ∈ RealDomain(; lower=-0.999)
    θWTCL ∈ RealDomain()
    θWTVC ∈ RealDomain()
    # Random effect parameters
    # Variance-covariance matrix for inter-individual variability
    Ω ∈ PSDDomain(2)
    # Residual unexplained variability
    σpro ∈ RealDomain(; lower=0.0)
  end
  @covariates begin
    """
    Body Weight (kg)
    """
    WEIGHT
    """
    Age (years)
    """
    AGE
    """
    Sex
    """
    SEX
  end
  @random begin
    # Sampling random effect parameters
    η ~ MvNormal(Ω)
  end
  @pre begin
    # Effect of female sex on CL
    COVSEXCL = if SEX == "Female"
      # For SEX == "Female", estimate the effect
      1 + θSEXCLF
    elseif SEX == "Male"
      # For SEX == "Male", set to the reference value
      1
    else
      # Return error message if specified conditions are not met
      error("Expected SEX to be either \"Female\" or \"Male\" but the value was: $SEX")
    end

    # Effect of body weight on CL
    COVWTCL = (WEIGHT / 70)^θWTCL

    # Effect of body weight on VC
    COVWTVC = (WEIGHT / 70)^θWTVC

    # Individual PK parameters
    CL = θCL * exp(η[1]) * COVWTCL * COVSEXCL
    VC = θVC * exp(η[2]) * COVWTVC
    KA = θKA
  end
  @init begin
    # Define initial conditions
    Depot = 0.0
    Central = 0.0
  end
  @vars begin
    # Concentrations in compartments
    centc := Central / VC
  end
  @dynamics begin
    # Differential equations
    Depot' = -KA * Depot
    Central' = KA * Depot - CL * centc
  end
  @derived begin
    # Definition of derived variables
    # Individual-predicted concentration
    ipre := @.(Central / VC)
    # Dependent variable
    """
    Warfarin Concentration (mg/L)
    """
    pkconc ~ @.Normal(ipre, sqrt((ipre * σpro)^2))
  end
end
init_params_sexwt = (;
  θCL=1,
  θVC=10,
  θKA=1,
  θSEXCLF=0.01,
  θWTCL=0.75,
  θWTVC=1.0,
  Ω=[0.09 0.01; 0.01 0.09],
  σpro=0.3,
)
mod_fit_sexwt = fit(mod_code_sexwt, examp_df_pumas, init_params_sexwt, FOCE())

## Compare the covariate and the base models
imod_fit = inspect(mod_fit)
imod_fit_sex = inspect(mod_fit_sex)
imod_fit_wt = inspect(mod_fit_wt)
imod_fit_sexwt = inspect(mod_fit_sexwt)
plot_kwargs = (; separate=true, limit=12, columns=3, figure=(; size=(900, 900)), paginate=true)
display(subject_fits(imod_fit; plot_kwargs...)[1])
display(subject_fits(imod_fit_sex; plot_kwargs...)[1])
display(subject_fits(imod_fit_wt; plot_kwargs...)[1])
display(subject_fits(imod_fit_sexwt; plot_kwargs...)[1])
display(vpc_plot(vpc(mod_fit)))
display(vpc_plot(vpc(mod_fit_sexwt)))

## Likelihood Ratio Test for comparing nested models
##   https://en.wikipedia.org/wiki/Likelihood-ratio_test
##
## Let us consider a model parametrized by θ ∈ 𝚯,
## where 𝚯 is the space of all possible parameters.
## Let L(θ) be the likelihood of parameters θ according to this model and the data we have.
##
## A nested model is obtained by fixing some of the parameters θ.
## More generally, a nested model is defined by a subset of the parameter space 𝚯₀ ⊆ 𝚯.
##
## For example, if 𝚯 = ℜ³ we could decide to fix the third parameter θ₃ to 0.
## This would correspond to 𝚯₀ = {(θ₁, θ₂, 0) s.t. (θ₁, θ₂) ∈ ℜ²}.
##
## The model with parameter space 𝚯 is more general then the one with parameter space 𝚯₀.
## Moreover, any specific model obtained for some θ ∈ 𝚯₀
## is also a valid model for the wider space 𝚯.
## Thus, the model corresponding to parameter space 𝚯₀ is said to be *nested*.
##
## In our case the general model is the joint PK/covariate model
## while the nested model is the base model that ignores covariates effect.
## The latter can be obtained from the former by fixing the population-level parameters of the covariate model (usually to zero),
##
## Statistical test:
##  - Null hypothesis: θ ∈ 𝚯₀, i.e., the nested model is sufficient to explain the data.
#     In our case: covariates are not necessary to explain the data.
##  - Alternative hypothesis: θ ∈ 𝚯 ∖ 𝚯₀, i.e., the more general model is necessary to explain the data.
##    In our case: covariates are necessary to explain the data.
##
## Test statistic:
##
##             sup {L(θ) s.t. θ ∈ 𝚯₀}            L(θ̂₀)
## λ = -2 log ————————————————————————— = -2 log ——————— = 2 (l(θ̂) - l(θ̂₀))
##             sup {L(θ) s.t. θ ∈ 𝚯 }            L(θ̂ )
##
## where θ̂ is the Maximum Likelihood Estimate (MLE) of the parameters obtained using the general model,
## θ̂₀ is the MLE obtained using the nested model
## and l(θ) = log L(θ) is the loglikelihood function.
##
## It is clear that L(θ̂) ≥ L(θ̂₀) and thus λ ≥ 0.
## If L(θ̂) is much larger than L(θ̂₀), i.e., if λ is very large,
## then the general model is much better at explaining the data
## and we may conclude that such additional generality is necessary.
## In our case this would mean concluding that there is a covariate effect that cannot be ignored.
## But how large is enough for us to conclude so?
##
## If the null hypothesis is true,
## the test statistic is asymptotically distributed
## according to a χ² (chi-squared) distribution with degrees of freedom
## equal to the difference in the number of parameters between the two models,
## i.e., the degrees of freedom is the number of additional *estimable* parameters in the alternative model.
##
## Let cdf be the cumulative distribution function of the χ² distribution.
## Then 1 - cdf(λ) is "the probability of obtaining test results at least as extreme as the result actually observed,
## under the assumption that the null hypothesis is correct",
## AKA the p-value (https://en.wikipedia.org/wiki/P-value).
##
## If the p-value derived from the LRT statistic is lower than your desired threshold α,
## then you will reject the null hypothesis in favor of the alternative hypothesis,
## indicating that the alternative model provides a better fit to the data.
## In our case, this means concluding that there is a covariate effect on the model.
##
## α is the type-1 error rate, commonly set to 0.05.
## A type I error occurs when we reject the null hypothesis
## and erroneously state that the study found significant differences when there was no difference.

## Perform likelihood ratio test between base model and covariate model
lrt = lrtest(
  mod_fit,     # nested model, the null hypothesis, in our case the model without covariates
  mod_fit_sex, # general model, the alternative hypothesis, in our case the model with covariates
)

## Check lrt.statistic is what we expected
lrt.statistic == 2 * (loglikelihood(mod_fit_sex) - loglikelihood(mod_fit))

## Check lrt.statistic is what we expected
lrt.Δdf == 1 # the models differ for one population parameter

## Get the pvalue
lrt_pvalue = pvalue(lrt)

## Check the pvalue is what we expected
lrt_pvalue ≈ 1 - cdf(Chisq(1), lrt.statistic)

## Check whether we can reject the null hypothesis
alpha = 0.05
lrt_pvalue < alpha # unfortunately not! SEX does not appear to be a useful covariate

## Same for WEIGHT vs no covariates
lrt = lrtest(mod_fit, mod_fit_wt)

## Same for SEX/WEIGHT vs no covariates
lrt = lrtest(mod_fit, mod_fit_sexwt)

## Same for SEX/WEIGHT vs WEIGHT
lrt = lrtest(mod_fit_wt, mod_fit_sexwt)

## Same for SEX vs WEIGHT?
lrt = lrtest(mod_fit_sex, mod_fit_wt)
# This is meaningless, because the models are not nested!
# Pumas will not check for you, so you have to be careful.
