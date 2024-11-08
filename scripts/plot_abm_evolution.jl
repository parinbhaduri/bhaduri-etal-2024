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

mdf = DataFrame(CSV.File(joinpath(dirname(@__DIR__),"workflow/CHANCE_C/dataframes/mdf_balt_city.csv")))
filter!(row -> !(row.step == 0), mdf) #Remove initial time step from each realization record
mdf_balt = subset(mdf, :levee => ByRow(isequal(false)), :slr_scen => ByRow(isequal("medium")), :risk_averse => ByRow(isequal(0.3)))

##Idealized Experiment
adf_base = DataFrame(CSV.File(joinpath(dirname(@__DIR__), "workflow/toy_model/dataframes/adf_base.csv")))
#Separate high RA and low RA
adf_base_high = filter(:risk_averse => isequal(0.3), adf_base)
adf_base_low = filter(:risk_averse => isequal(0.7), adf_base)

adf_levee = DataFrame(CSV.File(joinpath(dirname(@__DIR__), "workflow/toy_model/dataframes/adf_levee.csv")))
#Separate high RA and low RA
adf_levee_high = filter(:risk_averse => isequal(0.3), adf_levee)
adf_levee_low = filter(:risk_averse => isequal(0.7), adf_levee)

flood_100 = [GEV_return(1/100) for _ in 1:51]

mdf_base = DataFrame(CSV.File(joinpath(dirname(@__DIR__), "workflow/toy_model/dataframes/mdf_base.csv")))
mdf_base = subset(mdf_base, :risk_averse => ByRow(isequal(0.3))) #Just grab one flood record ensemble

mdf_levee = DataFrame(CSV.File(joinpath(dirname(@__DIR__), "workflow/toy_model/dataframes/mdf_levee.csv")))
mdf_levee = subset(mdf_levee, :risk_averse => ByRow(isequal(0.3)))

function pop_response(mdf, adf)
    base_max_depth = combine(groupby(mdf, :seed), :floodepth => maximum => :max_depth, [:floodepth, :step] => ((depth,step) -> step[argmax(depth)])  => :step)

    max_high = Array{Union{Missing, Float64}}(missing,length(base_max_depth.seed),12)
    max_low = copy(max_high)

    for (row_index, row) in enumerate(eachrow(base_max_depth))
        pop_mem = row.step + 12 <= 50 ? range(row.step, row.step + 12, step = 1) : range(row.step, 50, step = 1)

        max_resp_high = subset(adf, :seed => ByRow(isequal(row.seed)), :step => ByRow(step -> step in collect(pop_mem)))
        pop_high = [(max_resp_high.count_floodplain_fam[i] .- max_resp_high.count_floodplain_fam[i-1]) for i in 2:length(max_resp_high.count_floodplain_fam)]

        max_high[row_index, 1:Int(length(pop_high))] = pop_high
    end
    
    #lev_height = GEV_return(1/100)
    #extreme_runs = findall(base_max_depth.max_depth .> lev_height)
    ext_max = max_high#[extreme_runs,:]#, max_low[extreme_runs,:])

    #Create categories for boxplot
    mat_size = size(ext_max)
    category = hcat([repeat([i],mat_size[1]) for i = 1:mat_size[2]]...)

    mem_cat = reduce(vcat, category)
    max_val = reduce(vcat, ext_max)
    #remove missing values
    miss_ind = findall(ismissing, max_val)
    max_val = max_val[Not(miss_ind)]
    mem_cat = mem_cat[Not(miss_ind)]
    

    return mem_cat, max_val
    
end

"""
resp_med = mapslices(x -> median(skipmissing(x)), ext_max, dims=1)
resp_quantiles = mapslices(x -> quantile(skipmissing(x), [0.025, 0.975]), ext_max, dims=1)

row = base_max_depth[base_max_depth.seed .== 1005,:][1,:]
pop_mem = row.step + 15 <= 50 ? range(row.step, row.step + 15, step = 1) : range(row.step, 50, step = 1)
max_response = subset(adf_base_high, :seed => ByRow(isequal(row.seed)), :step => ByRow(step -> step in collect(pop_mem)))
pop_change = [(max_response.count_floodplain_fam[i] .- max_response.count_floodplain_fam[i-1]) ./ max_response.count_floodplain_fam[i-1] for i in 2:length(max_response.count_floodplain_fam)]
"""

##Plot Baseline Results
fig = Figure(size = (1000, 1000), fontsize = 16, pt_per_unit = 1, figure_padding = 20)
ga = fig[1, 1:2] = GridLayout()
gb = fig[2, 1:2] = GridLayout()
gc = fig[3, 1:2] = GridLayout()

ax1 = Axis(ga[1, 1], ylabel = rich("Change in Population (count)"; font = :bold), xlabel = rich("Time Since Major Flood (years)"; font = :bold),
title = " a. Floodplain Population Response after Major Flood Event in No Levee Scenario (Idealized)", titlesize = 18,
limits = ((0,13), nothing), xgridvisible = false)
hidespines!(ax1, :t, :r)

