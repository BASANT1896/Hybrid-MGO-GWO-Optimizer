function [M, cofi, A, D] = exploration(X, BestX, Iter, MaxIter, N, dim, i)
% exploration - compute exploration quantities for MGO (minimal, fixed)
% Now requires i so D can use X(i,:)

% Random subset of solutions
RandomSolution = randperm(N, ceil(N/3));

% Construct M (keeps original floor/ceil behavior)
M = X(randi([(ceil(N/3)), N]), :) * floor(rand) + mean(X(RandomSolution, :)) .* ceil(rand);

% Calculate coefficient vector (unchanged)
cofi = Coefficient_Vector(dim, Iter, MaxIter);

% A as in original
A = randn(1, dim) .* exp(2 - Iter * (2 / MaxIter));

% D MUST use the current individual's position X(i,:)
D = (abs(X(i, :)) + abs(BestX)) * (2 * rand - 1);
end
