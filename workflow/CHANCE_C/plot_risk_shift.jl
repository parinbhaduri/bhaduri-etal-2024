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

base_dam_250 = DataFrame(CSV.File(joinpath(@__DIR__,"dataframes/base_event_damage_250.csv")))
levee_dam_250 = DataFrame(CSV.File(joinpath(@__DIR__,"dataframes/levee_event_damage_250.csv")))

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

ax1 = Axis(fig[1, 1], ylabel = "Difference in Loss (\$ Thousands)", xlabel = "Surge Event (m)",limits = ((0.75,4), nothing),
 xgridvisible = false, yticks = ([0, 2e4, 4e4], ["0","20", "40"]), titlealign = :center, title = "Comparing Flood Impact between Levee and Baseline Scenario")

CairoMakie.lines!(ax1, event_size, diff_med, color = "orange", linewidth = 2.5)
 #, label = false)
 
CairoMakie.band!(ax1, event_size, diff_LB, diff_UB, color = ("orange", 0.35))
 
CairoMakie.lines!(ax1, event_size, threshold, linestyle = :dash, color = "black", linewidth = 2)



#Add 100-year event and Floodwall height
CairoMakie.vlines!(ax1, [1.98, 2.804], color = ["green", "purple"], linewidth = 2.5)

#Create Legend
elem_1 = [LineElement(color = "orange", linestyle = :solid)]

elem_2 = [PolyElement(color = ("orange", 0.35))]

elem_3 = [LineElement(color = "green", linestyle = :solid)]

elem_4 = [LineElement(color = "purple", linestyle = :solid)]

axislegend(ax1, [[elem_1, elem_2], [elem_3, elem_4]] , [["Median", "90% Interval"],
["100-Year Event", "Flood Wall Height"]], ["Ensemble Summary", "Design Levels"], 
position = :lt, orientation = :vertical, framevisible = false)

display(fig)

CairoMakie.save(joinpath(pwd(),"figures/balt_rs.png"), fig)