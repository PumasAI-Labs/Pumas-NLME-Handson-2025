# Script: 02-data_visualization.jl
# Purpose: Visualize warfarin PK/PD data
# ========================================================

using AlgebraOfGraphics, CairoMakie

include("01-data_reading.jl")

@info "A first plot of DV against TIME"
data(
    dropmissing(df, "DV")
) * mapping(
    "TIME",
    "DV",
) * visual(Lines) |> draw

@info "...what a mess! There are two endpoints. We need to split the plot on the DVID variable"
data(
    dropmissing(df, "DV")
) * mapping(
    "TIME",
    "DV",
    row = "DVID" => nonnumeric # to interpret it as discrete 
) * visual(Lines) |> draw

@info "...the graphs wrap around. We also need to group on ID"
data(
    dropmissing(df, "DV")
) * mapping(
    "TIME",
    "DV",
    row = "DVID" => nonnumeric,  
    group = "ID" => nonnumeric
) * visual(Lines) |> draw

@info "...better but the two endpoints have different scale to we need to loosen the yaxes"
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

@info "...many lines are overlapping so let us adjust the opacity"
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

@info "...almost there. We need a title and some better looking labels"
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
    figure = (; title = "Warfarin data"),
)

@info "Covariate effects: SEX"
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
    figure = (; title = "Warfarin data"),
)

@info "Covariate effects: AGE"
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
    figure = (; title = "Warfarin data"),
)

@info "Covariate effects: AGE"
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
    figure = (; title = "Warfarin data"),
)