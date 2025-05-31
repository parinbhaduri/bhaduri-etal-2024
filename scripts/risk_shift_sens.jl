### Looking at Risk Shifting Sensitivity to Pop. Growth and RA
#for Baltimore Experiment ###
#activate project environment
using Pkg
Pkg.activate(".")
Pkg.instantiate()

using CSV, DataFrames
using StatsBase
using Statistics
using CairoMakie
using ColorSchemes
using FileIO

#Idealized
ret_per = range(10, 1000, length=100)
thresh_ideal = zeros(length(ret_per))

#Baltimore
event_size = collect(range(0.75, 4.0, step = 0.25))
thresh_balt = zeros(length(event_size))

## Read in dataframes for Baltimore Experiment. Calculate Risk Shifting 
base_dam_ng = DataFrame(CSV.File(joinpath(dirname(@__DIR__),"workflow/CHANCE_C/dataframes/base_event_damage_no_growth.csv")))
levee_dam_ng = DataFrame(CSV.File(joinpath(dirname(@__DIR__),"workflow/CHANCE_C/dataframes/levee_event_damage_no_growth.csv")))

base_dam_low_ng = DataFrame(CSV.File(joinpath(dirname(@__DIR__),"workflow/CHANCE_C/dataframes/base_event_no_growth_low_RA.csv")))
levee_dam_low_ng = DataFrame(CSV.File(joinpath(dirname(@__DIR__),"workflow/CHANCE_C/dataframes/levee_event_no_growth_low_RA.csv")))


## Read in dataframes for Baltimore Experiment. Calculate Risk Shifting 
base_dam_2g = DataFrame(CSV.File(joinpath(dirname(@__DIR__),"workflow/CHANCE_C/dataframes/base_event_damage_two_growth.csv")))
levee_dam_2g = DataFrame(CSV.File(joinpath(dirname(@__DIR__),"workflow/CHANCE_C/dataframes/levee_event_damage_two_growth.csv")))

base_dam_low_2g = DataFrame(CSV.File(joinpath(dirname(@__DIR__),"workflow/CHANCE_C/dataframes/base_event_two_growth_low_RA.csv")))
levee_dam_low_2g = DataFrame(CSV.File(joinpath(dirname(@__DIR__),"workflow/CHANCE_C/dataframes/levee_event_two_growth_low_RA.csv")))


#Function to Calculate Median and 95% Uncertainty Interval
function rt_interval(levee_df,base_df)
    diff_dam = Matrix(levee_df) .- Matrix(base_df) 

    diff_med = vec(mapslices(x -> median(x), diff_dam, dims=2))

    diff_UI = mapslices(x -> quantile(x, [0.025, 0.975]), diff_dam, dims=2)
    diff_LB = diff_UI[:,1]
    diff_UB = diff_UI[:,2]

    return diff_med, diff_LB, diff_UB
end

diff_med_ng, diff_LB_ng, diff_UB_ng = rt_interval(levee_dam_ng, base_dam_ng)
diff_med_low_ng, diff_LB_low_ng, diff_UB_low_ng = rt_interval(levee_dam_low_ng, base_dam_low_ng)

diff_med_2g, diff_LB_2g, diff_UB_2g = rt_interval(levee_dam_2g, base_dam_2g)
diff_med_low_2g, diff_LB_low_2g, diff_UB_low_2g = rt_interval(levee_dam_low_2g, base_dam_low_2g)

##Read in Data for Idealized Experiment
occ_bp_low_ra_hi = DataFrame(CSV.File(joinpath(dirname(@__DIR__),"workflow/toy_model/dataframes/bp_low_ra_hi.csv")))
occ_bp_low_ra_low = DataFrame(CSV.File(joinpath(dirname(@__DIR__),"workflow/toy_model/dataframes/bp_low_ra_low.csv")))

