function [BestF,BestX,cnvg]=hybrid(N,MaxIter,LB,UB,dim,fobj)

lb=ones(1,dim).*LB;
ub=ones(1,dim).*UB;

%Initialize the first random population of Gazelles
X=initialization(N,dim,UB,LB);

% initialize Best Gazelle
BestX=[];
BestFitness=inf;


for i=1:N

    % Calculate the fitness of the population
    Sol_Cost(i,:)=fobj(X(i,:));%#ok

    % Update the Best Gazelle if needed
    if Sol_Cost(i,:)<=BestFitness
        BestFitness=Sol_Cost(i,:);
        BestX=X(i,:);
    end
end

%mainloop
for Iter=1:MaxIter
    for i=1:N

        % --- EXPLORATION: compute M, cofi, A, D (extracted) ---
        [M, cofi, A, D] = exploration(X, BestX, Iter, MaxIter, N, dim, i);

        % --------------------------------------------------------

        % --- EXPLOITATION: build candidate, boundary-check & eval (extracted) ---
        [NewX , Sol_CostNew] = exploitation_hybrid(X, BestX, lb, ub, N, cofi, M, A, D, i, fobj, LB, UB, Iter, MaxIter, Sol_Cost);

        % ---------------------------------------------------------------------------

        % Adding new gazelles to the herd
        X=[X; NewX];       %#ok
        Sol_Cost=[Sol_Cost; Sol_CostNew];%#ok
        [~,idbest]=min(Sol_Cost);
        BestX=X(idbest,:);

    end

    % Update herd
    [Sol_Cost, SortOrder]=sort(Sol_Cost);
    X=X(SortOrder,:);
    [BestFitness,idbest]=min(Sol_Cost);
    BestX=X(idbest,:);
    X=X(1:N,:);
    Sol_Cost=Sol_Cost(1:N,:);
    cnvg(Iter)=BestFitness;%#ok
    BestF=BestFitness;
end
end

