#activate project environment
using Pkg
Pkg.activate(pwd())
Pkg.instantiate()


#Set up parallell processors; Include necessary functions from other scripts
include(joinpath(@__DIR__, "src/parallel_setup.jl"))


seed_range = range(1000, 2000, step = 1)
flood_rps = range(10,1000, step = 10)

##Run ABM breaching scenarios and save output to CSV
#Overtopping only
occ_none = risk_shift(Elevation, seed_range; breach = false, parallel = true, showprogress = true)
CSV.write(joinpath(@__DIR__,"dataframes/breach_none.csv"), occ_none)

#base conditions
occ_base = risk_shift(Elevation, seed_range; breach_null = 0.3, parallel = true, showprogress = true)
CSV.write(joinpath(@__DIR__,"dataframes/breach_base.csv"), occ_base)

#high likelihood of breaching
occ_high = risk_shift(Elevation, seed_range; breach_null = 0.5, parallel = true, showprogress = true)
CSV.write(joinpath(@__DIR__,"dataframes/breach_high.csv"), occ_high)

#remove parallel processors
rmprocs(workers())