using Pkg
Pkg.activate(".")
Pkg.instantiate()

using CSV, DataFrames
using CairoMakie

##Import results from benchmark damage scenario (breaching, 1% pop growth)
base_dam = DataFrame(CSV.File(joinpath(@__DIR__,"dataframes/base_event_damage.csv")))
levee_dam = DataFrame(CSV.File(joinpath(@__DIR__,"dataframes/levee_event_damage.csv")))

#Calculate Median and 95% Uncertainty Interval
diff_dam = Matrix(levee_dam) .- Matrix(base_dam) 

diff_med = vec(mapslices(x -> median(x), diff_dam, dims=2))

diff_UI = mapslices(x -> quantile(x, [0.025, 0.975]), diff_dam, dims=2)
diff_LB = diff_UI[:,1]
diff_UB = diff_UI[:,2]

base_null = DataFrame(CSV.File(joinpath(@__DIR__,"dataframes/base_event_no_breach_no_growth.csv")))
levee_null = DataFrame(CSV.File(joinpath(@__DIR__,"dataframes/levee_event_no_breach_no_growth.csv")))

#Calculate Median and 95% Uncertainty Interval
diff_dam_null = Matrix(levee_null) .- Matrix(base_null) 
    
diff_med_null = vec(mapslices(x -> median(x), diff_dam_null, dims=2))
    
diff_UI_null = mapslices(x -> quantile(x, [0.025, 0.975]), diff_dam_null, dims=2)
diff_LB_null = diff_UI_null[:,1]
diff_UB_null = diff_UI_null[:,2]

## Plot results
#Create backdrop
fig = Figure(size = (900,600), fontsize = 16, pt_per_unit = 1, figure_padding = 10)

ax1 = Axis(fig[1, 1], ylabel = "Difference in Loss", xlabel = "Surge Event (m)",limits = ((0.75,4), nothing),
 xgridvisible = false, titlealign = :center, title = "Comparing Flood Impact between Levee and Baseline Scenario")

#ax2 = Axis(fig[1, 2], ylabel = "Difference in Loss", xlabel = "Surge Event (m)",limits = ((0.75,4), nothing),
# xgridvisible = false, titlealign = :center, title = "Comparing Flood Impact between Levee and Baseline Scenario")

#linkaxes!(ax1, ax2)

event_size = collect(range(0.75, 4.0, step = 0.25))
threshold = zeros(length(event_size))

CairoMakie.lines!(ax1, event_size, diff_med, color = "orange", linewidth = 2.5)
 #, label = false)
 
CairoMakie.band!(ax1, event_size, diff_LB, diff_UB, color = ("orange", 0.35))
 
CairoMakie.lines!(ax1, event_size, threshold, linestyle = :dash, color = "black", linewidth = 2)


CairoMakie.lines!(ax1, event_size, diff_med_null, color = "blue", linewidth = 2.5)
 #, label = false)
 
CairoMakie.band!(ax1, event_size, diff_LB_null, diff_UB_null, color = ("blue", 0.35))
 
CairoMakie.lines!(ax1, event_size, threshold, linestyle = :dash, color = "black", linewidth = 2)

display(fig)
