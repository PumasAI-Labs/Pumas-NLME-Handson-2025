## Time-To-Event Models a.k.a. Survival Analysis
#    https://tutorials.pumas.ai/html/discrete/05-TimeToEvent.html
#    Collett, D. (2015). Modelling survival data in medical research. Chapman and Hall/CRC.
#    Smith, P. J. (2002). Analysis of failure and survival data. Chapman and Hall/CRC.
#    Ibrahim, J. G., Chen, M. H., Sinha, D., Ibrahim, J. G., & Chen, M. H. (2001). Bayesian survival analysis. New York: Springer.

using Test
using DataFrames
using DataFramesMeta
using Pumas
using PumasUtilities
using CairoMakie
using AlgebraOfGraphics

## Survival Time
#    A random variable T with support [0, ∞) which represent the time of death/failure/etc.
#    Its distribution can be described uniquely by any of the following:
#
#    * Probability Density Function (PDF)
#        f(t)
#
#    * Cumulative Distribution Function (CDF)
#        F(t) = P(T ≤ t) = integral of f between 0 and t
#        Fraction of individuals who are "dead" at time t
#        By definition increasing!
#        F(0) = 0, F(∞) = 1
#
#                        F(t + Δt) - F(t)      proportional number of failures      number of failures / total number of entities
#        F'(t) = f(t) = —————————————————— = ——————————————————————————————————— = ———————————————————————————————————————————————
#                               Δt            time interval in which they occur          time interval in which they occur
#
#        f(t) is the instantaneuous proportional failure rate
#
#    * Survival Function
#        S(t) = P(T > t) = 1 - F(t)
#        Fraction of individuals who are "alive" at time t
#        By definition decreasing!
#        S'(t) = -f(t)
#
#    * Hazard Function
#      the (instantaneuous) proportional failure rate of the entities still functioning at time t
#
#              number of failures / entities still functioning
#      h(t) = —————————————————————————————————————————————————
#                    time interval in which they occur
#
#      Since "entities still functioning" = S(t) * "total number of entities", we have:
#
#              f(t)
#      h(t) = ——————
#              S(t)
#
#      If you are still not convinced, another derivation:
#
#              P(t < T < t + Δt | T > t)     P(t < T < t + Δt ∧ T > t)     P(t < T < t + Δt)     F(t + Δt) - F(t)     f(t)
#      h(t) = ——————————————————————————— = ——————————————————————————— = ———————————————————— = —————————————————— = ——————
#                        Δt                       Δt ⋅ P(T > t)              Δt ⋅ P(T > t)          Δt ⋅ S(t)         S(t)
#          
#      How to get S(t) from h(t)?
#
#              f(t)       S′(t)        d
#      h(t) = —————— = - ——————— = - ———— log(S(t))
#              S(t)       S(t)        dt
#
#      This is a differential equation with known initial condition S(0) = 1.
#      The solution is
#
#      S(t) = exp(-Λ(t))
#
#      where Λ(t) =  Integral  h(s)
#                   s ∈ (0, t)
#
#      Why deal with h(t) instead of f(t) or S(t)?
#      It is easier to model:
#       * h(t) needs to be non-negative and that's all
#       * f(t) needs to be positive and integrate to 1 on (0, ∞)
#       * S(t) needs to be positive and decreasing
#

## Commonly used parametric distributions for survival times
#
#  Exponential: parametrized by the shape θ in Distributions.jl.
#  Another common choice is parametrizing by the rate λ = 1 / θ.
#  h(t) = λ is the hazard rate of the Exponential distribution
#  constant hazard <--> memoryless property
#  (sometimes people denote the hazard by λ(t) too)
x = 0:0.1:12.5
λ = [0.1, 0.2, 0.5]
for (fun, label) in [(pdf, "PDF"), (cdf, "CDF")]
  values = mapreduce(vcat, λ) do λ
    d = Exponential(inv(λ))
    return fun.(d, x)
  end
  plt =
    data((;
      λ=repeat(λ; inner=length(x)),
      x=repeat(x; outer=length(λ)),
      values,
    )) *
    mapping(
      :x => "outcome",
      :values => label,
      row=:λ => (x -> L"\lambda = %$(x)"),
    ) *
    visual(Lines)
  display(draw(plt))
end

