#!/bin/bash
# =============================================================================
# PyPSA-DE auf AWS EC2 ausführen (Single Large Instance, kein Cluster)
#
# Empfohlene Instanz: r5.8xlarge (256 GB RAM, 32 vCPUs) als Spot-Instanz
# OS: Ubuntu 22.04 LTS (ami-0c7217cdde317cfec in us-east-1)
#
# Nutzung (auf der EC2-Instanz):
#   chmod +x run_aws_ec2.sh
#   ./run_aws_ec2.sh 2>&1 | tee run.log
# =============================================================================

set -euo pipefail

REPO_URL="https://github.com/PyPSA/pypsa-de.git"
WORKDIR="$HOME/pypsa-de"
CONFIG="config/config_2019_246nodes.yaml"   # 2019 elec-only 246 Knoten
# CONFIG="config/config_2030_246nodes.yaml" # alternativ: 2030
TARGET="solve_elec_networks"
CORES=20   # Gurobi threads (aus der Config) + etwas Reserve

echo "=== PyPSA-DE AWS EC2 Setup ==="
echo "Instance: $(curl -s http://169.254.169.254/latest/meta-data/instance-type 2>/dev/null || echo 'unknown')"
echo "RAM:      $(free -h | awk '/Mem:/{print $2}')"
echo "CPUs:     $(nproc)"
echo "Start:    $(date)"

# --- 1. System-Pakete ---
sudo apt-get update -qq
sudo apt-get install -y -qq git curl wget unzip

# --- 2. Pixi installieren ---
if ! command -v pixi &>/dev/null; then
    echo "Installing pixi..."
    curl -fsSL https://pixi.sh/install.sh | bash
    export PATH="$HOME/.pixi/bin:$PATH"
    echo 'export PATH="$HOME/.pixi/bin:$PATH"' >> ~/.bashrc
fi
export PATH="$HOME/.pixi/bin:$PATH"

# --- 3. Repo klonen ---
if [ ! -d "$WORKDIR" ]; then
    echo "Cloning pypsa-de..."
    git clone "$REPO_URL" "$WORKDIR"
fi
cd "$WORKDIR"

# --- 4. Eigene Config-Dateien übertragen (von lokalem Mac aus, vor diesem Skript):
#    scp -i ~/.ssh/your-key.pem \
#        config/config_2019_246nodes.yaml \
#        config/config_2030_246nodes.yaml \
#        ubuntu@EC2_IP:~/pypsa-de/config/
# ----------------------------------------------------------------------------

# --- 5. Pixi-Umgebung vorbereiten ---
echo "Installing pixi environment (first time: ~10 min)..."
pixi install

# --- 6. Snakemake ausführen ---
echo "=== Starte Snakemake: $TARGET mit $CONFIG ==="
pixi run snakemake \
    --cores "$CORES" \
    --configfile "$CONFIG" \
    --rerun-incomplete \
    --keep-going \
    "$TARGET"

echo "=== Fertig: $(date) ==="
echo "Ergebnisse in: $WORKDIR/results/"

# --- 7. Ergebnisse sichern (optional: auf S3 hochladen) ---
# aws s3 sync results/ s3://YOUR-BUCKET/pypsa-de-results/ --exclude "*.log"
