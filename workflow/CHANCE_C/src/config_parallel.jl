using Distributed
addprocs(12, exeflags="--project=$(Base.active_project())")

@everywhere include("data_collect.jl")

@everywhere begin
    using CHANCE_C
    using Statistics
    using CSV, DataFrames
    using FileIO
end