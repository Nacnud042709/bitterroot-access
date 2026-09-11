# Load source data into the raw schema.
#
# Run from the repo root with Docker running and the data/ folder populated.
# GDAL comes from the OSGeo4W install; this script adds it to PATH for its
# own scope only, so it does not interfere with ArcGIS Pro's Python.
#
#   .\scripts\load_raw.ps1
#
# Every load uses -overwrite, so the script is safe to rerun.

param(
    [string]$DataDir = ".\data",
    [string]$OSGeo4W = "C:\Users\dunca\AppData\Local\Programs\OSGeo4W"
)

$ErrorActionPreference = 'Stop'

# --- GDAL environment -----------------------------------------------------
$env:PATH      = "$OSGeo4W\bin;" + $env:PATH
$env:GDAL_DATA = "$OSGeo4W\apps\gdal\share\gdal"
$env:PROJ_LIB  = "$OSGeo4W\share\proj"

if (-not (Get-Command ogr2ogr -ErrorAction SilentlyContinue)) {
    throw "ogr2ogr not found. Check the -OSGeo4W path: $OSGeo4W"
}

# --- Database connection from .env ----------------------------------------
if (-not (Test-Path ".env")) {
    throw "No .env file found. Run this from the repo root."
}

$cfg = @{}
foreach ($line in (Get-Content .env | Where-Object { $_ -match '=' -and $_ -notmatch '^\s*#' })) {
    $k, $v = $line -split '=', 2
    $cfg[$k.Trim()] = $v.Trim()
}

$PG = "PG:host=localhost port=$($cfg.PGPORT_HOST) dbname=$($cfg.POSTGRES_DB) user=$($cfg.POSTGRES_USER) password=$($cfg.POSTGRES_PASSWORD)"

# --- Helper ---------------------------------------------------------------
function Load-Layer {
    param(
        [string]   $Source,
        [string]   $Layer,
        [string]   $Target,
        [string]   $GeomType,
        [string[]] $ExtraArgs = @()
    )

    if (-not (Test-Path $Source)) {
        throw "Source not found: $Source"
    }

    Write-Host "Loading $Target ..." -ForegroundColor Cyan

    $ogrArgs = @(
        '-f', 'PostgreSQL', $PG, $Source, $Layer,
        '-nln', $Target,
        '-lco', 'GEOMETRY_NAME=geom',
        '-lco', 'FID=gid',
        '-nlt', $GeomType,
        '-overwrite', '-progress'
    ) + $ExtraArgs

    & ogr2ogr @ogrArgs
    if ($LASTEXITCODE -ne 0) { throw "ogr2ogr failed loading $Target (exit $LASTEXITCODE)" }
}

function Load-Table {
    # Non-spatial table: no geometry options.
    param(
        [string] $Source,
        [string] $Layer,
        [string] $Target
    )

    if (-not (Test-Path $Source)) {
        throw "Source not found: $Source"
    }

    Write-Host "Loading $Target ..." -ForegroundColor Cyan

    & ogr2ogr -f PostgreSQL $PG $Source $Layer -nln $Target -overwrite -progress
    if ($LASTEXITCODE -ne 0) { throw "ogr2ogr failed loading $Target (exit $LASTEXITCODE)" }
}

# --- Watershed Boundary Dataset (HU-2 Region 17) --------------------------
Load-Layer "$DataDir\WBD_17_HU2_GDB\WBD_17_HU2_GDB.gdb" `
           "WBDHU8" "raw.wbd_huc8" "MULTIPOLYGON"

# --- NHDPlus High Resolution, HUC4 1701 -----------------------------------
# -dim XY strips the Z and M values carried by NHD geometry.
$nhd = "$DataDir\NHDPLUS_H_1701_HU4_GDB\NHDPLUS_H_1701_HU4_GDB.gdb"

Load-Layer $nhd "NHDFlowline"  "raw.nhd_flowline"  "MULTILINESTRING" @('-dim','XY')
Load-Layer $nhd "NHDWaterbody" "raw.nhd_waterbody" "MULTIPOLYGON"    @('-dim','XY')
Load-Layer $nhd "NHDArea"      "raw.nhd_area"      "MULTIPOLYGON"    @('-dim','XY')
Load-Table $nhd "NHDPlusFlowlineVAA" "raw.nhd_flowline_vaa"

# --- Cadastral parcels ----------------------------------------------------
Load-Layer "$DataDir\Ravalli_GDB\Ravalli_Parcels.gdb" `
           "OwnerParcel" "raw.parcels_ravalli" "MULTIPOLYGON"

Load-Layer "$DataDir\Missoula_GDB\Missoula_Parcels.gdb" `
           "OwnerParcel" "raw.parcels_missoula" "MULTIPOLYGON"

# --- Public land ownership ------------------------------------------------
Load-Layer "$DataDir\MTPublicLands_GDB\Montana_PublicLands.gdb" `
           "Montana_PublicLands" "raw.public_lands" "MULTIPOLYGON"

# --- FWP Fishing Access Sites ---------------------------------------------
Load-Layer "$DataDir\FWPLND_FAS_POINTS_6602612104277579060\fishing_access_points.gdb" `
           "Fishing_Access_Sites___Points" "raw.fas_point" "POINT"

Load-Layer "$DataDir\FWPLND_FAS_-8439914100656288219\fishing_access_polygons.gdb" `
           "Fishing_Access_Sites___Polygons" "raw.fas_poly" "MULTIPOLYGON"

# --- MSDI road centerlines ------------------------------------------------
Load-Layer "$DataDir\TransportationFramework_gdb\TransportationFramework.gdb" `
           "RoadCenterLine" "raw.roads" "MULTILINESTRING"

# --- National Bridge Inventory (Montana only, FIPS 30) --------------------
Load-Layer "$DataDir\NTAD_National_Bridge_Inventory_1344491286157784889\NBI.gdb" `
           "National_Bridge_Inventory" "raw.nbi" "POINT" `
           @('-where', "STATE_CODE_001 = '30'")

Write-Host "`nAll raw layers loaded." -ForegroundColor Green