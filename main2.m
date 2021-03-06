%Author: Lavisha Aggarwal, derived from Sanketh Shetty's work

%This function computes the new rich representation of the given data and
%computes a 15(10) dimensional representation for 2D(ND) data where the
%differnt components are 1.No of neighbors 2. mean distance between points
%in nbhood 3. stddev of distance between pts in nbhood 4. shiftvector
%density 6. 1st derivative density 7. 2nd derivative density 8.
%isotropy(force sum) 9. isotropy(force sign) 10.
%isotropy(uniformity)(11-15 only for 2 dimensional data) 11.
%elongation 12.area 13. perimeter 14. eccentricity 15. gabriel measure
clc;
close all;
clear all;
addpath isotropy;
addpath misc;
addpath hierarchy;
filename = 'Aggregation.txt'
%filename = 'data_spiral.txt';
%filename = 'data_crescents.txt';
%filename = 'sample_data.txt';
%filename = 'data_set_1_8_1_gaussian.txt';
% Example data set:
%filename = 'unbalance.txt';
data = load(filename);
data = data(:,1:2);
scatter(data(:,1), data(:,2), 1,ones(size(data,1),1));
% isotropy_criterion: specify the criterion to use when computing shift
% vectors. Options:
% 'force-sum' : Performs clustering using force-sum criterion
% 'force-sign' : Performs clustering using force-sign criterion
% 'uniformity' : Performs clustering using uniformity criterion
criterion = 'uniformity';
% votes are weighted by degree
% alpha : specify level of significance of the isotropy test. 
% With the force-sum and force-sign criterion (unpublished), 
% of isotropy of a neighborhood. Here a single alpha value determines the
% cutoff point for the voting. If increasing the neighborhood size reduces
% the degree of isotropy below this threshold, voting is stopped.
% e.g. alpha = 0.01;
%lavisha - crescent data, i got perfect labelling with alpha = 0.001
alpha = 0.05;
% win_size: specify a window size for testing.
% Typically set to 25 for force_sign and uniformity.
% For force_sum set it to 10 and the criterion automatically adjusts to the
% number of points used in the test.
win_size = 25;
algorithm = 'connected-components';
options.min_cluster_size = 20;
options.merge_outliers = 1;

params.Kmax = min(200, size(data,1)); % maximum window size for testing
% Subspace estimation
% options: 'MLE','Eigen','NearestNbr_dim','proj_L1','proj_L2',
params.method_dim = 'MLE';
%options: 'SnapShot','localPCA';
params.subspace = 'SnapShot';
params.subspace_refine = 0; % 1: Refines neighborhood points to include 
% only those in the linear subspace
params.Kper_dim = 10; % Number of points x dimension gives number of points
% used in estimating the local linear subspace
params.Krefine_dim = 2;
params.method_refine = 'mode';
params.Kper_dimC = 10;
params.cdf_file = 'isotropy/look_up_cdf_101_bins_50dim.mat';
params.startK = min(win_size, size(data,1));

%neighbors_criterion = 'Fixed_number';
neighbors_criterion = 'Fixed_radius';
% Precompute Neighbors
if strcmp(neighbors_criterion, 'Fixed_number')
    data_neighbors = precompute_nearest_neighbors(data, params.Kmax);
else
    [data_neighbors, nbr_radius] = precompute_neighbors_fixedradius(data);        
end

%Define the new representation for the data
d = size(data,2);
if d ==2
    number_properties = 15;
else
    number_properties = 10;
end
data_rich = zeros(size(data,1), number_properties);

for i = 1:1:size(data,1)
   data_nbrs = data_neighbors{i};
   data_rich(i,1) = size(data_nbrs,2);
   [data_rich(i,2), data_rich(i,3)] = compute_stats(i, data, data_nbrs);
   data_rich(i,4) = compute_shiftvector(i, data, data_nbrs);
   data_rich(i,5) = compute_density(i, data, data_nbrs, nbr_radius);
    
