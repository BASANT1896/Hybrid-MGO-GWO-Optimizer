function compare_many_algorithms()
% compare_many_algorithms - compare many optimization algos on one benchmark
% Robust version: avoids nanmedian/fragile reshape calls (safe for Octave/MATLAB).

%% ----------------- User settings -----------------
base_algos_folder = 'C:\Users\BASANT\MOUNTAIN_GAZELLE\compare_all_algos\'; % CHANGE if needed
algorithms = {'mgo','hybrid','gwo','pso','woa','sca','tsa'}; % order shown in legend
SearchAgents_no = 30;
Max_iteration   = 500;
Runs            = 30;
Function_name   = 'F7';   % F1..F23 or any benchmark recognized by Get_Functions_details
rng_seed        = 1;
save_results    = true;
outfilename     = sprintf('compare_many_%s_R%d_I%d.mat', Function_name, Runs, Max_iteration);
% --------------------------------------------------

% add the entire base folder so which() can find files already on path
if exist(base_algos_folder,'dir')
    addpath(genpath(base_algos_folder));
else
    error('Base algorithms folder not found: %s', base_algos_folder);
end

% problem details
[lb, ub, dim, fobj] = Get_Functions_details(Function_name);
if numel(lb) > 1
    LB = lb(1); UB = ub(1);
else
    LB = lb; UB = ub;
end

nAlgos = numel(algorithms);
all_curves = NaN(nAlgos, Runs, Max_iteration);
best_vals = NaN(nAlgos, Runs);

% Resolve or create callable for each algorithm
algo_callables = cell(1, nAlgos);
for a = 1:nAlgos
    name = algorithms{a};
    fprintf('Resolving algorithm: %s\n', name);

    % special-case: PSO -> prefer pso_wrapper inside PSO folder
    if strcmpi(name,'pso')
        pso_candidate = fullfile(base_algos_folder,'PSO','pso_wrapper.m');
        if exist(pso_candidate,'file')
            % use function name 'pso_wrapper' (should be on path due to addpath)
            algo_callables{a} = 'pso_wrapper';
            fprintf('  Using PSO wrapper: %s\n', pso_candidate);
            continue;
        end
    end

    % 1) first try which() (function on path)
    fname_on_path = which(name);
    if ~isempty(fname_on_path)
        algo_callables{a} = name;
        fprintf('  Found on path: %s\n', fname_on_path);
        continue;
    end

    % 2) search for folder inside base_algos_folder (case-insensitive)
    dirListing = dir(base_algos_folder);
    dirNames = {dirListing([dirListing.isdir]).name};
    % ignore '.' and '..'
    dirNames = setdiff(dirNames,{'.','..'});
    foundFolder = '';
    for k = 1:numel(dirNames)
        if strcmpi(dirNames{k}, name)
            foundFolder = fullfile(base_algos_folder, dirNames{k});
            break;
        end
    end

    if isempty(foundFolder)
        % try ANY folder that contains the algorithm name
        for k = 1:numel(dirNames)
            if contains(lower(dirNames{k}), lower(name))
                foundFolder = fullfile(base_algos_folder, dirNames{k});
                break;
            end
        end
    end

    if isempty(foundFolder)
        error('Could not locate folder or function for algorithm "%s". Looked in %s', name, base_algos_folder);
    end

    fprintf('  Found folder: %s\n', foundFolder);

    % 3) look for candidate files inside foundFolder
    files = dir(fullfile(foundFolder,'*.m'));
    filenames = {files.name};

    % priority: <name>.m or <Name>.m, then main.m/Main.m, then any file containing name
    targetFile = '';
    for variant = {sprintf('%s.m', name), sprintf('%s.m', upper(name)), sprintf('%s.m', lower(name))}
        idx = find(strcmpi(filenames, variant{1}), 1);
        if ~isempty(idx)
            targetFile = fullfile(foundFolder, filenames{idx});
            break;
        end
    end
    if isempty(targetFile)
        % look for main.m or Main.m
        idx = find(strcmpi(filenames,'main.m'),1);
        if ~isempty(idx)
            targetFile = fullfile(foundFolder, filenames{idx});
        end
    end
    if isempty(targetFile)
        % fallback: any file containing the algorithm name
        for k=1:numel(filenames)
            if contains(lower(filenames{k}), lower(name))
                targetFile = fullfile(foundFolder, filenames{k});
                break;
            end
        end
    end

    if isempty(targetFile)
        error('No .m file found in folder %s for algorithm %s', foundFolder, name);
    end

    fprintf('  Using file: %s\n', targetFile);

    % 4) determine whether targetFile defines a function (and its name) or is a script
    %    We'll try to parse the first non-empty line for "function"
    fid = fopen(targetFile,'r');
    firstFuncName = '';
    isScript = true;
    if fid ~= -1
        while ~feof(fid)
            line = strtrim(fgetl(fid));
            if isempty(line) || startsWith(line,'%'), continue; end
            % check for function declaration
            if startsWith(line,'function')
                isScript = false;
                % try to extract name after = or function <out>= <name>(...)
                % simple parse: find '(' and extract word before it
                % remove 'function' and outputs
                lineNoFun = strtrim(strrep(line,'function',''));
                % remove outputs like [a,b] =
                eqpos = strfind(lineNoFun,'=');
                if ~isempty(eqpos)
                    rhs = strtrim(lineNoFun(eqpos+1:end));
                else
                    rhs = lineNoFun;
                end
                % name is token up to '('
                par = strfind(rhs,'(');
                if ~isempty(par)
                    firstFuncName = strtrim(rhs(1:par(1)-1));
                else
                    % fallback to first token
                    tokens = regexp(rhs,'\w+','match');
                    if ~isempty(tokens), firstFuncName = tokens{1}; end
                end
            end
            break;
        end
        fclose(fid);
    end

    if ~isScript && ~isempty(firstFuncName)
        % try using that function name (should be on path because addpath(genpath(...)) was called)
        algo_callables{a} = firstFuncName;
        fprintf('  Detected function: %s (from file)\n', firstFuncName);
    else
        % create wrapper that runs the script (main-style) inside its folder
        fprintf('  Creating wrapper for script: %s\n', targetFile);
        algo_callables{a} = create_script_wrapper(foundFolder);
    end
