

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