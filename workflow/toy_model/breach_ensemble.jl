#activate project environment
using Pkg
Pkg.activate(".")
Pkg.instantiate()


#Set up parallell processors; Include necessary functions from other scripts
include(joinpath(@__DIR__, "src/parallel_setup.jl"))


seed_range = range(1000, 1999, step = 1)

##Run ABM breaching scenarios and save output to CSV
#Overtopping only
occ_none = risk_shift(Elevation, seed_range; breach = false, parallel = true, showprogress = true)
occ_none_RSI = risk_shift(Elevation, seed_range; breach = false, parallel = true, showprogress = true, metric = "integral")
occ_none_RSI = DataFrame(seed = seed_range, RSI = occ_none_RSI[1,:])
CSV.write(joinpath(@__DIR__,"dataframes/breach_none.csv"), occ_none)
CSV.write(joinpath(@__DIR__,"dataframes/breach_none_RSI.csv"), occ_none_RSI)

#base conditions
occ_base = risk_shift(Elevation, seed_range; breach_null = 0.4, parallel = true, showprogress = true)
occ_base_RSI = risk_shift(Elevation, seed_range; breach_null = 0.4, parallel = true, showprogress = false, metric = "integral")
occ_base_RSI = DataFrame(seed = seed_range, RSI = occ_base_RSI[1,:])
CSV.write(joinpath(@__DIR__,"dataframes/breach_base.csv"), occ_base)
CSV.write(joinpath(@__DIR__,"dataframes/breach_base_RSI.csv"), occ_base_RSI)

#base conditions, low Risk Aversion
occ_base_low = risk_shift(Elevation, seed_range; breach_null = 0.4, risk_averse = 0.7, parallel = true, showprogress = true)
occ_base_low_RSI = risk_shift(Elevation, seed_range; breach_null = 0.4, risk_averse = 0.7, parallel = true, showprogress = true, metric = "integral")
occ_base_low_RSI = DataFrame(seed = seed_range, RSI = occ_base_low_RSI[1,:])
CSV.write(joinpath(@__DIR__,"dataframes/breach_base_RA_low.csv"), occ_base_low)
CSV.write(joinpath(@__DIR__,"dataframes/breach_base_low__RSI.csv"), occ_base_low_RSI)

#high likelihood of breaching
occ_high = risk_shift(Elevation, seed_range; breach_null = 0.5, parallel = true, showprogress = true)
occ_high_RSI = risk_shift(Elevation, seed_range; breach_null = 0.5, parallel = true, showprogress = true, metric = "integral")
occ_high_RSI = DataFrame(seed = seed_range, RSI = occ_high_RSI[1,:])
CSV.write(joinpath(@__DIR__,"dataframes/breach_high.csv"), occ_high)
CSV.write(joinpath(@__DIR__,"dataframes/breach_high_RSI.csv"), occ_high_RSI)





#remove parallel processors
rmprocs(workers())