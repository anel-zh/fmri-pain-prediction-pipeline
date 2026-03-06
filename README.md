
## Connectivity Features

Connectivity features were computed using:

- ROI time series extraction
- Dynamic Conditional Correlation (DCC)
- Schaefer 265 ROI brain parcellation
- Temporal binning of connectivity patterns

Connectivity captures **longer-term brain state changes** associated with sustained pain (e.g., capsaicin vs rest).

## Activation Features

Activation features were estimated using:

- voxel-level HRF modeling
- event-related design matrices
- temporal binning of activation responses

Activation captures **moment-to-moment changes in perceived pain intensity**.

## Machine Learning Model

Prediction models were trained using **Cross-Validated Principal Component Regression (CV-PCR)**.

Dataset split:

### Longitudinal dataset

Training: 17 sessions  
Validation: 4 sessions  
Testing: 5 sessions  

### Population dataset

Training: 78 participants  
Validation: 22 participants  
Testing: 22 participants  

Model selection was based on validation performance.

---

# Results

### Individual-Level Prediction

| Model | Correlation (r) | R² |
|------|------|------|
Connectivity | 0.69 | 0.47 |
Activation | 0.73 | 0.51 |
Combined | **0.90** | **0.79** |

Combining connectivity and activation produced the strongest predictive performance.

### Population-Level Prediction

| Model | Correlation (r) |
|------|------|
Connectivity | 0.40 |
Activation | 0.67 |
Combined | **0.75** |

The combined model also generalized to the population dataset.

### Comparison with Prior Pain Signatures

The proposed model demonstrates improved predictive sensitivity compared to previously reported sustained pain signatures.

### Mechanistic Interpretation

Results suggest complementary roles for connectivity and activation:

**Connectivity**

- captures sustained brain state changes
- reflects long-term neural dynamics

**Activation**

- captures moment-to-moment fluctuations
- reflects immediate intensity changes

Combining these signals improves prediction of tonic pain intensity.

---

# Visualization and Interpretation

This repository includes visualization scripts used to interpret model outputs.

Examples include:

- pain trajectory plots
- prediction vs actual comparisons
- connectivity feature visualization
- activation pattern visualization

These visualizations support interpretation of how connectivity and activation contribute to pain prediction.

Example figures will be added to illustrate:

- model prediction trajectories
- connectivity vs activation contributions
- variance decomposition of combined models

---

# Skills Demonstrated

This project demonstrates several advanced data science and neuroscience skills:

Neuroimaging processing
- analysis of 4D fMRI data
- ROI-based signal extraction
- dynamic connectivity modeling

Machine learning
- dimensionality reduction (PCA)
- cross-validated regression models
- model validation and testing

Time-series analysis
- dynamic functional connectivity
- temporal binning of neural signals
- modeling longitudinal data

Scientific computing
- large-scale data processing
- reproducible analysis pipelines
- visualization and interpretation of neural data

---

# Future Work

Planned next steps include:

- interpretation of model weights
- comparison between personalized and population models
- specificity testing against other affective states
- comparison with acute pain prediction models
- extension of the model to clinical pain datasets

---

# References

Kohoutová et al., Nature Neuroscience (2022)  
Gordon et al., Neuron (2017)  
Lee et al., Nature Medicine (2021)  
Zhou et al., bioRxiv (2023)
