### Calculate Risk Shifting Summaries for model ensembles by manipulating parameters involved in the
    #Agent Probability Calculation. All summaries have breaching set to false. 
#activate project environment
using Pkg
Pkg.activate(".")
Pkg.instantiate()


#Set up parallell processors; Include necessary functions from other scripts
include(joinpath(@__DIR__, "src/parallel_setup.jl"))

seed_range = range(1000, 2000, step = 1)
flood_rps = range(10,1000, step = 10)

## Model with Fixed Effect Changes
occ_fe_base = risk_shift(Elevation, seed_range; breach = false, fe = 1.0, parallel = true, showprogress = true)
CSV.write(joinpath(@__DIR__,"dataframes/fixed_effect_base.csv"), occ_fe_base)

occ_fe_3 = risk_shift(Elevation, seed_range; breach = false, fe = 0.3, parallel = true, showprogress = true)
CSV.write(joinpath(@__DIR__,"dataframes/fixed_effect_3.csv"), occ_fe_3)

occ_fe_5 = risk_shift(Elevation, seed_range; breach = false, fe = 0.5, parallel = true, showprogress = true)
CSV.write(joinpath(@__DIR__,"dataframes/fixed_effect_5.csv"), occ_fe_5)

occ_fe_7 = risk_shift(Elevation, seed_range; breach = false, fe = 0.7, parallel = true, showprogress = true)
CSV.write(joinpath(@__DIR__,"dataframes/fixed_effect_7.csv"), occ_fe_7)

## Model with Risk Aversion Changes
occ_bp_low_ra_hi = risk_shift(Elevation, seed_range; breach = false, risk_averse = 0.3, prob_move = 0.01, parallel = true, showprogress = true)
CSV.write(joinpath(@__DIR__,"dataframes/bp_low_ra_hi.csv"), occ_bp_low_ra_hi)

occ_bp_low_ra_low = risk_shift(Elevation, seed_range; breach = false, risk_averse = 0.7, prob_move = 0.01, parallel = true, showprogress = true)
CSV.write(joinpath(@__DIR__,"dataframes/bp_low_ra_low.csv"), occ_bp_low_ra_low)

occ_bp_hi_ra_hi = risk_shift(Elevation, seed_range; breach = false, risk_averse = 0.3, prob_move = 0.05, parallel = true, showprogress = true)
CSV.write(joinpath(@__DIR__,"dataframes/bp_hi_ra_hi.csv"), occ_bp_hi_ra_hi)

occ_bp_hi_ra_low = risk_shift(Elevation, seed_range; breach = false, risk_averse = 0.7, prob_move = 0.05, parallel = true, showprogress = true)
CSV.write(joinpath(@__DIR__,"dataframes/bp_hi_ra_low.csv"), occ_bp_hi_ra_low)

#remove parallel processors
rmprocs(workers())