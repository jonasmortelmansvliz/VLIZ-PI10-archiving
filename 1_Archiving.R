rm(list = ls(all = TRUE))

# --- Load config ---
source("config.R")

# --- Normalize paths ---
dest_dirs <- normalizePath(dest_dirs, winslash = "/", mustWork = FALSE)
source_dir_norm <- normalizePath(source_dir, winslash = "/", mustWork = FALSE)

# --- Verify locations ---
valid_source <- dir.exists(source_dir_norm)
valid_dests  <- sapply(dest_dirs, dir.exists)
cat("Source directory exists:", valid_source, "\n")
print(setNames(valid_dests, dest_dirs))
rm(valid_dests, valid_source)

# --- Date prefix from folder name (e.g., '2025-04-22' -> '20250422') ---
date_part <- gsub("[^0-9]", "", basename(source_dir_norm))  # keep only digits

# --- Gather all files (recursively) ---
all_items <- list.files(source_dir_norm, full.names = TRUE, recursive = TRUE, include.dirs = FALSE)

# --- Progress bar setup ---
total_ops <- length(dest_dirs) * length(all_items)
pb <- utils::txtProgressBar(min = 0, max = total_ops, style = 3)
tick <- 0L
on.exit(close(pb), add = TRUE)

# --- Copy loop with renaming for .tar files ---
for (dest_dir in dest_dirs) {
  message("Copying to: ", dest_dir)
  
  for (item in all_items) {
    # Build relative path from source root
    rel_path <- sub(paste0("^", source_dir_norm), "", normalizePath(item, winslash = "/"))
    target_path <- file.path(dest_dir, rel_path)
    
    # If it's a .tar file, optionally rename to include date prefix
    base_name <- basename(item)
    if (rename_tar_with_date && grepl("\\.tar$", base_name, ignore.case = TRUE)) {
      new_base_name <- paste0(date_part, "-", tools::file_path_sans_ext(base_name), ".tar")
      target_path <- file.path(dirname(target_path), new_base_name)
    }
    
    # Ensure target directory exists
    dir.create(dirname(target_path), recursive = TRUE, showWarnings = FALSE)
    
    # Copy (skip if already present and overwrite not allowed)
    if (!file.exists(target_path) || overwrite_existing) {
      success <- file.copy(item, target_path, overwrite = overwrite_existing)
      if (!success) warning("Failed to copy: ", item)
    }
    
    # Progress tick
    tick <- tick + 1L
    utils::setTxtProgressBar(pb, tick)
  }
}

message("\nDone.")

