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
using CairoMakie

#read in results
sa_df = DataFrame(CSV.File(joinpath(@__DIR__,"SA_Results/factor_map_table_100.csv")))
#sa_dict = CSV.File("workflow/SA Results/sobol_results.csv") |> Dict

##Plot analysis results
sobol_results = FileIO.load(joinpath(@__DIR__,"SA_Results/sobol_results_100.jld2"))

fig = Figure(size = (1800,1080), fontsize = 22, pt_per_unit = 1, figure_padding = 20)

ax = Axis(fig[1,1], xticks = (1:6, ["Risk Averse", "Breach Likelihood", "Pop. Growth", "Flood Memory", "Expectation Effect", "Base Move Prob."]),                
        xticklabelrotation = pi/4, ylabel = "First-Order Sensitivity Index", limits = (nothing, (0,0.8)), xgridvisible = false)
hidespines!(ax,:t, :r)

CairoMakie.barplot!(ax, sobol_results["firstorder"], color = colorant"#005F73")
display(fig)

CairoMakie.save(joinpath(pwd(),"figures/first_order_100.png"), fig)

#For second order interactions
second_order_mat = Plots.heatmap(sobol_results["secondorder_conf"], xticks=(1:6, names(sa_df)[1:end-1]), yticks=(1:6, names(sa_df)[1:end-1]), c = cgrad(:berlin))
nrow,ncol = size(sobol_results["secondorder"])
ann = [(j, i, Plots.text(round(sobol_results["secondorder"][i, j], digits=3), 8, :white, :center)) for i in 1:nrow for j in 1:ncol]
annotate!(ann, linecolor=:white)

#"secondorder" = second order interactions among parameters
#"secondorder_conf" = confidence levels of those second order interactions
savefig(second_order_mat, joinpath(pwd(),"figures/second_order_100.png"))