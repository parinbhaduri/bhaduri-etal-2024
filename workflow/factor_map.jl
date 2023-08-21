
#using Distributed
#addprocs(4)

include("damage_realizations.jl")
import GlobalSensitivityAnalysis as GSA
using DataStructures

"""
@everywhere include("damage_realizations.jl")
@everywhere begin
    import GlobalSensitivityAnalysis as GSA
    using DataStructures
end
"""


#create function to run model using samples
function flood_scan(param_values::AbstractArray{<:Number, N}) where N

    numruns = size(param_values, 1)
    Y = zeros(numruns, 1)

    
    models = [flood_ABM(;Elev = Elevation, risk_averse = param_values[i,1], N = 1200, pop_growth = 0, seed = 1897) for i in 1:numruns]
    models_levee = [flood_ABM(;Elev = Elevation, risk_averse = param_values[i,1], levee = 1/100, breach = true, N = 1200, pop_growth = 0, seed = 1897) for i in 1:numruns]
    #Run models
    _ = ensemblerun!([models models_levee], dummystep, combine_step!, 50; showprogress = true)

    flood_rps = range(10,1000, step = 10)

    for i in 1:numruns
        #Calculate depth difference for each model in category
        occupied = depth_difference(models[i], flood_rps)
        occupied_levee = depth_difference(models_levee[i], flood_rps; breach_null = param_values[i,2])

        #Calculate as percent increase
        occ_perc = (occupied_levee - occupied) ./ occupied
        #sum the columns to return the integral. Essentially returns a weighted average exposure increase
        Y[i] = sum(occ_perc ./ collect(flood_rps)) 
    end
    #Convert any NaN values to 0 
    Y = replace(Y, NaN => 0)
    return Y
end


#define data
data = SobolData(
    params = OrderedDict(:risk_averse => Uniform(0,1), :breach_null => Uniform(0.3,0.5),)
)

samples = GSA.sample(data)

#run model
Y = flood_scan(samples)

#analyze model
analyze(data, Y)

#Plot results

















model = flood_ABM(;Elev = Elevation, risk_averse = 0.3, N = 1200, pop_growth = 0, seed = 1897)
model_levee = flood_ABM(;Elev = Elevation, risk_averse = 0.3, levee = 1/100, breach = true, N = 1200, pop_growth = 0, seed = 1897)

occupied = depth_difference(model, flood_rps)
occupied_levee = depth_difference(model_levee, flood_rps; breach_null = 0.45)

#Calculate as percent increase
occ_perc = (occupied_levee - occupied) ./ occupied
#sum the columns to return the integral. Essentially returns a weighted average exposure increase
sum(occ_perc ./ collect(flood_rps)) 













### code taken from paramscan function in Agents.jl

##Necessary Functions

# This function is taken from DrWatson:
function dict_list(c::Dict)
    iterable_fields = filter(k -> typeof(c[k]) <: Vector, keys(c))
    non_iterables = setdiff(keys(c), iterable_fields)

    iterable_dict = Dict(iterable_fields .=> getindex.(Ref(c), iterable_fields))
    non_iterable_dict = Dict(non_iterables .=> getindex.(Ref(c), non_iterables))

    vec(map(Iterators.product(values(iterable_dict)...)) do vals
        dd = Dict(keys(iterable_dict) .=> vals)
        if isempty(non_iterable_dict)
            dd
        elseif isempty(iterable_dict)
            non_iterable_dict
        else
            merge(non_iterable_dict, dd)
        end
    end)
end

##Create dictionary of model parameters with lower and upper bounds
parameters = Dict()
output_params = [k for (k, v) in parameters if typeof(v) <: Vector]

combs = dict_list(parameters)

    progress = ProgressMeter.Progress(length(combs); enabled = true)
    mapfun = parallel ? pmap : map
    all_data = ProgressMeter.progress_map(combs; mapfun, progress) do comb
        ##add function to perform on each model combination
        run_single(comb, output_params, initialize;
                   agent_step!, model_step!, n, kwargs...)
    end



test = ones(100, 1000)
test_levee = copy(test) * 2

sum((test_levee ./ test) ./ collect(flood_rps), dims = 1)
sum(test_levee ./ (test .* collect(flood_rps)), dims = 1) 

