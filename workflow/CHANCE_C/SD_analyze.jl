#Analysis for Scenario Discovery
#activate project environment
using Pkg
Pkg.activate(".")
Pkg.instantiate()

using MLJ
using DataStructures
using Distributions
using DataFrames, CSV
using FileIO


#Read in Model Runs
data = DataFrame(CSV.File(joinpath(@__DIR__,"SA_Results/scen_disc_table.csv")))
##Convert each Categorical Column into OrderedFactor SciType
data_reg = coerce(data, :breach => OrderedFactor,
                        :mem => OrderedFactor,
                        :slr => OrderedFactor)


DecisionTreeRegressor = @load DecisionTreeRegressor pkg=DecisionTree
model = DecisionTreeRegressor(max_depth=3)

#labels = [i > 0 ? 1 : -1 for i in data_new[:,:RSI]]
lab_reg = data_reg[:,:RSI]
features = select(data_reg, Not(:RSI))

mach_reg = machine(model, features, lab_reg) |> MLJ.fit!

factor_import = stack(DataFrame(feature_importances(mach_reg)))

evaluate(model, features, lab_reg, resampling=CV(nfolds=10, shuffle=true, rng=123), measure=[RootMeanSquaredError()])
fitted_params(mach_reg).tree

CSV.write(joinpath(@__DIR__, "dataframes/SD_feature_importance.csv"), factor_import)










"""
fig = Figure(size = (1800,1080), fontsize = 18, pt_per_unit = 1, figure_padding = 20)

ax = Axis(fig[1,1], yticks = (1:6, reverse(["Risk Averse", "Pop. Growth", "Expectation Effect", "SLR", "Breach", "Flood Memory"])),                
        xlabel = "Feature Importance", limits = ((0,0.8), nothing), ygridvisible = false)

hidespines!(ax,:t, :r)
CairoMakie.barplot!(ax, reverse(factor_import.value), color =colorant"#52A3B8", direction = :x)
display(fig)

CairoMakie.save(joinpath(pwd(),"figures/SD_feature_importance.png"), fig)


##Tree Selection
# run 10-fold cross validation, returns array of coefficients of determination (R^2)

n_folds = 10
depth = collect(range(1, 5, step = 1))
CV_scores = []
for n_depth in depth
    r2 = nfoldCV_tree(labels, features, n_folds, 1.0, n_depth)
    score = mean(r2)
    append!(CV_scores, score)
end

CV_scores
#Select best depth and create tree 
model = build_tree(labels, features, 0, 3)
model = prune_tree(model, 0.9)
print_tree(model, 3)

impurity_importance(model)
"""