## Weibull: parametrized by the shape α and the scale θ
#  h(t) = (α/θ) * (t/θ)^(α-1)
#  If α = 1, h(t) is constant: the distribution is exponential
#  If α < 1, h(t) is decreasing: the longer you survive the less likely you are to die
#                                (e.g., most failures are due to defective items that fail early)
#  If α > 1, h(t) is increasing: the longer you survive the more likely you are to die
#                                (e.g., most failures are due to old age)
x = 0:0.1:10.0
αθ = Iterators.product([0.5, 1.5, 3.0], [2, 3, 5])
α = vec(getindex.(αθ, 1))
θ = vec(getindex.(αθ, 2))
for (fun, label) in [(pdf, "PDF"), (cdf, "CDF")]
  values = mapreduce((α, θ) -> fun.(Weibull(α, θ), x), vcat, α, θ)
  plt =
    data((;
      α=repeat(α; inner=length(x)),
      θ=repeat(θ; inner=length(x)),
      x=repeat(x; outer=length(α)),
      values
    )) *
    mapping(
      :x => "outcome",
      :values => label;
      row=:θ => (x -> L"\theta = %$(x)"),
      col=:α => (x -> L"\alpha = %$(x)"),
    ) *
    visual(Lines)
  display(draw(plt))
end

## Three approaches to estimating the survival function:
#    1. Kaplan-Meyer Estimator
#         non-parametric approach
#           * pro: no hypothesis on the shape of the survival function is necessary
#           * con: resulting survival function is not smooth
#           * con: difficult to exploit covariates
#    2. Cox Proportional Hazards Model
#         semi-parametric approach:
#           non-parametric baseline + parametric model using covariates
#    3. Accelerated Failure Time Model
#         parametric approach using a parametrized distribution family

## Kaplan-Meier Estimator
#    https://en.wikipedia.org/wiki/Kaplan%E2%80%93Meier_estimator
#
#  Given N samples tᵢ from a survival time random variable T,
#  estimate the survival function.
#  Equivalently, we can consider that we have a single sample
#  from each of N i.i.d. Tᵢ survival times.
#  These samples will in practice come from different subjects,
#  which are assumed to behave all in the same way
#  and not affect each other in any way.
#
#  1. Remove duplicate times, getting a set
#       {tₖ} for k = 1,...,K
#     where K ≤ N.
#
#  2. Estimate the survival function as
#     
#                          dₖ
#    S(t) =  Product  1 - ————  
#           k: tₖ ≤ t      nₖ
#
#    where
#      * dₖ is the number of deaths at time tₖ
#      * nₖ is the number of individuals known to have survived up to time tₖ
#        (they may have died at time tₖ or later, but not earlier)
#
#    Actually, there is a much simpler formula!
#
#                                          1                       n. of individuals who died before or at time t
#    S(t) = 1 - F(t) = 1 - P(T ≤ t) = 1 - ———    Sum     dₖ = 1 - ————————————————————————————————————————————————
#                                          N   k: tₖ ≤ t                      total number of individuals
#
#   Why would anyone use the more complicated product formula?
#   Bacause it works with censoring.
#
#   A survival observation is censored
#   when the subject was only monitored up to a certain time t̃
#   without it failing or dying .
#   Such an observation still brings information about the survival function,
#   because it tells us that T > t̃.

## Kaplan-Meier example
using Survival
t = [2, 2, 3, 5, 5, 7, 9, 16, 16, 18] # event times
s = [1, 1, 0, 1, 0, 1, 1, 1, 1, 0]    # 0 means censoring, 1 means failure
survival_fit = fit(KaplanMeier, t, s)
plt =
  mapping(survival_fit.events.time => L"t", survival_fit.survival => L"S(t)") *
  visual(Stairs; step=:post, linewidth=3)
draw(
  plt;
  axis=(; xticks=1:18, yticks=0.0:0.1:1.0, limits=((0, nothing), (0, nothing))),
)


## Cox Proportional Hazards Model
#
#  We now have one sample from each of N independent survival times Tᵢ.
#  The Tᵢ are no longer assumed to be identically distributed
#  (each subject has its own surivival time distribution)
#  and we want to use covariates to model the difference between them
#  (individualize the survival distribution to each subject).
#
#  The hazard is modelled as
#    h(t) = h₀(t) exp( β₁ x₁ + β₂ x₂ + … + βₚ xₚ )
#  where
#    * h₀(t) is the baseline hazard, a non-parametric estimate common to all subjects
#    * xⱼ are the covariates
#    * βⱼ are coefficients to be estimated (the parametric part)

## Accelerated Failure Time (AFT) Model
#
#  Like Cox Proportional Hazards Model,
#  but with h₀(t) begin the hazard function of a parametrized family of distributions.
#  This is a fully parametric approach.
#

## Survival modelling in Pumas

