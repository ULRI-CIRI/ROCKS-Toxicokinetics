# The Toxicokinetic Data Landscape for a Global Chemical Collection

Chemical risk to the public depends on hazard, exposure, and dose–response relationships, including toxicokinetics (TK). We assessed available TK information for the Report on Chemical Knowledge and Safety (ROCKS) global collection of 238,602 chemical entities with plausible human exposure based on evidence of commercial use and/or occurrence in human or environmental monitoring datasets. Public human in vivo TK data were available for fewer than 1% of chemicals. For TK half-life, which indicates bioaccumulation potential, we found measured values spanning ten orders of magnitude. To address sparse data, we combined in vitro TK data and new quantitative structure–property relationship (QSPR) model predictions to generate high-throughput toxicokinetic (HTTK) estimates for 21% of the ROCKS collection. We characterized HTTK uncertainty using available in vivo data and Monte Carlo analysis. HTTK identified most chemicals with long in vivo half-lives. Limitations of physico-chemical QSPR models are a barrier to chemical coverage; we identified chemicals for which new experiments would be useful. Finally, we generated in vitro–in vivo extrapolation (IVIVE) factors to translate in vitro points of departure from new approach methods (NAMs) into human oral, dermal, and inhalation exposures. This research highlights TK data gaps while improving access to measured and predicted TK properties.

## Key Files

* `CreateROCKSFigures.Rmd`: RMarkdown code to perform analysis and create figures for ROCKS TK Landscape manuscript
* `ivivedb_funcs.R `: Code for accessing DuckDB version of CITK
* `tables/`: Folder containing output tables for ROCKS TK Landscape manuscript
* `figs/`: Folder containing output figures for ROCKS TK Landscape manuscript
* `data/`: Folder containing source data files
* `db/`: Folder containing the DuckDB prototype

## CITK

