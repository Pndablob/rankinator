#import "@preview/tabut:1.0.2": tabut, records-from-csv
#import "@preview/oxifmt:0.2.1": strfmt

// Load the CSV data
#let results = records-from-csv(csv("results.csv"))

// map_range for color mapping
#let map_range(
  value: float, 
  from_min: float, 
  from_max: float, 
  to_min: float, 
  to_max: float
) = {
  (value - from_min) * (to_max - to_min) / (from_max - from_min) + to_min
}

// Datasets to include
#let datasets = (
  "scifact",
  // "msmarco",
  "trec-covid",
  "webis-touche2020",
  "fiqa",
  "hotpotqa",
  "quora"
)

// Function to convert csv values to floats
#let convert_metrics_to_float = (data, metrics) => data.map(r => {
  let new_r = (:)
  for (k, v) in r.pairs() {
    new_r.insert(k, if metrics.contains(k) { float(v) } else { v })
  }
  new_r
})

// Function to generate the table for given metrics
#let generate_metric_table = (data, metrics, metric_prefix) => {
  // Convert string values to floats for the given metrics
  let data_converted = convert_metrics_to_float(data, metrics)
  // Sort by model name
  let data_converted = data_converted.sorted(key: d => d.at("model"))
  
  // Find maximum values for each metric (including ties)
  let minmax_values = metrics.fold((:), (acc, metric) => acc + (
    (metric): {
      let sorted = data_converted.map(r => r.at(metric)).sorted()
      (sorted.first(), sorted.last())
    }
  ))

  // Define column definitions
  let colDefs = (
    (header: [*Model*], func: r => r.model),
    ..metrics.map(metric => (
      header: [*\@#metric.split("@").at(1)*], // Add backslash before @
      func: r => {
        let value = r.at(metric)
        let rounded_value = calc.round(value, digits: 3)
        
        let min_value = calc.round(minmax_values.at(metric).first(), digits: 3)
        let max_value = calc.round(minmax_values.at(metric).last(), digits: 3)
        
        let color = int(map_range(value: rounded_value, from_min: min_value - 0.01, from_max: max_value + 0.01, to_min: 150, to_max: 0))
        if rounded_value == max_value {
          [*#rounded_value*] // Bold the value
        } else {
          text(luma(color))[#rounded_value]
        }
      }
    )),
  )

  // Generate the table
  tabut(
    data_converted,
    colDefs,
    columns: (auto,) + metrics.map(_ => auto),
    align: (auto,) + metrics.map(_ => auto),
    fill: (_, row) => if calc.odd(row) { luma(240) } else { luma(220) },
    stroke: none
  )
}

/* #tabut(
  results,
  r => r,
) */

// Define metric groups
#let metric_groups = (
  "NDCG": (
    "NDCG@1", "NDCG@3", "NDCG@5", "NDCG@10", "NDCG@100", "NDCG@1000"
  ),
  "MAP": (
    "MAP@1", "MAP@3", "MAP@5", "MAP@10", "MAP@100", "MAP@1000"
  ),
  "Recall": (
    "Recall@1", "Recall@3", "Recall@5", "Recall@10", "Recall@100", "Recall@1000"
  ),
  "P": (
    "P@1", "P@3", "P@5", "P@10", "P@100", "P@1000"
  ),
)

// Generate tables for each metric group
#for (dataset) in datasets {
  for (metric_prefix, metrics) in metric_groups.pairs() {
    // Table title
    heading()[#{metric_prefix} Metrics for #dataset]
    
    // Filter data for "scifact" dataset
    let data = results.filter(r => r.dataset == dataset)
    // Generate and display the table
    generate_metric_table(data, metrics, metric_prefix)
    [#pagebreak()]
  }
}


