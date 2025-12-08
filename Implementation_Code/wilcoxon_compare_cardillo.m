function [pmat, hmat, stats_cell] = wilcoxon_compare_cardillo(resultsFileOrMatrix, algorithms, varargin)
% WILCOXON_COMPARE_CARDILLO
% Pairwise Wilcoxon signed-rank tests (with option to compare one reference
% algorithm vs all others and save a LaTeX table).
%
% Usage examples:
%  % All pairwise (default)
%  [pmat,h,stats] = wilcoxon_compare_cardillo(files, algos);
%
%  % Reference mode: compare 'hybrid' vs all others and save LaTeX
%  [pmat,h,stats] = wilcoxon_compare_cardillo(files, algos, ...
%       'Reference','hybrid','SaveLaTeX',true);
%
% Inputs:
%  - resultsFileOrMatrix: filename (string), numeric matrix (nAlgos x runs),
%                         or cell array / string array of filenames (one per algo).
%  - algorithms: cell array of names (1 x nAlgos)
%
% Optional name-value pairs:
%  'Alpha'      - significance level (default 0.05)
%  'Bonferroni' - true/false apply Bonferroni correction (default true)
%  'UsePlot'    - let wilcoxon plot (default false)
%  'Reference'  - name or index of reference algorithm (string or scalar). If empty, runs all pairwise comparisons.
%  'SaveLaTeX'  - true/false: save a LaTeX table showing Reference vs others (default true)
%  'LaTeXFile'  - filename to save LaTeX table (default: 'wilcoxon_ref_vs_others.tex')

% ---------- parse options ----------
opts = struct('Alpha',0.05,'Bonferroni',true,'UsePlot',false, ...
              'Reference',[],'SaveLaTeX',true,'LaTeXFile','wilcoxon_ref_vs_others.tex');
opts = parse_args(opts, varargin{:});
alpha = opts.Alpha;

% ---------- Octave statistics pkg auto-load (if needed) ----------
if exist('OCTAVE_VERSION','builtin')
    hasTiedrank = exist('tiedrank','file')==2 || exist('tiedrank','builtin')==5;
    if ~hasTiedrank
        try
            pkg load statistics;
            fprintf('Loaded Octave statistics package.\n');
            hasTiedrank = exist('tiedrank','file')==2 || exist('tiedrank','builtin')==5;
        catch
            warning('Could not auto-load statistics pkg. If not installed run: pkg install -forge statistics; pkg load statistics');
        end
    end
end

% ---------- load/interpret data (supports single file, numeric matrix, or list of files) ----------
if iscell(resultsFileOrMatrix) || (isstring(resultsFileOrMatrix) && ~isscalar(resultsFileOrMatrix))
    filelist = cellstr(resultsFileOrMatrix);
    nAlgos = numel(filelist);
    perFileData = cell(1,nAlgos); maxRuns = 0;
    for k=1:nAlgos
        fname = filelist{k};
        if ~exist(fname,'file'), error('File not found: %s', fname); end
        S = load(fname);
        perFileData{k} = extract_data_from_struct(S);
        perFileData{k} = perFileData{k}(:)'; maxRuns = max(maxRuns, numel(perFileData{k}));
    end
    finals = nan(nAlgos, maxRuns);
    for k=1:nAlgos, finals(k,1:numel(perFileData{k})) = perFileData{k}; end

elseif ischar(resultsFileOrMatrix) || isstring(resultsFileOrMatrix)
    fname = char(resultsFileOrMatrix);
    if exist(fname,'file')
        S = load(fname);
        if isfield(S,'best_vals'), finals = S.best_vals;
        elseif isfield(S,'finals'), finals = S.finals;
        elseif isfield(S,'all_curves')
            ac = S.all_curves; sz = size(ac);
            if numel(sz)==3, finals = squeeze(ac(:,:,end));
            else error('Cannot interpret all_curves variable shape in %s.', fname);
            end
        else
            fld = fieldnames(S); found=false;
            for f=1:numel(fld), v=S.(fld{f}); if isnumeric(v), finals=v; found=true; break; end; end
            if ~found, error('No suitable numeric var in %s', fname); end
        end
    else
        error('File not found: %s', fname);
    end

elseif isnumeric(resultsFileOrMatrix)
    finals = resultsFileOrMatrix;
else
    error('First arg must be filename, cell array of filenames, string array, or numeric matrix.');
end

% ensure finals is nAlgos x Runs
if isvector(finals), finals = reshape(finals, [size(finals,1), max(1,size(finals,2))]); end
[nAlgos, nRuns] = size(finals);

% algorithm names
if nargin < 2 || isempty(algorithms)
    algorithms = arrayfun(@(k) sprintf('A%d',k), 1:nAlgos, 'UniformOutput', false);
end
if numel(algorithms) ~= nAlgos
    warning('Number of algorithm names differs from data rows. Adjusting.');
    if numel(algorithms) < nAlgos
        for k = numel(algorithms)+1:nAlgos, algorithms{k} = sprintf('A%d',k); end
    else
        algorithms = algorithms(1:nAlgos);
    end
end

% resolve reference (if any)
refIdx = [];
if ~isempty(opts.Reference)
    if ischar(opts.Reference) || isstring(opts.Reference)
        refName = char(opts.Reference);
        refIdx = find(strcmpi(refName, algorithms), 1);
        if isempty(refIdx), error('Reference algorithm name "%s" not found among algorithms.', refName); end
    elseif isnumeric(opts.Reference) && isscalar(opts.Reference)
        refIdx = opts.Reference;
        if refIdx < 1 || refIdx > nAlgos, error('Reference index out of range.'); end
    else
        error('Reference must be a name (string) or scalar index.');
    end
end

