using Distributed
addprocs(12, exeflags="--project=$(Base.active_project())")

@everywhere include("toy_ABM_functions.jl")
@everywhere include("damage_realizations.jl")

@everywhere begin
    import GlobalSensitivityAnalysis as GSA
    using DataStructures
    using SharedArrays
    using CSV
    using FileIO
end

#config file for paralellization properties. File read in for workflow scripts