function stats = wilcoxon(varargin)
%WILCOXON Nonparametric Wilcoxon signed-rank test for paired samples.
%
%   STATS = WILCOXON(X1, X2)
%   STATS = WILCOXON(X1, X2, 'Alpha', ALPHA, 'Plot', PLOT, 'Display', DISPLAY)
%
%   This function performs the nonparametric Wilcoxon signed-rank test to
%   evaluate the difference between paired (dependent) samples.
%
%   If the number of non-zero differences is less than or equal to 15, the
%   algorithm uses the exact distribution of signed ranks. Otherwise, it
%   uses a normal distribution approximation with continuity correction.
%
%   MATLAB's SIGNRANK returns the same p-values, but this WILCOXON
%   function provides additional estimates (binomial and Hodges-Lehmann
%   estimators with confidence intervals) that are useful for publications.
%
%   Inputs:
%     X1, X2   - paired data vectors (row or column, same length).
%
%   Name–Value pair arguments:
%     'Alpha'  - significance level (scalar in (0,1), default = 0.05).
%
%     'Plot'   - logical-like flag to show diagnostic plots:
%                true  -> show Wilcoxon paired-plot and boxplot
%                false -> no plots (default)
%
%     'Display'- logical-like flag controlling command-window output:
%                true  -> print tables and messages (default)
%                false -> run silently, only return STATS
%
%   Output:
%     STATS    - structure with test results and estimators:
%                .method      - 'Exact distribution' or 'Normal approximation'
%                .n           - number of non-zero paired differences
%                .W           - Wilcoxon signed-rank statistic
%                .tieadj      - tie adjustment from tiedrank
%                .alpha       - significance level
%                .binomial.estimate - median(difference) estimator
%                .binomial.CI       - [lower upper] CI for binomial estimator
%                .HL.estimate       - Hodges-Lehmann estimator
%                .HL.CI             - [lower upper] CI for HL estimator
%                .meanW      - theoretical mean of W under H0 (0)
%                .stdW       - std(W) (NaN if exact distribution used)
%                .z          - Z value for normal approximation (NaN if exact)
%                .p_one      - one-tailed p-value (NaN if exact)
%                .p_two      - two-tailed p-value
%
%   Example:
%
%     X1 = [77 79 79 80 80 81 81 81 81 82 82 82 82 83 83 84 84 84 84 85 85 86 86 87 87];
%     X2 = [82 82 83 84 84 85 85 86 86 86 86 86 86 86 86 86 87 87 87 88 88 88 89 90 90];
%
%     % Default alpha = 0.05, no plots, with printed output:
%     wilcoxon(X1, X2)
%
%     % Alpha = 0.01, with plots, silent (no printed output):
%     stats = wilcoxon(X1, X2, 'Alpha', 0.01, 'Plot', true, 'Display', false);
%
%   Created by Giuseppe Cardillo
%   giuseppe.cardillo.75@gmail.com
%
%   To cite this file, this would be an appropriate format:
%   Cardillo G. (2006). Wilcoxon test: non parametric Wilcoxon test for
%   paired samples. Available on GitHub: https://github.com/dnafinder/wilcoxon

% -------------------------------------------------------------------------
% Input parsing
% -------------------------------------------------------------------------
narginchk(2, Inf);

x1 = varargin{1};
x2 = varargin{2};

validateattributes(x1, {'numeric'}, ...
    {'vector','real','finite','nonnan','nonempty'}, mfilename, 'X1', 1);
validateattributes(x2, {'numeric'}, ...
    {'vector','real','finite','nonnan','nonempty'}, mfilename, 'X2', 2);

x1 = x1(:);
x2 = x2(:);

assert(numel(x1) == numel(x2), 'X1 and X2 must have the same length.');

% Keep originals for plotting
x1_orig = x1;
x2_orig = x2;

% Name–Value pairs
if nargin > 2
    nvArgs = varargin(3:end);
