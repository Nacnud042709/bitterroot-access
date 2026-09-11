# Bitterroot Public Water Access

Modeling which reaches of the Bitterroot River and its tributaries are
legally accessible for recreation under Montana's stream access law, and
how far a person must travel along the channel from the nearest legal
entry point.

**Status:** Phase 0 complete — environment setup.

## Setup

Requires Docker Desktop, GDAL (via OSGeo4W), and Miniforge.

**1. Start the database.** Copy `.env.example` to `.env` and set a password, then:

    docker compose up -d --build
    docker compose exec db psql -U bitterroot -d bitterroot -f /sql/00_schemas.sql

**2. Download the source data.** Every layer, with its agency, URL, format,
and retrieval date, is listed in the `model.data_sources` table created by
the schema script. Extract each download into `data/`.

**3. Load and build:**

    .\scripts\load_raw.ps1
    .\scripts\build_stage.ps1

`load_raw.ps1` reads credentials from `.env` and locates GDAL in the OSGeo4W
install; pass `-OSGeo4W <path>` if yours is installed elsewhere. Both scripts
are idempotent and safe to rerun.

**4. Verify:**

    docker compose exec db psql -U bitterroot -d bitterroot -f /sql/99_counts.sql

Expected row counts in `stage`: study_area 1, flowline 12,456, waterbody 1,240,
nhd_area 17, parcel 50,957, public_land 557, fas_point 15, fas_poly 14,
bridge 167.

**Python environment** (not required for the pipeline):

    conda env create -f environment.yml

## Structure

| Path | Contents |
|---|---|
| `sql/` | Schema definitions and transformation scripts |
| `scripts/` | Python and shell scripts |
| `qgis/` | QGIS project and styles |
| `docs/` | Methodology, data inventory, validation |

## Project CRS

EPSG:32100 — NAD83 / Montana (meters). All layers in `stage` and beyond
use this CRS.

## Disclaimer

This is a modeling exercise, not legal guidance. Access determinations
depend on posted signage, current ownership, and site conditions not
represented in public datasets. Consult Montana FWP and current landowner
information before entering any water.