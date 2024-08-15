#activate project environment
using Pkg
Pkg.activate(".")
Pkg.instantiate()

using CSV, DataFrames
using CairoMakie
using ColorSchemes

#import GEV functions from toy model
include(joinpath(@__DIR__, "src/toy_ABM_functions.jl")) #for GEV_return function

#Read in ABM ensemble evolution data
adf_base = DataFrame(CSV.File(joinpath(@__DIR__,"dataframes/adf_base.csv")))
#Separate high RA and low RA
adf_base_high = filter(:risk_averse => isequal(0.3), adf_base)
adf_base_low = filter(:risk_averse => isequal(0.7), adf_base)

adf_levee = DataFrame(CSV.File(joinpath(@__DIR__,"dataframes/adf_levee.csv")))
#Separate high RA and low RA
adf_levee_high = filter(:risk_averse => isequal(0.3), adf_levee)
adf_levee_low = filter(:risk_averse => isequal(0.7), adf_levee)

flood_100 = [GEV_return(1/100) for _ in 1:51]

mdf_base = DataFrame(CSV.File(joinpath(@__DIR__,"dataframes/mdf_base.csv")))
mdf_base = subset(mdf_base, :risk_averse => ByRow(isequal(0.3))) #Just grab one flood record ensemble

mdf_levee = DataFrame(CSV.File(joinpath(@__DIR__,"dataframes/mdf_levee.csv")))
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
fig = Figure(size = (1000, 1000))
ga = fig[1, 1:2] = GridLayout()
gb = fig[2, 1:2] = GridLayout()

ax1 = Axis(ga[1, 1], ylabel = "Change in Population (count)", xlabel = "Time Since Major Flood (years)", title = "a. Floodplain Population Response after Major Flood Event in No Levee Scenario",
limits = ((0,13), nothing), xgridvisible = false)
hidespines!(ax1, :t, :r)

ax2 = Axis(gb[1, 1], ylabel = "Difference in Population (count)", xlabel = "Model Timestep (year)", title = "b. Difference in Floodplain Population between Levee and No Levee Scenario", 
limits = ((0,50), (nothing, 400)), xgridvisible = false)
hidespines!(ax2, :t, :r)


palette = ColorSchemes.okabe_ito

#Plot Change in Population from year to year after Major Flood Event
cat_high, pop_change_high = pop_response(mdf_base, adf_base_high)

cat_low, pop_change_low = pop_response(mdf_base, adf_base_low)

dodge = Int.(vcat(ones(length(cat_high)),ones(length(cat_low)) .+ 1))

CairoMakie.boxplot!(ax1, vcat(cat_high, cat_low), vcat(pop_change_high, pop_change_low), dodge = dodge, color = map(d->d==1 ? palette[1] : palette[2], dodge), show_outliers = false)

#Create Legend
elem_1 = [PolyElement(color = palette[1])]

elem_2 = [PolyElement(color = palette[2])]

axislegend(ax1, [elem_1, elem_2] , ["High Risk Aversion", "Low Risk Aversion"], position = :rb, orientation = :horizontal, framevisible = false)
#CairoMakie.lines!(ax1, collect(0:15), vec(resp_med), color = "orange", linewidth = 2.5)
#, label = false)

#airoMakie.band!(ax1, collect(0:15), resp_quantiles[1,:], resp_quantiles[2,:], color = ("orange", 0.35))

#Plot Difference in floodplain population between levee and no levee scenario
pop_diff_high = transpose(reshape(adf_levee_high.count_floodplain_fam, (51,1000))) .-  transpose(reshape(adf_base_high.count_floodplain_fam, (51,1000)))
pop_diff_low = transpose(reshape(adf_levee_low.count_floodplain_fam, (51,1000))) .- transpose(reshape(adf_base_low.count_floodplain_fam, (51,1000)))

CairoMakie.series!(ax2, pop_diff_high, solid_color = (palette[1], 0.25), linewidth = 1, overdraw = true, transparency = true)
CairoMakie.series!(ax2, pop_diff_low, solid_color = (palette[2], 0.25), linewidth = 1, overdraw = true, transparency = true)
#Create Legend
elem_1 = [LineElement(color = palette[1], linestyle = nothing)]

elem_2 = [LineElement(color = palette[2], linestyle = nothing)]

axislegend(ax2, [elem_1, elem_2] , ["High Risk Aversion", "Low Risk Aversion"], position = :lt, orientation = :horizontal, framevisible = false)

display(fig)

CairoMakie.save(joinpath(pwd(),"figures/abm_evolution.png"), fig)