import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
from scipy import stats
import numpy as np

# Load and Clean the Data
df = pd.read_csv('sample_paired_data.csv', header=[0, 1])

box_palette = {"PRE": "#FFFFFF", "POST": "#E0E0E0"} 
    

new_columns = []
last_valid = None
for top, bottom in df.columns:
    if "Unnamed" in str(top) or top.startswith("Unnamed"):
        top = last_valid
    else:
        last_valid = top
    if "Unnamed" in str(bottom):
        bottom = ""
    new_columns.append((top, bottom))

df.columns = pd.MultiIndex.from_tuples(new_columns)


df = df[pd.to_numeric(df[('ID', '')], errors='coerce').notnull()] 

# IMPORTANT: Replace COLUMN_NAME with the correct column name based on CSV, should be EXACTLY the same as the column name in the CSV. 
# THIS WOULD BE YOUR SUBJECTS COLUMN.

df = df.set_index(('ID', '')) 

# PLOTTING LOOP:

categories = ['Measure_A', 'Measure_B', 'Measure_C'] # Replace TOTAL with the correct column name based on CSV, should be EXACTLY the same as the column name in the CSV. 
                        # IMPORTANT: this is the main header for the column name. If there are multiple columns, add them to the list.
jitter_amount = 0.01

fig, axes = plt.subplots(1, 3, figsize=(18, 9)) # IMPORTANT: change (1, 1) to the number of plots you want. 

for i, cat in enumerate(categories):
    ax = axes[i]
    
    pre_scores = df[cat]['PRE'].astype(float)
    post_scores = df[cat]['POST'].astype(float)
    
    # Significance Test (Paired T-Test)
    clean_indices = pre_scores.notna() & post_scores.notna()
    pre_clean = pre_scores[clean_indices].reset_index(drop=True)
    post_clean = post_scores[clean_indices].reset_index(drop=True)
    
    t_stat, p_val = stats.ttest_rel(pre_clean, post_clean)
    print("\n" + "="*30)
    print(f" Statistical Analysis ({cat})")
    print("="*30)
    print(f"Mean (Pre):  {pre_clean.mean():.4f}")
    print(f"Std  (Pre):  {pre_clean.std():.4f}")
    print(f"Mean (Post): {post_clean.mean():.4f}")
    print(f"Std  (Post): {post_clean.std():.4f}")
    significance = "Significant" if p_val < 0.05 else "NS"
    print(f"P-value:     {p_val:.5f} ({significance})")
    print("-" * 30)
    
    
   
    np.random.seed(42)
    jitter_values = [np.random.uniform(-jitter_amount, jitter_amount) 
                     for _ in range(len(pre_clean))]

    #  Spaghetti lines (solid)
    for j, jitter in enumerate(jitter_values):
        ax.plot([0 + jitter, 1 + jitter],
                [pre_clean[j], post_clean[j]],
                color='black', alpha=0.4, linewidth=1, zorder=3)

    #  Boxplot
    plot_data = pd.DataFrame({
        'Timepoint': ['PRE'] * len(pre_clean) + ['POST'] * len(post_clean),
        'Score': pd.concat([pre_clean, post_clean])
    })
    
    sns.boxplot(x='Timepoint', y='Score', data=plot_data, ax=ax, 
                width=0.2,
                palette=box_palette,
                hue='Timepoint', 
                legend=False,
                zorder=1,
                linewidth=1,
                boxprops=dict(edgecolor="black", alpha=0.7),
                whiskerprops=dict(color="black", linewidth=2),
                capprops=dict(color="black", linewidth=2),
                medianprops=dict(color="black", linewidth=2.5))
    
    # Dots (manually jittered to match line endpoints)
    for j, jitter in enumerate(jitter_values):
        ax.scatter(0 + jitter, pre_clean[j], color='black', s=16, zorder=4, alpha=0.5)
        ax.scatter(1 + jitter, post_clean[j], color='black', s=16, zorder=4, alpha=0.5)

    #  Significance Bracket
    y_max = plot_data['Score'].max()
    h = y_max * 0.05
    y_line = y_max + h
    y_text = y_line + h
    
    ax.plot([0, 0, 1, 1], [y_line, y_line+h, y_line+h, y_line], lw=2, c='k')
    
    significance = "ns"
    if p_val < 0.001: significance = "***"
    elif p_val < 0.01: significance = "**"
    elif p_val < 0.05: significance = "*"
    
    ax.text(0.5, y_text, f"{significance}\np={p_val:.5f}", 
            ha='center', va='bottom', color='black', fontsize=13)
    
    ax.set_title(f"{cat}", fontsize=18) # IMPORTANT: change this for title
    ax.set_ylim(top=y_text + (y_max * 0.1))  # removed bottom=0
    ax.set_ylabel("Score" if i==0 else "", fontsize=18) # IMPORTANT: change this for y-axis label
    ax.set_xlabel("Timepoint", fontsize=18) # IMPORTANT: change this for x-axis label
    ax.tick_params(axis='x', labelsize=16)
    
    # Dotted grid
    ax.grid(linestyle='--', linewidth=0.7)
    ax.set_axisbelow(True)  # keeps grid behind the plot elements

plt.tight_layout()
plt.show()
