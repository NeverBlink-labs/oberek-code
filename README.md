# OBEREK data models and pipelines

Ontology, data models, and pipelines from the OBEREK project, which monitors L'Albufera (Valencia, Spain). The pipelines collect water quality, weather, water flow, Sentinel-2, and community poll data, turn it into RDF, and calculate the project's Key Ecological Indicators (KEI-1, KEI-2, KEI-3) and the rice blast risk index (PRI).

The pipelines run on **Rusalka**, NeverBlink's streaming RDF engine. Satellite indices are calculated in SPARQL with the **RDF Tensor** extension (`t:` functions), documented at <https://w3id.org/rdf-tensor/> ([paper](https://arxiv.org/abs/2504.19224)).

## Contents

- `model/oberek-ontology-init/oberek_ontology.ttl`: the OBEREK ontology, built on SAREF (core, SAREF4WATR, SAREF4MARI), QUDT, WMO codes, and the DDI summary statistic vocabulary.
- `model/oberek-metadata-init/oberek_metadata.ttl`: sites, devices, sensors, poll questions, locations, and the baselines and thresholds used to score the KEIs, each with its source.
- `model/*`: lifting models (Jsonnet, YARRRML, LinkML) used by the ingestion pipelines, and `universal-sensor-export-processing`, which turns results into tables for CSV and JSON export.
- `pipeline/*`: ingestion and calculation pipelines.

### Ingestion

| Pipeline | Source | Lifting model |
|---|---|---|
| `iot-{north,south,southwest}-ingestion` | water quality probes over MQTT | `iot-water-processing` |
| `avamet-tancatestell-ingestion` | Fundació Assut weather station Tancat de l'Estell, read from its Inforatge page (inforatgest.com) | `avamet-data-processing` |
| `water-flow-ingestion` | CHJ flow gauging stations (dataset F56) | `water-flow-processing` |
| `copernicus-data-ingestion` | Sentinel-2 L2A bands through openEO | `copernicus-data-processing` |
| `poll-submit-api` | community poll answers (HTTP POST) | `poll-submit-reshape`, `polling-submission-processing` |
| `manual-poll-ingestion` | paper poll answers (CSV over HTTP) | `manual-poll-processing` |

### Calculation

| Pipeline | Input |
|---|---|
| `kei-1-processing` | IoT, Sentinel-2 |
| `kei-2-processing` | IoT, Tancat de l'Estell weather station, Sentinel-2, PRI |
| `kei-3-processing` | KEI-1, KEI-2 and polls from the last 30 days |
| `pri/hourly` → `pri/warning` → `pri/critical` | Tancat de l'Estell weather station |

All KEIs use a 1–5 scale (5 = best). KEI-1 and KEI-2 score each measured property against the baselines and thresholds in the metadata. KEI-3 is `5 - round(|mean(KEI-1, KEI-2) - poll satisfaction|)`.

The pipelines use Rusalka templates (`!template …`, not included) to save results and pass them between pipelines. Results are stored in an RDF store, `oberek-history`, which KEI-3 reads from. The metadata and ontology are loaded into the `oberek-metadata` and `oberek-ontology` stores, and the queries reach them with `SERVICE <rusalka://local/…>`.

## Placeholders

| Placeholder | What to put there |
|---|---|
| `<COPERNICUS_TOKEN_URL>` | Copernicus Data Space Ecosystem OAuth2 token endpoint |
| `<OPENEO_RESULT_URL>` | Copernicus Data Space Ecosystem openEO result endpoint |
| `<CHJ_GAUGING_STATIONS_ZIP_URL>` | CHJ download of dataset F56, "Estaciones de aforo de L'Albufera" |
| `<ESTELL_STATION_URL>` | Inforatge page (inforatgest.com) of the Tancat de l'Estell station |
| `<MQTT_HOST>` | your MQTT broker |
| `<MQTT_PORT>` | your MQTT broker's port |
| `<HTTP_PORT>` | the port the poll APIs (`poll-submit-api`, `manual-poll-ingestion`) listen on |

## Prefixes

The SPARQL queries use these prefixes without declaring them: `nb:` `https://neverblink.eu/ontologies/oberek/`, `nbi:` `https://neverblink.eu/oberek/`, `t:` `https://w3id.org/rdf-tensor/vocab#`, `rusalka:` `https://neverblink.eu/rusalka/ontology#`, `disco:` `http://rdf-vocabulary.ddialliance.org/discovery#`, `sst:` `http://rdf-vocabulary.ddialliance.org/cv/SummaryStatisticType/2.1.2/`. The other prefixes (`saref:`, `s4watr:`, `s4mari:`, `unit:`, `qudt_qk:`, `wmo:`, `wmdr:`, `bufr4_b13:`, `geo:`, `rdfs:`, `xsd:`) are declared in the ontology file.

## Licence

- Code (pipelines and lifting models): Apache License 2.0, see `LICENSE`.
- Ontology and metadata (`*.ttl`): Creative Commons Attribution 4.0 International (CC BY 4.0).

No measured data is included. Data collected with these pipelines stays under its source's terms (Copernicus data policy, CHJ conditions of reuse, Fundació Assut terms for the Tancat de l'Estell station).
