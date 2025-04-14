#!/bin/bash
#SBATCH --job-name=balt_MoM
#SBATCH --nodes=3
#SBATCH --ntasks-per-node=50
#SBATCH --output=workflow/CHANCE_C/test/output_text.txt
#SBATCH --error=workflow/CHANCE_C/test/error_text.txt
#SBATCH --exclusive

# Run the Julia code
julia +1.7 workflow/CHANCE_C/MoM_cluster.jl