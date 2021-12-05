function err_time=calculate_accessibility_error_under_given_cell_size(node_data,edge_data,edge_str,city_center,raster_size,net_n2n,node_type,node_street_len)

%% record raster parameters and generate raster network
log_lat_step=compute_log_lat_step_using_city_center(city_center,raster_size);
raster_para.center=city_center;
raster_para.log_lat_step=log_lat_step;
raster_para.boundary_X=[min(node_data(:,2)) max(node_data(:,2)) max(node_data(:,2)) min(node_data(:,2)) NaN];
raster_para.boundary_Y=[min(node_data(:,3)) min(node_data(:,3)) max(node_data(:,3)) max(node_data(:,3)) NaN];
raster_para.raster_size=raster_size;
net_raster_info=generate_network_raster_information(node_data,edge_data,raster_para);
% err_time=length(net_raster_info.raster_node(:,1))/length(net_raster_info.raster_data(:,1));
area_raster_info=integrate_area_raster_information(node_data,edge_data,edge_str,net_raster_info);
Np=length(node_data(:,1));

% calculate accessibility between raster
Nr=length(net_raster_info.raster_node(:,1));net_r2r=zeros(Nr,Nr);
for rf=1:Nr
    rnode=net_raster_info.node_raster(net_raster_info.node_raster(:,4)==rf,1);Rn=length(rnode);
    rdist=zeros(Np*Rn,1);%destination_node_raster_id,time
    for k=1:Rn
        rdist((k-1)*Np+(1:Np),1)=net_n2n(rnode(k),:);
    end
    net_r2r(rf,:)=accumarray(repmat(net_raster_info.node_raster(:,4),Rn,1),rdist)./(Rn*net_raster_info.raster_node(:,4));
end

%% calculate the optimal typical_node and the method error
raster_node=net_raster_info.raster_node;node_raster=net_raster_info.node_raster;
raster_typical_nodes=get_representative_nodes(raster_node,node_raster,[-node_type -node_street_len(:,1)],2);
typical_err_time=calculate_error_for_typical_node_based_methods(net_raster_info,node_data,edge_data,raster_typical_nodes,net_r2r);

%% calculate accessibility error for TMS
[trad_err_time,~]=calculate_accessibility_error_for_TMS(node_data,edge_data,area_raster_info,net_r2r);
err_time=[trad_err_time(1:3);typical_err_time];

