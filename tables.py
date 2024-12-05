with open('results.csv', 'r') as f:
    labels = f.readline().strip().split(',')
    lines = f.readlines()[1:]

    data = {}

    for line in lines:
        line = line.strip().split(',')
        line = dict(zip(labels, line))

        # print(line['dataset'], line['model'], line['NDCG@10'], line['MAP@10'], line['Recall@10'], line['P@10'])

        # NDCG@10: 0, MAP@10: 1, Recall@10: 2, P@10: 3
        if line['dataset'] not in data:
            data[line['dataset']] = {}
        data[line['dataset']][line['model']] = [line['NDCG@10'], line['MAP@10'], line['Recall@10'], line['P@10']]

    # print(data)

    best = {}
    for dataset in data:
        best[dataset] = {}

        max_ndcg = max([float(data[dataset][model][0]) for model in data[dataset]])
        max_map = max([float(data[dataset][model][1]) for model in data[dataset]])
        max_recall = max([float(data[dataset][model][2]) for model in data[dataset]])
        max_p = max([float(data[dataset][model][3]) for model in data[dataset]])
        for model in data[dataset]:
            if float(data[dataset][model][0]) == max_ndcg:
                best[dataset]['NDCG@10'] = model
            if float(data[dataset][model][1]) == max_map:
                best[dataset]['MAP@10'] = model
            if float(data[dataset][model][2]) == max_recall:
                best[dataset]['Recall@10'] = model
            if float(data[dataset][model][3]) == max_p:
                best[dataset]['P@10'] = model

    # write best to csv
    with open('best.csv', 'w') as f:
        f.write('dataset,NDCG@10,MAP@10,Recall@10,P@10\n')
        for dataset in best:
            f.write(f"{dataset},{best[dataset]['NDCG@10']},{best[dataset]['MAP@10']},{best[dataset]['Recall@10']},{best[dataset]['P@10']}\n")

    print(best)
