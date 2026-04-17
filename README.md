
# Paired Pre/Post Spaghetti-Boxplot
<img width="1710" height="900" alt="Figure_1" src="https://github.com/user-attachments/assets/f6144a5a-4481-4054-afd9-6637ac593782" />  

<br>

A Python script for visualizing paired pre/post measurements as combined spaghetti-boxplots with paired *t*-test significance annotations. Works with any dataset that has matched before/after observations across one or more measures — clinical outcomes, benchmark scores, A/B comparisons, etc.


## Features

- **Boxplots** for the PRE and POST distributions, side by side
- **Spaghetti lines** connecting each subject's paired scores
- **Significance brackets** rendered directly on the plot with the p-value and stars (`*`, `**`, `***`, or `ns`) from a paired *t*-test
- Clean, publication-ready styling (grayscale boxes, dashed grid, large legible fonts)
- Automatic handling of merged-cell CSV headers exported from Excel

## Requirements

```
pandas
numpy
matplotlib
seaborn
scipy
```

Install with:

```bash
pip install pandas numpy matplotlib seaborn scipy
```

## Quick Start

A sample dataset (`sample_paired_data.csv`) is included. Run the script directly:

```bash
python Spaghetti_BoxPlot_demo.py
```

This produces a 1×3 figure of spaghetti-boxplots for `Measure_A`, `Measure_B`, and `Measure_C`, plus console output with the paired *t*-test statistics for each measure.

## Data Format

The script expects a CSV with a **two-row (MultiIndex) header**:

- **Row 1:** the subject ID column name, then each measure name. You can either repeat the measure name across its PRE/POST pair, or leave the second cell blank (Excel-style merged cells) — the loader handles both.
- **Row 2:** empty under the subject ID column, then `PRE` / `POST` alternating under each measure.

Example:

| ID | Measure_A |      | Measure_B |      | Measure_C |      |
|----|-----------|------|-----------|------|-----------|------|
|    | PRE       | POST | PRE       | POST | PRE       | POST |
| 1  | 12        | 18   | 22        | 28   | 8         | 12   |
| 2  | 34        | 38   | 45        | 48   | 22        | 26   |
| …  | …         | …    | …         | …    | …         | …    |

The subject ID column must be **numeric**. This is intentional: the loader drops non-numeric rows so summary rows like `Mean` or `SD` at the bottom of the sheet are filtered out automatically.

## Using Your Own Data

Swap these values near the top of the script to point at your own CSV:

| Location | What to change |
|----------|----------------|
| `pd.read_csv('sample_paired_data.csv', …)` | Path to your CSV |
| `('ID', '')` (appears twice) | Your subject ID column name |
| `categories = [...]` | List of measure names to plot — must match the top-row headers exactly |
| `plt.subplots(1, 3, …)` | Change `3` to the number of measures |
| `ax.set_title(f"{cat}", …)` | Per-subplot title (defaults to the measure name) |
| `ax.set_ylabel(...)` / `ax.set_xlabel(...)` | Axis labels |

Rows with missing PRE or POST values for a given measure are dropped automatically before the paired *t*-test runs, so incomplete data won't break the pipeline.

## Output

For each measure, the script prints a summary block to the console:

```
==============================
 Statistical Analysis (Measure_A)
==============================
Mean (Pre):  24.8000
Std  (Pre):  13.8815
Mean (Post): 28.3500
Std  (Post): 14.0611
P-value:     0.00000 (Significant)
```

…and displays a matplotlib figure with one subplot per measure.

## License

MIT







