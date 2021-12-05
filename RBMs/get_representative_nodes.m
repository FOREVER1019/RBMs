function typical_node=get_representative_nodes(raster_data,node_raster,node_info,type)
typical_node=zeros(length(raster_data(:,1)),1);
% take the node with the smallest feature value in the raster as the typical_node
if type==1
    node_info=[node_info(:,1) (1:length(node_info(:,1)))'];
    node_info=node_info(randperm(length(node_info(:,1))),:);
    local_dist_temp=sortrows(node_info,1);
   
%     local_dist_temp=sortrows([node_info(:,1) (1:length(node_info(:,1)))']);
    local_dist_temp(:,3)=node_raster(local_dist_temp(:,2),4);
    [loc,index,~]=unique(local_dist_temp(:,3));
    typical_node(loc,1)=local_dist_temp(index,2);
end
% take the two nodes with the smallest feature value in the raster as typical_nodes
if type==2
    node_info=[node_info(:,1:2) (1:length(node_info(:,1)))'];
    node_info=node_info(randperm(length(node_info(:,1))),:);
    local_dist_temp=sortrows(node_info,[1 2]);

%     local_dist_temp=sortrows([node_info(:,1:2) (1:length(node_info(:,1)))']);
    local_dist_temp(:,4)=node_raster(local_dist_temp(:,3),4);
    [loc,index,~]=unique(local_dist_temp(:,4));
    typical_node(loc,1)=local_dist_temp(index,3);    
end
% take the three nodes with the smallest feature value in the raster as typical_nodes
if type==3
    node_info=[node_info(:,1:3) (1:length(node_info(:,1)))'];
    node_info=node_info(randperm(length(node_info(:,1))),:);
    local_dist_temp=sortrows(node_info,[1 2 3]);

%     local_dist_temp=sortrows([node_info(:,1:3) (1:length(node_info(:,1)))']);
    local_dist_temp(:,5)=node_raster(local_dist_temp(:,4),4);
    [loc,index,~]=unique(local_dist_temp(:,5));
    typical_node(loc,1)=local_dist_temp(index,4);
end

