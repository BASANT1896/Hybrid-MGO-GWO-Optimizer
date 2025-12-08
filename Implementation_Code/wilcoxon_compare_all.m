%% Wilcoxon: hybrid vs all other algorithms across F1..F7
clear; clc;

files = { ...
 'compare_many_F1_R30_I500.mat', ...
 'compare_many_F2_R30_I500.mat', ...
 'compare_many_F3_R30_I500.mat', ...
 'compare_many_F4_R30_I500.mat', ...
 'compare_many_F5_R30_I500.mat', ...
 'compare_many_F6_R30_I500.mat', ...
 'compare_many_F7_R30_I500.mat' };

funcNames = {'F1','F2','F3','F4','F5','F6','F7'};
algos = {'mgo','hybrid','gwo','pso','woa','sca','other'};  % order in best_vals matrix
refName = 'hybrid';

nFunc = numel(files);
nAlgo = numel(algos);

refIdx = find(strcmpi(refName, algos));

% Matrix to store p-values: rows = algorithms except hybrid, cols = F1..F7
pMatFunc = nan(nAlgo-1, nFunc);

rowNames = algos; rowNames(refIdx) = [];  % remove hybrid from rows

for f = 1:nFunc
    S = load(files{f});
    if isfield(S,'best_vals')
        data = S.best_vals;   % rows = algorithms, cols = runs
    elseif isfield(S,'finals')
        data = S.finals;
    else
        error('No best_vals or finals found in %s', files{f});
    end

    for a = 1:nAlgo
        if a == refIdx, continue; end
        xi = data(refIdx,:);       % hybrid
        xj = data(a,:);
        valid = ~isnan(xi) & ~isnan(xj);
        xi = xi(valid); xj = xj(valid);

        if exist('wilcoxon','file')
            stats = wilcoxon(xi(:), xj(:), 'Display',false, 'Plot',false);
            if isfield(stats,'p_two')
                p = stats.p_two;
            elseif isfield(stats,'p_two_tails')
                p = stats.p_two_tails;
            else
                error('No p-value found in stats');
            end
        else
            p = signrank(xi(:), xj(:));
        end

        % place p-value in matrix row × column
        r = a - (a>refIdx); % adjust index after removing hybrid row
        pMatFunc(r,f) = p;
    end
end

disp('Final 6x7 hybrid-vs-others Wilcoxon matrix:');
disp(pMatFunc);

%% Save LaTeX table
fid = fopen('wilcoxon_hybrid_across_functions.tex','w');

fprintf(fid,'\\begin{table}[ht]\\centering\\small\n');
fprintf(fid,'\\caption{Wilcoxon signed-rank: hybrid vs other algorithms across F1--F7.}\n');
fprintf(fid,'\\begin{tabular}{l%s}\\toprule\n', repmat('r',1,nFunc));
fprintf(fid,'Algorithm');
for f=1:nFunc, fprintf(fid,' & %s', funcNames{f}); end
fprintf(fid,' \\\\ \\midrule\n');

for r = 1:nAlgo-1
    fprintf(fid,'%s', rowNames{r});
    for f=1:nFunc
        fprintf(fid,' & %0.3e', pMatFunc(r,f));
    end
    fprintf(fid,' \\\\\n');
end

fprintf(fid,'\\bottomrule\\end{tabular}\n');
fprintf(fid,'\\end{table}\n');
fclose(fid);

fprintf('Saved LaTeX: wilcoxon_hybrid_across_functions.tex\n');
