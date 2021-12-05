function [DT_node,DT_edge_full]=create_DT(node_data,N,bounding_box,type)
% create connected DT network with given node number and edge number E
% DT_node: node_id log lat
% DT_edge_save:edge_id,from_node_id, to_node_id, edge_length(m)
%type=1 create DT with given node location
%type=2 create DT with randomly generated node location

if type==1
    DT_node=node_data;
else
%     bounding_box=[min(node_data(:,2)) min(node_data(:,3));max(node_data(:,2)) max(node_data(:,3))];
    DT_node=zeros(N,3);DT_node(:,1)=1:N;
    DT_node(:,2)=bounding_box(1,1)+rand(N,1)*(bounding_box(2,1)-bounding_box(1,1));
    DT_node(:,3)=bounding_box(1,2)+rand(N,1)*(bounding_box(2,2)-bounding_box(1,2));
end

% create a Delaunay triangulation of given node_data
TRI = delaunay(DT_node(:,2),DT_node(:,3));
DT_edge_full=[TRI(:,1) TRI(:,2);TRI(:,1) TRI(:,3);TRI(:,2) TRI(:,3)];
DT_edge_full=[min(DT_edge_full(:,1),DT_edge_full(:,2)),max(DT_edge_full(:,1),DT_edge_full(:,2))];
DT_edge_full=unique(DT_edge_full,'rows');

for e=1:length(DT_edge_full(:,1))
    DT_edge_full(e,3)=longitude_latitude(DT_node(DT_edge_full(e,1),2),DT_node(DT_edge_full(e,1),3),DT_node(DT_edge_full(e,2),2),DT_node(DT_edge_full(e,2),3))*1000;
end

% figure
% for e=1:length(DT_edge_save(:,1))
%     plot([DT_node(DT_edge_save(e,1),2) DT_node(DT_edge_save(e,2),2)],[DT_node(DT_edge_save(e,1),3) DT_node(DT_edge_save(e,2),3)],'k-');hold on;
% end