## Test dataset
#  ID: subject id
#  EVID: event type
#        3 -> reset event
#        0 -> observation event
#  DV: measurement (meaningful valid when EVID = 0)
#      1 -> failure events
#      0 -> censoring event
using PharmaDatasets
tte_single = dataset("tte_single")

## The EVID = 3 are not necessary (at least in Pumas)
#  Just discard them
tte_single_3 = @rsubset tte_single :EVID == 3
@test all(iszero, tte_single_3[:, :TIME])
@test all(iszero, tte_single_3[:, :DV])
tte_single = @rsubset tte_single :EVID != 3

## Exploratory Data Analysis
describe(tte_single)

## How many IDs?
@test sort(unique(tte_single[:, :ID])) == 1:300

## How many possible values of DOSE?
@test sort(unique(tte_single[:, :DOSE])) == [0, 1]

## Mean failure time depends on DOSE
@by tte_single :DOSE :mean_failure = mean(:TIME)

## Kaplan-Meier curves
survival_fit = fit(KaplanMeier, tte_single[:, :TIME], tte_single[:, :DV])
survival_fit_DOSE = let mask = isone.(tte_single[:, :DOSE])
  fit(KaplanMeier, tte_single[mask, :TIME], tte_single[mask, :DV])
end
survival_fit_NODOSE = let mask = iszero.(tte_single[:, :DOSE])
  fit(KaplanMeier, tte_single[mask, :TIME], tte_single[mask, :DV])
end
plt =
  data((;
    t=vcat(survival_fit.events.time, survival_fit_DOSE.events.time, survival_fit_NODOSE.events.time),
    s=vcat(survival_fit.survival, survival_fit_DOSE.survival, survival_fit_NODOSE.survival),
    which=vcat(
      fill("all", length(survival_fit.events.time)),
      fill("DOSE = 1", length(survival_fit_DOSE.events.time)),
      fill("DOSE = 0", length(survival_fit_NODOSE.events.time)),
    ),
  )) *
  mapping(:t => L"t", :s => L"S(t)", color=:which) *
  visual(Stairs; step=:post, linewidth=3)
draw(
  plt;
  axis=(; xticks=0:100:500, yticks=0.0:0.1:1.0, limits=((0, nothing), (0, nothing))),
)

## Convert the DataFrame to a Pumas.Population
tte_single_pop = read_pumas(
  tte_single;
  observations=[:DV],
  covariates=[:DOSE],
  id=:ID,
  time=:TIME,
  evid=:EVID,
  check=false, # otherwise read_pumas will complain about missing amt and cmt
)

## Exponential AFT model
tte_exp_model = @model begin
  @param begin
    # Parameters of the Exponential(θ) distribution corresponding to the baseline hazard
    # Rate λ̄ = 1 / θ
    λ̄ ∈ RealDomain(; lower=0)
    # NB we will denote with λ the final hazard of the model, after the proportional hazard correction

    # Parameters of the proportional hazard correction
    # Since we only have one covariate DOSE, we need a single parameter
    β ∈ RealDomain()
  end

  @covariates DOSE

  @pre begin
    # Baseline Hazard of the Exponential distribution
    λ₀ = λ̄
    # Full Hazard including proportional hazard correction
    λ = λ₀ * exp(β * DOSE)
    # NB in general the proportional hazard will depend on time
    #    * covariates may be time-dependent
    #    * some covariates may be the output of another component of the same model
    #      (e.g., DOSE may be the concentration in a compartment of a PK model)
  end

  @dynamics begin
    # We need the cumulative hazard Λ,
    # whose derivative is equal to the hazard λ
    Λ' = λ
  end

  @derived begin
    # Pumas TimeToEvent distribution,
    # parametrized by the hazard λ and the cumulative hazard Λ.
    # Possible values for DV:
    #   * 0 -> censoring event
    #   * 1 -> failure/death event
    DV ~ @. TimeToEvent(λ, Λ)
  end
end

