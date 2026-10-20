---
type: Document Text
title: "Fire Danger Forecast (technical background)"
description: "How EFFIS computes the Fire Weather Index and its danger classes."
resource: ../11-effis-fire-danger-forecast.html
tags: [europe, fire-danger-index]
status: stable
language: en
publisher: "EFFIS, Copernicus Emergency Management Service"
retrieved_at: 2026-10-19T00:00:00Z
sources:
  - { id: original, resource: https://forest-fire.emergency.copernicus.eu/about-effis/technical-background/fire-danger-forecast, title: "Fire Danger Forecast (technical background)" }
generated: { by: process:html-main-content-extraction, at: 2026-10-20T10:26:36Z }
---
* jrc-effis@ec.europa.eu

Login to access admin area

### Fire Danger Forecast

In 2007, after a test phase of 5 years during which different national fire danger indices were implemented in EFFIS, the EFFIS network adopted the Canadian Forest Fire Weather Index (FWI) System as the method to assess the fire danger level in a harmonized way throughout Europe.

Currently, the fire danger forecast module of EFFIS provides access to fire danger indices using numerical weather forecast from two deterministic models i.e. ECMWF (~8 km) and MeteoFrance (~10 km). You can select the model in the pull-down menu of the EFFIS Current Situation Viewer.

However, given the different climatic conditions in Europe, EFFIS publishes two indicators derived from the FWI that provide information on the local/temporal variability of the FWI compared to a historical series of approximately 40 years. These indicators are the **ranking**, which provides percentiles of occurrence of the values, and the **anomaly**, computed as a standard deviation from the 40-year historical mean values. These indices are available in the pull down menu of the fire danger section.

#### Fire danger assessment from deterministic models

In EFFIS, the FWI is computed from the ECMWF model (8 km), which provides 1 to 9 days forecasts, and from the MeteoFrance model (10 km), which provides up to 3 days forecasts. The Fire Weather Index is mapped in 6 classes (low, medium, high, very high, extreme and very extreme). The "**Very Extreme**" Fire Danger Class was introduced in June 2021 to provide discrimination about the level of fire danger in extensive areas that were initially classified at "Extreme" Fire Danger in the Mediterranean region during the summer months. The "**Very Extreme**" class include areas with **FWI values above 70.**

The fire danger classes are the same for all countries and maps show a harmonized picture of the spatial distribution of fire danger level throughout Europe, Middle East and North Africa. The values for the FWI and its sub-components are provided below.

| Fire Danger Classes | FWI | FFMC | DMC | DC | ISI | BUI | Anomaly | Ranking |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Low | < 11.2 | < 82.7 | < 15.7 | < 256.1 | < 3.2 | < 24.2 | < 0.0 | < 80.0 |
| Moderate | 11.2 - 21.3 | 82.7 - 86.1 | 15.7 - 27.9 | 256.1 - 334.1 | 3.2 - 5.0 | 24.2 - 40.7 | 0.0 - 0.5 | 80.0 - 90.0 |
| High | 21.3 - 38.0 | 86.1 - 89.2 | 27.9 - 53.1 | 334.1 - 450.6 | 5.0 - 7.5 | 40.7 - 73.3 | 0.5 - 1.0 | 90.0 - 95.0 |
| Very High | 38.0 - 50.0 | 89.2 - 93.0 | 53.1 - 83.6 | 450.6 - 600.0 | 7.5 - 13.4 | 73.3 - 133.1 | 1.0 - 1.5 | 95.0 - 98.0 |
| Extreme | 50.0 - 70.0 | 93.0 - 96.0 | 83.6 - 160.7 | 600.0 - 749.4 | 13.4 - 26.8 | 133.1 - 193.1 | 1.5 - 2.5 | 98.0 - 99.0 |
| Very Extreme | > 70.0 | > 96.0 | > 160.7 | > 749.4 | > 26.8 | > 193.1 | > 2.5 | > 99.0 |

In 2019, due to the interest of countries in comparing the performance of the FWI with other relevant fire danger indices, the Australian McArthur Forest Fire Danger Index (MARK-5), the Keetch-Byram Drought Index (KBDI) and the National Fire Danger Rating System (NFDRS) have been made available through the EFFIS Fire Danger Forecast module. Information on these indices, which are all computed from numerical weather predictions of the ECMWF deterministic model, is available at the links provided in this paragraph.

The maps of forecasted fire danger level can be consulted through the web mapping interface of EFFIS and are also made available to the users through the Data and services section of EFFIS.

A data-transformation model of the FWI is also used to provide a measure of fire control difficulty: the Daily Severity Rating (DSR: Van Wagner, C.E., Pickett, T.L., 1985). Its average of daily estimates over a week is called Weekly Severity Rating (WSR) and it provided in EFFIS through the Current Statistics Portal.

Additional information on the map viewer tool downloading the User Guide to the EFFIS Current Situation Viewer.

**References**

Van Wagner, C.E., Pickett, T.L., 1985. **Equations and FORTRAN program for the Canadian Forest Fire Weather Index System**.*Forestry Technical Report*. Canadian Forestry Service, Ottawa, Canada. https://purl.org/INRMM-MiD/c-14026112

Camia, A., Amatulli, G., 2010. **Climatology of FWI over Europe: fire danger anomalies and index percentile rankings**. In: *Proceedings of the VI International Conference on Forest Fire Research*. Presented at the VI International Conference on Forest Fire Research, Coimbra, Portugal, p. B04+. Camia_and_Amatulli_2010__ICFFR-2010_B04.pdf

Copernicus Emergency Management Service, 2019. **Fire danger indices historical data from the Copernicus Emergency Management Service**. In: *Copernicus Climate Change Service (C3S) Climate Data Stor*e (CDS). https://doi.org/10.24381/cds.0e89c522

* JRC Mission
* Cookies
* Legal notice
* Sitemap
* Privacy Statement
* Accessibility Statement

*
