function [err_time,traditional_raster_net,traditional_net_r2r]=calculate_accessibility_error_for_TMS(node_data,edge_data,area_raster_info,net_r2r)

log_step=area_raster_info.log_lat_step(1);lat_step=area_raster_info.log_lat_step(2);
raster_data_road=area_raster_info.raster_data(area_raster_info.raster_data(:,6)<3,:);
org_raster_id=raster_data_road(:,1);raster_data_road(:,1)=1:length(raster_data_road(:,1));
% the speed of each raster
for r=1:length(raster_data_road(:,1))
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
    raster_data_road(r,4)=fspeed;
end

raster_edge_road=zeros(length(raster_data_road(:,1))*4,4);eid=0;
%establish the connect with those type-1/2 raster
for r=1:length(raster_data_road(:,1))
    rlog=raster_data_road(r,2);rlat=raster_data_road(r,3);
    local_raster_id=raster_data_road(abs(raster_data_road(:,2)-rlog)<=1.1*log_step & abs(raster_data_road(:,3)-rlat)<=1.1*lat_step,1);
    local_raster_id=setdiff(local_raster_id,unique(raster_edge_road(raster_edge_road(1:eid,2)==r | raster_edge_road(1:eid,3)==r,2:3)));
    local_raster_id=setdiff(local_raster_id,r);
    if ~isempty(local_raster_id)
        for k=1:length(local_raster_id)
            rdist=longitude_latitude(raster_data_road(r,2),raster_data_road(r,3),raster_data_road(local_raster_id(k),2),raster_data_road(local_raster_id(k),3));
            eid=eid+1;raster_edge_road(eid,:)=[eid r local_raster_id(k) (rdist*raster_data_road(r,4)+rdist*raster_data_road(local_raster_id(k),4))/2];
        end
    end
end
raster_edge_road=raster_edge_road(1:eid,:);
traditional_raster_net=sparse([raster_edge_road(:,2);raster_edge_road(:,3)],[raster_edge_road(:,3);raster_edge_road(:,2)],[raster_edge_road(:,4);raster_edge_road(:,4)],length(raster_data_road(:,1)),length(raster_data_road(:,1)));
traditional_net_r2r=all_shortest_paths(traditional_raster_net);
% [traditional_tt,traditional_pp,~]=graphshortestpath(traditional_raster_net,487);traditional_tt(524)
% [a,b]=components(traditional_raster_net);
%  get net_time_r2r for type 1 raster node
raster_node_id=area_raster_info.raster_node(area_raster_info.raster_node(:,9)==1,2);
[~,loc]=ismember(raster_node_id,org_raster_id);
traditional_net_r2r=traditional_net_r2r(loc,loc);

%¼ÆËãÎó²î
Np=length(node_data(:,1));
raster_node_num=area_raster_info.raster_node(area_raster_info.raster_node(:,9)==1,4);
abs_err_time=raster_node_num'*abs(net_r2r-traditional_net_r2r)*raster_node_num/Np/(Np-1);
r2r_vec=zeros(length(net_r2r(:,1))*length(net_r2r(:,1)),3);
r2r_vec(:,1)=reshape(net_r2r,length(net_r2r(:,1))*length(net_r2r(:,1)),1);
r2r_vec(:,2)=reshape(traditional_net_r2r,length(net_r2r(:,1))*length(net_r2r(:,1)),1);
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

