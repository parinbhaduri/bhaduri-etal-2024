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

##read in results
#Sobol Sensitivity
sa_df = DataFrame(CSV.File(joinpath(dirname(@__DIR__),"workflow/toy_model/SA_Results/factor_map_table_100.csv")))
#sa_dict = CSV.File("workflow/SA Results/sobol_results.csv") |> Dict
sobol_results = FileIO.load(joinpath(dirname(@__DIR__),"workflow/toy_model/SA_Results/sobol_results_100.jld2"))

#Scenario Discovery
factor_import = DataFrame(CSV.File(joinpath(dirname(@__DIR__),"workflow/CHANCE_C/dataframes/SD_feature_importance.csv")))

##Plot analysis results
fig = Figure(size = (3600,1080), fontsize = 16, pt_per_unit = 1, figure_padding = 20)

#ax1 = Axis(fig[1,1:2], xticks = (1:6, ["Risk Averse", "Breach Likelihood", "Pop. Growth", "Flood Memory", "Expectation Effect", "Base Move Prob."]),                
#        xticklabelrotation = pi/4, ylabel = rich("First-Order\n Sensitivity Index"; font = :bold), title = "a. Idealized Experiment", titlealign = :left, titlesize = 18,
#         limits = (nothing, (0,0.8)), xgridvisible = false)
#hidespines!(ax1,:t, :r)

ax1 = Axis(fig[1,1], xticks = (1:6, ["Risk Averse", "Pop. Growth", "Expectation Effect", "SLR", "Breach", "Flood Memory"]), 
        xticklabelrotation = pi/4, ylabel = rich("Feature Importance"; font = :bold), #title = "b. Baltimore Experiment", titlealign = :left, titlesize = 18,
         limits = (nothing, (0,0.8)), xgridvisible = false)
hidespines!(ax1,:t, :r)


#CairoMakie.barplot!(ax1, sobol_results["firstorder"], color = colorant"#005F73")
CairoMakie.barplot!(ax1, factor_import.value, color =colorant"#52A3B8")#, direction = :x)
display(fig)

CairoMakie.save(joinpath(pwd(),"figures/scen_disc_balt.png"), fig)











##Plot MoM results
mom_df = DataFrame(CSV.File(joinpath(dirname(@__DIR__),"workflow/toy_model/SA_Results/MoM_results_ideal_100_norm.csv")))
#mom_df_norm = DataFrame(CSV.File(joinpath(dirname(@__DIR__),"workflow/toy_model/SA_Results/MoM_results_ideal_100.csv")))
mom_df_balt = DataFrame(CSV.File(joinpath(dirname(@__DIR__),"workflow/CHANCE_C/SA_Results/MoM_results_balt_100_norm.csv")))

sqrt.(mom_df[!,"exp_var"])
sqrt.(mom_df_balt[!,"exp_var"])

fig = Figure(size = (3600,1080), fontsize = 16, pt_per_unit = 1, figure_padding = 20)

ax1 = Axis(fig[1,1:2], xticks = (1:6, mom_df[!,"params"]),                
        xticklabelrotation = pi/4, ylabel = rich("Mean of\n Elementary Effects"; font = :bold), title = "a. Idealized Experiment", titlealign = :left, titlesize = 18,
         limits = (nothing, nothing), xgridvisible = false) #(0,0.8)
hidespines!(ax1,:t, :r)

ax2 = Axis(fig[2,1:2], xticks = (1:6, mom_df[!,"params"]), 
        xticklabelrotation = pi/4, ylabel = rich("Variance of\n Elementary Effects"; font = :bold), title = "b. Idealized Experiment", titlealign = :left, titlesize = 18,
         limits = (nothing, nothing), xgridvisible = false)
hidespines!(ax2,:t, :r)


CairoMakie.barplot!(ax1, mom_df[!,"exp_mean"], color = colorant"#005F73")
CairoMakie.barplot!(ax2, mom_df[!,"exp_var"], color =colorant"#E0BB00")#, direction = :x)

display(fig)



fig = Figure(size = (3600,1080), fontsize = 16, pt_per_unit = 1, figure_padding = 20)

ax1 = Axis(fig[1,1:2], xticks = (1:6, mom_df_balt[!,"params"]),                
        xticklabelrotation = pi/4, ylabel = rich("Mean of\n Elementary Effects"; font = :bold), title = "a. Baltimore Experiment", titlealign = :left, titlesize = 18,
         limits = (nothing, nothing), xgridvisible = false) #(0,0.8)
hidespines!(ax1,:t, :r)

ax2 = Axis(fig[2,1:2], xticks = (1:6, mom_df_balt[!,"params"]), 
        xticklabelrotation = pi/4, ylabel = rich("Variance of\n Elementary Effects"; font = :bold), title = "b. Baltimore Experiment", titlealign = :left, titlesize = 18,
         limits = (nothing, nothing), xgridvisible = false)
hidespines!(ax2,:t, :r)


CairoMakie.barplot!(ax1, mom_df_balt[!,"exp_mean"], color = colorant"#52A3B8")
CairoMakie.barplot!(ax2, mom_df_balt[!,"exp_var"], color =colorant"#FFE669")#, direction = :x)

display(fig)

CairoMakie.save(joinpath(pwd(),"figures/SA_visualize.png"), fig)






"""
#For second order interactions
second_order_mat = Plots.heatmap(sobol_results["secondorder_conf"], xticks=(1:6, names(sa_df)[1:end-1]), yticks=(1:6, names(sa_df)[1:end-1]), c = cgrad(:berlin))
nrow,ncol = size(sobol_results["secondorder"])
ann = [(j, i, Plots.text(round(sobol_results["secondorder"][i, j], digits=3), 8, :white, :center)) for i in 1:nrow for j in 1:ncol]
annotate!(ann, linecolor=:white)

#"secondorder" = second order interactions among parameters
#"secondorder_conf" = confidence levels of those second order interactions
savefig(second_order_mat, joinpath(pwd(),"figures/second_order_100.png"))
"""