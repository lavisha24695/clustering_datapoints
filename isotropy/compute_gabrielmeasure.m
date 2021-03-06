function gmeasure2 = compute_gabrielmeasure(data)
n = size(data,1);
d = size(data,2);
gmeasure = zeros(n,1);
[V,C] = voronoin(data);
nbr = cell(n,1);

for i = 1:1:n
    if mod(i,1000)==0
        fprintf('\n*');
    elseif mod(i,100)==0
        fprintf('*');
    end
    polygonpts = V(C{i},:);
    polygonpts = polygonpts(sum(polygonpts,d)~=Inf, :);
    no_vertices = size(polygonpts, 1);
    %Find the point numbers of the neighboring cells
    nbr{i} = zeros(no_vertices,1);
    for j = 1:1:no_vertices
        pt1 = C{i}(j);
        if(j==no_vertices)
            pt2 = C{i}(1);
        else
            pt2 = C{i}(j+1);
        end
        for k = 1:1:n
            if k==i
                continue;
            end
            if any(find(C{k}==pt1))&& any(find(C{k}==pt2))
                break;
            end
        end
        nbr{i}(j) = k;
    end
    %Find the gmeasure for each neighbor
    gmeasures = zeros(no_vertices,1);
    for j=1:1:no_vertices
        edgept1 = polygonpts(j,:);
        if(j==no_vertices)
            edgept2 = polygonpts(1,:);
        else
            edgept2 = polygonpts(j+1,:);
        end
        centerpt1 = data(i,:);
        centerpt2 = data(nbr{i}(j),:);
        line1 = cross([edgept1(1) edgept1(2) 1],[edgept2(1) edgept2(2) 1]);
        line2 = cross([centerpt1(1) centerpt1(2) 1],[centerpt2(1) centerpt2(2) 1]);
        intpt_h = cross(line1, line2);
        intpt = [intpt_h(1)/intpt_h(3) intpt_h(2)/intpt_h(3)];
        lambda = sum(intpt-edgept1)/sum(edgept2-edgept1);
        % Check if the line joining the 2 centres cuts the edge
        if (lambda>=0) && (lambda<=1)
            gmeasures(j) = 1;
        else
            d_gmeasure = sqrt(sumsqr(centerpt1 - centerpt2));
        v1 = abs(dot([edgept1 1], line2));
        v2 = abs(dot([edgept2 1], line2));
        if(v1<v2)
            p1 = edgept1;
            if j ==1
            p2 = data(nbr{i}(no_vertices),:);
            else
            p2 = data(nbr{i}(j-1),:);
            end
        else
            p1 = edgept2;
            if j == no_vertices
            p2 = data(nbr{i}(1),:);
            else
            p2 = data(nbr{i}(j+1),:);
            end
        end
        D = sqrt(sumsqr(p1-p2));
        gmeasures(j) = D/d_gmeasure;
        end
    end
    gmeasure(i) = mean(gmeasures);
end
gmeasure2 = gmeasure;
mean1 = mean(gmeasure);
std1 = std(gmeasure);
gmeasure2(find(gmeasure>mean1 + 2*std1)) = mean1 + 2*std1;

%load(fname);
end