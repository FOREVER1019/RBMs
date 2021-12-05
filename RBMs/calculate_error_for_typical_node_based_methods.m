function err_time=calculate_error_for_typical_node_based_methods(net_raster_info,org_node_data,org_edge_data,typical_node,net_r2r)

% edge_speed_time=update_road_edge_speed_time(org_edge_data);
% org_edge_data(:,6)=edge_speed_time(:,1);
neibor_edge=get_typical_nodes_connection_information(net_raster_info,org_edge_data,typical_node);
raster_edge=net_raster_info.raster_edge;
raster_node=net_raster_info.raster_node;
Np=length(org_node_data(:,1));
% get raster_edge_long
raster_edge_long=raster_edge(raster_edge(:,4)~=0,1:6);
raster_edge_long(:,4)=org_edge_data(raster_edge_long(:,6),4)./(org_edge_data(raster_edge_long(:,6),6)*1000/60);
raster_edge_typ=zeros(length(raster_edge(:,1)),4);
raster_edge_typ(length(neibor_edge(:,1))+1:length(raster_edge(:,1)),:)=raster_edge_long(:,1:4);

% directly use the fastest travel time between typical_nodes as weights
raster_edge_typ(1:length(neibor_edge(:,1)),:)=neibor_edge(:,1:4);
raster_net_typ=sparse([raster_edge_typ(:,2);raster_edge_typ(:,3)],[raster_edge_typ(:,3);raster_edge_typ(:,2)],[raster_edge_typ(:,4);raster_edge_typ(:,4)]);
raster_D_typ=all_shortest_paths(raster_net_typ);
abs_err_time=raster_node(:,4)'*abs(net_r2r-raster_D_typ)*raster_node(:,4)/Np/(Np-1);

raster_node_num=raster_node(:,4);
r2r_vec=zeros(length(net_r2r(:,1))*length(net_r2r(:,1)),3);
r2r_vec(:,1)=reshape(net_r2r,length(net_r2r(:,1))*length(net_r2r(:,1)),1);
r2r_vec(:,2)=reshape(raster_D_typ,length(net_r2r(:,1))*length(net_r2r(:,1)),1);
cc_err_time=min(min(corrcoef(r2r_vec(:,1),r2r_vec(:,2))));
raster_node_num_vec=reshape(raster_node_num*raster_node_num',length(net_r2r(:,1))*length(net_r2r(:,1)),1);
raster_node_num_vec(r2r_vec(:,1)==0,:)=[];r2r_vec(r2r_vec(:,1)==0,:)=[];
rel_err_time=raster_node_num_vec'*(abs(r2r_vec(:,1)-r2r_vec(:,2))./r2r_vec(:,1))/Np/(Np-1);

err_time=[abs_err_time rel_err_time cc_err_time];





