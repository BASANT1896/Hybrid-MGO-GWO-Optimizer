%FOR COMPARISON BETWEEN MGO/GWO AND HYBRID ALGORITHM ONLY

function compare_3_algorithms()



SearchAgents_no = 30;
Max_iteration   = 500;
Runs            = 30;                % set >1 to get meaningful mean/std
Function_name   = 'F7';
rng_seed        = 1;

save_results = true;
outfilename = sprintf('compare_MGO_Hybrid_GWO_%s_R%d_I%d.mat', Function_name, Runs, Max_iteration);

mgo_folder    = 'C:\Users\BASANT\MOUNTAIN_GAZELLE\compare_all_algos\MGO';
gwo_folder    = 'C:\Users\BASANT\MOUNTAIN_GAZELLE\compare_all_algos\GWO';
hybrid_folder = 'C:\Users\BASANT\MOUNTAIN_GAZELLE\compare_all_algos\HYBRID';

if exist(mgo_folder,'dir'); addpath(mgo_folder); fprintf('Added MGO folder: %s\n', mgo_folder); end
if exist(gwo_folder,'dir'); addpath(gwo_folder); fprintf('Added GWO folder: %s\n', gwo_folder); end
if exist(hybrid_folder,'dir'); addpath(hybrid_folder); fprintf('Added HYBRID folder: %s\n', hybrid_folder); end

% candidate names (try these to locate the functions)
mgo_names    = {'MGO','mgo'};
hybrid_names = {'hybrid','Hybrid','MGO_hybrid','mgo_hybrid'};
gwo_names    = {'GWO','gwo'};

% --------------- Problem details ---------------
[lb, ub, dim, fobj] = Get_Functions_details(Function_name);
if numel(lb) > 1
    LB = lb(1); UB = ub(1);
else
    LB = lb; UB = ub;
end


all_curves.mgo    = NaN(Runs, Max_iteration);
all_curves.hybrid = NaN(Runs, Max_iteration);
all_curves.gwo    = NaN(Runs, Max_iteration);

final_vals.mgo    = NaN(Runs,1);
final_vals.hybrid = NaN(Runs,1);
final_vals.gwo    = NaN(Runs,1);

mgo_fun    = find_working_fun(mgo_names, SearchAgents_no, Max_iteration, LB, UB, dim, fobj);
hybrid_fun = find_working_fun(hybrid_names, SearchAgents_no, Max_iteration, LB, UB, dim, fobj);
gwo_fun    = find_working_fun(gwo_names, SearchAgents_no, Max_iteration, LB, UB, dim, fobj);

fprintf('Using functions: MGO -> %s, Hybrid -> %s, GWO -> %s\n', mgo_fun, hybrid_fun, gwo_fun);


rng(rng_seed);
for r = 1:Runs
    fprintf('Run %d / %d\n', r, Runs);
    seed_state = rng;
    % MGO
    rng(seed_state);
    try
        [BestF, ~, cnvg] = feval(mgo_fun, SearchAgents_no, Max_iteration, LB, UB, dim, fobj);
    catch ME
        warning('MGO failed on run %d: %s', r, ME.message);
        BestF = NaN; cnvg = NaN(1, Max_iteration);
    end
    cnvg = ensure_length(cnvg, Max_iteration);
    all_curves.mgo(r,:) = cnvg;
    final_vals.mgo(r) = BestF;

    % HYBRID
    rng(seed_state);
    try
        [BestF_h, ~, cnvg_h] = feval(hybrid_fun, SearchAgents_no, Max_iteration, LB, UB, dim, fobj);
    catch ME
        warning('Hybrid failed on run %d: %s', r, ME.message);
        BestF_h = NaN; cnvg_h = NaN(1, Max_iteration);
    end
    cnvg_h = ensure_length(cnvg_h, Max_iteration);
    all_curves.hybrid(r,:) = cnvg_h;
    final_vals.hybrid(r) = BestF_h;

    % GWO
    rng(seed_state);
    try
        [BestF_g, ~, cnvg_g] = feval(gwo_fun, SearchAgents_no, Max_iteration, LB, UB, dim, fobj);
    catch ME
        warning('GWO failed on run %d: %s', r, ME.message);
        BestF_g = NaN; cnvg_g = NaN(1, Max_iteration);
    end
    cnvg_g = ensure_length(cnvg_g, Max_iteration);
    all_curves.gwo(r,:) = cnvg_g;
    final_vals.gwo(r) = BestF_g;
