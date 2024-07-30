#activate project environment
using Pkg
Pkg.activate(".")
Pkg.instantiate()

using CSV, DataFrames
using Statistics
using CairoMakie
using ColorSchemes
using FileIO

## Read in dataframes
base_dam = DataFrame(CSV.File(joinpath(@__DIR__,"dataframes/base_event_damage.csv")))
levee_dam = DataFrame(CSV.File(joinpath(@__DIR__,"dataframes/levee_event_damage.csv")))

base_dam_low = DataFrame(CSV.File(joinpath(@__DIR__,"dataframes/base_event_low_RA.csv")))
levee_dam_low = DataFrame(CSV.File(joinpath(@__DIR__,"dataframes/levee_event_low_RA.csv")))

event_size = collect(range(0.75, 4.0, step = 0.25))
threshold = zeros(length(event_size))

#Take Difference between Levee and No Levee, then b/w RA scenarios
diff_dam = Matrix(levee_dam) .- Matrix(base_dam)
diff_dam_low = Matrix(levee_dam_low) .- Matrix(base_dam_low)

diff_dam_RA = diff_dam .- diff_dam_low

#Calculate Median and 95% Uncertainty Interval
diff_med_RA = vec(mapslices(x -> median(x), diff_dam_RA, dims=2))

diff_UI_RA = mapslices(x -> quantile(x, [0.025, 0.975]), diff_dam_RA, dims=2)
diff_LB_RA = diff_UI_RA[:,1]
diff_UB_RA = diff_UI_RA[:,2]




## Plot results 
#Create backdrop
palette = ColorSchemes.okabe_ito

fig = Figure(size = (1000,600), fontsize = 23, pt_per_unit = 1, figure_padding = 15)

ax1 = Axis(fig[1, 1], ylabel = "Flood Loss (\$ Thousands)", xlabel = "Surge Event (m)",limits = ((0.75,4), nothing),
 xgridvisible = false, yticks = ([0, 2e4, 4e4], ["0","20", "40"]), titlealign = :center, title = rich("Difference in Flood Loss (High Risk Aversion - Low Risk Aversion)";font=:bold))

CairoMakie.lines!(ax1, event_size, diff_med_RA, color = palette[6], linewidth = 5)
 #, label = false)
 
CairoMakie.band!(ax1, event_size, diff_LB_RA, diff_UB_RA, color = (palette[6], 0.35))

CairoMakie.lines!(ax1, event_size, threshold, linestyle = :dash, color = "black", linewidth = 2)

#Add 100-year event and Floodwall height
#CairoMakie.vlines!(ax1, [1.98, 2.804], color = [palette[3], palette[7]], linewidth = 2.5)

display(fig)
"""
#Create Legend
elem_1 = [LineElement(color = palette[6], linestyle = :solid, linewidth = 5)]

elem_2 = [PolyElement(color = (palette[6], 0.35))]

elem_3 = [LineElement(color = palette[3], linestyle = :solid)]

elem_4 = [LineElement(color = palette[7], linestyle = :solid)]

axislegend(ax1, [[elem_1, elem_2], [elem_3, elem_4]] , [["Median", "95% Interval"],
["100-Year Event", "Flood Wall Height"]], ["Ensemble Summary", "Design Levels"], 
position = :lt, orientation = :vertical, framevisible = false)

axislegend(ax1, [elem_1, elem_2] , ["Median", "95% Interval"], "Ensemble Summary", 
position = :lt, orientation = :vertical, framevisible = false)
"""


CairoMakie.save(joinpath(pwd(),"figures/balt_rs_diffRA.png"), fig)