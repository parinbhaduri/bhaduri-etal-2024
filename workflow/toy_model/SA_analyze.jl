#activate project environment
using Pkg
Pkg.activate(".")
Pkg.instantiate()

import GlobalSensitivityAnalysis as GSA
using DataStructures
using Distributions
using DataFrames, CSV

## Calculate sobol indices from results in factor_map_cluster.jl
#Set return period for Levee height
l_H = 1/100

#define data
data = GSA.SobolData(
    params = OrderedDict(:risk_averse => Uniform(0,1), :breach_null => Uniform(0.3,0.5), :pop_growth => Uniform(0,0.05),
    :mem => Categorical([(1/12) for _ in 1:12]), :fixed_effect => Uniform(0.0,0.08), :base_move => Uniform(0.01,0.05),),
    N = 1000,
    
)

#load outcomes from csv file 
sa_df = DataFrame(CSV.File(joinpath(@__DIR__,"SA_Results/factor_map_table_100.csv")))

#analyze
sobol_results = GSA.analyze(data, sa_df.RSI)
#save dictionary
using FileIO
save(joinpath(@__DIR__,"SA_Results/sobol_results_100.jld2"), sobol_results)




