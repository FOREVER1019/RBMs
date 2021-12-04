function [err_time,improved_traditional_net_r2r]=calculate_accessibility_error_for_LC_MS(node_data,edge_data,area_raster_info,net_r2r)

raster_edge=area_raster_info.raster_edge(area_raster_info.raster_edge(:,7)==1,1:6);
raster_node=area_raster_info.raster_node;
edge_speed_time=update_road_edge_speed_time(edge_data);
raster_data_t1=area_raster_info.raster_data(area_raster_info.raster_data(:,6)==1,:);
org_raster_id=raster_data_t1(:,1);raster_data_t1(:,1)=1:length(raster_data_t1(:,1));
% the speed of each raster
for r=1:length(raster_data_t1(:,1))
    rid=org_raster_id(r,1);
    cover_node=area_raster_info.node_raster(area_raster_info.node_raster(:,2)==rid,1);
    if ~isempty(cover_node)
        fspeed=max(edge_data(ismember(edge_data(:,2),cover_node) | ismember(edge_data(:,3),cover_node),6));
    else
        fspeed=0;
    end
    temp_edge=area_raster_info.edge_raster(area_raster_info.edge_raster(:,2)==rid,1);
    if  ~isempty(temp_edge)
        fspeed=60/max(fspeed,max(edge_data(temp_edge,6)));%the unit is also minute/km
    else
        fspeed=60/fspeed;
    end
    raster_data_t1(r,4)=fspeed;
end

neibor_edge=raster_edge(raster_edge(:,4)==0,1:4);
for e=1:length(neibor_edge(:,1))
    fraster=raster_node(neibor_edge(e,2),2);traster=raster_node(neibor_edge(e,3),2);
    rdist=longitude_latitude(raster_data_t1(fraster,2),raster_data_t1(fraster,3),raster_data_t1(traster,2),raster_data_t1(traster,3));
    neibor_edge(e,4)=(rdist*raster_data_t1(fraster,4)+rdist*raster_data_t1(traster,4))/2;
end
raster_edge_long=raster_edge(raster_edge(:,4)~=0,1:6);
raster_edge_long(:,4)=edge_speed_time(raster_edge_long(:,6),2);
raster_edge_t=zeros(length(raster_edge(:,1)),4);
raster_edge_t(length(neibor_edge(:,1))+1:length(raster_edge(:,1)),:)=raster_edge_long(:,1:4);
raster_edge_t(1:length(neibor_edge(:,1)),:)=neibor_edge;

raster_net_t=sparse([raster_edge_t(:,2);raster_edge_t(:,3)],[raster_edge_t(:,3);raster_edge_t(:,2)],[raster_edge_t(:,4);raster_edge_t(:,4)]);
improved_traditional_net_r2r=all_shortest_paths(raster_net_t);

Np=length(node_data(:,1));
raster_node_num=area_raster_info.raster_node(area_raster_info.raster_node(:,9)==1,4);
abs_err_time=raster_node_num'*abs(net_r2r-improved_traditional_net_r2r)*raster_node_num/Np/(Np-1);

r2r_vec=zeros(length(net_r2r(:,1))*length(net_r2r(:,1)),3);
r2r_vec(:,1)=reshape(net_r2r,length(net_r2r(:,1))*length(net_r2r(:,1)),1);
r2r_vec(:,2)=reshape(improved_traditional_net_r2r,length(net_r2r(:,1))*length(net_r2r(:,1)),1);
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

% err_time=abs_err_time;
err_time=[abs_err_time rel_err_time cc_err_time abs_err_prop rel_err_prop];

