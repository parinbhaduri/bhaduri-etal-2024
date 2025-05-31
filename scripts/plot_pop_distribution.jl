#activate project environment
using Pkg
Pkg.activate(".")
Pkg.instantiate()

using CSV, DataFrames
using CairoMakie
using ColorSchemes

#import GEV functions from toy model
include(joinpath(dirname(@__DIR__), "workflow/toy_model/src/toy_ABM_functions.jl")) #for GEV_return function

### Read in ABM ensemble evolution data
##Baltimore Experiment
adf = DataFrame(CSV.File(joinpath(dirname(@__DIR__),"workflow/CHANCE_C/dataframes/adf_balt_city.csv")))

balt_base_high = subset(adf, :levee => ByRow(isequal(false)), :slr_scen => ByRow(isequal("medium")), :risk_averse => ByRow(isequal(0.3)))
balt_base_low = subset(adf, :levee => ByRow(isequal(false)), :slr_scen => ByRow(isequal("medium")),  :risk_averse => ByRow(isequal(0.7)))

balt_levee_high = subset(adf, :levee => ByRow(isequal(true)), :slr_scen => ByRow(isequal("medium")), :risk_averse => ByRow(isequal(0.3)))
balt_levee_low = subset(adf, :levee => ByRow(isequal(true)), :slr_scen => ByRow(isequal("medium")), :risk_averse => ByRow(isequal(0.7)))

##Idealized Experiment
ideal_base = DataFrame(CSV.File(joinpath(dirname(@__DIR__), "workflow/toy_model/dataframes/adf_base.csv")))
#Separate high RA and low RA
ideal_base_high = filter(:risk_averse => isequal(0.3), ideal_base)
ideal_base_low = filter(:risk_averse => isequal(0.7), ideal_base)

ideal_levee = DataFrame(CSV.File(joinpath(dirname(@__DIR__), "workflow/toy_model/dataframes/adf_levee.csv")))
#Separate high RA and low RA
ideal_levee_high = filter(:risk_averse => isequal(0.3), ideal_levee)
ideal_levee_low = filter(:risk_averse => isequal(0.7), ideal_levee)

flood_100 = [GEV_return(1/100) for _ in 1:51]


##Plot Baseline Results
fig = Figure(size = (1000, 1500), fontsize = 16, pt_per_unit = 1, figure_padding = 20)
ga = fig[1, 1:2] = GridLayout()
gb = fig[2, 1:2] = GridLayout()


ax1 = Axis(ga[1, 1], xlabel = rich("Difference in Population (count)"; font = :bold), ylabel = rich("Count"; font = :bold),
 title = "a. Idealized Experiment", titlealign = :left, titlesize = 18, ygridvisible = false)
hidespines!(ax1, :t, :r)

ax2 = Axis(gb[1, 1], xlabel = rich("Difference in Population (count)"; font = :bold), ylabel = rich("Count"; font = :bold),
 title = "b. Baltimore Experiment", titlealign = :left, titlesize = 18, ygridvisible = false, xticks = ([-5e3, 0, 5e3, 1e4], ["-5000","0","5000","10000"]))
hidespines!(ax2, :t, :r)


Palette = ColorSchemes.okabe_ito

#Plot Difference in floodplain population between levee and no levee scenario (Baltimore)
ideal_base_final_high = filter(row -> (row.step == 50), ideal_base_high)
ideal_levee_final_high = filter(row -> (row.step == 50), ideal_levee_high)

ideal_base_final_low = filter(row -> (row.step == 50), ideal_base_low)
ideal_levee_final_low = filter(row -> (row.step == 50), ideal_levee_low)

ideal_diff_high = ideal_levee_final_high.count_floodplain_fam .-  ideal_base_final_high.count_floodplain_fam
ideal_diff_low = ideal_levee_final_low.count_floodplain_fam .-  ideal_base_final_low.count_floodplain_fam

CairoMakie.hist!(ax1, ideal_diff_high, color = (Palette[1], 0.75))
CairoMakie.hist!(ax1, ideal_diff_low, color = (Palette[2], 0.75), offset = 1)

#Create Legend
elem_1 = [PolyElement(color = Palette[1])]
elem_2 = [PolyElement(color = Palette[2])]


axislegend(ax1, [elem_1, elem_2] , ["High Risk Aversion", "Low Risk Aversion"], position = :rt,
 orientation = :vertical, framevisible = false)

#Plot Difference in floodplain population between levee and no levee scenario (Baltimore)
balt_base_final_high = filter(row -> (row.step == 50), balt_base_high)
balt_levee_final_high = filter(row -> (row.step == 50), balt_levee_high)

balt_base_final_low = filter(row -> (row.step == 50), balt_base_low)
balt_levee_final_low = filter(row -> (row.step == 50), balt_levee_low)

balt_diff_high = balt_levee_final_high.sum_population_f_c_bgs .-  balt_base_final_high.sum_population_f_c_bgs
balt_diff_low = balt_levee_final_low.sum_population_f_c_bgs .-  balt_base_final_low.sum_population_f_c_bgs

