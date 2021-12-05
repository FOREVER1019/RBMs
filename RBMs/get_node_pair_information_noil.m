function local_node_pair=get_node_pair_information_noil(net_raster_info,node_data,edge_data)

raster_data=net_raster_info.raster_data;raster_node=net_raster_info.raster_node;
raster_edge=net_raster_info.raster_edge;node_raster=net_raster_info.node_raster;
log_step=net_raster_info.log_lat_step(1);lat_step=net_raster_info.log_lat_step(2);

clear raster_info

% identify all neighboring edges from raster_edge
neibor_edge=raster_edge(raster_edge(:,4)==0,:);
local_node_pair=struct; % fnode_id, tnode_id, net_dist, travel_time

for ne=1:length(neibor_edge(:,1))
    % identify the local networks for two neighboring cells and combine them
    fnode=neibor_edge(ne,2);tnode=neibor_edge(ne,3);  % raster_node_id
    fcell=raster_node(fnode,2);tcell=raster_node(tnode,2);  % raster_id
    f_local_cell_id=raster_data(abs(raster_data(:,2)-raster_data(fcell,2))<=1.1*log_step & abs(raster_data(:,3)-raster_data(fcell,3))<=1.1*lat_step,1);
    f_local_node=node_raster(ismember(node_raster(:,2),f_local_cell_id),1);
    t_local_cell_id=raster_data(abs(raster_data(:,2)-raster_data(tcell,2))<=1.1*log_step & abs(raster_data(:,3)-raster_data(tcell,3))<=1.1*lat_step,1);
    t_local_node=node_raster(ismember(node_raster(:,2),t_local_cell_id),1);
    local_nodes=union(f_local_node,t_local_node);
    local_edges=edge_data(ismember(edge_data(:,2),local_nodes(:,1)) & ismember(edge_data(:,3),local_nodes(:,1)),[2 3 4 6]);
    % renumber node id in local_edges for components calculation
    [~,local_edges(:,1)]=ismember(local_edges(:,1),local_nodes);[~,local_edges(:,2)]=ismember(local_edges(:,2),local_nodes);
    local_nodes=node_data(local_nodes(:,1),:);
    local_nodes(:,4)=local_nodes(:,1);    %the fourth column of local_nodes stores the serial number of the node in org_node_data
    local_nodes(:,1)=(1:length(local_nodes(:,1)))';

    
   %% obtain and save the node pair information between raster c and neighboring rasters
    % calculate the fastest path of any two points through the local_net
    local_net=sparse([local_edges(:,1);local_edges(:,2)],[local_edges(:,2);local_edges(:,1)],[local_edges(:,3)./(local_edges(:,4)*1000/60);local_edges(:,3)./(local_edges(:,4)*1000/60)],length(local_nodes(:,1)),length(local_nodes(:,1)));
%     local_net=sparse([local_edges(:,1);local_edges(:,2)],[local_edges(:,2);local_edges(:,1)],[local_edges(:,3);local_edges(:,3)],length(local_nodes(:,1)),length(local_nodes(:,1)));
    % in order to minimize the travel time and the number of paths, calculate the path based on the raster with a small number of nodes
    if length(find(node_raster(:,4)==fnode))<length(find(node_raster(:,4)==tnode))
        [node_pair_inf,node_pair_path]=get_node_pair_inf_tc_noil(fnode,tnode,node_raster,local_nodes,local_net);
    else
        [node_pair_inf,node_pair_path]=get_node_pair_inf_tc_noil(tnode,fnode,node_raster,local_nodes,local_net);
    end
    local_node_pair(ne).basic_info=node_pair_inf; 
    local_node_pair(ne).path=node_pair_path;
end


