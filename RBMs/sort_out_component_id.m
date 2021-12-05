function [node_data,edge_data,edge_str,new_org_node]=sort_out_component_id(node_data,edge_data,edge_str)
define_constants;
node_data=node_data(ismember(node_data(:,1),unique(edge_data(:,[EF ET]))),:);
temp_str=struct;etag=0;
for e=1:length(edge_data(:,1))
    etag=etag+1;
    temp_str(etag).X=edge_str(edge_data(e)).X;
    temp_str(etag).Y=edge_str(edge_data(e)).Y; 
end
[~,edge_data(:,2)]=ismember(edge_data(:,2),node_data(:,1));
[~,edge_data(:,3)]=ismember(edge_data(:,3),node_data(:,1));
new_org_node=[(1:length(node_data(:,1)))' node_data(:,1)];
node_data(:,1)=(1:length(node_data(:,1)))';
edge_data(:,1)=(1:length(edge_data(:,1)))';
edge_str=temp_str(1:etag);