#Analysis for Scenario Discovery
#activate project environment
using Pkg
Pkg.activate(".")
Pkg.instantiate()

using DecisionTree
using DataStructures
using Distributions
using DataFrames, CSV
using FileIO

#Read in Model Runs
data = DataFrame(CSV.File(joinpath(dirname(@__DIR__),"toy_model/SA_Results/factor_map_table_100.csv")))
data = data[1:1800,:]

labels = [i > 0 ? 1 : -1 for i in data[:,:RSI]]
features = Matrix(select(data, Not(:RSI)))



##Tree Selection
# run 10-fold cross validation, returns array of coefficients of determination (R^2)

n_folds = 10
leaves = collect(range(1, 12, step = 1))
CV_scores = []
for n_leaf in leaves
    r2 = nfoldCV_tree(labels, features, n_folds, 1.0, n_leaf)
    score = mean(r2)
    append!(CV_scores, score)
end

model = build_tree(labels, features, 0, 3)
print_tree(model, 3)

impurity_importance(model)