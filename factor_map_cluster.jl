
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
@everywhere include(joinpath(@__DIR__,"workflow/damage_realizations.jl"))
@everywhere begin
    import GlobalSensitivityAnalysis as GSA
    using DataStructures
    using SharedArrays
    using CSV
    using FileIO
end


#Set seed range
seed_range = range(1000, 1999, step = 1)

#Set return period for Levee height
l_H = 1/100

#create function to run model using samples
function flood_scan(param_values::AbstractArray{<:Number, N}, levee_rp::Float64) where N

    numruns = size(param_values, 1)
    Y = zeros(numruns, 1)

    progress = Agents.ProgressMeter.Progress(numruns; enabled = true)
    Y[1,1] = mean(risk_shift(Elevation, seed_range; risk_averse = param_values[1,1], levee = levee_rp, breach = true, 
    pop_growth = param_values[1,3], breach_null = param_values[1,2], N = 1200, mem = Int(param_values[1,4]), fe = param_values[1,5], prob_move = param_values[1,6], parallel = true, showprogress = false, metric = "integral"))

    Agents.ProgressMeter.next!(progress)

    Agents.ProgressMeter.progress_map(2:numruns; progress) do i
        Y[i,1] = mean(risk_shift(Elevation, seed_range; risk_averse = param_values[i,1], levee = levee_rp, breach = true, 
    pop_growth = param_values[i,3], breach_null = param_values[i,2], N = 1200, mem = Int(param_values[i,4]), fe = param_values[i,5], prob_move = param_values[i,6], parallel = true, showprogress = false, metric = "integral"))
    end

    return Y
end


#define data
data = GSA.SobolData(
    params = OrderedDict(:risk_averse => Uniform(0,1), :breach_null => Uniform(0.3,0.5), :pop_growth => Uniform(0,0.05),
    :mem => Categorical([(1/12) for _ in 1:12]), :fixed_effect => Uniform(0.0,0.08), :base_move => Uniform(0.01,0.05),),
    N = 1000,
)

samples = GSA.sample(data)

#For flood memory
samples[:,5] .+= 3.0

#run model
Y = flood_scan(samples, l_H)

## Save results
#Create Dataframe to store values

params = data.params.keys
push!(params, :RSI)

factor_samples = DataFrame(hcat(samples,Y), params)
CSV.write(joinpath(@__DIR__, "workflow/SA Results/factor_map_table_100.csv"), factor_samples)

#Analyze model results
#analyze
sobol_results = GSA.analyze(data, Y)
#save dictionary
save(joinpath(@__DIR__, "workflow/SA Results/sobol_results_100.jld2"), sobol_results)
#CSV.write("workflow/SA Results/sobol_results.csv", sobol_results)



