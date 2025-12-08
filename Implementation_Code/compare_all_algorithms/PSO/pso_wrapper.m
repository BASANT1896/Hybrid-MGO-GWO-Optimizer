function [BestF, BestX, cnvg] = pso_wrapper(SearchAgents_no, MaxIter, LB, UB, dim, fobj)
% PSO wrapper matching signature used by compare scripts.
% Usage:
%   [BestF, BestX, cnvg] = pso_wrapper(N, MaxIter, LB, UB, dim, fobj)
%
% This implements a standard PSO and returns:
%   BestF  - best objective value found (scalar)
%   BestX  - best position (1 x dim)
%   cnvg   - vector (1 x MaxIter) of best cost per iteration
%
% Notes:
% - LB and UB may be scalars or 1xd vectors.
% - fobj is a function handle: cost = fobj(x) where x is 1xd.

% Normalize LB/UB to vectors
if isscalar(LB)
    VarMin = LB * ones(1,dim);
else
    VarMin = LB(:)'; % row
end
if isscalar(UB)
    VarMax = UB * ones(1,dim);
else
    VarMax = UB(:)'; % row
end

% Parameters (you can tune these if desired)
nPop = SearchAgents_no;   % swarm size
MaxIt = MaxIter;          % iterations

% PSO coefficients (sane defaults)
w = 1;            % inertia
wdamp = 0.99;     % inertia damping
c1 = 1.5;         % personal
c2 = 2.0;         % global

% Velocity limits (vector-aware)
VelMax = 0.1 * (VarMax - VarMin);
VelMin = -VelMax;

% Particle structure
empty_particle.Position = [];
empty_particle.Cost = [];
empty_particle.Velocity = [];
empty_particle.Best.Position = [];
empty_particle.Best.Cost = [];

particle = repmat(empty_particle, nPop, 1);

GlobalBest.Cost = inf;
GlobalBest.Position = zeros(1,dim);

% Initialization
for i = 1:nPop
    % Uniform init in each dimension
    particle(i).Position = VarMin + rand(1,dim).*(VarMax - VarMin);

    % zero velocity
    particle(i).Velocity = zeros(1,dim);

    % evaluate
    particle(i).Cost = fobj(particle(i).Position);

    % personal best
    particle(i).Best.Position = particle(i).Position;
    particle(i).Best.Cost = particle(i).Cost;

    % update global best
    if particle(i).Best.Cost < GlobalBest.Cost
        GlobalBest = particle(i).Best;
    end
end

% Convergence storage
cnvg = nan(1, MaxIt);

% Main loop
for it = 1:MaxIt
    for i = 1:nPop
        % update velocity
        particle(i).Velocity = w*particle(i).Velocity ...
            + c1*rand(1,dim).*(particle(i).Best.Position - particle(i).Position) ...
            + c2*rand(1,dim).*(GlobalBest.Position - particle(i).Position);

        % apply velocity limits (elementwise)
        particle(i).Velocity = max(particle(i).Velocity, VelMin);
        particle(i).Velocity = min(particle(i).Velocity, VelMax);

        % update position
        particle(i).Position = particle(i).Position + particle(i).Velocity;

        % velocity mirror for out-of-bounds
        IsOutside = (particle(i).Position < VarMin) | (particle(i).Position > VarMax);
        particle(i).Velocity(IsOutside) = -particle(i).Velocity(IsOutside);

        % apply position limits
        particle(i).Position = max(particle(i).Position, VarMin);
        particle(i).Position = min(particle(i).Position, VarMax);

        % evaluate
        particle(i).Cost = fobj(particle(i).Position);

        % update personal best
        if particle(i).Cost < particle(i).Best.Cost
            particle(i).Best.Position = particle(i).Position;
            particle(i).Best.Cost = particle(i).Cost;
            % update global best
            if particle(i).Best.Cost < GlobalBest.Cost
                GlobalBest = particle(i).Best;
            end
        end
    end

    % store best cost this iteration
    cnvg(it) = GlobalBest.Cost;

    % display optional (comment out if noisy)
    % disp(['PSO iter ' num2str(it) ': Best Cost = ' num2str(cnvg(it))]);

    % damping
    w = w * wdamp;
end

% outputs
BestF = GlobalBest.Cost;
BestX = GlobalBest.Position;

end