% ---------- prepare outputs ----------
pmat = nan(nAlgos);
hmat = nan(nAlgos);          % numeric: 1 = significant, 0 = not, NaN = undefined
stats_cell = cell(nAlgos);

use_cardillo = ~isempty(which('wilcoxon'));
if use_cardillo
    fprintf('Found wilcoxon.m on path — using it (plots=%d).\n', double(opts.UsePlot));
else
    fprintf('wilcoxon.m not found: falling back to MATLAB signrank.\n');
end

% ---------- compute tests ----------
if isempty(refIdx)
    % full pairwise (original behavior)
    pairs = nchoosek(1:nAlgos,2);
else
    % only reference vs each other (ref always first column in pairs)
    others = setdiff(1:nAlgos, refIdx);
    pairs = [repmat(refIdx, numel(others),1), others(:)];
end

for k=1:size(pairs,1)
    i = pairs(k,1); j = pairs(k,2);
    xi = finals(i,:); xj = finals(j,:);
    valid = ~isnan(xi) & ~isnan(xj);
    xi = xi(valid); xj = xj(valid);
    if numel(xi) < 2
        p = NaN; stats = struct();
    else
        try
            if use_cardillo
                stats = wilcoxon(xi(:), xj(:), 'Alpha', opts.Alpha, 'Plot', opts.UsePlot, 'Display', false);
                if isfield(stats,'p_two'), p = stats.p_two;
                elseif isfield(stats,'p_two_tails'), p = stats.p_two_tails;
                else
                    fld = intersect({'p_two','p_value_two_tails','p'}, fieldnames(stats));
                    if ~isempty(fld), p = stats.(fld{1}); else p = NaN; end
                end
            else
                [p, ~, sgn_stats] = signrank(xi(:), xj(:));
                stats = struct('signrank', sgn_stats, 'method', 'signrank');
            end
        catch ME
            warning('Test failed for %s vs %s: %s', algorithms{i}, algorithms{j}, ME.message);
            p = NaN; stats = struct();
        end
    end
    pmat(i,j) = p;
    pmat(j,i) = p;
    stats_cell{i,j} = stats;
    stats_cell{j,i} = stats;
end

for i=1:nAlgos, pmat(i,i)=0; end

% ---------- multiple-comparison correction ----------
if opts.Bonferroni
    % number of tests actually performed
    m = size(pairs,1);
    adjAlpha = opts.Alpha / max(1,m);
else
    adjAlpha = opts.Alpha;
end

% Fill hmat with numeric values: 1 (significant), 0 (not), NaN (undefined)
for i=1:nAlgos
    for j=1:nAlgos
        if i==j
            hmat(i,j) = 0;
            continue;
        end
        if ~isnan(pmat(i,j))
            hmat(i,j) = double(pmat(i,j) < adjAlpha);  % 1 or 0
        else
            hmat(i,j) = NaN;
        end
    end
end

% ---------- print (compact) ----------
fprintf('\nComputed %d test(s). Bonferroni adj alpha = %g\n', size(pairs,1), adjAlpha);

% ---------- optionally save a LaTeX table (reference vs others) ----------
if opts.SaveLaTeX && ~isempty(refIdx)
    fid = fopen(opts.LaTeXFile,'w');
    if fid == -1, warning('Could not open LaTeX file for writing: %s', opts.LaTeXFile);
    else
        fprintf(fid, '%% LaTeX: Wilcoxon (Reference=%s vs others)\n', algorithms{refIdx});
        fprintf(fid, '\\begin{table}[ht]\\centering\\small\n');
        fprintf(fid, '\\caption{Wilcoxon signed-rank test: %s vs other algorithms (two-tailed p-values).}\\label{tab:wilcox_ref}\n', algorithms{refIdx});
        fprintf(fid, '\\begin{tabular}{lr}\\toprule\n');
        fprintf(fid, 'Algorithm & p-value \\\\\\midrule\n');
        for j = 1:nAlgos
            if j==refIdx, continue; end
            pv = pmat(refIdx,j);
            if isnan(pv), s='---'; else s = sprintf('%0.3e', pv); end
            if ~isnan(pv) && pv < adjAlpha
                fprintf(fid, '%s & \\textbf{%s} \\\\\n', algorithms{j}, s);
            else
                fprintf(fid, '%s & %s \\\\\n', algorithms{j}, s);
            end
        end
        fprintf(fid, '\\bottomrule\\end{tabular}\n');
        fprintf(fid, '\\begin{tablenotes}[flushleft]\\item Notes: Two-tailed Wilcoxon signed-rank p-values; bold indicates significance after Bonferroni correction (adj $\\alpha$ = %g).\\end{tablenotes}\n', adjAlpha);
        fprintf(fid, '\\end{table}\n');
        fclose(fid);
        fprintf('Saved LaTeX table: %s\n', opts.LaTeXFile);
    end
end

end

%% ---------- helpers ----------
function out = parse_args(defaults, varargin)
out = defaults;
if isempty(varargin), return; end
for k=1:2:numel(varargin)
    name = varargin{k}; val = varargin{k+1};
    if ischar(name), name = name; end
    out.(name) = val;
end
end

function data = extract_data_from_struct(S)
% extract numeric vector/matrix from loaded .mat struct
if isfield(S,'best_vals'), data = S.best_vals;
elseif isfield(S,'finals'), data = S.finals;
elseif isfield(S,'all_curves')
    ac = S.all_curves; sz = size(ac);
    if numel(sz)==3, data = squeeze(ac(:,:,end));
    else error('Cannot interpret all_curves variable shape.');
    end
else
    fld = fieldnames(S); found=false;
    for f=1:numel(fld), v=S.(fld{f}); if isnumeric(v), data=v; found=true; break; end; end
    if ~found, error('No numeric data found in file.'); end
end
end
