#!/bin/bash
#SBATCH --job-name=parallel_test_julia
#SBATCH --nodes=1
#SBATCH --ntasks=40
#SBATCH --output=workflow/SA results/output_text.txt
#SBATCH --error=workflow/SA results/error_text.txt
#SBATCH --exclusive

# Run the Julia code
julia +1.7 factor_map_cluster.jl