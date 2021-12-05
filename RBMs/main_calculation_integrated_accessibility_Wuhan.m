
%% data
metro_speed=35; drive_speed=29.12; 
city_id=43; define_constants;
city_name='Wuhan';%city name

load(strcat('.\',num2str(city_id),city_name,'\','sqr60_node_data.mat'),'node_data');
load(strcat('.\',num2str(city_id),city_name,'\','sqr60_edge_data.mat'),'edge_data');
load(strcat('.\',num2str(city_id),city_name,'\','sqr60_edge_str.mat'),'edge_str');
load(strcat('.\',num2str(city_id),city_name,'\sqr60_rs1_area_raster_info.mat'),'area_raster_info');
load(strcat('.\',num2str(city_id),city_name,'\sqr60_rs1_net_raster_info.mat'),'net_raster_info');
load(strcat('.\',num2str(city_id),city_name,'\','metro_data.mat'),'metro_data');
edge_data(:,6)=drive_speed;
Np=length(node_data(:,1));

near_node=zeros(length(metro_data.node(:,1)),1);
for n=1:length(metro_data.node(:,1))
    near_node(n)=node_data(sum(abs(node_data(:,2:3)-metro_data.node(n,2:3)),2)==min(sum(abs(node_data(:,2:3)-metro_data.node(n,2:3)),2)),1);
end

metro_edge=[near_node(metro_data.edge(:,2:3)) metro_data.edge(:,4)];
metro_edge=[(length(edge_data(:,1))+1:length(edge_data(:,1))+length(metro_edge(:,1)))' metro_edge];
metro_edge(:,5)=0;metro_edge(:,6)=metro_speed;
integrated_edge_data=[edge_data;metro_edge];

integrated_edge_str=edge_str;
for e=1:length(metro_edge(:,1))
    integrated_edge_str(e+max(size(edge_str))).X=[node_data(metro_edge(e,2),2) node_data(metro_edge(e,3),2) NaN];
    integrated_edge_str(e+max(size(edge_str))).Y=[node_data(metro_edge(e,2),3) node_data(metro_edge(e,3),3) NaN];
end
save(strcat('.\',num2str(city_id),city_name,'\','metro_near_node.mat'),'near_node');
save(strcat('.\',num2str(city_id),city_name,'\','integrated_edge_data.mat'),'integrated_edge_data');
save(strcat('.\',num2str(city_id),city_name,'\','integrated_edge_str.mat'),'integrated_edge_str');

raster_para.boundary_X=net_raster_info.boundary_X;
raster_para.boundary_Y=net_raster_info.boundary_Y;
raster_para.center=net_raster_info.center;
raster_para.raster_size=net_raster_info.raster_size;
raster_para.log_lat_step=net_raster_info.log_lat_step;

metro_net_raster_info=generate_network_raster_information(node_data,integrated_edge_data,raster_para);
metro_area_raster_info=integrate_area_raster_information(node_data,integrated_edge_data,integrated_edge_str,metro_net_raster_info);
save(strcat('.\',num2str(city_id),city_name,'\','integrated_metro_net_raster_info.mat'),'metro_net_raster_info');
save(strcat('.\',num2str(city_id),city_name,'\','integrated_metro_area_raster_info.mat'),'metro_area_raster_info');

primary_net_r2r=compute_primary_net_time_r2r(node_data,integrated_edge_data,metro_net_raster_info);
raster_node_num=metro_net_raster_info.raster_node(:,4);
aver_acc=raster_node_num'*primary_net_r2r*raster_node_num/Np/(Np-1);
save(strcat('.\',num2str(city_id),city_name,'\','integrated_primary_net_r2r.mat'),'primary_net_r2r');

load(strcat('.\',num2str(city_id),city_name,'\sqr60_node_type.mat'),'node_type');
load(strcat('.\',num2str(city_id),city_name,'\sqr60_node_street_len.mat'),'node_street_len');
raster_typical_nodes=get_representative_nodes(metro_net_raster_info.raster_node,metro_net_raster_info.node_raster,[-node_type -node_street_len(:,1)],2);
neibor_edge=get_typical_nodes_connection_information(metro_net_raster_info,integrated_edge_data,raster_typical_nodes);
raster_edge=metro_net_raster_info.raster_edge;
raster_node=metro_net_raster_info.raster_node;
raster_edge_long=raster_edge(raster_edge(:,4)~=0,1:6);
raster_edge_long(:,4)=integrated_edge_data(raster_edge_long(:,6),4)./(integrated_edge_data(raster_edge_long(:,6),6)*1000/60);
raster_edge_typ=zeros(length(raster_edge(:,1)),4);
raster_edge_typ(length(neibor_edge(:,1))+1:length(raster_edge(:,1)),:)=raster_edge_long(:,1:4);
raster_edge_typ(1:length(neibor_edge(:,1)),:)=neibor_edge(:,1:4);
raster_net_typ=sparse([raster_edge_typ(:,2);raster_edge_typ(:,3)],[raster_edge_typ(:,3);raster_edge_typ(:,2)],[raster_edge_typ(:,4);raster_edge_typ(:,4)]);
raster_net_r2r=all_shortest_paths(raster_net_typ);
save(strcat('.\',num2str(city_id),city_name,'\','integrated_raster_net_r2r.mat'),'raster_net_r2r');

raster_node_num=metro_net_raster_info.raster_node(:,4);
abs_err_time=raster_node_num'*abs(primary_net_r2r-raster_net_r2r)*raster_node_num/Np/(Np-1);

r2r_vec=zeros(length(primary_net_r2r(:,1))*length(primary_net_r2r(:,1)),3);
r2r_vec(:,1)=reshape(primary_net_r2r,length(primary_net_r2r(:,1))*length(primary_net_r2r(:,1)),1);
r2r_vec(:,2)=reshape(raster_net_r2r,length(primary_net_r2r(:,1))*length(primary_net_r2r(:,1)),1);
cc_err_time=min(min(corrcoef(r2r_vec(:,1),r2r_vec(:,2))));
rel_err_time=abs_err_time/aver_acc;
olc_err_time=[abs_err_time rel_err_time cc_err_time];
save(strcat('.\',num2str(city_id),city_name,'\','olc_err_time.mat'),'olc_err_time');

[~,traditional_net_r2r]=compute_traditional_net_time_r2r(integrated_edge_data,metro_area_raster_info);
raster_node_id=area_raster_info.raster_node(metro_area_raster_info.raster_node(:,9)==1,2);
traditional_net_r2r=traditional_net_r2r(raster_node_id,raster_node_id); 
save(strcat('.\',num2str(city_id),city_name,'\','integrated_traditional_net_r2r.mat'),'traditional_net_r2r');

raster_node_num=metro_net_raster_info.raster_node(:,4);
abs_err_time=raster_node_num'*abs(primary_net_r2r-traditional_net_r2r)*raster_node_num/Np/(Np-1);

r2r_vec=zeros(length(primary_net_r2r(:,1))*length(primary_net_r2r(:,1)),3);
r2r_vec(:,1)=reshape(primary_net_r2r,length(primary_net_r2r(:,1))*length(primary_net_r2r(:,1)),1);
r2r_vec(:,2)=reshape(traditional_net_r2r,length(primary_net_r2r(:,1))*length(primary_net_r2r(:,1)),1);
cc_err_time=min(min(corrcoef(r2r_vec(:,1),r2r_vec(:,2))));
rel_err_time=abs_err_time/aver_acc;

tms_err_time=[abs_err_time rel_err_time cc_err_time];
save(strcat('.\',num2str(city_id),city_name,'\','tms_err_time.mat'),'tms_err_time');
