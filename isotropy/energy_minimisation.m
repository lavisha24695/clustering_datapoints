function [labels,flow, unary, binary, binary2] = energy_minimisation(data, weight, data_neighbors, data_original)
   
    D = size(weight,2);
    N = size(data,1);
    % y = zeros(n,1);
    p = zeros(N,1);
    theta = zeros(N,1);
    for i = 1:1:N
       p(i) = sum(data(i,:).*weight);
    end
    [pmax, maxi] = max(p);
    [pmin, mini] = min(p);
    theta1 = zeros(N,2);
    %theta2 = zeros(N,1);
    fprintf('Pmax: %d, Pmin: %d\n',pmax, pmin);
    for i = 1:1:N
       theta1(i,1) = (pmax - p(i))/(pmax-pmin);
       theta1(i,2) = (p(i) - pmin)/(pmax-pmin);
       theta(i) = (pmax + pmin - 2*p(i))/(pmax - pmin);
    end
    theta1 = 10*theta1;
    
  %  for k = 10:10:100
        w = zeros(N,N);
        binary2 = zeros(N,N);
        for i = 1:1:N
            nbrs = data_neighbors{i};
            for j = 1:1:size(nbrs,2)
                w(i,nbrs(j)) = exp(-100* sum(weight.*(data(i,:) - data(nbrs(j),:)).*(data(i,:) - data(nbrs(j),:))));
               %w(i,nbrs(j)) =  k*0.001/sum(weight.*(data(i,:) - data(nbrs(j),:)).*(data(i,:) - data(nbrs(j),:)));
            end    
        end
        %w = exp(-100*binary2);
        A = sparse(w);
        T = sparse(theta1);
        [flow, labels] = maxflow(A,T);
%        yhat = logical(labels);
 %       f = figure;
 %       scatter(data_original(:,1), data_original(:,2), 1,yhat);
 %       aa = sprintf('plot %d', k);
 %       title(aa);
   % end
    unary = theta1;
    binary = w;
end