end
for i = 1:1:size(data,1)
   data_nbrs = data_neighbors{i};
   data_rich(i,6) = compute_fungradient(i, data, data_nbrs, data_rich(:,5));
end

for i = 1:1:size(data,1)
   data_nbrs = data_neighbors{i};
   data_rich(i,7) = compute_fungradient(i, data, data_nbrs, data_rich(:,6)); 
end

[pvals1, pvals2, pvals3] = isotropy_measures(data, win_size);
data_rich(:,8) = pvals1;
data_rich(:,9) = pvals2;
data_rich(:,10) = pvals3;
if d ==2
    fprintf('Computing voronoi properties\n');
    [elongation, area, perimeter] = compute_voronoiprops(data);
    data_rich(:, 11) = elongation;
    data_rich(:, 12) = area;
    data_rich(:, 13) = perimeter;
    data_rich(:, 14) = compute_eccentricity(data);
    fprintf('Computing gabriel measure\n');
    data_rich(:, 15) = compute_gabrielmeasure(data);   
end
data_original = data;
%Normalize the data
data = data_rich;
for d = 1:1:number_properties
   data(:,d) = (data_rich(:,d) - min(data_rich(:,d)))/(max(data_rich(:,d))- min(data_rich(:,d)));
end
fname = sprintf('rich%s.mat',filename);
save(fname,'data','data_original');

%Code to save images of the respective plots
name1 = {'Number of Neighbors' ,'Mean Distance', 'Std Deviation Distance', 'Shiftvector Magnitude', 'Density',...
     '1st Derivative Density', '2nd Derivative Density', 'Isotropy Force Sum', 'Isotropy Force Sign', 'Isotropy Uniformity', 'Elongation',...
     'Log Voronoi cell Area', 'Log Voronoi cell Perimeter', 'Eccentricity', 'Log Gabriel measure'};
for i = 1:1:15
    f = figure;
    scatter(data_original(:,1), data_original(:,2), 1, data(:,i))
    colorbar
    name2 = sprintf('%s.png',name1{i});
    title(name1{i})
    saveas(f, name2) 
end

%{
%Estimate intrinsic dimensions of point neighborhoods
data_dimensions = estimate_dimensionality(data,data_neighbors,params);
%Refine the dimension estimates over local neighborhoods
data_dimensions = ...
    refine_dimension_estimates(data_dimensions, data_neighbors,...
    params.method_refine,params.Krefine_dim);

data_dimensions = min(round(data_dimensions), 50);
data_dimensions = min(round(data_dimensions), size(data,2));
%Assign Local Coordinates
[data_coordinates,data_dimensions] = ...
    local_coordinate_assignment(data,data_dimensions,...
    data_neighbors,params.Kper_dim,params.subspace);        
pvals = isotropy_uniformity(data, ...
    data_dimensions, data_neighbors, data_coordinates, params);

isborder = pvals < alpha;
labels = cluster_labeling_mst(isborder,...
        data_neighbors, data, options.min_cluster_size);


figure;
scatter(data(:,1), data(:,2), 3, pvals(:))
figure;
plot(data(isborder,1), data(isborder,2),'.', 'color','r')
hold on
plot(data(~isborder,1), data(~isborder,2),'.', 'color','b')
figure;
uniquelabels = unique(labels);
for i=1:size(uniquelabels,1)
    indices = find(~(labels-uniquelabels(i)));
    clusterpts = data(indices,:);
    hold on
    plot(clusterpts(:,1), clusterpts(:,2), '.','color',rand(1,3));
end

%}
%Visualising the neighborhood around a point, for neighbors_criterion='Fixed_number'
%{
pt = 2655;
nbr_index = data_neighbors(pt).order;
plot(data(nbr_index,1), data(nbr_index,2),'r.')
hold on
plot(data(pt,1), data(pt,2), 'k.')
hold on
indices = linspace(1,size(data,1), size(data,1));
nonnbr_index = setdiff(indices, nbr_index);
plot(data(nonnbr_index,1), data(nonnbr_index,2), 'b.')
%}
