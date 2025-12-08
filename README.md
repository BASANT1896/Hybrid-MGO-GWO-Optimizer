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

### **Option A: Download ZIP**
1. Click the green **Code** button (top-right of repo)
2. Select **Download ZIP**
3. Extract the folder anywhere on your computer

### **Option B: Clone with Git**
```bash
git clone https://github.com/YourUsername/YourRepoName.git



### Citations:

MGO Original Code:benyamin abdollahzadeh (2025). Mountain Gazelle Optimizer (https://in.mathworks.com/matlabcentral/fileexchange/118680-mountain-gazelle-optimizer), MATLAB Central File Exchange. Retrieved December 8, 2025.
GWO Original Code:Seyedali Mirjalili (2025). Grey Wolf Optimizer (GWO) (https://in.mathworks.com/matlabcentral/fileexchange/44974-grey-wolf-optimizer-gwo), MATLAB Central File Exchange. Retrieved December 8, 2025.



