### Conduct Method Of Morris SA on toy model ###
#File for running sensitivity analysis on Cluster 

using Distributed

num_cores = parse(Int,ENV["SLURM_TASKS_PER_NODE"])
addprocs(num_cores)

# instantiate and precompile environment
@everywhere begin
  using Pkg;Pkg.activate(@__DIR__); 
  Pkg.instantiate(); Pkg.precompile()
end

#For parallel
@everywhere include(joinpath(@__DIR__,"workflow/toy_model/src/toy_ABM_functions.jl"))
@everywhere include(joinpath(@__DIR__,"workflow/toy_model/src/damage_realizations.jl"))
@everywhere begin
    using GlobalSensitivity
    using DataStructures
    using Distributions
    using SharedArrays
    using DataFrames
    using CSV
    using FileIO
    using Random
end

"""
#activate project environment
using Pkg
Pkg.activate(".")
Pkg.instantiate()

#Set up parallell processors; Include necessary functions from other scripts
include(joinpath(@__DIR__, "src/parallel_setup.jl"))
"""
#Set a random seed
Random.seed!(1)

seed_range = range(1000, 1999, step = 1)

#create function to run model using samples
function exp_shift(param_values::Vector)

  Y = mean(risk_shift(Elevation, seed_range; risk_averse = param_values[1], levee = 1/100, breach = true, 
      pop_growth = param_values[3], breach_null = param_values[2], N = 1200, mem = Int(round(param_values[4])), fe = param_values[5],
      prob_move = param_values[6], parallel = true, showprogress = false, metric = "integral")
  )
  
  return Y
end

#create variable of vector bounds
var_vec = [(0,1),(0.25,0.5),(0,0.05),(3,15),(0,0.1),(0.01,0.05)]
#Run Method of Morris
s = gsa(exp_shift, Morris(num_trajectory=100), var_vec)

#Get mean and variance of EE 
param_avg = abs.(s.means)
param_var = s.variances

#Save To DataFrame
using DataFrames, CSV

MoM_results = DataFrame(params=["Risk Averse", "Breach Likelihood", "Pop. Growth", "Flood Memory", "Expectation Effect", "Base Move Prob."],
          exp_mean = param_avg[1,:],
          exp_var = param_var[1,:]
)

CSV.write(joinpath(@__DIR__, "SA_Results/MoM_results_ideal_100.csv"), MoM_results)
