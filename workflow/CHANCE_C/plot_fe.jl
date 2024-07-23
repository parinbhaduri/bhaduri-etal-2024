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

##Import results from benchmark damage scenario (no breaching, no pop growth)
base_null = DataFrame(CSV.File(joinpath(@__DIR__,"dataframes/base_event_no_breach_no_growth.csv")))
levee_null = DataFrame(CSV.File(joinpath(@__DIR__,"dataframes/levee_event_no_breach_no_growth.csv")))

#Calculate Median and 95% Uncertainty Interval
diff_dam_null = Matrix(levee_null) .- Matrix(base_null) 
    
diff_med_null = vec(mapslices(x -> median(x), diff_dam_null, dims=2))
    
diff_UI_null = mapslices(x -> quantile(x, [0.025, 0.975]), diff_dam_null, dims=2)
diff_LB_null = diff_UI_null[:,1]
diff_UB_null = diff_UI_null[:,2]

##Import results from optimal f_e damage scenario (no breaching, no pop growth)
base_optim = DataFrame(CSV.File(joinpath(@__DIR__,"dataframes/base_event_optimFE_no_breach_no_growth.csv")))
levee_optim = DataFrame(CSV.File(joinpath(@__DIR__,"dataframes/levee_event_optimFE_no_breach_no_growth.csv")))

#Calculate Median and 95% Uncertainty Interval
diff_dam_optim = Matrix(levee_optim) .- Matrix(base_optim) 
    
diff_med_optim = vec(mapslices(x -> median(x), diff_dam_optim, dims=2))
    
diff_UI_optim = mapslices(x -> quantile(x, [0.025, 0.975]), diff_dam_optim, dims=2)
diff_LB_optim = diff_UI_optim[:,1]
diff_UB_optim = diff_UI_optim[:,2]

## Plot results
#Create backdrop
fig = Figure(size = (900,700), fontsize = 16, pt_per_unit = 1, figure_padding = 10)

ax1 = Axis(fig[1, 1:2], ylabel = "Difference in Loss (\$ Thousands)", xlabel = "Surge Event (m)",limits = ((0.75,4), nothing),
 xgridvisible = false, yticks = ([0, 2e4, 4e4], ["0","20", "40"]), titlealign = :center, title = "a. Flood Risk Transference between Benchmark and No Levee Breach Ensemble")

ax2 = Axis(fig[2, 1:2], ylabel = "Difference in Loss (\$ Thousands)", xlabel = "Surge Event (m)",limits = ((0.75,4), nothing),
 xgridvisible = false, yticks = ([0, 2e4, 4e4], ["0","20", "40"]), titlealign = :center, title = "b. Matching Benchmark Flood Risk Transference by increasing Levee Influence")

#gl2 = GridLayout(fig[1:3, 2:3], height = Relative(0.5))
#ax3 = Axis(gl2[1, 1], ylabel = "Difference in Loss (\$ Thousands)", xlabel = "Surge Event (m)",limits = ((0.75,4), nothing),
# xgridvisible = false, yticks = ([0, 2e4, 4e4], ["0","20", "40"]), titlealign = :center, title = "Fixed Effect Included")

linkaxes!(ax1, ax2)

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

#Create Legend
elem_1 = [LineElement(color = "orange", linestyle = :solid)]

elem_2 = [PolyElement(color = ("orange", 0.35))]

elem_3 = [LineElement(color = "blue", linestyle = :solid)]

elem_4 = [PolyElement(color = ("blue", 0.35))]

axislegend(ax1, [[elem_1, elem_2], [elem_3, elem_4]] , [["Median", "90% Interval"],["Median", "90% Interval"]],
 ["Benchmark Ensemble Summary", "No Levee Breach Ensemble Summary"], position = :lt, orientation = :horizontal, framevisible = false)

CairoMakie.lines!(ax2, event_size, diff_med, color = "orange", linewidth = 2.5)
 #, label = false)
 
CairoMakie.band!(ax2, event_size, diff_LB, diff_UB, color = ("orange", 0.35))
 
CairoMakie.lines!(ax2, event_size, threshold, linestyle = :dash, color = "black", linewidth = 2)

CairoMakie.lines!(ax2, event_size, diff_med_optim, color = "green", linewidth = 2.5)
 #, label = false)
 
CairoMakie.band!(ax2, event_size, diff_LB_optim, diff_UB_optim, color = ("green", 0.35))
 
CairoMakie.lines!(ax2, event_size, threshold, linestyle = :dash, color = "black", linewidth = 2)

#Create Legend
elem_1 = [LineElement(color = "orange", linestyle = :solid)]

elem_2 = [PolyElement(color = ("orange", 0.35))]

elem_3 = [LineElement(color = "green", linestyle = :solid)]

elem_4 = [PolyElement(color = ("green", 0.35))]

axislegend(ax2, [[elem_1, elem_2], [elem_3, elem_4]] , [["Median", "90% Interval"],["Median", "90% Interval"]],
 ["Benchmark Ensemble Summary", "FIxed Effect Ensemble Summary"], position = :lt, orientation = :horizontal, framevisible = false)

display(fig)

CairoMakie.save(joinpath(pwd(),"figures/balt_rs_fe.png"), fig)
