function [node_pair_inf,node_pair_path]=get_node_pair_inf_tc_noil(fnode,tnode,node_raster,local_nodes,local_net)

ic_nodes=node_raster(node_raster(:,4)==fnode,1);ic_nodes=local_nodes(ismember(local_nodes(:,4),ic_nodes),1); 
jc_nodes=node_raster(node_raster(:,4)==tnode,1);jc_nodes=local_nodes(ismember(local_nodes(:,4),jc_nodes),1);

node_pair_inf=zeros(length(local_nodes(:,1)),4);ntag=0;   % fnode_id, tnode_id, net_dist, travel_time
node_pair_path=zeros(1,20*length(local_nodes(:,1)));ptag=0;  % nodes in path1 NaN nodes in path2 NaN 

for i=1:length(ic_nodes)     
    in=ic_nodes(i);
    [local_tt,local_p,~]=graphshortestpath(local_net,in);   %in to the fastest path to all nodes in local_net
    for j=1:length(jc_nodes)
        jn=jc_nodes(j);
        path_R=local_p{jn};
        travel_time=local_tt(jn);
        if travel_time<Inf
            path_length=travel_time;  %under distance accessibility
            
%% under travel time accessibility
%             path_length=0;
%             for n=1:length(path_R)-1
%                 path_length=path_length+longitude_latitude(local_nodes(path_R(n),2),local_nodes(path_R(n),3),local_nodes(path_R(n+1),2),local_nodes(path_R(n+1),3))*1000;
%             end
%             
            ntag=ntag+1;
            node_pair_inf(ntag,:)=[local_nodes(in,4) local_nodes(jn,4) path_length travel_time];
            path_temp=local_nodes(path_R,4);
            node_pair_path(ptag+1:ptag+length(path_temp)+1)=[path_temp' NaN];
            ptag=ptag+length(path_temp)+1;
        end
    end
end
node_pair_inf=node_pair_inf(1:ntag,:);
node_pair_path=node_pair_path(1:ptag);