CairoMakie.hist!(ax2, balt_diff_high, color = (Palette[1], 0.75))
CairoMakie.hist!(ax2, balt_diff_low, color = (Palette[2], 0.75), offset = 1)

#Create Legend
elem_1 = [PolyElement(color = Palette[1])]
elem_2 = [PolyElement(color = Palette[2])]


axislegend(ax2, [elem_1, elem_2] , ["High Risk Aversion", "Low Risk Aversion"], position = :rt,
 orientation = :vertical, framevisible = false)

display(fig)



CairoMakie.save(joinpath(pwd(),"figures/abm_population_final.png"), fig)



### Additional Analysis
#Check records with negative pop difference for CHANCE-C 
neg_pop_high = findall(<(0), balt_diff_high)
println("Percent of High RA Realizations with Negative Population Differences (CHANCE-C): $((length(neg_pop_high)/1000) * 100)%")

neg_pop_low = findall(<(0), balt_diff_low)
println("Percent of Low RA Realizations with Negative Population Differences (CHANCE-C): $((length(neg_pop_low)/1000) * 100)%")

#Plot Associated Flood records
seeds_high = balt_levee_final_high.seed[neg_pop_high]
seeds_low = balt_levee_final_low.seed[neg_pop_low]

floods_low = mdf_balt[[x in seeds_low for x in mdf_balt.seed],:]
floods_high = mdf_balt[[x ∉ seeds_low for x in mdf_balt.seed],:]
records_low = transpose(reshape(floods_low.flood_record, (50,length(seeds_low))))
records_high = transpose(reshape(floods_high.flood_record, (50,1000 - length(seeds_low))))
#records = transpose(reshape(mdf_balt.flood_record, (50,1000)))

fig = Figure(size = (1000, 1000), fontsize = 16, pt_per_unit = 1, figure_padding = 20)

ax = Axis(fig[1, 1], ylabel = rich("Surge Height (meters)"; font = :bold), xlabel = rich("Model Time Step (years)"; font = :bold),
title = " a. Floodplain Population Response after Major Flood Event in No Levee Scenario (Idealized)", titlesize = 18,
limits = (nothing, nothing), xgridvisible = false)
hidespines!(ax, :t, :r)

CairoMakie.series!(ax, records_low, solid_color = (:black, 0.25), linewidth = 1)
display(fig)







"""
ax3 = Axis(gc[1, 1], ylabel = rich("Difference in Population (count)"; font = :bold), xlabel = rich("Model Timestep (year)"; font = :bold),
title = "c. Difference in Floodplain Population between Levee and No Levee Scenario (Baltimore)", titlesize = 18, 
 xgridvisible = false, yticks = ([-5e3, 0, 5e3, 1e4], ["-5000","0","5000","10000"]), limits = ((0,50), (nothing, nothing)))
hidespines!(ax3, :t, :r)


ax3 = Axis(gc[1, 1], xlabel = rich("Difference in Population (count)"; font = :bold), ylabel = rich("Count"; font = :bold),
 title = "c. Difference in Final Floodplain Population between Levee and No Levee Scenario (Baltimore)", titlesize = 16, 
  ygridvisible = false, xticks = ([-5e3, 0, 5e3, 1e4], ["-5000","0","5000","10000"]))
hidespines!(ax3, :t, :r)
"""

"""
balt_diff_high = transpose(reshape(balt_levee_high.sum_population_f_c_bgs, (51,1000))) .-  transpose(reshape(balt_base_high.sum_population_f_c_bgs, (51,1000)))
balt_diff_low = transpose(reshape(balt_levee_low.sum_population_f_c_bgs, (51,1000))) .- transpose(reshape(balt_base_low.sum_population_f_c_bgs, (51,1000)))

CairoMakie.series!(ax3, balt_diff_high, solid_color = (Palette[1], 0.25), linewidth = 1)#, overdraw = true, transparency = true)
CairoMakie.series!(ax3, balt_diff_low, solid_color = (Palette[2], 0.25), linewidth = 1)#, overdraw = true, transparency = true)
#Create Legend
elem_1 = [LineElement(color = Palette[1], linestyle = nothing)]

elem_2 = [LineElement(color = Palette[2], linestyle = nothing)]

axislegend(ax3, [elem_1, elem_2] , ["High Risk Aversion", "Low Risk Aversion"], position = :lt, orientation = :horizontal,
 framevisible = false)

#Alternative Plot ***
balt_base_final_high = filter(row -> (row.step == 50), balt_base_high)
balt_levee_final_high = filter(row -> (row.step == 50), balt_levee_high)

balt_base_final_low = filter(row -> (row.step == 50), balt_base_low)
balt_levee_final_low = filter(row -> (row.step == 50), balt_levee_low)

balt_diff_high = balt_levee_final_high.sum_population_f_c_bgs .-  balt_base_final_high.sum_population_f_c_bgs
balt_diff_low = balt_levee_final_low.sum_population_f_c_bgs .-  balt_base_final_low.sum_population_f_c_bgs

CairoMakie.hist!(ax3, balt_diff_high, color = (Palette[1], 0.75))
CairoMakie.hist!(ax3, balt_diff_low, color = (Palette[2], 0.75), offset = 1)
"""