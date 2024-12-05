#import "@preview/tabut:1.0.2": tabut, records-from-csv
#import "@preview/oxifmt:0.2.1": strfmt

#set page(margin: 1em, flipped: true)
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
  
  for model in models {
    let entry = (
      "model": model
    )
    for dataset in datasets {
      let matching_row = data.find(row => row.dataset == dataset and row.model == model)
      entry.insert(dataset, matching_row.at("NDCG@10"))
    }
    transformed.push(entry)
  }
  return transformed
}
#let data = transform_data(results)
#let datasets = data.at(0).keys().slice(1,)
#let models = data.map(r => r.model)

// Find maximum values for each metric (including ties)
#let minmax_values = datasets.fold((:), (acc, dataset) => acc + (
  (dataset): {
    let model_results = results.filter(test => test.dataset == dataset).map(res => res.at("NDCG@10")).sorted();
    (model_results.first(), model_results.last())
  }
))

#let colDefs = (
  (header: [*Models*], func: r => [#r.model]),
  ..datasets.map(dataset => (
    header: /* rotate(90deg, reflow: true) */[#dataset],
    func: r => {
      let value = float(r.at(dataset))
      let rounded_value = calc.round(value, digits: 3)
      let min_value = minmax_values.at(dataset).first()
      let max_value = minmax_values.at(dataset).last()
      
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