function net_r2r=compute_primary_net_time_r2r(node_data,edge_data,net_raster_info)
define_constants;
edge_speed_time=update_road_edge_speed_time(edge_data);
fnet=sparse([edge_data(:,EF);edge_data(:,ET)],[edge_data(:,ET);edge_data(:,EF)],[edge_speed_time(:,2);edge_speed_time(:,2)]);%for calculating the shortest paths
node_raster=net_raster_info.node_raster;raster_node=net_raster_info.raster_node; clear raster_info;
Nr=length(raster_node(:,1));Np=length(node_data(:,1));net_r2r=zeros(Nr,Nr);
for rf=1:Nr
    rnode=node_raster(node_raster(:,4)==rf,1);Rn=length(rnode);
    rdist=zeros(Np*Rn,1);%destination_node_raster_id,time
    for k=1:Rn
        rdist((k-1)*Np+(1:Np),1)=shortest_paths(fnet,rnode(k));
    end
    net_r2r(rf,:)=accumarray(repmat(node_raster(:,4),Rn,1),rdist)./(Rn*raster_node(:,4));
end