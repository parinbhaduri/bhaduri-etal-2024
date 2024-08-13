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

#Calculate Median and 95% Uncertainty Interval
diff_dam = Matrix(levee_dam) .- Matrix(base_dam) 

diff_med = vec(mapslices(x -> median(x), diff_dam, dims=2))

diff_UI = mapslices(x -> quantile(x, [0.025, 0.975]), diff_dam, dims=2)
diff_LB = diff_UI[:,1]
diff_UB = diff_UI[:,2]

#Calculate Median and 95% Uncertainty Interval for low RA Scenario
diff_dam_low = Matrix(levee_dam_low) .- Matrix(base_dam_low) 

diff_med_low = vec(mapslices(x -> median(x), diff_dam_low, dims=2))

diff_UI_low = mapslices(x -> quantile(x, [0.025, 0.975]), diff_dam_low, dims=2)
diff_LB_low = diff_UI_low[:,1]
diff_UB_low = diff_UI_low[:,2]


## Plot results 
#Create backdrop
palette = ColorSchemes.okabe_ito

fig = Figure(size = (1800,1080), fontsize = 22, pt_per_unit = 1, figure_padding = 20)

ax1 = Axis(fig[1, 1], ylabel = rich(rich("Difference in Loss (\$ Thousands)\n";font=:bold),rich("[Levee - No Levee]")),
 xlabel = rich("Surge Event (m)";font=:bold), yticks = ([-2e4, 0, 2e4, 4e4], ["-20","0","20","40"]), limits = ((0.75,4), nothing),
 xgridvisible = false, titlealign = :center,
  title = "Comparing Flood Impact between Levee and No Levee Scenario")

CairoMakie.lines!(ax1, event_size, diff_med_low, color = palette[2], linewidth = 5)
 #, label = false)
 
CairoMakie.band!(ax1, event_size, diff_LB_low, diff_UB_low, color = (palette[2], 0.35))


CairoMakie.lines!(ax1, event_size, diff_med, color = palette[1], linewidth = 5)
 #, label = false)
 
CairoMakie.band!(ax1, event_size, diff_LB, diff_UB, color = (palette[1], 0.35))
 
CairoMakie.lines!(ax1, event_size, threshold, linestyle = :dash, color = "black", linewidth = 2)




#Add 100-year event and Floodwall height
CairoMakie.vlines!(ax1, [1.98, 2.804], color = [palette[3], palette[7]], linewidth = 2.5)

#Create Legend
elem_1 = [LineElement(color = palette[1], linestyle = :solid, linewidth = 5), PolyElement(color = (palette[1], 0.35))]

elem_2 = [LineElement(color = palette[2], linestyle = :solid, linewidth = 5), PolyElement(color = (palette[2], 0.35))]

elem_3 = [LineElement(color = palette[3], linestyle = :solid)]

elem_4 = [LineElement(color = palette[7], linestyle = :solid)]

axislegend(ax1, [[elem_1, elem_2], [elem_3, elem_4]] , [["High Risk Aversion", "Low Risk Aversion"],
["100-Year Event", "Flood Wall Height"]], ["Ensemble Summary", "Design Levels"], 
position = :lt, orientation = :vertical, framevisible = false, labelsize = 18)

display(fig)

CairoMakie.save(joinpath(pwd(),"figures/balt_rs_pres.svg"), fig)