end

% =============== run experiments =================
rng(rng_seed);
for r = 1:Runs
    fprintf('Run %d / %d\n', r, Runs);
    seed_state = rng;
    for a = 1:nAlgos
        rng(seed_state); % fairness
        callable = algo_callables{a};
        try
            % call canonical signature
            if isa(callable,'function_handle') || ischar(callable)
                [out1,out2,out3] = feval(callable, SearchAgents_no, Max_iteration, LB, UB, dim, fobj);
            else
                error('Unknown callable for algorithm %s', algorithms{a});
            end

            % normalize
            BestF = out1; BestX = out2; cnvg = out3;
            if isempty(cnvg) && ~isempty(out2) && numel(out2) > 1
                cnvg = out2;
            end
            cnvg = ensure_length(cnvg, Max_iteration);
            all_curves(a, r, :) = cnvg;
            if isnumeric(BestF) && isscalar(BestF)
                best_vals(a,r) = BestF;
            else
                best_vals(a,r) = nanmin_compat(cnvg);
            end
            fprintf('  %s: ok\n', func2str_safe(callable));
        catch ME
            warning('Algorithm %s failed on run %d: %s', algorithms{a}, r, ME.message);
            all_curves(a, r, :) = NaN(1, Max_iteration);
            best_vals(a, r) = NaN;
        end
    end
end

% ---------- Robust median-curves computation (no nanmedian / reshape) ----------
median_curves = NaN(nAlgos, Max_iteration);

