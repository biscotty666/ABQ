#' ---
#' title: Albuquerque Demographics
#' ---
#'

library(tidycensus)
library(tidyverse)
library(ggspatial)
library(sf)
library(units)
library(crsuggest)
library(gt)
library(gtExtras)
library(ggtext)
library(glue)
library(patchwork)
library(janitor)
library(nngeo)
library(zeallot)
options(tigris_use_cache = TRUE)


dist_plot <- function(df) {
  ggplot(df) +
    annotation_map_tile(
      type = "osm", alpha = 0.7,
      zoomin = -1, cachedir = "~/.cache/maps/"
    ) +
    geom_sf(aes(color = district), fill = NA, linewidth = 1) +
    geom_sf_label(aes(label = district),
      fontface = "bold",
      nudge_y = 1000, nudge_x = -500, fill = "gray",
      label.padding = unit(0.1, "lines"),
      size = 3.5
    ) +
    scale_color_viridis_d() +
    theme_void() +
    labs(title = "Albuquerque Council Districts")
}

get_tables <-
  function(geography, table, labels,
           state = NULL, county = NULL,
           geometry = F) {
    if (geography != "us") state <- "NM"
    if (geography == "tract") county <- "Bernalillo"
    get_acs(
      geography = geography,
      state = state,
      county = county,
      table = table,
      year = year,
      geometry = geometry,
      cache_table = T
    ) %>%
      clean_names() %>%
      select(-2) %>%
      clean_names() %>%
      left_join(labels)
  }

get_labels <- function(table) {
  acs_vars %>%
    filter(str_detect(name, table)) %>%
    select(1:2) %>%
    mutate(
      label = str_replace(label, "Estimate!!Total:!!", ""),
      label = str_replace(label, "Estimate!!", ""),
      label = str_replace(label, ":!!", "_"),
      label = str_replace(label, ":$", "")
    ) %>%
    rename(variable = name)
}


split_dists <- function(df, vars) {
  st_intersection(df, council_dists) %>%
    mutate(
      area_split = st_area(.),
      area_pct = area_split / area,
      new_value = as.numeric(round(value * area_pct, 0))
    )
}


prepare_tables <- function(df, group, variable) {
  totals <- df %>%
    group_by_at(group) %>%
    summarise(total = sum(value))
  df %>%
    group_by_at(c(variable, group)) %>%
    summarise(value = sum(value)) %>%
    left_join(totals) %>%
    mutate(percent = value / total) %>%
    select(-c(total, value)) %>%
    pivot_wider(
      names_from = .data[[group]],
      values_from = percent
    ) %>%
    ungroup()
}

print_table <- function(df, group, title, subtitle = "") {
  df %>%
    arrange(.data[[group]]) %>%
    gt(rowname_col = group) %>%
    fmt_percent(columns = everything(), decimals = 1) %>%
    tab_style(
      style = cell_text(align = "center"),
      locations = cells_column_labels(columns = everything())
    ) %>%
    tab_header(
      title = md(title),
      subtitle = md(subtitle)
    ) %>%
    tab_source_note(source_note = md("*Source: census.gov, acs5, 2023*")) %>%
    tab_style(
      style = cell_text(align = "right"),
      locations = cells_source_notes()
    ) %>%
    gt_theme_espn() %>%
    opt_align_table_header(align = "center") %>%
    cols_align(align = "center", columns = everything()) %>%
    data_color(
      palette = "RColorBrewer::RdBu", direction = "row",
      method = "bin"
    )
}


calculate_dist_percents <- function(df1, df2) {
  totals <- df1 %>%
    group_by(district) %>%
    summarise(total = sum(value))
  df2 %>%
    group_by(district) %>%
    summarise(value = sum(value)) %>%
    left_join(totals) %>%
    mutate(
      percent = value / total,
      label = glue("{round(percent, 3) * 100}%")
    )
}

map_percentage <- function(sf) {
  dist_plot(council_dists) +
    geom_sf(data = sf, aes(fill = percent), alpha = 0.35) +
    scale_fill_viridis_c() +
    geom_sf_label(
      data = council_dists, aes(label = district), fontface = "bold",
      nudge_y = 1000, nudge_x = -500, fill = "gray",
      label.padding = unit(0.1, "lines"), size = 3.5
    ) +
    geom_sf_label(
      data = sf,
      aes(label = label),
      fill = "grey", nudge_y = -1000
    ) +
    guides(color = "none") +
    labs(
      title = "Percentage of the population",
      caption = source
    )
}


compare_plot <- function(df, fill, x_var, position = "fill") {
  df %>%
    ggplot(aes(
      x = .data[[x_var]],
      y = value,
      fill = .data[[fill]]
    )) +
    geom_col(position = position) +
    scale_fill_viridis_d() +
    theme(axis.title = element_blank()) +
    labs(caption = source)
}


mf_plot <- function(df, groups, pos) {
  df %>%
    group_by_at(groups) %>%
    summarise(value = sum(value)) %>%
    mutate(value = ifelse(sex == "Male", -value, value)) %>%
    ggplot(aes(x = value, y = .data[[groups[pos]]], fill = sex)) +
    geom_col() +
    theme(
      axis.ticks = element_blank(),
      axis.text.x = element_blank(),
      axis.title.y = element_blank()
    )
}


race_clean <- function(df, area) {
  df %>%
    filter(str_detect(label, "_")) %>%
    separate(label, c("hisp", "race"), sep = "_") %>%
    {
      if (area) {
        select(., geoid, hisp, race, value = estimate, area)
      } else {
        select(., hisp, race, value = estimate)
      }
    } %>%
    mutate(
      hisp = if_else(hisp == "Not Hispanic or Latino",
        "Non-Hispanic", "Hispanic"
      ),
      race = str_replace(race, " alone$", ""),
      race = if_else(str_detect(race, "Two"), "Two or more races", race),
      race = if_else(str_detect(race, "Black"), "Black", race),
      race = if_else(str_detect(race, "Indian"), "American Indian", race)
    ) %>%
    group_by(hisp, race)
}


# edu_levels <- unique(edu_bern$education)
# edu_levels <-
#   c("No HS Diploma", "High school graduate", edu_levels[-(1:11)])

simplify_education <- function(df) {
  df %>%
    mutate(
      education = case_when(
        education == "No schooling completed" |
          education == "Nursery to 4th grade" |
          education == "5th and 6th grade" |
          education == "7th and 8th grade" |
          education == "9th grade" |
          education == "10th grade" |
          education == "11th grade" |
          education == "12th grade, no diploma"
        ~ "No HS Diploma",
        education == "Some college, 1 or more years, no degree" |
          education == "Some college, less than 1 year" |
          education == "High school graduate (includes equivalency)"
        ~ "High school graduate",
        TRUE ~ education
      ),
      education = factor(education, edu_levels)
    )
}
