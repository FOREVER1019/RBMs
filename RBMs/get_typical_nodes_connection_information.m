function neibor_edge=get_typical_nodes_connection_information(raster_info,org_edge_data,typical_node)

raster_data=raster_info.raster_data;raster_node=raster_info.raster_node;
raster_edge=raster_info.raster_edge;node_raster=raster_info.node_raster;
log_step=raster_info.log_lat_step(1);lat_step=raster_info.log_lat_step(2);

clear raster_info

% identify all neighboring edges from raster_edge
neibor_edge=raster_edge(raster_edge(:,4)==0,:);
for e=1:length(neibor_edge(:,1))
    % identify the local networks for two neighboring cells and combine them
    fnode=neibor_edge(e,2);tnode=neibor_edge(e,3);  % raster_node_id
    fcell=raster_node(fnode,2);tcell=raster_node(tnode,2);  % raster_id
    f_local_cell_id=raster_data(abs(raster_data(:,2)-raster_data(fcell,2))<=1.1*log_step & abs(raster_data(:,3)-raster_data(fcell,3))<=1.1*lat_step,1);
    f_local_node=node_raster(ismember(node_raster(:,2),f_local_cell_id),1);
    t_local_cell_id=raster_data(abs(raster_data(:,2)-raster_data(tcell,2))<=1.1*log_step & abs(raster_data(:,3)-raster_data(tcell,3))<=1.1*lat_step,1);
    t_local_node=node_raster(ismember(node_raster(:,2),t_local_cell_id),1);
    local_node=union(f_local_node,t_local_node);
    local_edge=org_edge_data(ismember(org_edge_data(:,2),local_node(:,1)) & ismember(org_edge_data(:,3),local_node(:,1)),[2 3 4 6]);
    % renumber node id in local_edges for components calculation
    [~,local_edge(:,1)]=ismember(local_edge(:,1),local_node);[~,local_edge(:,2)]=ismember(local_edge(:,2),local_node);
    % calculate the travel time and travel path between two typical nodes
    local_net=sparse([local_edge(:,1);local_edge(:,2)],[local_edge(:,2);local_edge(:,1)],[local_edge(:,3)./(local_edge(:,4)*1000/60);local_edge(:,3)./(local_edge(:,4)*1000/60)],length(local_node),length(local_node));
    %% if there are multiple typical nodes, add them directly here
    for t=1:length(typical_node(1,:))
        tnode1=find(local_node(:,1)==typical_node(fnode,t));tnode2=find(local_node(:,1)==typical_node(tnode,t));
        local_tt=shortest_paths(local_net,tnode1);
        neibor_edge(e,t+3)=local_tt(tnode2);
    end
end
    
    