occ_bp_hi_ra_hi = DataFrame(CSV.File(joinpath(dirname(@__DIR__),"workflow/toy_model/dataframes/bp_hi_ra_hi.csv")))
occ_bp_hi_ra_low = DataFrame(CSV.File(joinpath(dirname(@__DIR__),"workflow/toy_model/dataframes/bp_hi_ra_low.csv")))

## Plot results
#Create backdrop
fig = Figure(size = (700,800), fontsize = 16, pt_per_unit = 1, figure_padding = 18)

ax1 = Axis(fig[1, 1:2], ylabel = rich("Difference in Loss\n (\$ Thousands)";font=:bold),
xlabel = rich("Surge Event (m)";font=:bold), titlesize = 18, yticks = ([-2e4, 0, 2e4, 4e4], ["-20","0","20","40"]), limits = ((0.75,4), nothing),
xgridvisible = false, titlealign = :left, title = "a. Baltimore Experiment (No Growth)")

ax2 = Axis(fig[2, 1:2], ylabel = rich("Difference in Loss\n (\$ Thousands)";font=:bold),
 xlabel = rich("Surge Event (m)";font=:bold), titlesize = 18, yticks = ([-2e4, 0, 2e4, 4e4], ["-20","0","20","40"]), limits = ((0.75,4), nothing),
 xgridvisible = false, titlealign = :left, title = "b. Baltimore Experiment (2% Growth)")


Palette = ColorSchemes.okabe_ito
##Panel A
CairoMakie.lines!(ax1, event_size, diff_med_low_ng, color = Palette[2], linewidth = 3.5)
 #, label = false)
CairoMakie.band!(ax1, event_size, diff_LB_low_ng, diff_UB_low_ng, color = (Palette[2], 0.35))


CairoMakie.lines!(ax1, event_size, diff_med_ng, color = Palette[1], linewidth = 3.5)
 #, label = false)
CairoMakie.band!(ax1, event_size, diff_LB_ng, diff_UB_ng, color = (Palette[1], 0.35))
 
CairoMakie.lines!(ax1, event_size, thresh_balt, linestyle = :dash, color = "black", linewidth = 2)

#Add 100-year event and Floodwall height
CairoMakie.vlines!(ax1, 2.804, color = Palette[3], linewidth = 2.5) # 100-yr event = 1.98 m



##Panel B
CairoMakie.lines!(ax2, event_size, diff_med_low_2g, color = Palette[2], linewidth = 3.5)
 #, label = false)
CairoMakie.band!(ax2, event_size, diff_LB_low_2g, diff_UB_low_2g, color = (Palette[2], 0.35))


CairoMakie.lines!(ax2, event_size, diff_med_2g, color = Palette[1], linewidth = 3.5)
 #, label = false)
CairoMakie.band!(ax2, event_size, diff_LB_2g, diff_UB_2g, color = (Palette[1], 0.35))
 
CairoMakie.lines!(ax2, event_size, thresh_balt, linestyle = :dash, color = "black", linewidth = 2)

#Add 100-year event and Floodwall height
CairoMakie.vlines!(ax2, 2.804, color = Palette[3], linewidth = 2.5) # 100-yr event = 1.98 m

#Create Legend
elem_1 = [LineElement(color = Palette[1], linestyle = :solid, linewidth = 5), PolyElement(color = (Palette[1], 0.35))]

elem_2 = [LineElement(color = Palette[2], linestyle = :solid, linewidth = 5), PolyElement(color = (Palette[2], 0.35))]

elem_3 = [LineElement(color = Palette[3], linestyle = :solid)]

#elem_4 = [LineElement(color = Palette[7], linestyle = :solid)]

Legend(fig[3, 1:2], [elem_1, elem_2, elem_3] , ["High Risk Aversion", "Low Risk Aversion", "Levee Height"],
orientation = :horizontal, framevisible = false, labelsize = 16) #position = :lt,

rowgap!(fig.layout, 2, 25)
display(fig)

