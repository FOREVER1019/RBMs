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

%% change raster size and test the effect
load(strcat(num2str(city_id),city_name,'\aver_acc_time.mat'),'aver_acc');
load(strcat(num2str(city_id),city_name,'\node_type.mat'),'node_type');
load(strcat(num2str(city_id),city_name,'\node_street_len.mat'),'node_street_len');
edge_speed_time=update_road_edge_speed_time(edge_data);
fnet=sparse([edge_data(:,EF);edge_data(:,ET)],[edge_data(:,ET);edge_data(:,EF)],[edge_speed_time(:,2);edge_speed_time(:,2)]);%for calculating the shortest paths
net_n2n=all_shortest_paths(fnet);
save(strcat(num2str(city_id),city_name,'\sqr60_net_n2n.mat'),'net_n2n','-v7.3');

raster_size=[(100:100:400)/1000 (500:500:20000)/1000];
err_time=zeros(length(raster_size),2,3);
for s=1:length(raster_size)
    err_time(s,:,:)=calculate_accessibility_error_under_given_cell_size(node_data,edge_data,edge_str,[clog clat],raster_size(s),net_n2n,node_type,node_street_len);
end
err_time(:,:,2)=err_time(:,:,1)/aver_acc;
save(strcat(num2str(city_id),city_name,'\sqr60_rsX_err_time.mat'),'err_time');

%% change raster center and test the effect
load(strcat(num2str(city_id),city_name,'\aver_acc_time.mat'),'aver_acc');
load(strcat(num2str(city_id),city_name,'\node_type.mat'),'node_type');
load(strcat(num2str(city_id),city_name,'\node_street_len.mat'),'node_street_len');
load(strcat(num2str(city_id),city_name,'\sqr60_net_n2n.mat'),'net_n2n');
raster_size=1;Numsim=50;
err_time=zeros(Numsim,2,3); cell_center=zeros(Numsim,2);
for s=1:Numsim
    cell_center(s,:)=[clog-0.0083+2*0.0083*rand(1) clat-0.0083+2*0.0083*rand(1)];
    err_time(s,:,:)=calculate_accessibility_error_under_given_cell_size(node_data,edge_data,edge_str,cell_center(s,:),raster_size,net_n2n,node_type,node_street_len);
end
err_time(:,:,2)=err_time(:,:,1)/aver_acc;
save(strcat(num2str(city_id),city_name,'\sqr60_rsX_err_time.mat'),'err_time');
save(strcat(num2str(city_id),city_name,'\sqr60_rs1_centerX_err_time.mat'),'err_time');

%% random speed and test the effect
load(strcat(num2str(city_id),city_name,'\rs1_net_raster_info.mat'),'net_raster_info');
load(strcat(num2str(city_id),city_name,'\rs1_area_raster_info.mat'),'area_raster_info');
raster_size=1;Numsim=50;
err_time=zeros(Numsim,2,3);
aver_acc=zeros(Numsim,1);
for s=1:Numsim
    new_edge_data=random_road_speed_V2(city_id,edge_data);  %
    [err_time(s,:,:),net_r2r]=calculate_accessibility_error_under_random_speed(node_data,new_edge_data,edge_str,net_raster_info,area_raster_info);
    aver_acc(s)=net_raster_info.raster_node(:,4)'*net_r2r*net_raster_info.raster_node(:,4)/Np/(Np-1);
    err_time(s,:,2)=err_time(s,:,1)/aver_acc(s);
end
save(strcat(num2str(city_id),city_name,'\sqr60_rs1_speedX_err_time.mat'),'err_time');
save(strcat(num2str(city_id),city_name,'\sqr60_rs1_speedX_aver_acc.mat'),'aver_acc');

%% compute err time for subarea to test the effect of area size
load(strcat(num2str(city_id),city_name,'\rs1_net_raster_info.mat'),'net_raster_info');
osm_edge=shaperead(strcat(num2str(city_id),city_name,'\sqr60_osmnx\edges.shp'));%shp data for the road edge segments
raster_para.center=net_raster_info.center;raster_para.raster_size=net_raster_info.raster_size;
raster_para.log_lat_step=net_raster_info.log_lat_step;log_lat_step=net_raster_info.log_lat_step;
area_radius=5:5:25;
err_time=zeros(length(area_radius),2,3);
aver_acc=zeros(length(area_radius),1);
for s=1:length(area_radius)
    s
    boundary.X=[clog-log_lat_step(1)*area_radius(s) clog+log_lat_step(1)*area_radius(s) clog+log_lat_step(1)*area_radius(s) clog-log_lat_step(1)*area_radius(s) NaN];
    boundary.Y=[clat-log_lat_step(2)*area_radius(s) clat-log_lat_step(2)*area_radius(s) clat+log_lat_step(2)*area_radius(s) clat+log_lat_step(2)*area_radius(s) NaN];
    local_edge=local_osm_road_network_given_bounding_box(osm_edge,boundary);
    [node_data,edge_data,edge_str]=node_edge_matrice_from_osm_edge(city_id,local_edge);
    Np=length(node_data(:,1));
    raster_para.radius=area_radius(s);
    raster_para.boundary_X=boundary.X;
    raster_para.boundary_Y=boundary.Y;
    
    [err_time(s,:,:),net_r2r]=calculate_traditional_and_nrm_err_time(node_data,edge_data,edge_str,raster_para);
    aver_acc(s)=net_raster_info.raster_node(:,4)'*net_r2r*net_raster_info.raster_node(:,4)/Np/(Np-1);
    err_time(s,:,2)=err_time(s,:,1)/aver_acc(s);
end
save(strcat(num2str(city_id),city_name,'\sqr60_rs1_radiusX_err_time.mat'),'err_time');
save(strcat(num2str(city_id),city_name,'\sqr60_rs1_radiusX_aver_acc.mat'),'aver_acc');

