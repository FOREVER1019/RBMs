
% function: calculate accessibility error for all 35 RBMs for a give city
% err_time:[abosolute error time; normalized error time; the Pearson
% correlation coefficient between accessibility derived from the RBM and the VBM;
% the proportion of cell pairs with accessibility estimation error smaller than 5, 10, and 30 minutes
% the proportion of cell pairs with relative accessibility estimation error smaller than 5%, 10%, and 20%]

clc;clear variables;
define_constants;
city_id=178;
[~,~,raw_cities]=xlsread('city_basic_data.xlsx');
city_name=cell2mat(raw_cities(city_id,CN));
clog=cell2mat(raw_cities(city_id,CX));clat=cell2mat(raw_cities(city_id,CY));%city name
load(strcat(num2str(city_id),city_name,'\node_data.mat'),'node_data');
load(strcat(num2str(city_id),city_name,'\edge_data.mat'),'edge_data');
load(strcat(num2str(city_id),city_name,'\edge_str.mat'),'edge_str');
Np=length(node_data(:,1));
edge_data(:,6)=60;

%% compute travel distance based accessibility derived from the VBM
load(strcat(num2str(city_id),city_name,'\rs1_net_raster_info.mat'),'net_raster_info');
net_r2r=compute_primary_net_time_r2r(node_data,edge_data,net_raster_info);
aver_acc=net_raster_info.raster_node(:,4)'*net_r2r*net_raster_info.raster_node(:,4)/Np/(Np-1);
save(strcat(num2str(city_id),city_name,'\rs1_primary_net_dist_r2r.mat'),'net_r2r');
save(strcat(num2str(city_id),city_name,'\aver_acc_dist.mat'),'aver_acc');

%% compute node betweenness
edge_speed_time=update_road_edge_speed_time(edge_data);
fnet=sparse([edge_data(:,EF);edge_data(:,ET)],[edge_data(:,ET);edge_data(:,EF)],[edge_speed_time(:,2);edge_speed_time(:,2)]);%for calculating the shortest paths
[Bn,~]=betweenness_centrality(fnet);
save(strcat(num2str(city_id),city_name,'\fd_Bn_NF.mat'),'Bn');

%% get local transportation network information
load(strcat(num2str(city_id),city_name,'\rs1_net_raster_info.mat'),'net_raster_info');
node_pair=get_node_pair_information_noil(net_raster_info,node_data,edge_data);
save(strcat(num2str(city_id),city_name,'\rs1_node_pair_dist.mat'),'node_pair','-v7.3');

%% estimate accessibility and calculate accessibility estimation error for the LC&RN-RBM
load(strcat(num2str(city_id),city_name,'\aver_acc_dist.mat'),'aver_acc');
load(strcat(num2str(city_id),city_name,'\rs1_net_raster_info.mat'),'net_raster_info');
load(strcat(num2str(city_id),city_name,'\rs1_primary_net_dist_r2r.mat'),'net_r2r');
load(strcat(num2str(city_id),city_name,'\rs1_raster_typical_nodes_LC_RN.mat'),'raster_typical_nodes');
load(strcat(num2str(city_id),city_name,'\rs1_rand_typical_nodes_LC_RN.mat'),'rand_typical_nodes');

load(strcat(num2str(city_id),city_name,'\rs1_node_pair_dist.mat'),'node_pair');
err_dist=zeros(length(raster_typical_nodes(1,:)),9);
for t=1:length(raster_typical_nodes(1,:))
    [err_dist(t,:),net_r2r_LC_RN]=calculate_accessibility_error_for_LC_RN(net_raster_info,node_data,edge_data,net_r2r,raster_typical_nodes(:,t),node_pair);
end
err_dist(:,2)=err_dist(:,1)/aver_acc;
save(strcat(num2str(city_id),city_name,'\rs1_error_dist_LC_RN.mat'),'err_dist');
err_dist_rand=zeros(length(raster_typical_nodes(1,:)),9);
for t=1:length(rand_typical_nodes(1,:))
    err_dist_rand(t,:)=calculate_accessibility_error_for_LC_RN(net_raster_info,node_data,edge_data,net_r2r,rand_typical_nodes(:,t),node_pair);
end
err_dist_rand(:,2)=err_dist_rand(:,1)/aver_acc;
save(strcat(num2str(city_id),city_name,'\rs1_error_dist_LC_RN_rand.mat'),'err_dist_rand');