## Weibull AFT model
tte_wei_model = @model begin
  @param begin
    # Parameters of the Weibull(α, θ) distribution corresponding to the baseline hazard
    # Rate λ̄ = 1 / θ where θ is the scale parameter
    λ̄ ∈ RealDomain(; lower=0)
    # NB we will denote with λ the final hazard of the model, after the proportional hazard correction
    # Shape K = α (to use a name more commonly used in the biomedical modelling community)
    K ∈ RealDomain(; lower=0)

    # Parameters of the proportional hazard correction
    # Since we only have one covariate DOSE, we need a single parameter
    β ∈ RealDomain()
  end

  @covariates DOSE

  @pre begin
    # Baseline Hazard of the Weibull Exponential distribution
    # NB 1e-10 added for numerical stability
    λ₀ = λ̄ * K * (λ̄ * t + 1e-10)^(K - 1)
    # Full Hazard including proportional hazard correction
    λ = λ₀ * exp(β * DOSE)
    # NB in general the proportional hazard will depend on time
    #    * covariates may be time-dependent
    #    * some covariates may be the output of another component of the same model
    #      (e.g., DOSE may be the concentration in a compartment of a PK model)
  end

  @dynamics begin
    # We need the cumulative hazard Λ,
    # whose derivative is equal to the hazard λ
    Λ' = λ
  end

  @derived begin
    # Pumas TimeToEvent distribution,
    # parametrized by the hazard λ and the cumulative hazard Λ.
    # Possible values for DV:
    #   * 0 -> censoring event
    #   * 1 -> failure/death event
    DV ~ @. TimeToEvent(λ, Λ)
  end
end

## Gompertz AFT Model
#    https://en.wikipedia.org/wiki/Gompertz_distribution
tte_gomp_model = @model begin
  @param begin
    # Parameters of the Gompertz distribution corresponding to the baseline hazard
    # Rate λ̄
    λ̄ ∈ RealDomain(; lower=0)
    # NB we will denote with λ the final hazard of the model, after the proportional hazard correction
    # Shape K
    K ∈ RealDomain(; lower=0)

    # Parameters of the proportional hazard correction
    # Since we only have one covariate DOSE, we need a single parameter
    β ∈ RealDomain()
  end

  @covariates DOSE

  @pre begin
    # Baseline Hazard of the Gompertz distribution
    λ₀ = λ̄ * exp(K * t)
    # Full Hazard including proportional hazard correction
    λ = λ₀ * exp(β * DOSE)
    # NB in general the proportional hazard will depend on time
    #    * covariates may be time-dependent
    #    * some covariates may be the output of another component of the same model
    #      (e.g., DOSE may be the concentration in a compartment of a PK model)
  end

  @dynamics begin
    # We need the cumulative hazard Λ,
    # whose derivative is equal to the hazard λ
    Λ' = λ
  end

  @derived begin
    # Pumas TimeToEvent distribution,
    # parametrized by the hazard λ and the cumulative hazard Λ.
    # Possible values for DV:
    #   * 0 -> censoring event
    #   * 1 -> failure/death event
    DV ~ @. TimeToEvent(λ, Λ)
  end
end

## Fit the models
tte_single_exp_fit =
  fit(tte_exp_model, tte_single_pop, (; λ̄ = 0.001, β = 0.001), NaivePooled());
tte_single_wei_fit =
  fit(tte_wei_model, tte_single_pop, (; λ̄ = 0.001, K = 0.001, β = 0.001), NaivePooled());
tte_single_gomp_fit =
  fit(tte_gomp_model, tte_single_pop, (; λ̄ = 0.001, K = 0.001, β = 0.001), NaivePooled());

## Compare estimates
compare_estimates(;
  Exponential=tte_single_exp_fit,
  Weibull=tte_single_wei_fit,
  Gompertz=tte_single_gomp_fit,
)

## Compare estimates SEs
df_exponential = coeftable(infer(tte_single_exp_fit))
df_weibull = coeftable(infer(tte_single_wei_fit))
df_gompertz = coeftable(infer(tte_single_gomp_fit))

## Compare estimates in linear scale
@rsubset! df_exponential :parameter == "β"
@rtransform! df_exponential :model = "exponential"
@rsubset! df_weibull :parameter == "β"
@rtransform! df_weibull :model = "Weibull"
@rsubset! df_gompertz :parameter == "β"
@rtransform! df_gompertz :model = "Gompertz"
df = vcat(df_exponential, df_weibull, df_gompertz)
@rtransform! df $(
  [:estimate, :ci_lower, :ci_upper] .=>
    (x -> exp.(x)) .=> [:estimate, :ci_lower, :ci_upper]
)
df[:, :Δci] = df[:, :ci_upper] .- df[:, :ci_lower]
df[:, [:parameter, :estimate, :ci_lower, :ci_upper, :Δci, :model]]

## Hazard functions taken from the models
function hazard_exponential(param, DOSE, t)
  return param.λ̄ * exp(param.β * DOSE)
end
function hazard_weibull(param, DOSE, t)
  return param.λ̄ * param.K * (param.λ̄ * t + 1e-10)^(param.K - 1) * exp(param.β * DOSE)
end
function hazard_gompertz(param, DOSE, t)
  return param.λ̄ * exp(param.K * t) * exp(param.β * DOSE)
end

