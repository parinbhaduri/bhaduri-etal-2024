
using Distributed
addprocs(4, exeflags="--project=$(Base.active_project())")

include("damage_realizations.jl")
import GlobalSensitivityAnalysis as GSA
using DataStructures


@everywhere include("damage_realizations.jl")
@everywhere begin
    import GlobalSensitivityAnalysis as GSA
    using DataStructures
    using SharedArrays
end

#Set seed range
seed_range = range(1000, 1999, step = 1)

#create function to run model using samples
function flood_scan(param_values::AbstractArray{<:Number, N}) where N

    numruns = size(param_values, 1)
    Y = zeros(numruns, 1)

    progress = Agents.ProgressMeter.Progress(numruns; enabled = true)
    Y[1,1] = mean(risk_shift(Elevation, seed_range; risk_averse = param_values[1,1], levee = 1/100, breach = true, 
    pop_growth = param_values[1,3], breach_null = param_values[1,2], N = 1200, parallel = true, showprogress = false, metric = "integral"))

    Agents.ProgressMeter.next!(progress)

    Agents.ProgressMeter.progress_map(2:numruns; progress) do i
        Y[i,1] = mean(risk_shift(Elevation, seed_range; risk_averse = param_values[i,1], levee = 1/100, breach = true, 
    pop_growth = param_values[i,3], breach_null = param_values[i,2], N = 1200, parallel = true, showprogress = false, metric = "integral"))
    end

    return Y
end


#define data
data = GSA.SobolData(
    params = OrderedDict(:risk_averse => Uniform(0,1), :breach_null => Uniform(0.3,0.5), :pop_growth => Uniform(0,0.05)),
    N = 50,
)

samples = GSA.sample(data)

#run model
Y = flood_scan(samples)

#analyze model
GSA.analyze(data, Y)

#Plot results