%% estimate accessibility and calculate accessibility estimation error for the TMS-RBM
load(strcat(num2str(city_id),city_name,'\aver_acc_dist.mat'),'aver_acc');
load(strcat(num2str(city_id),city_name,'\rs1_area_raster_info.mat'),'area_raster_info');
[err_dist,net_r2r_TMS]=calculate_accessibility_error_for_TMS(node_data,edge_data,area_raster_info,net_r2r);
err_dist(:,2)=err_dist(:,1)/aver_acc;
save(strcat(num2str(city_id),city_name,'\rs1_err_dist_TMS.mat'),'err_dist');

%% estimate accessibility and calculate accessibility estimation error for the LC&MS-RBM
load(strcat(num2str(city_id),city_name,'\aver_acc_dist.mat'),'aver_acc');
load(strcat(num2str(city_id),city_name,'\rs1_area_raster_info.mat'),'area_raster_info');
load(strcat(num2str(city_id),city_name,'\rs1_primary_net_dist_r2r.mat'),'net_r2r');
[err_dist,net_r2r_LC_MS]=calculate_accessibility_error_for_LC_MS(node_data,edge_data,area_raster_info,net_r2r);
err_dist(:,2)=err_dist(:,1)/aver_acc;
save(strcat(num2str(city_id),city_name,'\rs1_net_r2r_LC_MS.mat'),'net_r2r_TMS');
save(strcat(num2str(city_id),city_name,'\rs1_err_dist_LC_MS.mat'),'err_dist');

%% estimate accessibility and calculate accessibility estimation error for the NN&RN-RBM
load(strcat(num2str(city_id),city_name,'\aver_acc_dist.mat'),'aver_acc');
load(strcat(num2str(city_id),city_name,'\rs1_area_raster_info.mat'),'area_raster_info');
load(strcat(num2str(city_id),city_name,'\rs1_net_raster_info.mat'),'net_raster_info');
load(strcat(num2str(city_id),city_name,'\rs1_primary_net_dist_r2r.mat'),'net_r2r');
load(strcat(num2str(city_id),city_name,'\rs1_node_pair_dist.mat'),'node_pair');
load(strcat(num2str(city_id),city_name,'\rs1_raster_typical_nodes_NN_RN.mat'),'raster_typical_nodes');
load(strcat(num2str(city_id),city_name,'\rs1_rand_typical_nodes_NN_RN.mat'),'rand_typical_nodes');

err_dist=calculate_accessibility_error_for_NN_RN(node_data,edge_data,net_raster_info,area_raster_info,raster_typical_nodes,net_r2r,node_pair);
err_dist(:,2)=err_dist(:,1)/aver_acc;
save(strcat(num2str(city_id),city_name,'\rs1_error_dist_NN_RN.mat'),'err_dist');
err_dist_rand=zeros(length(raster_typical_nodes(1,:)),9);
for t=1:length(rand_typical_nodes(1,:))
    err_dist_rand(t,:)=calculate_accessibility_error_for_NN_RN(node_data,edge_data,net_raster_info,area_raster_info,rand_typical_nodes(:,t),net_r2r,node_pair);
end
err_dist_rand(:,2)=err_dist_rand(:,1)/aver_acc;
save(strcat(num2str(city_id),city_name,'\rs1_error_dist_NN_RN_rand.mat'),'err_dist_rand');

%% estimate accessibility and calculate accessibility estimation error for the HB-RBM
load(strcat(num2str(city_id),city_name,'\aver_acc_dist.mat'),'aver_acc');
load(strcat(num2str(city_id),city_name,'\rs1_net_raster_info.mat'),'net_raster_info');
load(strcat(num2str(city_id),city_name,'\rs1_primary_net_dist_r2r.mat'),'net_r2r');
load(strcat(num2str(city_id),city_name,'\rs1_node_pair_dist.mat'),'node_pair');
load(strcat(num2str(city_id),city_name,'\ft_Bn_NF.mat'),'Bn');

raster_node=net_raster_info.raster_node; node_raster=net_raster_info.node_raster;
bc_typical_node=get_representative_nodes(raster_node,node_raster,-Bn,1);
%     save(strcat(num2str(city_id),city_name,'\bc_typical_node'),'bc_typical_node');

[err_dist,net_r2r_HB]=calculate_accessibility_error_for_LC_RN(net_raster_info,node_data,edge_data,net_r2r,bc_typical_node,node_pair);
err_dist(:,2)=err_dist(:,1)/aver_acc;
save(strcat(num2str(city_id),city_name,'\rs1_err_dist_HB.mat'),'err_dist');
save(strcat(num2str(city_id),city_name,'\rs1_net_r2r_HB'),'net_r2r_HB');