## Survival functions
#  S(t) = exp(-Λ(t)) where Λ(t) =  Integral  h(s)
#                                 s ∈ (0, t)
function survival_exponential(param, DOSE, t)
  I = hazard_exponential(param, DOSE, 0.0) * t
  return exp(-I)
end
function survival_weibull(param, DOSE, t)
  hazard_weibull_0 = hazard_weibull(param, DOSE, 0.0)
  hazard_weibull_t = hazard_weibull(param, DOSE, t)
  I = (hazard_weibull_t * param.λ̄ * t + 1e-10 * (hazard_weibull_t - hazard_weibull_0)) / (param.λ̄ * param.K)
  return exp(-I)
end
function survival_gompertz(param, DOSE, t)
  I = (hazard_gompertz(param, DOSE, t) - hazard_gompertz(param, DOSE, 0.0)) / param.K
  return exp(-I)
end

## Plot the survival functions
t = 1:500
s_exponential_dose_0 = survival_exponential.(Ref(coef(tte_single_exp_fit)), 0, t)
s_exponential_dose_1 = survival_exponential.(Ref(coef(tte_single_exp_fit)), 1, t)
s_weibull_dose_0 = survival_weibull.(Ref(coef(tte_single_wei_fit)), 0, t)
s_weibull_dose_1 = survival_weibull.(Ref(coef(tte_single_wei_fit)), 1, t)
s_gompertz_dose_0 = survival_gompertz.(Ref(coef(tte_single_gomp_fit)), 0, t)
s_gompertz_dose_1 = survival_gompertz.(Ref(coef(tte_single_gomp_fit)), 1, t)
plt =
  data((;
    # data in a long table format
    t=repeat(t, 6), # 2 DOSES ⋅ 3 AFT models
    s=vcat(
      s_exponential_dose_0,
      s_exponential_dose_1,
      s_weibull_dose_0,
      s_weibull_dose_1,
      s_gompertz_dose_0,
      s_gompertz_dose_1,
    ),
    DOSE=repeat(
      [0, 1];
      inner=length(t), # repeat 0 500x then 1 500x
      outer=3,         # 3 AFT models
    ),
    MODEL=repeat(["exponential", "Weibull", "Gompertz"]; inner=2 * length(t)),    # repeat each model 1_000x
  )) *
  mapping(:t => L"t", :s => L"S(t)"; color=:DOSE => nonnumeric, row=:MODEL) *
  visual(Lines)
plt_km =
  data((;
    t=vcat(survival_fit_NODOSE.events.time, survival_fit_DOSE.events.time),
    s=vcat(survival_fit_NODOSE.survival, survival_fit_DOSE.survival),
    DOSE=vcat(fill(0, length(survival_fit_NODOSE.events.time)), fill(1, length(survival_fit_DOSE.events.time))),
    MODEL=repeat(["Kaplan-Meier"]; inner=length(survival_fit_NODOSE.events.time) + length(survival_fit_DOSE.events.time)),
  )) *
  mapping(:t => L"t", :s => L"S(t)", color=:DOSE => nonnumeric, row=:MODEL) *
  visual(Stairs; step=:post, linewidth=3)
draw(
  plt + plt_km;
  figure=(; size=(600, 600)),
  axis=(; xticks=0:100:500, yticks=0.0:0.2:1.0, limits=((0, nothing), (0, nothing))),
)

## VPCs
_vpc_exp = vpc(tte_single_exp_fit; stratify_by=[:DOSE])
begin
  fig = vpc_plot(_vpc_exp; figure=(; size=(750, 320)))
  Makie.Label(fig.figure[0, :], "Exponential AFT Model"; fontsize=20)
  display(fig)
end
_vpc_wei = vpc(tte_single_wei_fit; stratify_by=[:DOSE])
begin
  fig = vpc_plot(_vpc_wei; figure=(; size=(750, 320)))
  Makie.Label(fig.figure[0, :], "Weibull AFT Model"; fontsize=20)
  display(fig)
end
_vpc_gomp = vpc(tte_single_gomp_fit; stratify_by=[:DOSE])
begin
  fig = vpc_plot(_vpc_gomp; figure=(; size=(750, 320)))
  Makie.Label(fig.figure[0, :], "Gompertz AFT Model"; fontsize=20)
  display(fig)
end

## Simulations
simpop = simobstte(tte_wei_model, tte_single_pop, coef(tte_single_wei_fit); maxT=500.0, nT=50)

## Final Notes
#   * do not use random effects in a survival model
#   * unless the random effects appear in other parts of the model such as the PK
#   * repeated events (multiple events with DV = 1) are also supported
