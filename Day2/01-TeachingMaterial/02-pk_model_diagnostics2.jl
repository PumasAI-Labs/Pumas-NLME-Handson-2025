# Script: 02-pk_model_diagnostics2.jl
# Purpose: Perform and interpret model diagnostics for the warfarin PK model
# ==============================================================
using Pumas
include(joinpath("..", "..", "Day1", "01-TeachingMaterial", "03-pk_model_fitting.jl"))

# Get inspection data
insp = inspect(fpm)
insp_df = DataFrame(insp)

# Get inspection data with npdes
insp_npde = inspect(fpm; nsim = 5000)
insp_npde_df = DataFrame(insp_npde)

# We can compare the two versions
goodness_of_fit(insp)
goodness_of_fit(insp_npde)

# While the goodness_of_fit function is a quick way to plot the diagnostics,
# it can sometimes be useful to plot the quantities based on the DataFrame
# output from inspect. This gives you completely control over the plotting.

# A raw plot of the NPDEs against is simply
data(
    insp_npde_df
) * mapping(
    "time",
    "conc_npde"
) * visual(Scatter) |> draw

# A linear fit can be added with
data(
    dropmissing(insp_npde_df, "conc_npde")
) * mapping(
    "time",
    "conc_npde"
) * (
    visual(Scatter) +
    AlgebraOfGraphics.linear()
) |> draw

# while a LOESS line can be added with
data(
    dropmissing(insp_npde_df, "conc_npde")
) * mapping(
    "time",
    "conc_npde"
) * (
    visual(Scatter) +
    AlgebraOfGraphics.smooth()
) |> draw

# More on VPCs
# Pumas uses local quantile regression instead of binning. The approach is inspired by
# https://ascpt.onlinelibrary.wiley.com/doi/full/10.1002/psp4.12319

# Redo default vpc
vpc_res_conc = vpc(
    fpm;
)

vpc_plot(
    vpc_res_conc;
    figurelegend = (
        position = :b, 
        orientation = :vertical,
        tellheight = true,
        tellwidth = false,
        nbanks = 2
    ),
    axis = (; title = "VPC with default bandwidth (2)")
)

# The neightborhood of the local regression is controlled by the bandwidth parameter
vpc_res_conc_bw10 = vpc(
    fpm;
    bandwidth = 10.0,
)

vpc_plot(
    vpc_res_conc_bw10;
    figurelegend = (
        position = :b, 
        orientation = :vertical,
        tellheight = true,
        tellwidth = false,
        nbanks = 2
    ),
    axis = (; title = "VPC with bandwidth=10")
)

# An challenge for VPCs is that the prodictions depend on
# dosing and covariates so we might be comparing vastly
# different distributions.

# We can check if there are differences in dosing
dropmissing(unique(df, "AMOUNT"), "AMOUNT")

# There is but let us check the amount per kg
@rselect dropmissing(unique(df, "AMOUNT"), "AMOUNT") begin
    :AMOUNT_PER_KG = :AMOUNT / :WEIGHT
end

# so all subjects are getting the same weight adjusted dose.
# However, we can still attempt a prediction corrected VPC to
# see if subject heterogeneity seems to matter

vpc_res_conc_pc = vpc(
    fpm;
    prediction_correction = true
)

vpc_plot(vpc_res_conc_pc;
    figurelegend = (
        position = :b, 
        orientation = :vertical,
        tellheight = true,
        tellwidth = false,
        nbanks = 2
    ),
    axis = (; title = "Prediction corrected VPC")
)

# An alternative way to account for subject heterogeneity is to
# stratify the plot based on discrete covariates.

vpc_res_conc_by_sex = vpc(
    fpm;
    stratify_by = [:SEX]
)

vpc_plot(vpc_res_conc_by_sex;
    figurelegend = (
        position = :b, 
        orientation = :vertical,
        tellheight = true,
        tellwidth = false,
        nbanks = 2
    ),
)


# Exercises
# - Try alternative bandwidths to see the effect
# - Try to stratify on WEIGHT. Follow the instructions in the error message
#   to generate stratified VPCs based on WEIGHT. Use `paginate = true` when
#   plotting the vpcs to distribute the figures over more plots pages. Remember, 
#   that you can render them by calling display.(you_vpc_vector)
tmp = vpc(
    fpm;
    stratify_by = [:WEIGHT],
    maxnumstrats = [32]
)

tmp_p = vpc_plot(tmp; paginate = true)
display.(tmp_p)