for a = 1:nAlgos
    % extract slice for algorithm a
    slice = squeeze(all_curves(a,:,:)); % could be Max_iteration x Runs OR Runs x Max_iteration OR vector

    % normalize to [Max_iteration x Runs]
    if isempty(slice)
        data = NaN(Max_iteration, 1);
    elseif isvector(slice)
        v = slice(:);
        if numel(v) == Max_iteration
            data = reshape(v, [Max_iteration, 1]);
        elseif numel(v) == Runs
            % assume it's final-per-run vector -> repeat per-iteration
            data = repmat(v(:)', Max_iteration, 1); % Max_iteration x Runs
        else
            % unknown vector length: treat as single-run time series and pad/truncate
            tmp = NaN(Max_iteration,1);
            tmp(1:min(numel(v),Max_iteration)) = v(1:min(numel(v),Max_iteration));
            data = tmp;
        end
    else
        % matrix case: try to make rows = iterations
        [r,c] = size(slice);
        if r == Max_iteration
            data = slice;
        elseif c == Max_iteration
            data = slice';
        elseif r == Runs
            data = slice';
            if size(data,1) ~= Max_iteration
                data = NaN(Max_iteration, max(1,size(slice,2)));
            end
        else
            % ambiguous: create NaN matrix so medians are NaN (safe)
            data = NaN(Max_iteration, max(1,c));
        end
    end

    % now data is Max_iteration x R (R may be 1)
    R = size(data,2);

    % compute median per iteration using sorting (ignoring NaNs)
    med_row = NaN(1, Max_iteration);
    for it = 1:Max_iteration
        vals = data(it, :);
        vals = vals(~isnan(vals));
        if isempty(vals)
            med_row(it) = NaN;
        else
            vals = sort(vals);
            L = numel(vals);
            if mod(L,2) == 1
                med_row(it) = vals((L+1)/2);
            else
                med_row(it) = 0.5*(vals(L/2) + vals(L/2+1));
            end
        end
    end

    median_curves(a, :) = med_row;
end
% ---------------- end robust median computation -------------------------

% plot all on same figure
figure('Name','Convergence Comparison - All Algos','NumberTitle','off','Units','normalized','Position',[0.1 0.1 0.7 0.6]);
hold on;
iters = 1:Max_iteration;
colors = lines(nAlgos);
for a = 1:nAlgos
    semilogy(iters, median_curves(a,:), 'LineWidth', 1.6, 'Color', colors(a,:));
end
legend(algorithms,'Location','northeastoutside');
xlabel('Iteration'); ylabel('Best score (log scale)');
title(sprintf('Median Convergence over %d Runs on %s', Runs, Function_name));
axis tight; grid off; box on;
hold off;

% compute final statistics from all_curves
% ensure all_curves shape nAlgos x Runs x Max_iteration
sz = size(all_curves);
if numel(sz) == 2
    % ambiguous; attempt to reshape sen save_resultsibly only when safe
    if sz(2) == Max_iteration
        all_curves = reshape(all_curves, [sz(1), 1, sz(2)]);
    elseif sz(1) == Max_iteration
        all_curves = reshape(all_curves, [1, sz(2), sz(1)]);
    end
    sz = size(all_curves);
end

finals = squeeze(all_curves(:,:,end)); % nAlgos x Runs (or nAlgos x 1)

% ---------- Robust final statistics (no nanmedian/std overloads) ----------
% ensure finals is 2D nAlgos x Runs
if isvector(finals)
    finals = reshape(finals, [size(finals,1), max(1,size(finals,2))]); % best-effort
end

mean_final = NaN(nAlgos,1);
median_final = NaN(nAlgos,1);
std_final = NaN(nAlgos,1);
best_overall = NaN(nAlgos,1);
worst_final = NaN(nAlgos,1);

for a = 1:nAlgos
    vals = finals(a,:);
    vals = vals(~isnan(vals));
    if isempty(vals)
        continue;
    end
    % mean ignoring NaNs
    mean_final(a) = sum(vals)/numel(vals);

    % median by sort (ignoring NaNs)
    v = sort(vals);
    L = numel(v);
    if mod(L,2) == 1
        median_final(a) = v((L+1)/2);
    else
        median_final(a) = 0.5*(v(L/2) + v(L/2+1));
    end

    % std (sample std)
    if numel(vals) > 1
        m = mean_final(a);
        std_final(a) = sqrt(sum((vals - m).^2)/(numel(vals)-1));
    else
        std_final(a) = 0;
    end

    best_overall(a) = min(vals);
    worst_final(a) = max(vals);
end
% ---------------- end final stats ------------------------------

% Display table-like output
fprintf('\nSummary (final iteration statistics):\n');
fprintf('Algorithm, mean_final, median_final, std_final, best, worst\n');
for a=1:nAlgos
    fprintf('%s, %g, %g, %g, %g, %g\n', algorithms{a}, mean_final(a), median_final(a), std_final(a), best_overall(a), worst_final(a));
end

% Save results
% --- robust save with fallbacks ---
saveVars = {'algorithms','all_curves','median_curves','best_vals', ...
        'SearchAgents_no','Max_iteration','Runs','Function_name', ...
        'mean_final','median_final','std_final','best_overall','worst_final'};

% attempt 1: original outfilename (relative to pwd)
try
    save(outfilename, saveVars{:});
    fprintf('Saved results to %s\n', fullfile(pwd, outfilename));
catch ME1
    warning('Could not save to "%s": %s', outfilename, ME1.message);

    % attempt 2: save into temp directory
    try
        tmpfile = fullfile(tempdir, outfilename);
        save(tmpfile, saveVars{:});
        fprintf('Saved results to temp folder: %s\n', tmpfile);
    catch ME2
        warning('Could not save to tempdir: %s', ME2.message);

        % attempt 3: save into user's Documents or USERPROFILE
        if ispc
            userFolder = getenv('USERPROFILE');
            docs = fullfile(userFolder,'Documents');
            if ~exist(docs,'dir')
                docs = userFolder; % fallback to user profile
            end
        else
            userFolder = getenv('HOME');
            docs = fullfile(userFolder,'Documents');
            if ~exist(docs,'dir')
                docs = userFolder;
            end
        end
        try
            if ~exist(docs,'dir')
                mkdir(docs);
            end
            altfile = fullfile(docs, outfilename);
            save(altfile, saveVars{:});
            fprintf('Saved results to user folder: %s\n', altfile);
        catch ME3
            warning('Could not save to user folder: %s', ME3.message);
            error('All save attempts failed. Check folder permissions or choose a different output path.');
        end
    end
end
% --- end robust save ---


end

%% ================= helper functions =================

function wrapper = create_script_wrapper(folderPath)
% returns a function handle wrapper(N, MaxIter, LB, UB, dim, fobj)
% that cd's into folderPath, sets canonical variables, runs main.m (or any script),
% then extracts common outputs.
wrapper = @(N, MaxIter, LB, UB, dim, fobj) run_folder_script(folderPath, N, MaxIter, LB, UB, dim, fobj);
end

function [BestF, BestX, cnvg] = run_folder_script(folderPath, N, MaxIter, LB, UB, dim, fobj)
BestF = []; BestX = []; cnvg = [];
% remember cwd
curdir = pwd();
cleanupObj = onCleanup(@() cd(curdir));
cd(folderPath);

% set canonical variables that many main.m assume:
SearchAgents_no = N;
Max_iteration = MaxIter;
% also set alternative names used in some scripts:
MaxIter = MaxIter; Search_Agents = N; SearchAgentsNo = N;
Lowerbound = LB; Upperbound = UB; dimensions = dim;
LB_inside = LB; UB_inside = UB; dim_inside = dim;
Function_name = ''; % avoid conflict if main chooses its own
% provide function handle variable common names
fobj_var = fobj; objective = fobj; Func = fobj;

% identify which script to run: prefer main.m / Main.m; else the first .m in folder
if exist('main.m','file')
    scriptToRun = 'main.m';
elseif exist('Main.m','file')
    scriptToRun = 'Main.m';
else
    listing = dir('*.m');
    if isempty(listing)
        error('No .m files in folder %s', folderPath);
    end
    scriptToRun = listing(1).name;
end

% run the script (it executes in this function scope)
try
    run(scriptToRun);
catch ME
    % attempt to call as function named same as file (without extension)
    try
        fname = strtok(scriptToRun, '.');
        [BestF, BestX, cnvg] = feval(fname, N, MaxIter, LB, UB, dim, fobj); %#ok<FEVAL>
        return;
    catch ME2
        error('Running script %s in %s failed: %s', scriptToRun, folderPath, ME.message);
    end
end

% after running, attempt to extract outputs by common variable names
possibleBestF = {'BestF','bestF','best_score','Best_score','Alpha_score','Destination_fitness','Score','Leader_score'};
possibleBestX = {'BestX','bestX','best_pos','Best_pos','Destination_position','Position','Leader_pos'};
possibleCnvg  = {'cnvg','Convergence_curve','Convergence','convergence','conv','cnvg_history','bestHistory','Convergence'};

for i=1:numel(possibleBestF)
    if exist(possibleBestF{i},'var')
        BestF = eval(possibleBestF{i});
        break;
    end
end
for i=1:numel(possibleBestX)
    if exist(possibleBestX{i},'var')
        BestX = eval(possibleBestX{i});
        break;
    end
end
for i=1:numel(possibleCnvg)
    if exist(possibleCnvg{i},'var')
        cnvg = eval(possibleCnvg{i});
        break;
    end
end

% fallback: pick any numeric vector variable of reasonable length as cnvg
if isempty(cnvg)
    s = whos();
    for i=1:numel(s)
        if strcmp(s(i).class,'double') && s(i).size(1)*s(i).size(2) > 1 && s(i).size(1)*s(i).size(2) <= MaxIter
            try
                v = eval(s(i).name);
                if isnumeric(v)
                    cnvg = v(:)'; break;
                end
            catch
            end
        end
    end
end

% final fallback
if isempty(BestF) && ~isempty(cnvg)
    BestF = cnvg(end);
end
if isempty(BestX)
    BestX = NaN(1,dim);
end

% ensure cnvg is row
if ~isempty(cnvg)
    cnvg = cnvg(:)';
end

end

function vec = ensure_length(cnvg, L)
if isempty(cnvg)
    vec = NaN(1, L);
else
    cnvg = cnvg(:)';
    if numel(cnvg) < L
        vec = [cnvg, repmat(cnvg(end), 1, L-numel(cnvg))];
    else
        vec = cnvg(1:L);
    end
end
end

function v = nanmin_compat(x)
% nanmin_compat - min ignoring NaNs in a vector
if isempty(x)
    v = NaN;
    return;
end
x = x(:);
x = x(~isnan(x));
if isempty(x)
    v = NaN;
else
    v = min(x);
end
end

function s = func2str_safe(f)
if isa(f,'function_handle')
    try s = func2str(f); catch, s = '<function_handle>'; end
elseif ischar(f)
    s = f;
else
    s = '<unknown>';
end
end