else
    nvArgs = {};
end

p = inputParser;
p.FunctionName = mfilename;
addParameter(p, 'Alpha',   0.05,  @(x) validateattributes(x,{'numeric'}, ...
    {'scalar','real','finite','nonnan','>',0,'<',1}, mfilename, 'Alpha'));
addParameter(p, 'Plot',    false, @validateLogicalLike);
addParameter(p, 'Display', true,  @validateLogicalLike);
parse(p, nvArgs{:});

alpha       = p.Results.Alpha;
plotFlag    = logical(normalizeLogicalLike(p.Results.Plot));
displayFlag = logical(normalizeLogicalLike(p.Results.Display));

% -------------------------------------------------------------------------
% Wilcoxon signed-rank test computations
% -------------------------------------------------------------------------
if displayFlag
    disp('WILCOXON TEST');
    disp(' ');
end

% Differences
dff = x2 - x1;
dff(dff == 0) = [];       % eliminate null variations
n   = numel(dff);         % number of non-zero differences

if n < numel(x1)
    if displayFlag
        fprintf('There are %d null variations that will be deleted\n', numel(x1) - n);
    end
end

if isempty(dff)
    % All variations are zero: test cannot be performed
    if displayFlag
        disp('There are no variations. Wilcoxon test cannot be performed.');
    end
    stats = struct([]);
    return;
end

% Ranks of absolute differences with sign
[dRanks, tieadj] = tiedrank(abs(dff));   % ranks and ties
W                 = sum(dRanks .* sign(dff));  % Wilcoxon statistic (sum of signed ranks)

% Binomial estimator of median difference
dff_sorted = sort(dff);
pem        = median(dff_sorted);   % point estimate of median of differences
m          = ceil(n/2);            % location of the median

if mod(n,2) == 0
    % If even length, insert the median in the middle
    tmp        = [dff_sorted(1:m); pem; dff_sorted(m+1:end)];
    dff_sorted = tmp;
    clear tmp
    m = m + 1;
end

% Binomial confidence interval around the median
C = cumsum(binopdf(0:1:n, n, 0.5));
T = find(C <= alpha/2, 1, 'last') - 1;
if isempty(T)
    T = 0;
end
cintpem = dff_sorted([m-T, m+T]).';

% Hodges-Lehmann estimator via Walsh averages
[I,J] = ndgrid(dff_sorted, dff_sorted);
dWalsh = triu(I + J) / 2;
ld     = sort(dWalsh(dWalsh ~= 0));
clear I J dWalsh

HLe = median(ld);

if n > 15
    A   = n*(n+1)/4;
    B   = sqrt(n*(n+1)*(2*n+1)/24);
    Za  = -sqrt(2).*erfcinv(2.*(1-alpha/2));
    Tci = fix(A - Za.*B);
else
    TC  = [0 0 0 0 0 0 2 3 5 8 10 13 17 21 25];
    Tci = TC(n);
end
cintHLe = ld([Tci+1, end-Tci]).';

% Display estimators and CIs
if displayFlag
    Testim = table( ...
        [pem; HLe], ...
        [cintpem; cintHLe], ...
        'VariableNames', {'Mean_of_differences','Confidence_interval'}, ...
        'RowNames', {'Binomial_estimator','Hodges_Lehmann_estimator'});
    disp(Testim);
end

