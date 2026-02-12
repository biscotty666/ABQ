library(tidycensus)
library(tidyverse)
library(ggspatial)
library(sf)
library(units)
library(gt)
library(gtExtras)
library(ggtext)
library(glue)
library(janitor)
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
  load_variables(year, "acs5") %>%
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

print_table <- function(df, group, title, subtitle = "", pct = T) {
  df %>%
    arrange(.data[[group]]) %>%
    gt(rowname_col = group) %>%
    {
      if (pct) {
        fmt_percent(., columns = everything(), decimals = 1)
      } else {
        fmt_number(., columns = everything(), decimals = 0)
      }
    } %>%
    tab_style(
      style = cell_text(align = "center"),
      locations = cells_column_labels(columns = everything())
    ) %>%
    tab_header(
      title = md(title),
      subtitle = md(subtitle)
    ) %>%
    tab_source_note(source_note = source) %>%
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


map_demo <- function(sf, pct = T) {
  dist_plot(council_dists) +
    {
      if (pct) {
        geom_sf(data = sf, aes(fill = percent), alpha = 0.35)
      } else {
        geom_sf(data = sf, aes(fill = value), alpha = 0.35)
      }
    } +
    {
      if (pct) {
        scale_fill_viridis_c(labels = scales::label_percent())
      } else {
        scale_fill_viridis_c(labels = scales::label_comma())
      }
    } +
    geom_sf_label(
      data = council_dists,
      aes(label = district), fontface = "bold",
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
      title = ifelse(pct, "Percentage of the population", "Population"),
      caption = source,
      fill = NULL
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
