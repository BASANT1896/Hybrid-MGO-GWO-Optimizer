# Hybrid MGO–GWO Optimization Framework

This repository contains the complete implementation, experimentation scripts, and analysis tools for the improved **Hybrid MGO–GWO algorithm**.

The project focuses on enhancing optimization performance through a hybridization strategy that integrates **MGO’s exploration capability** with **GWO’s exploitation mechanism**, resulting in more stable and faster convergence across a wide range of benchmark functions.

---

## 📌 Key Features & Improvements

### 1. Hybrid MGO–GWO Algorithm
- Combines the exploration strength of MGO with the exploitation refinement of GWO.
- Provides smoother convergence and reduces premature stagnation.
- Performs especially well on unimodal and narrow-valley functions (e.g., Rosenbrock).

### 2. Updated Benchmarking Framework
- Standard benchmark functions (F1–F30).
- Fully Octave/MATLAB-compatible.
- Cleaned naming conventions and structured output handling.
- Automatic generation of mean, median, std, and convergence curves.

### 3. Statistical Significance Testing
- Automated **Wilcoxon signed-rank test** pipeline.
- Produces aggregated tables summarizing whether the Hybrid algorithm significantly outperforms MGO and GWO.
- Includes scripts for multiple-function comparisons.



