### Calculate expected flood losses at the BG level in the baseline and levee scenarios 
# Determining how large the fixed effect parameter needs to be to result in risk transference
### 

#activate project environment
using Pkg
Pkg.activate(".")
Pkg.instantiate()

#Set up parallell processors; Include necessary functions from other scripts
include(joinpath(@__DIR__, "src/config_parallel.jl"))

#Define input parameters
slr = true
no_of_years = 50
house_choice_mode = "flood_mem_utility"
flood_coefficient = -10.0^5
breach_null = 0.45 
risk_averse = 0.7
flood_mem = 10 
base_move = 0.025

#For Parallel:
seed_range = range(1000, 1999, step = 1)

##Import results from benchmark damage scenario (breaching, 1% pop growth)
base_dam = DataFrame(CSV.File(joinpath(@__DIR__,"dataframes/base_event_damage.csv")))
levee_dam = DataFrame(CSV.File(joinpath(@__DIR__,"dataframes/levee_event_damage.csv")))

#Calculate Median and 95% Uncertainty Interval
diff_dam = Matrix(levee_dam) .- Matrix(base_dam) 

diff_med = vec(mapslices(x -> median(x), diff_dam, dims=2))

diff_UI = mapslices(x -> quantile(x, [0.025, 0.975]), diff_dam, dims=2)
diff_LB = diff_UI[:,1]
diff_UB = diff_UI[:,2]


## Look at alternative benchmark scenario(no breaching, no pop growth)
breach = false
perc_growth = 0.0
fixed_effect = 0.0

#Calculate breach probability for each surge event (All zero since considering overtopping only)
surge_event = collect(range(0.75,4.0, step=0.25))
breach_prob = zeros(length(surge_event))

surge_overtop = Dict(zip(surge_event,breach_prob))

base_damage, levee_damage = risk_damage(balt_ddf, surge_overtop, seed_range;slr=slr, no_of_years=no_of_years, perc_growth=perc_growth, house_choice_mode=house_choice_mode, flood_coefficient=flood_coefficient,
    breach=breach, breach_null=breach_null, risk_averse=risk_averse, flood_mem=flood_mem, fixed_effect=fixed_effect, base_move=base_move, showprogress = true)

#Save Dataframes
CSV.write(joinpath(@__DIR__,"dataframes/base_event_lowRA_no_breach_no_growth.csv"), base_damage)
CSV.write(joinpath(@__DIR__,"dataframes/levee_event_lowRA_no_breach_no_growth.csv"), levee_damage)
#remove parallel processors
rmprocs(workers())

#using StatsBase
#using Optim


using CairoMakie

#base_null = DataFrame(CSV.File(joinpath(@__DIR__,"dataframes/base_event_no_breach_no_growth.csv")))
#levee_null = DataFrame(CSV.File(joinpath(@__DIR__,"dataframes/levee_event_no_breach_no_growth.csv")))

#Calculate Median and 95% Uncertainty Interval
diff_dam_null = Matrix(levee_damage) .- Matrix(base_damage) 
    
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