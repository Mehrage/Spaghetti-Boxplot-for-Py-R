library(tidyverse)
library(patchwork)  # install.packages("patchwork") if needed

# IMPORTANT : Recommended CSV file layout can be provided upon request for code to work. 

# ── Load & fix two-row header ─────────────────────────────────────────────────

raw <- read.csv("FILE_PATH_HERE", header = FALSE)

# Row 1: top-level names — forward-fill blanks
top_row <- as.character(raw[1, ])
for (i in seq_along(top_row)) {
  if (top_row[i] == "" || is.na(top_row[i])) top_row[i] <- top_row[i - 1]
}

# Row 2: PRE / POST / Subject label / grabs second row which usually contains pre and post labels
bot_row <- as.character(raw[2, ])

# Combine into single column names, e.g. "ARAT_PRE", "ARAT_POST"
# For the subject column, bot_row will have something like "Subject" — keep as-is
col_names <- ifelse(
  bot_row %in% c("PRE", "POST"),
  paste(top_row, bot_row, sep = "_"),
  bot_row
)

df <- raw[-(1:2), ]           # choose what rows / columns to keep and use. 
colnames(df) <- c("SUBJECTS", "BAYCREST", "TOTAL_PRE", "TOTAL_POST")# IMPORTANT : if there are sub columns used "MAIN_SUB" notation as seen in "TOTAL_POST"
df <- type.convert(df, as.is = TRUE)  # auto-convert numeric columns

# ── Settings ──────────────────────────────────────────────────────────────────

subject_col   <- "Subjects"    # adjust if your subject column has a different name
categories    <- c("TOTAL")  # replace with your actual category names : example CSV used has "TOTAL" column with two sub-columns. 
jitter_amount <- 0.01        # If multiple figures are needed side by side, add the category name / column name desired to be graphed.
set.seed(42)

# ── Helper: build one plot + print stats ──────────────────────────────────────

make_plot <- function(cat, df, first = FALSE) {
  
  pre_col  <- paste0(cat, "_PRE")
  post_col <- paste0(cat, "_POST")
  
  pre_scores  <- as.numeric(df[[pre_col]])
  post_scores <- as.numeric(df[[post_col]])
  
  clean_idx  <- !is.na(pre_scores) & !is.na(post_scores)
  pre_clean  <- pre_scores[clean_idx]
  post_clean <- post_scores[clean_idx]
  n          <- length(pre_clean)
  
  # ── Paired t-test ──────────────────────────────────────────────────────────
  
  t_result <- t.test(pre_clean, post_clean, paired = TRUE)
  p_val    <- t_result$p.value
  
  cat("\n", strrep("=", 30), "\n")
  cat(sprintf(" Statistical Analysis (%s)\n", cat))
  cat(strrep("=", 30), "\n")
  cat(sprintf("Mean (Pre):  %.4f\n", mean(pre_clean)))
  cat(sprintf("Std  (Pre):  %.4f\n",   sd(pre_clean)))
  cat(sprintf("Mean (Post): %.4f\n", mean(post_clean)))
  cat(sprintf("Std  (Post): %.4f\n",   sd(post_clean)))
  cat(sprintf("P-value:     %.5f (%s)\n", p_val,
              if (p_val < 0.05) "Significant" else "NS"))
  cat(strrep("-", 30), "\n")
  
  # ── Stars ──────────────────────────────────────────────────────────────────
  
  stars <- "ns"
  if      (p_val < 0.001) stars <- "***"
  else if (p_val < 0.01)  stars <- "**"
  else if (p_val < 0.05)  stars <- "*"
  
  # ── Tidy data ──────────────────────────────────────────────────────────────
  
  jitter_vals <- runif(n, -jitter_amount, jitter_amount)
  
  plot_df <- data.frame(
    Timepoint = factor(rep(c("PRE", "POST"), each = n), levels = c("PRE", "POST")),
    Score     = c(pre_clean, post_clean)
  )
  
  spag_df <- data.frame(
    id    = rep(seq_len(n), 2),
    x_jit = c(1 + jitter_vals, 2 + jitter_vals),
    Score = c(pre_clean, post_clean)
  )
  
  # ── Bracket positions ──────────────────────────────────────────────────────
  
  y_max  <- max(plot_df$Score, na.rm = TRUE)
  h      <- y_max * 0.05
  y_line <- y_max + h
  y_text <- y_line + (h * 1.18) # This setting should position the p value right above the bracket.
  label  <- sprintf("%s\np=%.5f", stars, p_val) 
  
  # ── ggplot ─────────────────────────────────────────────────────────────────
  
  ggplot(plot_df, aes(x = Timepoint, y = Score)) +
    
    geom_boxplot(aes(fill = Timepoint),
                 width = 0.2, linewidth = 0.5, # change for box width and width of lines around the boxes
                 outlier.shape = NA, color = "black", alpha = 0.7) +
    scale_fill_manual(values = c("PRE" = "white", "POST" = "#E0E0E0")) +
    
    geom_line(data = spag_df,
              aes(x = x_jit, y = Score, group = id),
              color = "black", alpha = 0.4, linewidth = 0.5) +
    
    geom_point(data = spag_df,
               aes(x = x_jit, y = Score),
               color = "black", size = 1.5, alpha = 0.5) +
    
    # Significance bracket
    annotate("segment", x = 1, xend = 1, y = y_line, yend = y_line + h) +
    annotate("segment", x = 2, xend = 2, y = y_line, yend = y_line + h) +
    annotate("segment", x = 1, xend = 2, y = y_line + h, yend = y_line + h) +
    annotate("text", x = 1.5, y = y_text, label = label,
             hjust = 0.5, vjust = 0, size = 4.5) +
    
    labs(title = "TITLE_HERE", # change this for title change
         x     = "Timepoint", # X-label.
         y     = if (first) "Score" else "") +  # y-label only on leftmost plot : change this depending on what you require. 
      #  y     = paste(cat, "Score")) + NOTE: this would allow for dynamic Y-label, each figure can have its own unique y-label.
    ylim(NA, y_text + y_max * 0.1) +
    theme_classic(base_size = 14) +
    theme(
      legend.position = "none",
      panel.grid.major = element_line(linetype = "dashed",
                                      linewidth = 0.5, color = "grey80"),
      panel.grid.minor = element_blank()
    )
}

# ── Build & combine plots ─────────────────────────────────────────────────────

plots <- lapply(seq_along(categories), function(i) {
  make_plot(categories[i], df, first = (i == 1))
})

# Stitch side-by-side with patchwork
combined <- wrap_plots(plots, nrow = 1)
print(combined)

# Optional: save to file
# ggsave("figure.png", combined, width = 4 * length(categories), height = 6, dpi = 300)