end

%STATISTICS:
median_mgo    = median(all_curves.mgo, 1);
median_hybrid = median(all_curves.hybrid, 1);
median_gwo    = median(all_curves.gwo, 1);

p25_mgo = prctile(all_curves.mgo, 25, 1); p75_mgo = prctile(all_curves.mgo, 75, 1);
p25_hybrid = prctile(all_curves.hybrid, 25, 1); p75_hybrid = prctile(all_curves.hybrid, 75, 1);
p25_gwo = prctile(all_curves.gwo, 25, 1); p75_gwo = prctile(all_curves.gwo, 75, 1);

mean_final.mgo   = mean_ignore_nan(final_vals.mgo);
median_final.mgo = median_ignore_nan(final_vals.mgo);
std_final.mgo    = std_ignore_nan(final_vals.mgo);
best_overall.mgo = min(final_vals.mgo);
worst_final.mgo  = max(final_vals.mgo);

mean_final.hybrid   = mean_ignore_nan(final_vals.hybrid);
median_final.hybrid = median_ignore_nan(final_vals.hybrid);
std_final.hybrid    = std_ignore_nan(final_vals.hybrid);
best_overall.hybrid = min(final_vals.hybrid);
worst_final.hybrid  = max(final_vals.hybrid);

mean_final.gwo   = mean_ignore_nan(final_vals.gwo);
median_final.gwo = median_ignore_nan(final_vals.gwo);
std_final.gwo    = std_ignore_nan(final_vals.gwo);
best_overall.gwo = min(final_vals.gwo);
worst_final.gwo  = max(final_vals.gwo);


fprintf('\nSummary (final iteration statistics):\n');
fprintf('Algorithm | mean_final | median_final | std_final | best | worst\n');
fprintf('MGO    | %g | %g | %g | %g | %g\n', mean_final.mgo, median_final.mgo, std_final.mgo, best_overall.mgo, worst_final.mgo);
fprintf('Hybrid | %g | %g | %g | %g | %g\n', mean_final.hybrid, median_final.hybrid, std_final.hybrid, best_overall.hybrid, worst_final.hybrid);
fprintf('GWO    | %g | %g | %g | %g | %g\n', mean_final.gwo, median_final.gwo, std_final.gwo, best_overall.gwo, worst_final.gwo);


iters = 1:Max_iteration;
fig = figure('Name','Convergence Comparison - MGO/Hybrid/GWO','NumberTitle','off');
ax = gca();
hold(ax,'on');

alpha_val = 0.18;

if all(~isnan(p25_mgo))
    hpatch_mgo = fill([iters fliplr(iters)], [p25_mgo fliplr(p75_mgo)], [0.85 0.92 1], 'EdgeColor','none');
    set(hpatch_mgo ,'FaceAlpha', alpha_val);
    % hide patches from legend
    try set(get(hpatch_mgo,'Annotation'),'LegendInformation',struct('IconDisplayStyle','off')); end
end
if all(~isnan(p25_hybrid))
    hpatch_hybrid = fill([iters fliplr(iters)], [p25_hybrid fliplr(p75_hybrid)], [0.95 0.95 0.95], 'EdgeColor','none');
    set(hpatch_hybrid,'FaceAlpha', alpha_val);
    try set(get(hpatch_hybrid,'Annotation'),'LegendInformation',struct('IconDisplayStyle','off')); end
end
if all(~isnan(p25_gwo))
    hpatch_gwo = fill([iters fliplr(iters)], [p25_gwo fliplr(p75_gwo)], [0.92 0.98 0.92], 'EdgeColor','none');
    set(hpatch_gwo,'FaceAlpha', alpha_val);
    try set(get(hpatch_gwo,'Annotation'),'LegendInformation',struct('IconDisplayStyle','off')); end
end


c_mgo = [0 0.447 0.741];
c_hybrid = [0 0 0];
c_gwo = [0.466 0.674 0.188];

