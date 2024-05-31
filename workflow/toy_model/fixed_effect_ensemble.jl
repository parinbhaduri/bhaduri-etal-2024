#activate project environment
using Pkg
Pkg.activate(".")
Pkg.instantiate()


#Set up parallell processors; Include necessary functions from other scripts
include(joinpath(@__DIR__, "src/parallel_setup.jl"))

seed_range = range(1000, 2000, step = 1)
flood_rps = range(10,1000, step = 10)
#Model with population growth
occ_fe_base = risk_shift(Elevation, seed_range; breach = false, fe = 0.0, parallel = true, showprogress = true)
CSV.write(joinpath(@__DIR__,"dataframes/fixed_effect_base.csv"), occ_fe_base)

occ_fe_3 = risk_shift(Elevation, seed_range; breach = false, fe = 0.03, parallel = true, showprogress = true)
CSV.write(joinpath(@__DIR__,"dataframes/fixed_effect_3.csv"), occ_fe_3)

occ_fe_5 = risk_shift(Elevation, seed_range; breach = false, fe = 0.05, parallel = true, showprogress = true)
CSV.write(joinpath(@__DIR__,"dataframes/fixed_effect_5.csv"), occ_fe_5)

occ_fe_7 = risk_shift(Elevation, seed_range; breach = false, fe = 0.07, parallel = true, showprogress = true)
CSV.write(joinpath(@__DIR__,"dataframes/fixed_effect_7.csv"), occ_fe_7)

#remove parallel processors
rmprocs(workers())