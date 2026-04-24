#!/bin/bash
# =============================================================================
# PyPSA-DE auf bwUniCluster 2.0 ausführen
# Dieses Skript wird als SLURM-Job für den Snakemake-Koordinator eingereicht.
# Die einzelnen Regeln (build, solve) werden von Snakemake als Sub-Jobs submitted.
#
# Nutzung:
#   sbatch run_bwunicluster.sh
#
# Vorher einmalig:
#   Trage deinen bwUniCluster-Account in profiles/bwunicluster/config.yaml ein
#   (Zeile: slurm_account: YOUR_PROJECT_ACCOUNT)
# =============================================================================

#SBATCH --job-name=pypsa-de-coordinator
#SBATCH --partition=dev              # dev für Test-Läufe (max 30 min), single für echte Läufe
#SBATCH --time=00:30:00             # Laufzeit des Koordinator-Jobs (nicht der Solve-Jobs)
#SBATCH --mem=8000                  # 8 GB reicht für den Snakemake-Koordinator
#SBATCH --cpus-per-task=2
#SBATCH --account=YOUR_PROJECT_ACCOUNT   # <-- hier deinen Account eintragen
#SBATCH --output=logs/slurm/snakemake_coordinator_%j.log
#SBATCH --error=logs/slurm/snakemake_coordinator_%j.err
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=clotilde.gourdin@gmail.com

set -euo pipefail

# --- Logging ---
echo "=== PyPSA-DE bwUniCluster Run ==="
echo "Job ID:    $SLURM_JOB_ID"
echo "Node:      $SLURMD_NODENAME"
echo "Start:     $(date)"
echo "Directory: $SLURM_SUBMIT_DIR"

cd "$SLURM_SUBMIT_DIR"

# --- Log-Ordner anlegen ---
mkdir -p logs/slurm

# --- Pixi-Umgebung aktivieren ---
# Pixi muss einmalig im Home-Verzeichnis installiert sein:
#   curl -fsSL https://pixi.sh/install.sh | bash
export PATH="$HOME/.pixi/bin:$PATH"

# --- Config auswählen (kommentiere die gewünschte ein) ---
CONFIG="config/config_2019_246nodes.yaml"   # 2019, Strom-only, 246 Knoten
# CONFIG="config/config_2030_246nodes.yaml" # 2030, Strom-only, 246 Knoten

# --- Snakemake-Ziel auswählen ---
TARGET="solve_elec_networks"    # Nur Stromnetz (empfohlen für 246 Knoten)
# TARGET="-call"                # Alles inkl. Sektor-Kopplung (braucht fat-Partition)

# --- Snakemake starten ---
pixi run snakemake \
    --profile profiles/bwunicluster \
    --configfile "$CONFIG" \
    $TARGET

echo "=== Run abgeschlossen: $(date) ==="