ax2 = Axis(gb[1, 1], ylabel = rich("Difference in Population (count)"; font = :bold), xlabel = rich("Model Timestep (year)"; font = :bold),
title = "b. Difference in Floodplain Population between Levee and No Levee Scenario (Idealized)", titlesize = 18, 
limits = ((0,50), (nothing, 400)), xgridvisible = false)
hidespines!(ax2, :t, :r)

ax3 = Axis(gc[1, 1], xlabel = rich("Difference in Population (count)"; font = :bold), ylabel = rich("Count"; font = :bold),
 title = "c. Difference in Final Floodplain Population between Levee and No Levee Scenario (Baltimore)", titlesize = 18, 
  ygridvisible = false, xticks = ([-5e3, 0, 5e3, 1e4], ["-5000","0","5000","10000"]))
hidespines!(ax3, :t, :r)


Palette = ColorSchemes.okabe_ito

#Plot Change in Population from year to year after Major Flood Event
cat_high, pop_change_high = pop_response(mdf_base, adf_base_high)

cat_low, pop_change_low = pop_response(mdf_base, adf_base_low)

dodge = Int.(vcat(ones(length(cat_high)),ones(length(cat_low)) .+ 1))

CairoMakie.boxplot!(ax1, vcat(cat_high, cat_low), vcat(pop_change_high, pop_change_low), dodge = dodge, color = map(d->d==1 ? Palette[1] : Palette[2], dodge), show_outliers = false)
CairoMakie.vlines!(ax1, 9.6, color = :black, linestyle = :dash) #Flood Memory line
text!(ax1, 9.7, -40, text=rich("Flood Memory Duration", font = :italic), align = (:left, :center), fontsize = 12)

#Create Legend
elem_1 = [PolyElement(color = Palette[1])]
elem_2 = [PolyElement(color = Palette[2])]


axislegend(ax1, [elem_1, elem_2] , ["High Risk Aversion", "Low Risk Aversion"], position = :cb,
 orientation = :horizontal, framevisible = false)
#CairoMakie.lines!(ax1, collect(0:15), vec(resp_med), color = "orange", linewidth = 2.5)
#, label = false)

#airoMakie.band!(ax1, collect(0:15), resp_quantiles[1,:], resp_quantiles[2,:], color = ("orange", 0.35))

#Plot Difference in floodplain population between levee and no levee scenario (Idealized)
pop_diff_high = transpose(reshape(adf_levee_high.count_floodplain_fam, (51,1000))) .-  transpose(reshape(adf_base_high.count_floodplain_fam, (51,1000)))
pop_diff_low = transpose(reshape(adf_levee_low.count_floodplain_fam, (51,1000))) .- transpose(reshape(adf_base_low.count_floodplain_fam, (51,1000)))

CairoMakie.series!(ax2, pop_diff_high, solid_color = (Palette[1], 0.25), linewidth = 1)#, overdraw = true, transparency = true)
CairoMakie.series!(ax2, pop_diff_low, solid_color = (Palette[2], 0.25), linewidth = 1)#, overdraw = true, transparency = true)
#Create Legend
elem_1 = [LineElement(color = Palette[1], linestyle = nothing)]

elem_2 = [LineElement(color = Palette[2], linestyle = nothing)]

axislegend(ax2, [elem_1, elem_2] , ["High Risk Aversion", "Low Risk Aversion"], position = :lt, orientation = :horizontal,
 framevisible = false)


#Plot Difference in floodplain population between levee and no levee scenario (Baltimore)
balt_base_final_high = filter(row -> (row.step == 50), balt_base_high)
balt_levee_final_high = filter(row -> (row.step == 50), balt_levee_high)

balt_base_final_low = filter(row -> (row.step == 50), balt_base_low)
balt_levee_final_low = filter(row -> (row.step == 50), balt_levee_low)

balt_diff_high = balt_levee_final_high.sum_population_f_c_bgs .-  balt_base_final_high.sum_population_f_c_bgs
balt_diff_low = balt_levee_final_low.sum_population_f_c_bgs .-  balt_base_final_low.sum_population_f_c_bgs

CairoMakie.hist!(ax3, balt_diff_high, color = (Palette[1], 0.75))
CairoMakie.hist!(ax3, balt_diff_low, color = (Palette[2], 0.75), offset = 1)

#Create Legend
elem_1 = [PolyElement(color = Palette[1])]
elem_2 = [PolyElement(color = Palette[2])]


axislegend(ax3, [elem_1, elem_2] , ["High Risk Aversion", "Low Risk Aversion"], position = :lt,
 orientation = :vertical, framevisible = false)

display(fig)

CairoMakie.save(joinpath(pwd(),"figures/abm_response_final.png"), fig)



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