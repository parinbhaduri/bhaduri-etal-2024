
include("damage_realizations.jl")
import GlobalSensitivityAnalysis as GSA
using DataStructures
using CSV

#For parallel
include("parallel_setup.jl")

#Set seed range
seed_range = range(1000, 1999, step = 1)

#create function to run model using samples
function flood_scan(param_values::AbstractArray{<:Number, N}) where N

    numruns = size(param_values, 1)
    Y = zeros(numruns, 1)

    progress = Agents.ProgressMeter.Progress(numruns; enabled = true)
    Y[1,1] = mean(risk_shift(Elevation, seed_range; risk_averse = param_values[1,1], levee = param_values[1,4], breach = Bool(param_values[1,8]), 
    pop_growth = param_values[1,3], breach_null = param_values[1,2], N = 1200, mem = Int(param_values[1,5]), fe = param_values[1,6], prob_move = param_values[1,7], parallel = true, showprogress = false, metric = "integral"))

    Agents.ProgressMeter.next!(progress)

    Agents.ProgressMeter.progress_map(2:numruns; progress) do i
        Y[i,1] = mean(risk_shift(Elevation, seed_range; risk_averse = param_values[i,1], levee = param_values[i,4], breach = Bool(param_values[i,8]), 
    pop_growth = param_values[i,3], breach_null = param_values[i,2], N = 1200, mem = Int(param_values[i,5]), fe = param_values[i,6], prob_move = param_values[i,7], parallel = true, showprogress = false, metric = "integral"))
    end

    return Y
end


#define data
data = GSA.SobolData(
    params = OrderedDict(:risk_averse => Uniform(0,1), :breach_null => Uniform(0.3,0.5), :pop_growth => Uniform(0,0.05), :levee => Categorical([(1/3) for _ in 1:3]),
    :mem => Categorical([(1/12) for _ in 1:12]), :fixed_effect => Uniform(0.0,0.08), :base_move => Uniform(0.01,0.05), :breach => Binomial(1, 0.5),),

    
)

samples = GSA.sample(data)
#For Levee
samples[:,4] = replace(samples[:,4], 1.0 => 1/50, 2.0 => 1/100, 3.0 => 1/500)
#For flood memory
samples[:,5] .+= 3.0

#run model
Y = flood_scan(samples)
## Save results
#Create Dataframe to store values

params = data.params.keys
push!(params, :RSI)

factor_samples = DataFrame(hcat(samples,Y), params)
CSV.write
#analyze model
GSA.analyze(data, Y)

## Plot results
#Create Dataframe to store values
params = data.params.keys
push!(params, :RSI)

factor_samples = DataFrame(hcat(samples,Y), params)

factor_samples[!, :state] = ifelse.(factor_samples.RSI .<=1, "improve", "worsen")


Plots.scatter(factor_samples.risk_averse, factor_samples.breach_null, group = factor_samples.state)
Plots.xlabel!("risk averse")
Plots.ylabel!("Breach null")
