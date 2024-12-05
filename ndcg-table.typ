#import "@preview/tabut:1.0.2": tabut, records-from-csv
#import "@preview/oxifmt:0.2.1": strfmt

#set page(margin: 4em)
#set align(center)

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

// Load the CSV data
#let results = records-from-csv(csv("results.csv"))

#let test = results.filter(r => r.dataset == "fiqa")

#let transform_data(data) = {
  let datasets = data.map(row => row.dataset).dedup().sorted()
  
  let models = data.map(row => row.model).dedup().sorted()
  
  let transformed = ()
  
  for dataset in datasets {
    let entry = (
      "dataset": dataset
    )
    for model in models {
      let matching_row = data.find(row => row.dataset == dataset and row.model == model)
      entry.insert(model, matching_row.at("NDCG@10"))
    }
    transformed.push(entry)
  }
  return transformed
}
#let data = transform_data(results)
#let models = data.at(0).keys().slice(1,)
#let datasets = data.map(r => r.dataset)

// Find maximum values for each metric (including ties)
#let minmax_values = datasets.fold((:), (acc, dataset) => acc + (
  (dataset): {
    let sorted = data.find(r => r.dataset == dataset).values().slice(1,).sorted()
    (sorted.first(), sorted.last())
  }
))

#let colDefs = (
  (header: [Dataset], func: r => [#r.dataset]),
  ..models.map(model => (
    header: rotate(90deg, reflow: true)[#model],
    func: r => {
      let value = float(r.at(model))
      let rounded_value = calc.round(value, digits: 3)
      let min_value = minmax_values.at(r.dataset).first()
      let max_value = minmax_values.at(r.dataset).last()
      
      let color = int(map_range(value: rounded_value, from_min: min_value - 0.01, from_max: max_value + 0.01, to_min: 120, to_max: 0))
      text(13pt)[#if rounded_value == calc.round(max_value, digits:3) {
        [*#rounded_value*] // Bold the value
      } else {
        text(luma(color))[#rounded_value]
      }]
    }
  ))
)
#set text(11pt)
#tabut(
  data,
  colDefs,
  inset: 0.7em,
  columns: (auto,) + models.map(_ => auto),
  align: center + horizon,
  fill: (_, row) => if calc.odd(row) { luma(240) } else { luma(220) },
  stroke: none
)