CairoMakie.save(joinpath(pwd(),"figures/risk_transference_pop_growth.png"), fig)




### Plot Idealized w/ Base Probability

fig = Figure(size = (700,800), fontsize = 16, pt_per_unit = 1, figure_padding = 18)

ax1 = Axis(fig[1, 1:2], ylabel = rich("Difference in\n Occupied Exposure";font=:bold), xlabel = rich("Return Period (years)";font=:bold), xscale = log10,
titlesize = 18, xticks = ([10,100,1000], string.([10,100,1000])), limits = ((10,1000), (-2500,4500)), xgridvisible = false, titlealign = :left, title = "a. Idealized Experiment (1% Base Move Probability)")

ax2 = Axis(fig[2, 1:2], ylabel = rich("Difference in\n Occupied Exposure";font=:bold), xlabel = rich("Return Period (years)";font=:bold), xscale = log10,
titlesize = 18, xticks = ([10,100,1000], string.([10,100,1000])), limits = ((10,1000), (-2500,4500)), xgridvisible = false, titlealign = :left, title = "b. Idealized Experiment (5% Base Move Probability)")


Palette = ColorSchemes.okabe_ito
##Panel A
CairoMakie.lines!(ax1, ret_per, occ_bp_low_ra_hi.median, color = Palette[1], linewidth = 3.5)
#, label = false)
CairoMakie.band!(ax1, ret_per, occ_bp_low_ra_hi.LB, occ_bp_low_ra_hi.RB, color = (Palette[1], 0.35))

CairoMakie.lines!(ax1, ret_per, occ_bp_low_ra_low.median, color = Palette[2], linewidth = 3.5)
#, label = false)
CairoMakie.band!(ax1, ret_per, occ_bp_low_ra_low.LB, occ_bp_low_ra_low.RB, color = (Palette[2], 0.35))

CairoMakie.lines!(ax1, ret_per, thresh_ideal, linestyle = :dash, color = "black", linewidth = 2)
#Add Floodwall Height
CairoMakie.vlines!(ax1, 100, color = Palette[3], linewidth = 2.5)

##Panel B
CairoMakie.lines!(ax2, ret_per, occ_bp_hi_ra_hi.median, color = Palette[1], linewidth = 3.5)
#, label = false)
CairoMakie.band!(ax2, ret_per, occ_bp_hi_ra_hi.LB, occ_bp_hi_ra_hi.RB, color = (Palette[1], 0.35))

CairoMakie.lines!(ax2, ret_per, occ_bp_hi_ra_low.median, color = Palette[2], linewidth = 3.5)
#, label = false)
CairoMakie.band!(ax2, ret_per, occ_bp_hi_ra_low.LB, occ_bp_hi_ra_low.RB, color = (Palette[2], 0.35))

CairoMakie.lines!(ax2, ret_per, thresh_ideal, linestyle = :dash, color = "black", linewidth = 2)
#Add Floodwall Height
CairoMakie.vlines!(ax2, 100, color = Palette[3], linewidth = 2.5)

#Create Legend
elem_1 = [LineElement(color = Palette[1], linestyle = :solid, linewidth = 5), PolyElement(color = (Palette[1], 0.35))]

elem_2 = [LineElement(color = Palette[2], linestyle = :solid, linewidth = 5), PolyElement(color = (Palette[2], 0.35))]

elem_3 = [LineElement(color = Palette[3], linestyle = :solid)]

#elem_4 = [LineElement(color = Palette[7], linestyle = :solid)]

Legend(fig[3, 1:2], [elem_1, elem_2, elem_3] , ["High Risk Aversion", "Low Risk Aversion", "Levee Height"],
orientation = :horizontal, framevisible = false, labelsize = 16) #position = :lt,

rowgap!(fig.layout, 2, 25)
display(fig)

CairoMakie.save(joinpath(pwd(),"figures/risk_transference_base_move.png"), fig)