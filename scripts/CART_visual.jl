#Classification Tree 
using Pkg
Pkg.activate(".")
Pkg.instantiate()

using CairoMakie
using CSV, DataFrames
using DataStructures
using Graphs
using GraphMakie
import MLJ
using NetworkLayout
using DecisionTree
using Statistics


##Functions to visualize Tree
import Base.convert
function Base.convert(::Type{SimpleDiGraph},model::DecisionTree.DecisionTreeClassifier; maxdepth=depth(model))
    if maxdepth == -1
        maxdepth = depth(model)
    end
    g = SimpleDiGraph()
    properties = Any[]
    walk_tree!(model.root.node,g,maxdepth,properties)
    return g, properties
end

function walk_tree!(node::DecisionTree.Node, g, depthLeft, properties)
    node_labels = ["Risk Averse", "Breach", "Pop. Growth", "Flood Memory", "Exp. Effect", "SLR"] #list of labels
    add_vertex!(g)

    if depthLeft == 0
        push!(properties,(Nothing,"..."))
        return vertices(g)[end]
    else
        depthLeft -= 1
    end

    current_vertex = vertices(g)[end]
    val = node.featval

    featval = isa(val,AbstractString) ? val : round(val;sigdigits=2)
    push!(properties,(Node," $(node_labels[node.featid]) < $featval ?"))


    child = walk_tree!(node.left,g,depthLeft,properties)
    add_edge!(g,current_vertex,child)

    child = walk_tree!(node.right,g,depthLeft,properties)
    add_edge!(g,current_vertex,child)

    return current_vertex
end

function walk_tree!(leaf::DecisionTree.Leaf, g, depthLeft, properties)
    add_vertex!(g)
    n_matches = count(leaf.values .== leaf.majority)
    #ratio = string(n_matches, "/", length(leaf.values))

    push!(properties,(Leaf,"$(leaf.majority)"))# : $(ratio)"))
    return vertices(g)[end]
end

@recipe(PlotDecisionTree) do scene
    Attributes(
        nodecolormap = :darktest,
        textcolor = RGBf(0.5,0.5,0.5),
        leafcolor = :darkgreen,
        nodecolor = :white,
        maxdepth = -1,
    )
end

import GraphMakie.graphplot
import Makie.plot!
function GraphMakie.graphplot(model::DecisionTreeClassifier;kwargs...)
    f,ax,h = plotdecisiontree(model;kwargs...)
    hidedecorations!(ax); hidespines!(ax)
    return f
end



function plot!(plt::PlotDecisionTree{<:Tuple{DecisionTreeClassifier}})

    @extract plt leafcolor,textcolor,nodecolormap,nodecolor,maxdepth
    model = plt[1]

    # convert to graph
    tmpObs = @lift convert(SimpleDiGraph,$model;maxdepth=$maxdepth)
    graph = @lift $tmpObs[1]
    properties = @lift $tmpObs[2]

    # extract labels
    labels = @lift [string(p[2]) for p in $properties]
    
    

    # set the colors, first for nodes & cutoff-nodes, then for leaves
    nlabels_color = map(properties, labels, leafcolor,textcolor,nodecolormap) do properties,labels,leafcolor,textcolor,nodecolormap

        # set colors for the individual elements
        leaf_ix = findall([p[1] == Leaf for p in properties])
        leafValues = [p[1] for p in split.(labels[leaf_ix]," : ")]

        # one color per category
        uniqueLeafValues = unique(leafValues)
        individual_leaf_colors = resample_cmap(nodecolormap,length(uniqueLeafValues))
        nlabels_color = Any[p[1] == Node ? textcolor : leafcolor for p in properties]
        for (ix,uLV) = enumerate(uniqueLeafValues)
            ixV = leafValues .== uLV
            nlabels_color[leaf_ix[ixV]] .= individual_leaf_colors[ix]
        end
        return nlabels_color
    end

    # plot :)
    graphplot!(plt,graph;layout=Buchheim(),
               nlabels=labels,
               node_size = 100,
               node_color=nodecolor,
               nlabels_color=nlabels_color,
               nlabels_align=(:center,:center),
               ##tangents=((0,-1),(0,-1))
               )
    return plt
    
end




#Read in Model Runs
data = DataFrame(CSV.File(joinpath(dirname(@__DIR__),"workflow/CHANCE_C/SA_Results/scen_disc_table.csv")))

data_class = copy(data)
data_class[!,:RSI] = [i > 0 ? "1" : "-1" for i in data_class[:,:RSI]]

neg_count = sum([i  == "-1" ? 1 : 0 for i in data_class[:,:RSI]]) #Count of -RSI values
println("Proportion of RSI Outcomes with no risk transference: $((neg_count/1800) * 100)")

#DecisionTreeClassifier = @load DecisionTreeClassifier pkg=DecisionTree
model = DecisionTreeClassifier(max_depth=4)

lab_class =  data_class[:,:RSI]
features = Matrix(select(data_class, Not(:RSI)))

fit!(model, features, lab_class)

print_tree(model)
plt = graphplot(model; textcolor = :black)
GraphMakie.save(joinpath(pwd(),"figures/dec_tree.png"), plt)









ext_data = copy(data)
#filter!(row -> (row.RSI > 0), ext_data)
thresh = quantile(ext_data[:, :RSI], 0.9) #90th Percentile
#Calculate top 10% threshold
ext_data[!,:RSI] = [i > thresh ? "1" : "-1" for i in ext_data[:,:RSI]]
neg_ext_count = sum([i  == "1" ? 1 : 0 for i in ext_data[:,:RSI]]) #Count of extreme RSI values
println("Proportion of RSI Outcomes with no risk transference: $((neg_ext_count/1800) * 100)")

model_ext = DecisionTreeClassifier(max_depth=3)

lab_ext =  ext_data[:,:RSI]
feat_ext = Matrix(select(ext_data, Not(:RSI)))

fit!(model_ext, feat_ext, lab_ext)

print_tree(model_ext)

plt_ext = graphplot(model_ext; textcolor = :black)

GraphMakie.save(joinpath(pwd(),"figures/dec_tree_extreme.png"), plt_ext)