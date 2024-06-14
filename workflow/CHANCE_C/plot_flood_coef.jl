### Check to see sensitivity of flood coefficient value on model outcomes ###
import Pkg
Pkg.activate(".")
Pkg.instantiate()

using CHANCE_C
using CSV, DataFrames
using Plots
using Printf

## Load input Data and Functions
include(joinpath(@__DIR__, "src/config.jl"))
include(joinpath(@__DIR__,"src/data_collect.jl"))



#Define input parameters
slr = true
no_of_years = 50
perc_growth = 0.01
house_choice_mode = "flood_mem_utility"
breach = true
breach_null = 0.45 
risk_averse = 0.3
flood_mem = 10
fixed_effect = 0.0 
base_move = 0.025
disamenity_coef = [0.0 -10.0^3 -10.0^5 -10.0^7]

disamenity_abms = [BaltSim(;slr=slr, no_of_years=no_of_years, perc_growth=perc_growth, house_choice_mode=house_choice_mode, flood_coefficient=i, levee=false,
breach=breach, breach_null=breach_null, risk_averse=risk_averse, flood_mem=flood_mem, fixed_effect=fixed_effect, base_move=base_move, seed=1897) for i in disamenity_coef]

adata = [(:population, sum, f_c_bgs), (:pop90, sum, f_c_bgs), (:population, sum, nf_c_bgs), (:pop90, sum, nf_c_bgs)]
mdata = [flood_scenario, flood_record]

        
adf_dis, mdf_dis = ensemblerun!(disamenity_abms, dummystep, model_step!, no_of_years; adata, mdata)
flood_pop_change = 100 .* (adf_dis.sum_population_f_c_bgs .- adf_dis.sum_pop90_f_c_bgs) ./ adf_dis.sum_pop90_f_c_bgs
nf_pop_change = 100 .* (adf_dis.sum_population_nf_c_bgs .- adf_dis.sum_pop90_nf_c_bgs) ./ adf_dis.sum_pop90_nf_c_bgs
#Plot results
#Plot results
#surge level
"""
surge_base = Plots.plot(mdf_dis.step[2:51], mdf_dis.flood_record[2:51], linecolor = :black, lw = 4)

Plots.title!("Disamenity Coeff. at Baseline, RA = 0.3")
"""

#Pop Change
#disam_col = cgrad(:blues, 7, categorical = true)
pop_disam = Plots.plot(adf_dis.step, flood_pop_change, group = adf_dis.ensemble, ls = :solid,
  label = [@sprintf("%.1E", coef) for coef in disamenity_coef], legend = :outerbottom, legendcolumns = 2, lw = 2.5)

#Plots.plot!(adf_dis.step, flood_pop_change, group = adf_dis.ensemble, 
#linecolor = [disam_col[1] disam_col[2] disam_col[3] disam_col[4] disam_col[5] disam_col[6] disam_col[7]], ls = :dash,
# label = false, lw = 2.5)

Plots.ylims!(-50,50)
Plots.xlabel!("Model Year")
Plots.ylabel!("% Change in Population")
Plots.title!("Floodplain Population by Disamenity Coefficient")

#create subplot
#disam_results = Plots.plot(surge_base, pop_disam, layout = (2,1), dpi = 300, size = (500,600))

        
savefig(pop_disam, joinpath(pwd(),"figures/disamen_coef.png"))