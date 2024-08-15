#analyze sensitivity analysis results
#activate project environment
using Pkg
Pkg.activate(".")
Pkg.instantiate()

import GlobalSensitivityAnalysis as GSA
using DataStructures
using FileIO
using DataFrames, CSV
using Plots

#read in results
sa_df = DataFrame(CSV.File(joinpath(@__DIR__,"SA_Results/factor_map_table_100.csv")))
#sa_dict = CSV.File("workflow/SA Results/sobol_results.csv") |> Dict

##Plot analysis results
sobol_results = load(joinpath(@__DIR__,"SA_Results/sobol_results_50.jld2"))
sa_plot = bar(names(sa_df)[1:end-1], sobol_results["firstorder"], fillcolor = colorant"#005F73", label = false, dpi = 300)
Plots.ylabel!("First-Order Sensitivity Index")
#bar!(names(sa_df)[1:end-1], sobol_results["totalorder"])

savefig(sa_plot, joinpath(pwd(),"figures/first_order_100.png"))

#For second order interactions
second_prder_mat = Plots.heatmap(sobol_results["secondorder_conf"], xticks=(1:6, names(sa_df)[1:end-1]), yticks=(1:6, names(sa_df)[1:end-1]), c = cgrad(:berlin))
nrow,ncol = size(sobol_results["secondorder"])
ann = [(j, i, Plots.text(round(sobol_results["secondorder"][i, j], digits=3), 8, :white, :center)) for i in 1:nrow for j in 1:ncol]
annotate!(ann, linecolor=:white)

#"secondorder" = second order interactions among parameters
#"secondorder_conf" = confidence levels of those second order interactions
savefig(second_order_mat, joinpath(pwd(),"figures/first_order_100.png"))