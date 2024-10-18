#activate project environment
using Pkg
Pkg.activate(".")
Pkg.instantiate()

using CSV, DataFrames
using Statistics
using CairoMakie
using ColorSchemes
using FileIO

## Read in dataframe for Idealized Experiment
occ_med = DataFrame(CSV.File(joinpath(dirname(@__DIR__),"workflow/toy_model/dataframes/breach_base.csv")))


## Read in dataframes for Baltimore Experiment. Calculate Risk Shifting 
base_dam = DataFrame(CSV.File(joinpath(dirname(@__DIR__),"workflow/CHANCE_C/dataframes/base_event_damage.csv")))
levee_dam = DataFrame(CSV.File(joinpath(dirname(@__DIR__),"workflow/CHANCE_C/dataframes/levee_event_damage.csv")))

base_dam_low = DataFrame(CSV.File(joinpath(dirname(@__DIR__),"workflow/CHANCE_C/dataframes/base_event_low_RA.csv")))
levee_dam_low = DataFrame(CSV.File(joinpath(dirname(@__DIR__),"workflow/CHANCE_C/dataframes/levee_event_low_RA.csv")))


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




#Idealized
ret_per = range(10, 1000, length=100)
thresh_ideal = zeros(length(ret_per))
#Baltimore
event_size = collect(range(0.75, 4.0, step = 0.25))
thresh_balt = zeros(length(event_size))


## Plot results
#Create backdrop
fig = Figure(size = (1500,600), fontsize = 18, pt_per_unit = 1, figure_padding = 18)

ax1 = Axis(fig[1, 1:2], ylabel = rich("Difference in Occupied Exposure";font=:bold), xlabel = rich("Return Period (years)";font=:bold), xscale = log10,
 xticks = ([10,100,1000], string.([10,100,1000])), limits = ((10,1000), nothing), xgridvisible = false, titlealign = :center, title = "Comparing Flood Impact between Levee and No Levee Scenario")

ax2 = Axis(fig[2, 1:2], ylabel = rich("Difference in Loss (\$ Thousands)\n";font=:bold),
 xlabel = rich("Surge Event (m)";font=:bold), yticks = ([-2e4, 0, 2e4, 4e4], ["-20","0","20","40"]), limits = ((0.75,4), nothing),
 xgridvisible = false, titlealign = :center,
  title = "Comparing Flood Impact between Levee and No Levee Scenario")


Palette = ColorSchemes.okabe_ito
#Panel A
CairoMakie.lines!(ax1, ret_per, occ_med.median, color = Palette[1], linewidth = 2.5)
#, label = false)

CairoMakie.band!(ax1, ret_per, occ_med.LB, occ_med.RB, color = (Palette[1], 0.35))

CairoMakie.lines!(ax1, ret_per, thresh_ideal, linestyle = :dash, color = "black", linewidth = 2)









CairoMakie.lines!(ax2, event_size, diff_med_low, color = Palette[2], linewidth = 5)
 #, label = false)
 
CairoMakie.band!(ax2, event_size, diff_LB_low, diff_UB_low, color = (Palette[2], 0.35))


CairoMakie.lines!(ax2, event_size, diff_med, color = Palette[1], linewidth = 5)
 #, label = false)
 
CairoMakie.band!(ax2, event_size, diff_LB, diff_UB, color = (Palette[1], 0.35))
 
CairoMakie.lines!(ax2, event_size, thresh_balt, linestyle = :dash, color = "black", linewidth = 2)


#Add 100-year event and Floodwall height
CairoMakie.vlines!(ax2, [1.98, 2.804], color = [Palette[3], Palette[7]], linewidth = 2.5)

#Create Legend
elem_1 = [LineElement(color = Palette[1], linestyle = :solid, linewidth = 5), PolyElement(color = (Palette[1], 0.35))]

elem_2 = [LineElement(color = Palette[2], linestyle = :solid, linewidth = 5), PolyElement(color = (Palette[2], 0.35))]

elem_3 = [LineElement(color = Palette[3], linestyle = :solid)]

elem_4 = [LineElement(color = Palette[7], linestyle = :solid)]

axislegend(ax2, [[elem_1, elem_2], [elem_3, elem_4]] , [["High Risk Aversion", "Low Risk Aversion"],
["100-Year Event", "Flood Wall Height"]], ["Ensemble Summary", "Design Levels"], 
position = :lt, orientation = :vertical, framevisible = false, labelsize = 18)

display(fig)

CairoMakie.save(joinpath(pwd(),"figures/balt_rs_pres.svg"), fig)