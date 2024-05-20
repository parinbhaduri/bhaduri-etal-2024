#activate project environment
using Pkg
Pkg.activate(".")
Pkg.instantiate()


#Set up parallell processors; Include necessary functions from other scripts
include(joinpath(@__DIR__, "src/parallel_setup.jl"))

seed_range = range(1000, 2000, step = 1)
flood_rps = range(10,1000, step = 10)
#Model with population growth
occ_pop_05 = risk_shift(Elevation, seed_range; pop_growth = 0.005, parallel = true, showprogress = true)
CSV.write(joinpath(@__DIR__,"dataframes/pop_growth_05.csv"), occ_pop_05)

occ_pop_1 = risk_shift(Elevation, seed_range; pop_growth = 0.01, parallel = true, showprogress = true)
CSV.write(joinpath(@__DIR__,"dataframes/pop_growth_1.csv"), occ_pop_1)

occ_pop_2 = risk_shift(Elevation, seed_range; pop_growth = 0.02, parallel = true, showprogress = true)
CSV.write(joinpath(@__DIR__,"dataframes/pop_growth_2.csv"), occ_pop_2)

occ_pop_5 = risk_shift(Elevation, seed_range; pop_growth = 0.05, parallel = true, showprogress = true)
CSV.write(joinpath(@__DIR__,"dataframes/pop_growth_5.csv"), occ_pop_5)

#remove parallel processors
rmprocs(workers())