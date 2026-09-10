# Bitterroot Public Water Access

Modeling which reaches of the Bitterroot River and its tributaries are
legally accessible for recreation under Montana's stream access law, and
how far a person must travel along the channel from the nearest legal
entry point.

**Status:** Phase 0 complete — environment setup.

## Stack

- PostgreSQL 18 / PostGIS 3.6 / pgRouting 4.0 (Docker)
- GDAL 3.13 (OSGeo4W)
- QGIS 3.44 LTR
- Python 3.12 / GeoPandas (conda)

## Setup

Requires Docker Desktop. Copy `.env.example` to `.env`, set a password, then:

    docker compose up -d --build
    docker compose exec db psql -U bitterroot -d bitterroot -f /sql/00_schemas.sql

Python environment:

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