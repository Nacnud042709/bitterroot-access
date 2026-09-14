# Rebuild the model schema from stage. Requires stage to be populated
# (see build_stage.ps1). Safe to rerun — every script drops and recreates.

$ErrorActionPreference = 'Stop'

$scripts = @(
    '16_ownership',        # parcel ownership classification
    '17_access_regime',    # access regime per parcel
    '18_access_fas',       # FWP fishing access sites
    '19_access_bridge',    # NBI bridge crossings
    '20_access_frontage',  # public land channel frontage
    '23_access_usfs',      # USFS boating sites
    '21_access_all',       # unified access layer (consumes 18,19,20,23)
    '22_channel_boundary'  # channel margin segmented by ownership
)

foreach ($s in $scripts) {
    Write-Host "Running $s ..." -ForegroundColor Cyan
    docker compose exec -e PAGER=cat db psql -U bitterroot -d bitterroot -v ON_ERROR_STOP=1 -f "/sql/$s.sql"
    if ($LASTEXITCODE -ne 0) { throw "Failed on $s" }
}

Write-Host "`nModel rebuilt." -ForegroundColor Green