% -------------------------------------------------------------------------
% Exact vs normal approximation
% -------------------------------------------------------------------------
stats = struct();
stats.n        = n;
stats.W        = W;
stats.tieadj   = tieadj;
stats.alpha    = alpha;
stats.binomial = struct('estimate', pem, 'CI', cintpem(:).');
stats.HL       = struct('estimate', HLe, 'CI', cintHLe(:).');

if n <= 15
    % Exact distribution of signed ranks
    ap = ff2n(n);          % all sign combinations (2-level full factorial design)
    ap(ap ~= 1) = -1;      % change 0 to -1
    k  = (1:n).';          % ranks 1..n
    J  = ap * k;           % all possible sums of signed ranks
    
    p_two = numel(J(abs(J) >= abs(W))) / numel(J);  % two-tailed p-value
    
    if displayFlag
        disp(' ');
        disp('The exact Wilcoxon distribution was used');
        disp(' ');
        Tres = table(W, p_two, 'VariableNames', {'W','p_value_two_tails'});
        disp(Tres);
    end
    
    stats.method = 'Exact distribution';
    stats.meanW  = 0;
    stats.stdW   = NaN;
    stats.z      = NaN;
    stats.p_one  = p_two / 2;
    stats.p_two  = p_two;
else
    % Normal approximation
    mW  = 0;
    sW  = sqrt((2*n^3 + 3*n^2 + n - tieadj) / 6);  % standard deviation
    zW  = (abs(W) - 0.5) / sW;                     % z-value with continuity correction
    p   = 1 - normcdf(zW);                         % one-tailed p-value
    p_two = 2 * p;                                 % two-tailed
    
    if displayFlag
        disp(' ');
        disp('Sample size is good enough to use the normal distribution approximation');
        disp(' ');
        Tres = table(W, mW, sW, zW, p, p_two, ...
            'VariableNames', {'W','Mean','SD','Z','p_value_one_tail','p_value_two_tails'});
        disp(Tres);
    end
    
    stats.method = 'Normal approximation';
    stats.meanW  = mW;
    stats.stdW   = sW;
    stats.z      = zW;
    stats.p_one  = p;
    stats.p_two  = p_two;
end

% -------------------------------------------------------------------------
% Plots (optional)
% -------------------------------------------------------------------------
if plotFlag
    scrsz = get(groot,'ScreenSize');
    
    % Paired plot
    hfig1 = figure;
    POS   = scrsz;
    POS(3)= POS(3)/2;
    set(hfig1,'Position',POS);
    
    xg = repmat([1 2], numel(x1_orig), 1);
    yg = [x1_orig, x2_orig];
    
    plot(xg, yg, 'b.', xg.', yg.', 'r-');
    axis square
    set(gca,'XLim',[0 3], ...
        'XtickMode','manual', ...
        'Xtick',0:3, ...
        'XtickLabel',{' ','Before','After',' '});
    title('Wilcoxon''s Plot');
    
    % Boxplot
    hfig2   = figure;
    POS2    = POS;
    POS2(1) = POS(1) + POS(3);
    set(hfig2,'Position',POS2);
    
    if n > 30
        txt = 'on';
    else
        txt = 'off';
    end
    
    boxplot(yg(:), xg(:), 'notch', txt);
    set(gca,'XtickLabel',{'Before','After'});
end

% -------------------------------------------------------------------------
% Output behaviour
% -------------------------------------------------------------------------
if nargout == 0
    clear stats
end

end

% -------------------------------------------------------------------------
% Local helper functions
% -------------------------------------------------------------------------

function tf = validateLogicalLike(x)
%VALIDATELOGICALLIKE Helper for inputParser: check logical-like values.
    try
        normalizeLogicalLike(x);
        tf = true;
    catch
        tf = false;
    end
end

function y = normalizeLogicalLike(x)
%NORMALIZELOGICALLIKE Convert various logical-like inputs to true/false.
    if islogical(x)
        y = x;
    elseif isnumeric(x) && isscalar(x)
        y = (x ~= 0);
    elseif ischar(x) || (isstring(x) && isscalar(x))
        s = lower(char(x));
        if any(strcmp(s, {'true','on','yes'}))
            y = true;
        elseif any(strcmp(s, {'false','off','no'}))
            y = false;
        else
            error('Invalid logical-like value: %s', s);
        end
    else
        error('Invalid type for logical-like option.');
    end
end
