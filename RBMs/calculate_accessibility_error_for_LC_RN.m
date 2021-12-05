function [err_time,raster_D_typ]=calculate_accessibility_error_for_LC_RN(net_raster_info,node_data,edge_data,net_r2r,typical_node,node_pair)

edge_speed_time=update_road_edge_speed_time(edge_data);
edge_data(:,6)=edge_speed_time(:,1);
raster_edge=net_raster_info.raster_edge;
raster_node=net_raster_info.raster_node;
Np=length(node_data(:,1));
% get raster_edge_long
raster_edge_long=raster_edge(raster_edge(:,4)~=0,1:6);
raster_edge_long(:,7)=edge_data(raster_edge_long(:,6),4)./(edge_data(raster_edge_long(:,6),6)*1000/60);

neibor_edge=raster_edge(raster_edge(:,4)==0,1:4);
raster_edge_typ=zeros(length(raster_edge(:,1)),4);
raster_edge_typ(length(neibor_edge(:,1))+1:length(raster_edge(:,1)),:)=raster_edge_long(:,[1 2 3 7]);

% Directly use the fastest travel time between typical_node as weights
for e=1:length(neibor_edge(:,1))
    fnode=typical_node(neibor_edge(e,2));tnode=typical_node(neibor_edge(e,3));
    node_pair_inf=node_pair(e).basic_info;
    [~,r_index]=ismember([fnode,tnode],node_pair_inf(:,1:2),'rows');
    if r_index~=0
        neibor_edge(e,4)=node_pair_inf(r_index,4);
    else
        [~,r_index]=ismember([tnode,fnode],node_pair_inf(:,1:2),'rows');
        neibor_edge(e,4)=node_pair_inf(r_index,4);
    end
end

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

abs_err_prop(1)=raster_node_num_vec'*(abs(r2r_vec(:,1)-r2r_vec(:,2))<5)/Np/(Np-1);
abs_err_prop(2)=raster_node_num_vec'*(abs(r2r_vec(:,1)-r2r_vec(:,2))<10)/Np/(Np-1);
abs_err_prop(3)=raster_node_num_vec'*(abs(r2r_vec(:,1)-r2r_vec(:,2))<30)/Np/(Np-1);
rel_err_prop(1)=raster_node_num_vec'*(abs(r2r_vec(:,1)-r2r_vec(:,2))./r2r_vec(:,1)<0.05)/Np/(Np-1);
rel_err_prop(2)=raster_node_num_vec'*(abs(r2r_vec(:,1)-r2r_vec(:,2))./r2r_vec(:,1)<0.1)/Np/(Np-1);
rel_err_prop(3)=raster_node_num_vec'*(abs(r2r_vec(:,1)-r2r_vec(:,2))./r2r_vec(:,1)<0.2)/Np/(Np-1);


err_time=[abs_err_time rel_err_time cc_err_time abs_err_prop rel_err_prop];






