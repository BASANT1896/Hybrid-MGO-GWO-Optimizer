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

 # 📘 How to Use This Optimizer

You need to set up **GNU Octave** or **MATLAB**, download the repository, and run the provided optimization algorithms (MGO, GWO, and Hybrid MGO-GWO).

---

## 🛠 1. Install GNU Octave (Free & Open Source)

If you do not have MATLAB, you can use **GNU Octave**, which is completely free.

Download here:

🔗 [https://octave.org/download](https://octave.org/download)

Install it using the default settings and launch Octave after installation.

---

## 📥 2. Download or Clone This Repository

### **Option A: Download ZIP (Recommended for Beginners)**

1. Open the repository:  
   🔗 https://github.com/BASANT1896/Hybrid-MGO-GWO-Optimizer
2. Click the green **Code** button (top-right).
3. Select **Download ZIP**.
4. Extract the ZIP file to any folder on your computer.

---

### **Option B: Clone the Repository Using Git**

If you prefer using Git Command Line Interface, run the following command:

```bash
git clone https://github.com/BASANT1896/Hybrid-MGO-GWO-Optimizer.git
```


### Citations:

MGO Original Code:benyamin abdollahzadeh (2025). Mountain Gazelle Optimizer (https://in.mathworks.com/matlabcentral/fileexchange/118680-mountain-gazelle-optimizer), MATLAB Central File Exchange. Retrieved December 8, 2025.
GWO Original Code:Seyedali Mirjalili (2025). Grey Wolf Optimizer (GWO) (https://in.mathworks.com/matlabcentral/fileexchange/44974-grey-wolf-optimizer-gwo), MATLAB Central File Exchange. Retrieved December 8, 2025.
PSO Original Code:Yarpiz / Mostapha Heris (2025). Particle Swarm Optimization (PSO) (https://in.mathworks.com/matlabcentral/fileexchange/52857-particle-swarm-optimization-pso), MATLAB Central File Exchange. Retrieved December 8, 2025.


