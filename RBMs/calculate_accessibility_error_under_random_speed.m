function [err_time,net_r2r]=calculate_accessibility_error_under_random_speed(node_data,edge_data,edge_str,net_raster_info,area_raster_info)

%% calculate accessibility between raster
net_r2r=compute_primary_net_time_r2r(node_data,edge_data,net_raster_info);

%% calculate the optimal typical_node and the method error
% calculate the accessibility and error of the improved method
Np=length(node_data(:,1));
node_type=get_node_info(net_raster_info,node_data,edge_data,1);

street_info=extract_road_street_information(node_data,edge_data,edge_str, 2);
node_street_len=zeros(Np,4);%max_street_len,sum_street_len,max_number_of_nodes_along_a_street, sum numer of nodes along all streets passing through the node
for n=1:Np
    temp_edge=edge_data(edge_data(:,2)==n | edge_data(:,3)==n,1);
    sid=unique(street_info.ids(temp_edge,2));temp_len=street_info.length(sid,2);temp_sid=zeros(length(sid),1);
    for k=1:length(sid)
        temp_sid(k)=length(unique(edge_data(street_info.ids(street_info.ids(:,2)==sid(k),1),[2 3])));
    end
    node_street_len(n,:)=[max(temp_len) sum(temp_len) max(temp_sid) sum(temp_sid)];
end
node_street_len(:,1:2)=node_street_len(:,1:2)*0.001;

raster_node=net_raster_info.raster_node;node_raster=net_raster_info.node_raster;
raster_typical_nodes=get_representative_nodes(raster_node,node_raster,[-node_type -node_street_len(:,1)],2);
typ_err_time=calculate_error_for_typical_node_based_methods(net_raster_info,node_data,edge_data,raster_typical_nodes,net_r2r);


%% calculate accessibility error for TMS
[trad_err_time,~]=calculate_accessibility_error_for_TMS(node_data,edge_data,area_raster_info,net_r2r);
err_time=[trad_err_time(1:3);typ_err_time];