To store and disseminate the data and predictions used to survey the ROCKS chemical collection, a new database was constructed: [CITK](https://doi.org/10.60752/102376.35054437) (Chemical Insights Toxicokinetic Database, pronounced “sci-tock”). The database includes chemical-specific in vitro TK parameters (HTTK inputs) and in vivo TK summary parameters. The database includes data for chemicals in the ROCKS collection as well as some additional data such as animal-specific in vitro TK from httk, the full list of pharmaceuticals (including failed and withdrawn drugs) from Lombardo et al. (2018), and the full collection of per- and poly-fluorinated substances (PFAS) from Dawson et al. (2023). A high-level description of the database is provided in Table S1 (Supporting Information). The database is downloadable from [https://doi.org/10.60752/102376.35054437](https://doi.org/10.60752/102376.35054437) in DuckDB format. R package httk v3.0.0 contains a subset of the tables and chemicals in the CITK database that are necessary to make predictions but does not contain the full database. 

### Table chemicals

Chemical identities, likely to be replaced with ROCid API. Primary key chem_id.
* chem_id INTEGER PRIMARY KEY
* chemical_id INTEGER
* cichem VARCHAR(20)
* DTXSID VARCHAR(20)
* CASRN VARCHAR(20)
* Compound VARCHAR(100)
    
### Table chemprop

Physico-chemical properties, intended to be replaced with ROCprop API
* chem_id_fk INTEGER
* Property VARCHAR(100)
* Value VARCHAR(20)
* FOREIGN KEY (chem_id_fk) REFERENCES chemicals (chem_id)
    
### Table refs

Table of references for data including Pub Med IDs (pmid). In many cases httk
relies on papers that have conducted massive surveys of the literature (we call
these "aggregator papers"). The aggregator papers are secondary sources, but
since in at least one case (Lombardo, 2018) they aggregate thousands of studies,
we do not currently have the capacity to re-review the primary literature. For
the time being we are just reporting the source (primary or secondary) from
which we have obtained the value.
* ref_id INTEGER PRIMARY KEY
* Reference VARCHAR(100)
* PMID VARCHAR(20)
* DOI VARCHAR(100)

### Table models

Table of all pharmacokinetic/toxicokinetic models used to make predictions for 
HTTK and IVIVE tabs. Most of the models are from the R package "httk" suite
of models. The model "in vivo" reflects new calculations made for
this database using the in vivo data.
* model_id INTEGER PRIMARY KEY
* Model VARCHAR
* FOREIGN KEY (ref_id_fk) REFERENCES REF refs (ref_id)

### Table cohorts

Table of all population groups for which IVIVE predictions have been made. The
"httk" R package uses a Monte Carlo sampler which can be used with a variety
of configuration paramweters. These "cohorts" attempt to capture the simulations
used. (NOTE: we should add the random number seed and platform so that the
pseudo-random number generator sequence can be captured, but this is not
currently in the schema.)
* cohort_id INTEGER PRIMARY KEY
* Percentile VARCHAR
* Species VARCHAR
* Source VARCHAR
* Cohort_Description VARCHAR
* Uncertainty BOOLEAN: Whether the Monte Carlo simulation includes measurement uncertainty
* Variability BOOLEAN: Whether the Monte Carlo simulation includes biological variability

### Table route
This table describes the unit exposues used to cause the steady-state plasma
concentrations (Css) reported in the IVIVE table.
* route_id INTEGER PRIMARY KEY
* Route_Description VARCHAR
* Route_Units VARCHAR
* Route_Magnitude DOUBLE

### Table invivo

Table of all <i>in vivo</i> experimental measurements of toxicokinetic 
properties. Most data are for animals.

Fields include: 
    * chem_id_fk: INTEGER Foreign key to chemicals table
    * Parameter: VARCHAR(100) Description of parameter (e.g. "half-life", "total clearance")
    * Value: DOUBLE The value of the parameter
    * Species: VARCHAR(50) The species from which the data were derived (e.g. "human", "rat", "mouse")
    * ref_id_fk: INTEGER Foreign key to references table
    * Units: VARCHAR(50) The units of the parameter value
    
### Table ivive

Table of  IVIVE factors 
(unit conversions from in vitro concentration to steady-state exposure) 
predicted with httk. Typically C<sub>ss</sub> as a function of a unit exposure.

Columns in this table:
    * FOREIGN KEY (chem_id_fk) REFERENCES chemicals (chem_id),
    * FOREIGN KEY (ref_id_fk) REFERENCES refs (ref_id),
    * FOREIGN KEY (model_id_fk) REFERENCES models (model_id),
    * FOREIGN KEY (cohort_id_fk) REFERENCES cohorts (cohort_id),
    * FOREIGN KEY (route_id_fk) REFERENCES routes (route_id): The route of exposure
    * Parameter VARCHAR(100): Description of parameter (e.g. "Clint", "fup", "Caco-2 permeability")
    * Type VARCHAR(50): Description of whether the value is a measurement or a prediction
    * Value DOUBLE: The value of the parameter
    * InVivoForal BOOLEAN: Was the in vivo measured Foral used for this calculation
    * HTTKBasis VARCHAR(20): Was HTTK based on measured, QSPR, or a mix of values
    * Units VARCHAR(50): The units of the parameter value
    * Species VARCHAR(50): The species for which the predictions were made
    * DataSourceSpecies VARCHAR(50),: The species from which the HTTK parameters were derived (e.g. "human", "rat", "mouse")

### Table httk
Table of toxicokinetic parameters predicted using HTTK models, 
including chemical half-life and total clearance.

Fields in this table:
    * FOREIGN KEY (chem_id_fk) REFERENCES chemicals (chem_id),
    * FOREIGN KEY (ref_id_fk) REFERENCES refs (ref_id),
    * FOREIGN KEY (model_id_fk) REFERENCES models (model_id),
    * FOREIGN KEY (cohort_id_fk) REFERENCES cohorts (cohort_id)
    * Parameter VARCHAR(100): Description of parameter (e.g. "half-life", "total clearance")
    * Value VARCHAR(10): The value of the parameter
    * Units VARCHAR(50): The units of the parameter Value
    * Species VARCHAR(50): The species for which the predictions were made
    * DataSourceSpecies VARCHAR(50): The species from which the HTTK parameters were derived (e.g. "human", "rat", "mouse")

### Table invitrotk
Table of all <i>in vitro</i> measurements of toxicokinetic properties.
Includes chemical-specific
Cl<sub>int</sub> (intrinsic hepatic clearance) and f<sub>up</sub> (fraction unbound in plasma) values
 Cl<sub>int</sub> and f<sub>up</sub> 
may be measured <i>in vitro</i> or predicted by quantitative structure-property relationship (QSPR)
models.

Fields include: 
    * chem_id_fk: INTEGER Foreign key to chemicals table
    * ref_id_fk: INTEGER Foreign key to references table
    * model_id_fk: INTEGER Foreign key to models table
    * cohort_id_fk: INTEGER Foreign key to cohorts table
    * Parameter: VARCHAR(100) Description of parameter (e.g. "Clint", "fup", "Caco-2 permeability")
    * Type: VARCHAR(50) Description of whether the value is a measurement or a prediction
    * Value: DOUBLE The value of the parameter
    * Units: VARCHAR(50) The units of the parameter value
    * Species VARCHAR(50): The species for which the measurement ws made

## UL Research Institutes - Chemical Insights

[UL Research Institutes](https://ul.org/) is a nonprofit safety-science organization whose legacy traces back to the historic Underwriters Laboratories, founded in 1894. For more than 130 years, the UL enterprise has been working toward the mission of a safer world. [Chemical Insights](https://ul.org/institutes-offices/chemical-insights/), one of six research institutes within ULRI, advances scientific understanding of how chemical exposures impact human health.

We are committed to producing peer-reviewed, open-access research that serves as a trusted resource for the public and scientific community.

We emphasize rigorous scientific peer review:

1.	Wherever possible, we integrate existing, peer-reviewed data and tools.
2.	When creating new data or methods, we submit them to external peer review to ensure quality and credibility.

Our goal is to inform standards and support evidence-based decision-making to protect public health. We are passionate about advancing scientific discovery and applying it to real-world health challenges.
  
## Reference

Wambaugh, John F., Kristin K. Isaacs, Nathaniel Charest, Andrew J. Shapiro, Zach Stanfield, Jonathan T. Wall, Katie Paul Friedman, Mark Wilson, Russell S. Thomas. "The Toxicokinetic Data Landscape for a Global Chemical Collection." submitted (2026).
