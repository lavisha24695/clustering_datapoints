function [eccentricity, elongation, gabriel, area, perimeter] = compute_voronoiprops(data)
    
    n = size(data,1);
    d = size(data,2);
    elongation = zeros(n,1);
    eccentricity = zeros(n,1);
    gabriel = zeros(n,1);
    area = zeros(n,1);
    perimeter = zeros(n,1);
    %ecc_intpts = zeros(n,2);
    %cents = zeros(n,2);
    [V,C] = voronoin(data);
    for i = 1:1:n
        polygonpts = V(C{i},:);
        polygonpts = polygonpts(sum(polygonpts,d)~=Inf, :);
        %%Computation of elongation
        [K, vol] = convhull(polygonpts);
        n_pts = size(polygonpts, 1);
        perim = 0;
        for j = 1:1:n_pts-1
           len = polygonpts(j, :) - polygonpts(j+1, :); 
           perim = perim + sqrt(sumsqr(len));
        end
        %length of the joining edge from the last point to the first point
        len = polygonpts(n_pts, :) - polygonpts(1, :); 
        perim = perim + sqrt(sumsqr(len));
        elongation(i) = vol/(perim*perim);
        area(i) = vol;
        perimeter(i) = perim;
        %%Computation of eccentricity
        centroid = sum(polygonpts)./size(polygonpts,1);
        pt = data(i,:);
        ecc_num = sqrt(sumsqr(pt-centroid));
        line = cross([centroid 1], [pt 1]);
        lines = zeros(n_pts,3);
        %cents(i,:) = centroid;
        min_dist = 10000000000;
        min_pt = [1,2];
        for j = 1:1:n_pts-1
           lines(j,:) = cross([polygonpts(j,:) 1],[polygonpts(j+1,:) 1]);
           intersec = cross(line, lines(j,:));
           int_pt = [intersec(1)/intersec(3) intersec(2)/intersec(3)];
           dis = sqrt(sumsqr(int_pt - pt));
           if dis<min_dist
               min_dist = dis;
               min_pt = int_pt;
           end
        end
           lines(n_pts,:) = cross([polygonpts(n_pts,:) 1],[polygonpts(1,:) 1]);
           intersec = cross(line, lines(n_pts,:));
           int_pt = [intersec(1)/intersec(3) intersec(2)/intersec(3)];
           dis = sqrt(sumsqr(int_pt - pt));
           if dis<min_dist
               min_dist = dis;
               min_pt = int_pt;
           end
        %ecc_intpts(i,:) = min_pt;
        ecc_den = sqrt(sumsqr(min_pt - centroid));
        eccentricity(i) = ecc_num/ecc_den;
    end
end