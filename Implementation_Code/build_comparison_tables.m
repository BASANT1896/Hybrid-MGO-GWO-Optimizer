function build_comparison_tables()

    
    results_folder = pwd();
    mat_files = dir(fullfile(results_folder, "compare_many_F*.mat"));

    if isempty(mat_files)
        error("No result files found such as compare_many_F1_*.mat");
    end

   
    master_algo_list = {};
    all_results = struct();   % will hold statistics for each F

    for k = 1:length(mat_files)
        file = fullfile(results_folder, mat_files(k).name);
        printf("Loading %s\n", file);

        data = load(file);

        algos = data.algorithms(:)';
        if isempty(master_algo_list)
            master_algo_list = algos;   % store once
        end

       
        mean_final   = data.mean_final(:)';
        median_final = data.median_final(:)';
        std_final    = data.std_final(:)';
        best_final   = data.best_overall(:)';
        worst_final  = data.worst_final(:)';

       
        func_name = data.Function_name;   % example: 'F1'
        all_results.(func_name).mean   = mean_final;
        all_results.(func_name).median = median_final;
        all_results.(func_name).std    = std_final;
        all_results.(func_name).best   = best_final;
        all_results.(func_name).worst  = worst_final;
    end

  
    func_names = fieldnames(all_results);

    for i = 1:length(func_names)
        F = func_names{i};
        outname = sprintf("table_%s.csv", F);
        printf("Writing %s\n", outname);

        fid = fopen(outname, "w");

     
        fprintf(fid, "Algorithm,Mean,Median,Std,Best,Worst\n");

        for a = 1:length(master_algo_list)
            fprintf(fid, "%s,%g,%g,%g,%g,%g\n", ...
                master_algo_list{a}, ...
                all_results.(F).mean(a), ...
                all_results.(F).median(a), ...
                all_results.(F).std(a), ...
                all_results.(F).best(a), ...
                all_results.(F).worst(a));
        end

        fclose(fid);
    end

 
    big_name = "comparison_all_functions.csv";
    printf("Writing %s\n", big_name);

    fid = fopen(big_name, "w");

   
    fprintf(fid, "Function,Algorithm,Mean,Median,Std,Best,Worst\n");

    for i = 1:length(func_names)
        F = func_names{i};
        for a = 1:length(master_algo_list)
            fprintf(fid, "%s,%s,%g,%g,%g,%g,%g\n", ...
                F, master_algo_list{a}, ...
                all_results.(F).mean(a), ...
                all_results.(F).median(a), ...
                all_results.(F).std(a), ...
                all_results.(F).best(a), ...
                all_results.(F).worst(a));
        end
    end

    fclose(fid);

    printf("All comparison tables generated successfully.");
end


