#activate project environment
using Pkg
Pkg.activate(".")
Pkg.instantiate()

using CSV, DataFrames
using CairoMakie
using ColorSchemes
using FileIO

#Read in Data
occ_base = DataFrame(CSV.File(joinpath(@__DIR__,"dataframes/fixed_effect_base.csv")))
occ_fe_3 = DataFrame(CSV.File(joinpath(@__DIR__,"dataframes/fixed_effect_3.csv")))
occ_fe_5 = DataFrame(CSV.File(joinpath(@__DIR__,"dataframes/fixed_effect_5.csv")))
occ_fe_7 = DataFrame(CSV.File(joinpath(@__DIR__,"dataframes/fixed_effect_7.csv")))

ret_per = range(10, 1000, length=100)
threshold = zeros(length(ret_per))
#Plot results

fig = Figure()

ax1 = Axis(fig[1, 1], ylabel = "Difference in Occupied Exposure", xlabel = "Return Period (years)", xscale = log10,
 xticks = ([10,100,1000], string.([10,100,1000])), limits = ((10,1000), nothing), xgridvisible = false)

hidespines!(ax1,:t, :r)

palette = ColorSchemes.tol_bright

#Baseline
CairoMakie.lines!(ax1, ret_per, occ_base.median, color = palette[1], linewidth = 2.5, label = "fe = 0.0")
#, label = false)
CairoMakie.band!(ax1, ret_per, occ_base.LB, occ_base.RB, color = (palette[1], 0.35))
CairoMakie.lines!(ax1, ret_per, threshold, linestyle = :dash, color = "black", linewidth = 2)

#2% Growth
CairoMakie.lines!(ax1, ret_per, occ_fe_3.median, color = palette[2], linewidth = 2.5, label = "fe = 0.03")
#, label = false)
CairoMakie.band!(ax1, ret_per, occ_fe_3.LB, occ_fe_3.RB, color = (palette[2], 0.35))
#CairoMakie.lines!(ax1, ret_per, threshold, linestyle = :dash, color = "black", linewidth = 2)

#5% Growth
CairoMakie.lines!(ax1, ret_per, occ_fe_7.median, color = palette[3], linewidth = 3, label = "fe = 0.07")
#, label = false)
CairoMakie.band!(ax1, ret_per, occ_fe_7.LB, occ_fe_7.RB, color = (palette[3], 0.35))
#CairoMakie.lines!(ax1, ret_per, threshold, linestyle = :dash, color = "black", linewidth = 2)

fig[1, 2] = Legend(fig, ax1, framevisible = false)
fig

CairoMakie.save(joinpath(pwd(),"figures/pop_growth.png"), fig)