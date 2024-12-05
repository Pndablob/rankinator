from beir import util, LoggingHandler
from beir.retrieval import models
from beir.datasets.data_loader import GenericDataLoader
from beir.retrieval.evaluation import EvaluateRetrieval
from beir.retrieval.search.dense import DenseRetrievalExactSearch as DRES

import logging
import pathlib
import os
import csv

#### Just some code to print debug information to stdout
logging.basicConfig(
    format="%(asctime)s - %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
    level=logging.INFO,
    handlers=[LoggingHandler()],
)
#### /print debug information to stdout

# List of models
models_list = [
    'all-mpnet-base-v2',
    'all-distilroberta-v1',
    'all-MiniLM-L12-v2',
    'all-MiniLM-L6-v2',
    'paraphrase-albert-small-v2',
    'paraphrase-MiniLM-L3-v2',
    'multi-qa-mpnet-base-dot-v1',
    'multi-qa-distilbert-cos-v1',
    'multi-qa-MiniLM-L6-cos-v1',
]

# List of datasets
datasets_list = [
    'scifact',
    'trec-covid',
    'webis-touche2020',
    'fiqa',
    'hotpotqa',
    'quora',
    'nq',
    'dbpedia-entity',
]

# Read existing results and collect completed tasks
completed_tasks = set()
if os.path.exists('results.csv'):
    logging.info('Found existing results.csv. Reading completed tasks.')
    with open('results.csv', 'r', newline='') as csvfile:
        dict_reader = csv.DictReader(csvfile)
        for row in dict_reader:
            model = row['model']
            dataset = row['dataset']
            completed_tasks.add((model, dataset))
else:
    logging.info('No existing results.csv found. Starting fresh.')

file_exists = os.path.exists('results.csv')

with open('results.csv', 'a' if file_exists else 'w', newline='') as output_file:
    dict_writer = None
    for dataset in datasets_list:
        logging.info("Processing dataset: {}".format(dataset))
        try:
            url = (
                "https://public.ukp.informatik.tu-darmstadt.de/thakur/BEIR/datasets/{}.zip".format(
                    dataset
                )
            )
            out_dir = os.path.join(pathlib.Path(__file__).parent.absolute(), "datasets")
            data_path = util.download_and_unzip(url, out_dir)
            corpus, queries, qrels = GenericDataLoader(data_folder=data_path).load(split="test")
        except Exception as e:
            logging.error("Error loading dataset '{}': {}".format(dataset, e))
            continue  # Skip to the next dataset

        for model_name in models_list:
            if (model_name, dataset) in completed_tasks:
                logging.info("Skipping model: {}, dataset: {} (already completed)".format(model_name, dataset))
                continue
            logging.info("Processing model: {}".format(model_name))
            try:
                model = DRES(models.SentenceBERT(model_name), batch_size=16)
                retriever = EvaluateRetrieval(model, score_function="dot")  # or "cos_sim" for cosine similarity
                results = retriever.retrieve(corpus, queries)
                ndcg, _map, recall, precision = retriever.evaluate(qrels, results, retriever.k_values)

                result_dict = {'model': model_name, 'dataset': dataset}
                result_dict.update(ndcg)
                result_dict.update(_map)
                result_dict.update(recall)
                result_dict.update(precision)

                # Initialize dict_writer if it's None
                if dict_writer is None:
                    keys = result_dict.keys()
                    dict_writer = csv.DictWriter(output_file, fieldnames=keys)
                    if not file_exists:
                        dict_writer.writeheader()

                dict_writer.writerow(result_dict)
                output_file.flush()  # Ensure data is written to file
                logging.info("Successfully processed model: {}, dataset: {}".format(model_name, dataset))
            except Exception as e:
                logging.error("Error processing model '{}' on dataset '{}': {}".format(model_name, dataset, e))
                continue  # Skip to the next model