h1 = semilogy(iters, median_mgo, 'LineWidth', 1.8, 'Color', c_mgo);
h2 = semilogy(iters, median_hybrid, 'LineWidth', 1.8, 'Color', c_hybrid);
h3 = semilogy(iters, median_gwo, 'LineWidth', 1.8, 'Color', c_gwo);


set(h1,'HandleVisibility','on'); set(h2,'HandleVisibility','on'); set(h3,'HandleVisibility','on');

legend([h1 h2 h3], {'MGO','Hybrid','GWO'}, 'Location', 'northeast');
xlabel('Iteration');
ylabel('Best score (log scale)');
title(sprintf('Median Convergence over %d Runs on %s', Runs, Function_name));

grid(ax,'off');
box(ax,'on');
hold(ax,'off');


if save_results
    saveVars = {'all_curves','final_vals','median_mgo','median_hybrid','median_gwo', ...
                'mean_final','median_final','std_final','best_overall','worst_final', ...
                'SearchAgents_no','Max_iteration','Runs','Function_name'};
    try
        save(outfilename, saveVars{:});
        fprintf('Saved results to %s\n', fullfile(pwd,outfilename));
    catch ME1
        warning('Could not save to "%s": %s', outfilename, ME1.message);
        try
            tmpfile = fullfile(tempdir, outfilename);
            save(tmpfile, saveVars{:});
            fprintf('Saved results to temp folder: %s\n', tmpfile);
        catch ME2
            warning('Could not save to tempdir: %s\n', ME2.message);
            % last fallback: user's Documents (best-effort)
            try
                if ispc
                    userFolder = getenv('USERPROFILE');
                    docs = fullfile(userFolder,'Documents');
                else
                    userFolder = getenv('HOME');
                    docs = fullfile(userFolder,'Documents');
                end
                if ~exist(docs,'dir'), docs = userFolder; end
                altfile = fullfile(docs, outfilename);
                save(altfile, saveVars{:});
                fprintf('Saved results to user folder: %s\n', altfile);
            catch ME3
                warning('All save attempts failed: %s', ME3.message);
            end
        end
    end
end

end


function name = find_working_fun(candidates, N, MaxIter, LB, UB, dim, fobj)

name = '';
for k = 1:length(candidates)
    fname = candidates{k};
    try
        testMaxIter = max(1, min(5, MaxIter));
        feval(fname, N, testMaxIter, LB, UB, dim, fobj); %#ok<FEVAL>
        name = fname;
        return;
    catch
        % try next
    end
end
error('None of the candidate function names worked. Tried: %s', strjoin(candidates, ', '));
end

function vec = ensure_length(cnvg, L)

if isempty(cnvg)
    vec = NaN(1,L);
    return;
end
cnvg = cnvg(:)'; % row
n = numel(cnvg);
if n >= L
    vec = cnvg(1:L);
elseif n == 0
    vec = NaN(1,L);
else
    lastv = cnvg(end);
    vec = [cnvg, repmat(lastv, 1, L-n)];
end
end

function m = mean_ignore_nan(X)

X = double(X);
m = NaN(1, size(X,2));
for j = 1:size(X,2)
    col = X(:,j);
    col = col(~isnan(col));
    if ~isempty(col), m(j) = sum(col)/numel(col); end
end
end

function s = std_ignore_nan(X)

X = double(X);
s = NaN(1, size(X,2));
for j = 1:size(X,2)
    col = X(:,j);
    col = col(~isnan(col));
    if numel(col) > 1
        mu = sum(col)/numel(col);
        s(j) = sqrt(sum((col-mu).^2)/(numel(col)-1));
    elseif numel(col) == 1
        s(j) = 0;
    end
end
end

function med = median_ignore_nan(X)

X = double(X);
med = NaN(1, size(X,2));
for j = 1:size(X,2)
    col = sort(X(~isnan(X(:,j)), j));
    if ~isempty(col)
        L = numel(col);
        if mod(L,2)==1
            med(j) = col((L+1)/2);
        else
            med(j) = 0.5*(col(L/2)+col(L/2+1));
        end
    end
end
end



