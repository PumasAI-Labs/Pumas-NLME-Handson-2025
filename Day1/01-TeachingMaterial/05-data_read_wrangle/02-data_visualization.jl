# =============================================================================
# Data Wrangling and Visualization - Part 2: Visualizing Data
# =============================================================================

# The recommended Julia packages for performing data visualization and generating
# publication-quality figures are:
# - AlgebraOfGraphics.jl: https://aog.makie.org/stable/
# - CairoMakie.jl: https://docs.makie.org/stable/explanations/backends/cairomakie

# AlgebraOfGraphics provides a set of tools for plotting data in Julia. Its 
# design and functionality are similar to theat of ggplot2 in R, whereby it 
# involves the development of layers (data, mapping aesthetics, and geometrics)
# to build a plot.

# CairoMakie is the underlying plotting system for AlgebraOfGraphics.jl using a
# Cairo backend to draw vector graphics to SVG and PNG.

# Import the previous data reading example for demonstration
include("01-data_reading.jl")

# -----------------------------------------------------------------------------
# 1. PACKAGES FOR VISUALIZING DATA
# -----------------------------------------------------------------------------
using AlgebraOfGraphics, CairoMakie

# -----------------------------------------------------------------------------
# 2. PLOT DV VERSUS TIME
# -----------------------------------------------------------------------------
# A first plot of DV against TIME"
data(
    dropmissing(df, "DV")
) * mapping(
    "TIME",
    "DV",
) * visual(Lines) |> draw

#...what a mess! There are two endpoints. We need to split the plot on the DVID
# variable

# -----------------------------------------------------------------------------
# 3. STRATIFY BY ENDPOINT
# -----------------------------------------------------------------------------

data(
    dropmissing(df, "DV")
) * mapping(
    "TIME",
    "DV",
    row = "DVID" => nonnumeric # to interpret it as discrete 
) * visual(Lines) |> draw

# ...the graphs wrap around. We also need to group on ID

# -----------------------------------------------------------------------------
# 4. GROUP BY ID
# -----------------------------------------------------------------------------

data(
    dropmissing(df, "DV")
) * mapping(
    "TIME",
    "DV",
    row = "DVID" => nonnumeric,  
    group = "ID" => nonnumeric
) * visual(Lines) |> draw

# ...better but the two endpoints have different scale to we need to loosen the
# y-axes

# -----------------------------------------------------------------------------
# 5. SEPARATE Y-AXIS FOR EACH ENDPOINT
# -----------------------------------------------------------------------------

data(
    dropmissing(df, "DV")
) * mapping(
    "TIME",
    "DV",
    row = "DVID" => nonnumeric,  
    group = "ID" => nonnumeric
) * visual(Lines) |> f -> draw(
    f;
    facet = (;linkyaxes = :minimal)
)

# ...many lines are overlapping so let us adjust the opacity

# -----------------------------------------------------------------------------
# 6. ADJUST OPACITY OF LINES
# -----------------------------------------------------------------------------

data(
    dropmissing(df, "DV")
) * mapping(
    "TIME",
    "DV",
    row = "DVID" => nonnumeric,  
    group = "ID" => nonnumeric
) * visual(
    Lines,
    color = ("black", 0.3)
) |> f -> draw(
    f;
    facet = (;linkyaxes = :minimal)
)

# ...almost there. We need a title and some better looking labels

# -----------------------------------------------------------------------------
# 7. FIGURE AND AXIS LABELS
# -----------------------------------------------------------------------------

data(
    dropmissing(df, "DV")
) * mapping(
    "TIME",
    "DV",
    group = "ID" => nonnumeric,
    row = "DVID" => (t -> t == 1 ? "PK" : "PD")
) * visual(
    Lines,
    color = ("black", 0.3)
) |> f -> draw(
    f;
    facet = (;linkyaxes = :minimal),
    figure = (;title = "Warfarin data"),
)

# -----------------------------------------------------------------------------
# 8. COLOR BY SEX
# -----------------------------------------------------------------------------

data(
    dropmissing(df, "DV")
) * mapping(
    "TIME",
    "DV",
    group = "ID" => nonnumeric,
    row = "DVID" => (t -> t == 1 ? "PK" : "PD"),
    color = "SEX" => nonnumeric
) * visual(
    Lines
) |> f -> draw(
    f;
    facet = (;linkyaxes = :minimal),
    figure = (;title = "Warfarin data"),
)

# -----------------------------------------------------------------------------
# 9. COLOR BY AGE
# -----------------------------------------------------------------------------

data(
    dropmissing(df, "DV")
) * mapping(
    "TIME",
    "DV",
    group = "ID" => nonnumeric,
    row = "DVID" => (t -> t == 1 ? "PK" : "PD"),
    color = "AGE"
) * visual(
    Lines
) |> f -> draw(
    f;
    facet = (;linkyaxes = :minimal),
    figure = (;title = "Warfarin data"),
)

# -----------------------------------------------------------------------------
# 10. COLOR BY AMOUNT
# -----------------------------------------------------------------------------

data(
    dropmissing(df, "DV")
) * mapping(
    "TIME",
    "DV",
    group = "ID" => nonnumeric,
    row = "DVID" => (t -> t == 1 ? "PK" : "PD"),
    color = "AMOUNT"
) * visual(
    Lines
) |> f -> draw(
    f;
    facet = (;linkyaxes = :minimal),
    figure = (;title = "Warfarin data"),
)

# -----------------------------------------------------------------------------
# TIPS AND BEST PRACTICES
# -----------------------------------------------------------------------------
# 1. General structure of plotting layers consist of data, mapping and visual
# elements
# 2. Elements of a layer are concatenated using * (multiplication operator)
# 3. Multiple layers are superimposed onto each other using + (addition operator)
# 4. The implementation is consistent with the order of operations, therefore
# the order of which layers are sequentially added is important
# 5. Once all layers are combined, the resulting plot is compiled using draw

# Next Steps:
# 1. Data wrangling (03-data_wrangling.jl)"
# 2. Creating a Pumas population object