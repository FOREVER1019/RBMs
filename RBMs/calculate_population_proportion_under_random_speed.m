function pop_prop=calculate_population_proportion_under_random_speed(org_node_data,org_edge_data,org_edge_str,net_raster_info,area_raster_info,qj_hospitals)


%% calculate accessibility between raster
define_constants;
edge_speed_time=update_road_edge_speed_time(org_edge_data);
fnet=sparse([org_edge_data(:,EF);org_edge_data(:,ET)],[org_edge_data(:,ET);org_edge_data(:,EF)],[edge_speed_time(:,2);edge_speed_time(:,2)],length(org_node_data(:,1)),length(org_node_data(:,1)));%for calculating the shortest paths
node_raster=net_raster_info.node_raster;raster_node=net_raster_info.raster_node; 
hos_raster=unique(node_raster(qj_hospitals(:,4),4));Nh=length(hos_raster);
Nr=length(raster_node(:,1));Np=length(org_node_data(:,1));
net_r2r=zeros(Nh,Nr);
for rf=1:Nh
    rnode=node_raster(node_raster(:,4)==hos_raster(rf),1);Rn=length(rnode);
    rdist=zeros(Np*Rn,1);%destination_node_raster_id,time
    for k=1:Rn
        rdist((k-1)*Np+(1:Np),1)=shortest_paths(fnet,rnode(k));
    end
    net_r2r(rf,:)=accumarray(repmat(node_raster(:,4),Rn,1),rdist)./(Rn*raster_node(:,4));
end
prim_acc=min(net_r2r);

%% calculate the optimal typical_node and the method error
% calculate the accessibility and error of the improved method
node_type=get_node_info(net_raster_info,org_node_data,org_edge_data,1);

street_info=extract_road_street_information(org_node_data,org_edge_data,org_edge_str, 2);
node_street_len=zeros(Np,4);%max_street_len,sum_street_len,max_number_of_nodes_along_a_street, sum numer of nodes along all streets passing through the node
for n=1:Np
    temp_edge=org_edge_data(org_edge_data(:,2)==n | org_edge_data(:,3)==n,1);
    if ~isempty(temp_edge)        
    sid=unique(street_info.ids(temp_edge,2));temp_len=street_info.length(sid,2);temp_sid=zeros(length(sid),1);
    for k=1:length(sid)
        temp_sid(k)=length(unique(org_edge_data(street_info.ids(street_info.ids(:,2)==sid(k),1),[2 3])));
    end
    node_street_len(n,:)=[max(temp_len) sum(temp_len) max(temp_sid) sum(temp_sid)];
    end
end
node_street_len(:,1:2)=node_street_len(:,1:2)*0.001;

raster_node=net_raster_info.raster_node;node_raster=net_raster_info.node_raster;
typical_node=get_representative_nodes(raster_node,node_raster,[-node_type -node_street_len(:,1)],2);

neibor_edge=get_typical_nodes_connection_information(net_raster_info,org_edge_data,typical_node);
raster_edge=net_raster_info.raster_edge;
raster_edge_long=raster_edge(raster_edge(:,4)~=0,1:6);
raster_edge_long(:,4)=org_edge_data(raster_edge_long(:,6),4)./(org_edge_data(raster_edge_long(:,6),6)*1000/60);
raster_edge_typ=zeros(length(raster_edge(:,1)),4);
raster_edge_typ(length(neibor_edge(:,1))+1:length(raster_edge(:,1)),:)=raster_edge_long(:,1:4);
raster_edge_typ(1:length(neibor_edge(:,1)),:)=neibor_edge(:,1:4);
nrm_rnet=sparse([raster_edge_typ(:,2);raster_edge_typ(:,3)],[raster_edge_typ(:,3);raster_edge_typ(:,2)],[raster_edge_typ(:,4);raster_edge_typ(:,4)]);

nrm_r2r=zeros(Nh,Nr);
for rf=1:Nh
    nrm_r2r(rf,:)=shortest_paths(nrm_rnet,hos_raster(rf));
end
nrm_acc=min(nrm_r2r);

%% calculate the error of traditional raster method
log_step=area_raster_info.log_lat_step(1);lat_step=area_raster_info.log_lat_step(2);
raster_data_road=area_raster_info.raster_data(area_raster_info.raster_data(:,6)<3,:);
org_raster_id=raster_data_road(:,1);raster_data_road(:,1)=1:length(raster_data_road(:,1));
% the speed of each raster
for r=1:length(raster_data_road(:,1))
    rid=org_raster_id(r,1);
    cover_node=area_raster_info.node_raster(area_raster_info.node_raster(:,2)==rid,1);
    if ~isempty(cover_node)
        fspeed=max(org_edge_data(ismember(org_edge_data(:,2),cover_node) | ismember(org_edge_data(:,3),cover_node),6));
    else
        fspeed=0;
    end
    temp_edge=area_raster_info.edge_raster(area_raster_info.edge_raster(:,2)==rid,1);
    if  ~isempty(temp_edge)
        fspeed=60/max(fspeed,max(org_edge_data(temp_edge,6)));%the unit is also minute/km
    else
        fspeed=60/fspeed;
    end
    if isempty(fspeed)
        fspeed=0;
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
traditional_rnet=sparse([raster_edge_road(:,2);raster_edge_road(:,3)],[raster_edge_road(:,3);raster_edge_road(:,2)],[raster_edge_road(:,4);raster_edge_road(:,4)],length(raster_data_road(:,1)),length(raster_data_road(:,1)));

hos_raster_t=unique(node_raster(qj_hospitals(:,4),2));Nh=length(hos_raster_t);

trad_r2r=zeros(Nh,length(traditional_rnet(:,1)));
for rf=1:Nh
    trad_r2r(rf,:)=shortest_paths(traditional_rnet,hos_raster_t(rf));
end
trad_acc=min(trad_r2r);

raster_data_road=area_raster_info.raster_data(area_raster_info.raster_data(:,6)<3,:);
org_raster_id=raster_data_road(:,1);
raster_node_id=area_raster_info.raster_node(area_raster_info.raster_node(:,9)==1,2);
[~,loc]=ismember(raster_node_id,org_raster_id);
trad_acc=trad_acc(loc); 

%% calculate the proportion of service population--Method 2, people are in the raster
raster_pop=area_raster_info.raster_data(area_raster_info.raster_data(:,6)==1,5);
raster_node=net_raster_info.raster_node;raster_data=net_raster_info.raster_data;
rnode_pop=zeros(length(raster_node(:,1)),1);
for r=1:length(raster_data(:,1))
    rid=raster_node(raster_node(:,2)==r,1);
    rnode_num=raster_node(rid,4);
    rnode_pop(rid)=rnode_num*raster_pop(r)/sum(rnode_num);
end
pop_prop(1,:)=[sum(rnode_pop(prim_acc<=60)) sum(rnode_pop(nrm_acc<=60)) sum(rnode_pop(trad_acc<=60))]/sum(rnode_pop);
pop_prop(2,:)=[sum(rnode_pop(prim_acc<=30)) sum(rnode_pop(nrm_acc<=30)) sum(rnode_pop(trad_acc<=30))]/sum(rnode_pop);



