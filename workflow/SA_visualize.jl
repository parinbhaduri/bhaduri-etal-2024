#analyze sensitivity analysis results
import GlobalSensitivityAnalysis as GSA
using DataStructures
using FileIO
using DataFrames, CSV

#read in results
sa_df = DataFrame(CSV.File("workflow/SA_Results/factor_map_table_100.csv"))
#sa_dict = CSV.File("workflow/SA Results/sobol_results.csv") |> Dict

## Plot results
#factor_samples[!, :state] = ifelse.(factor_samples.RSI .<=1, "improve", "worsen")


Plots.scatter(factor_samples.risk_averse, factor_samples.breach_null, group = factor_samples.state)
Plots.xlabel!("risk averse")
Plots.ylabel!("Breach null")


##Plot analysis results
using Plots

sobol_results = load(joinpath(@__DIR__,"SA_Results/sobol_results_50.jld2"))
sa_plot = bar(names(sa_df)[1:end-1], sobol_results["firstorder"], fillcolor = colorant"#005F73", label = false)
Plots.ylabel!("First-Order Sensitivity Index")
#bar!(names(sa_df)[1:end-1], sobol_results["totalorder"])

savefig(sa_plot, joinpath(@__DIR__,"SA_Results/figures/first_order_50.svg"))

#For second order interactions
heatmap(sobol_results["secondorder_conf"], xticks=(1:6, names(sa_df)[1:end-1]), yticks=(1:6, names(sa_df)[1:end-1]), c = cgrad(:vik, rev = true))
nrow,ncol = size(sobol_results["secondorder_conf"])
ann = [(j, i, text(round(sobol_results["secondorder_conf"][i, j], digits=3), 8, :white, :center)) for i in 1:nrow for j in 1:ncol]
annotate!(ann, linecolor=:white)

#"secondorder" = second order interactions among parameters
#"secondorder_conf" = confidence levels of those second order interactions