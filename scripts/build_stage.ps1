# Rebuild the stage schema from raw. Requires raw to be populated
# (see load_raw.ps1). Safe to rerun — every script drops and recreates.

$ErrorActionPreference = 'Stop'

$scripts = @(
    '02_study_area',
    '04_flowlines',
    '05_waterbody',
    '06_nhdarea',
    '07_parcels',
    '08_parcel_repair',
    '09_public_lands',
    '10_public_land_repair',
    '11_fas',
    '12_bridges'
)

foreach ($s in $scripts) {
    Write-Host "Running $s ..." -ForegroundColor Cyan
    docker compose exec -e PAGER=cat db psql -U bitterroot -d bitterroot -v ON_ERROR_STOP=1 -f "/sql/$s.sql"
    if ($LASTEXITCODE -ne 0) { throw "Failed on $s" }
}

Write-Host "`nStage rebuilt." -ForegroundColor Green
docker compose exec -e PAGER=cat db psql -U bitterroot -d bitterroot -f /sql/99_counts.sql