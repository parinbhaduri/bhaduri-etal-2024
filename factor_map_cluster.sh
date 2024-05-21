#!/bin/bash
#SBATCH --job-name=flood_abm_sobol
#SBATCH --nodes=1
#SBATCH --ntasks=40
#SBATCH --output=workflow/toy_model/output/SA_Results/output_text.txt
#SBATCH --error=workflow/toy_model/output/SA_Results/error_text.txt
#SBATCH --exclusive

# Run the Julia code
julia +1.7 factor_map_cluster.jl
