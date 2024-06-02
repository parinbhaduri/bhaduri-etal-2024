#activate project environment
using Pkg
Pkg.activate(".")
Pkg.instantiate()

using CSV, DataFrames
using Statistics
using CairoMakie
using FileIO

## Read in dataframes
base_dam = DataFrame(CSV.File(joinpath(@__DIR__,"dataframes/base_event_damage.csv")))
levee_dam = DataFrame(CSV.File(joinpath(@__DIR__,"dataframes/levee_event_damage.csv")))

event_size = collect(range(0.75, 4.0, step = 0.25))
threshold = zeros(length(event_size))

#Calculate Median and 95% Uncertainty Interval
diff_dam = Matrix(levee_dam) .- Matrix(base_dam) 

diff_med = vec(mapslices(x -> median(x), diff_dam, dims=2))

diff_UI = mapslices(x -> quantile(x, [0.025, 0.975]), diff_dam, dims=2)
diff_LB = diff_UI[:,1]
diff_UB = diff_UI[:,2]


## Plot results
#Create backdrop
fig = Figure(size = (900,600), fontsize = 16, pt_per_unit = 1, figure_padding = 10)

ax1 = Axis(fig[1, 1], ylabel = "Difference in Loss", xlabel = "Surge Event (m)",limits = ((0.75,4), nothing),
 xgridvisible = false, titlealign = :center, title = "Comparing Flood Impact between Levee and Baseline Scenario")

CairoMakie.lines!(ax1, event_size, diff_med, color = "orange", linewidth = 2.5)
 #, label = false)
 
CairoMakie.band!(ax1, event_size, diff_LB, diff_UB, color = ("orange", 0.35))
 
CairoMakie.lines!(ax1, event_size, threshold, linestyle = :dash, color = "black", linewidth = 2)

display(fig)

CairoMakie.save(joinpath(pwd(),"figures/balt_rs.png"), fig)