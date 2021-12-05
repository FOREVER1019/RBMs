function raster_info=generate_network_raster_information_friction_map(org_node_data,org_edge_data,raster_para)
%raster_para.center: with city center as default, and can be also adjusted around city center
%raster_para.size:the width and length of each square raster
%raster_para.log_lat_step: the longtitude and latitude interval per km
%raster_para.boundary_X and boundary_Y: with NaN to differentiate different boundary component
%raster_info.log_lat_step;
%raster_info.raster_data:raster_id,raster_longitude, raster_latitude;
%raster_info.node_raster:node_id,raster_id,covered_node_component_id
%raster_info.raster_node:raster_id,covered_node_component_id,number_of_covered_component_nodes,typical_node_id1,typical_node_id2,typical_node_id3.)
%typical_node_id1 is the node id with the minimum ecludean distance to raster center;
%typical_node_id2 is the node id with the mimumum average ecludean distance to all other component nodes
%typical_node_id3 is the node id with the mimumum average shortest network distance to all other component nodes
%typical_node_id4 is the node id with the minimum average fastest travel time to all other component nodes
%raster_edge: edge_id, from_raster_node_id, to_raster_node_id,0 or from_node_id, 0 or to_node_id, 0 or org_edge_id
define_constants;
[~,R] = geotiffread('friction_surface_2015_v1.0\friction_surface_2015_v1.0.tif');
lat_step=R.CellExtentInLatitude;log_step=R.CellExtentInLongitude;

%% extract the network area bounding box
min_log=min([raster_para.boundary_X org_node_data(:,NX)']);max_log=max([raster_para.boundary_X org_node_data(:,NX)']);
min_lat=min([raster_para.boundary_Y org_node_data(:,NY)']);max_lat=max([raster_para.boundary_Y org_node_data(:,NY)']);

%% compute the location of raster nodes in the longtitude and latitude horizons
bottom_y=floor((R.LatitudeLimits(2)-min_lat)/lat_step)+1;up_y=floor((R.LatitudeLimits(2)-max_lat)/lat_step)+1;
left_x=floor((min_log-R.LongitudeLimits(1))/log_step)+1;right_x=floor((max_log-R.LongitudeLimits(1))/log_step)+1;

%% generate and record each raster location data
raster_data=zeros(abs(right_x-left_x)*abs(up_y-bottom_y),3);rid=0;
node_raster=org_node_data(:,[1 1 1 1]);node_raster(:,2)=0;
for yid=min(up_y,bottom_y):max(up_y,bottom_y)
    for xid=min(left_x,right_x):max(left_x,right_x)
        [rlat,rlog]=intrinsicToGeographic(R,xid,yid);
        rnode=org_node_data(abs(org_node_data(:,NX)-rlog)<=1/2*log_step & abs(org_node_data(:,NY)-rlat)<=1/2*lat_step,:);
        if ~isempty(rnode)
            rid=rid+1;raster_data(rid,1:3)=[rid rlog rlat];
            node_raster(rnode(:,1),2)=rid;
        end
    end
end
raster_data=raster_data(1:rid,:);

% assign a raster id to those nodes not assigned a raster id using the above codes
if sum(node_raster(:,2)==0)>0
    temp_node=node_raster(node_raster(:,2)==0,1);
    for i=1:length(temp_node)
        dist_raster=sortrows([raster_data(:,1) abs(raster_data(:,2)-org_node_data(temp_node(i),NX))+abs(raster_data(:,3)-org_node_data(temp_node(i),NY))],2);
        node_raster(temp_node(i),2)=dist_raster(1,1);
    end
end

%% determine the raster node data, including separating a raster into multiple raster nodes 
Nr=length(raster_data(:,1));
raster_node=zeros(Nr*2,8);rid=0;%raster_node_id,raster_id,raster_component_id,number_of_component_nodes,basic_typical_node1,basic_typical_node2,basic_typical_node3,basic_typical_node4
for r=1:Nr
    org_raster_node=node_raster(node_raster(:,2)==r,1);
    local_raster_id=raster_data(abs(raster_data(:,2)-raster_data(r,2))<=1.1*log_step & abs(raster_data(:,3)-raster_data(r,3))<=1.1*lat_step,1);
    local_node=node_raster(ismember(node_raster(:,2),local_raster_id),1);
    local_edge=org_edge_data(ismember(org_edge_data(:,2),local_node(:,1)) & ismember(org_edge_data(:,3),local_node(:,1)),:);
    
    % 按照顺序对节点和边重新编号
    [~,local_edge(:,2)]=ismember(local_edge(:,2),local_node);
    [~,local_edge(:,3)]=ismember(local_edge(:,3),local_node);
    [~,new_raster_node]=ismember(org_raster_node,local_node);
    
    % 寻找栅格r中的节点所处团，确定每个节点与栅格点的对应关系
    snet= sparse([local_edge(:,2);local_edge(:,3)],[local_edge(:,3);local_edge(:,2)],[local_edge(:,4);local_edge(:,4)],length(local_node),length(local_node));
    sdist=all_shortest_paths(snet);[ci,~] = components(snet); %there might be some isolated node
    raster_com=unique(ci(new_raster_node)); % 栅格r中节点所在团编号
    
    edge_speed_time=update_road_edge_speed_time(local_edge);
    fnet=sparse([local_edge(:,2);local_edge(:,3)],[local_edge(:,3);local_edge(:,2)],[edge_speed_time(:,2);edge_speed_time(:,2)],length(local_node),length(local_node));
    fdist=all_shortest_paths(fnet);
    
    % 根据栅格c中的团数量，将栅格c分成多个栅格
    for cid=1:length(raster_com)
        raster_node_com=intersect(local_node(ci==raster_com(cid)),org_raster_node);
        node_raster(raster_node_com,3)=cid; 
        rid=rid+1;raster_node(rid,1:4)=[rid r cid length(raster_node_com)];
        
        %identify the typical node in the cid component set of the raster r
        if length(raster_node_com)==1
           raster_node(rid,5:8)=raster_node_com(1);
        else
            % the first method is to identify according to the nearest eclidean distance to the center of raster r
            dist_temp=zeros(length(raster_node_com),2);
            for n=1:length(raster_node_com)
                dist_temp(n,:)=[raster_node_com(n) longitude_latitude(org_node_data(raster_node_com(n),2),org_node_data(raster_node_com(n),3),raster_data(r,2),raster_data(r,3))];
            end
            dist_temp=sortrows(dist_temp,2);raster_node(rid,5)=dist_temp(1,1);
            
            % 离同一团中其它节点直线距离最近的typical node
            dist_temp=zeros(length(raster_node_com),length(raster_node_com));
            for i=1:length(raster_node_com)-1
                for j=i+1:length(raster_node_com)
                    dist_temp(i,j)=longitude_latitude(org_node_data(raster_node_com(i),2),org_node_data(raster_node_com(i),3),org_node_data(raster_node_com(j),2),org_node_data(raster_node_com(j),3));
                    dist_temp(j,i)=dist_temp(i,j);
                end
            end
            dist_temp=sortrows([raster_node_com sum(dist_temp,2)],2);raster_node(rid,6)=dist_temp(1,1);
            
            %离同一团中其它节点网络距离最近的typical node
            [~,new_raster_node_com]=ismember(raster_node_com,local_node);
            dist_temp=sortrows([raster_node_com sum(sdist(new_raster_node_com,new_raster_node_com),2)],2);raster_node(rid,7)=dist_temp(1,1);
            
            %离同一团中其它节点网络旅行时间最近的typical node
            [~,new_raster_node_com]=ismember(raster_node_com,local_node);
            dist_temp=sortrows([raster_node_com sum(fdist(new_raster_node_com,new_raster_node_com),2)],2);raster_node(rid,8)=dist_temp(1,1);
        end
    end  
end
raster_node=raster_node(1:rid,:);

%construct the raster edge data among raster nodes
raster_edge=zeros(rid*3,6);eid=0;%raster_edge_id, from_raster_node_id, to_raster_node_id, from_node_id (for long edges, 0 otherwise),to_node_id (for long edges, 0 otherwise),long_edge_id_in_org_edge_data
for r=1:Nr
    basic_raster_node=node_raster(node_raster(:,2)==r,1);
    local_raster_id=raster_data(abs(raster_data(:,2)-raster_data(r,2))<=1.1*log_step & abs(raster_data(:,3)-raster_data(r,3))<=1.1*lat_step,1);
    local_node=node_raster(ismember(node_raster(:,2),local_raster_id),1);
    local_edge=org_edge_data(ismember(org_edge_data(:,2),local_node(:,1)) & ismember(org_edge_data(:,3),local_node(:,1)),:);

    % 按照顺序对节点和边重新编号
    [~,local_edge(:,2)]=ismember(local_edge(:,2),local_node);[~,local_edge(:,3)]=ismember(local_edge(:,3),local_node);
    [~,new_raster_node]=ismember(basic_raster_node,local_node);
    
    % 寻找栅格r中的节点所处团，确定每个节点与栅格点的对应关系
    net= sparse([local_edge(:,2);local_edge(:,3)],[local_edge(:,3);local_edge(:,2)],[local_edge(:,4);local_edge(:,4)],length(local_node),length(local_node));
    [ci,~] = components(net);  %there might be some isolated node
    raster_com=unique(ci(new_raster_node)); % 栅格r中节点所在团编号
    % 根据栅格c中的团数量，将栅格c分成多个栅格
    for cid=1:length(raster_com)
        center_rid=raster_node(raster_node(:,2)==r & raster_node(:,3)==cid,1);  % 栅格r中团raster_com(cid)对应的raster_node编号
        com_node=node_raster(local_node(ci==raster_com(cid)),:);  % 在团raster_com(cid)里面的所有局部栅格点
        neighbor_rnode=setdiff(unique(com_node(:,2:3),'row'),[r cid],'row');  % 在团raster_com(cid)里面的其它栅格点的raster data, 和团编号 （除了中心栅格外）
        neighbor_rnode=neighbor_rnode(ismember(neighbor_rnode(:,1),local_raster_id),:); %保证是在
        
        if ~isempty(neighbor_rnode)
            for h=1:length(neighbor_rnode(:,1))
                neighbor_rid=raster_node(raster_node(:,2)==neighbor_rnode(h,1) & raster_node(:,3)==neighbor_rnode(h,2),1);
                if eid==0 || sum((raster_edge(1:eid,2)==center_rid & raster_edge(1:eid,3)==neighbor_rid) | (raster_edge(1:eid,3)==center_rid & raster_edge(1:eid,2)==neighbor_rid))==0
                   eid=eid+1;raster_edge(eid,1:3)=[eid center_rid neighbor_rid];
                end
            end
        end 
    end
end

for n=1:length(node_raster(:,1))
    node_raster(n,4)=raster_node(raster_node(:,2)==node_raster(n,2) & raster_node(:,3)==node_raster(n,3),1);
end

%long edges connecting not neigboring raster nodes 
for e=1:length(org_edge_data(:,1))
    fnode=org_edge_data(e,2);tnode=org_edge_data(e,3);
    fraster=node_raster(fnode,2);fcell=node_raster(fnode,4);     
    traster=node_raster(tnode,2);tcell=node_raster(tnode,4); 
    if abs(raster_data(fraster,2)-raster_data(traster,2))>1.1*log_step||abs(raster_data(fraster,3)-raster_data(traster,3))>1.1*lat_step
        temp_raster=raster_edge((raster_edge(1:eid,2)==fcell & raster_edge(1:eid,3)==tcell) | (raster_edge(1:eid,3)==fcell & raster_edge(1:eid,2)==tcell),:);
        if isempty(temp_raster)
           eid=eid+1;raster_edge(eid,:)=[eid fcell tcell fnode tnode e];
        else
            if org_edge_data(e,EH)<org_edge_data(temp_raster(1,6),EH)
               raster_edge(temp_raster(1,1),2:6)=[fcell tcell fnode tnode e];
            end
        end
    end
end
raster_edge=raster_edge(1:eid,:);

raster_info=struct;
raster_info.boundary_X=raster_para.boundary_X;
raster_info.boundary_Y=raster_para.boundary_Y;
raster_info.center=raster_para.center;
raster_info.raster_data=raster_data;
raster_info.node_raster=node_raster;
raster_info.log_lat_step=[log_step lat_step];
raster_info.raster_node=raster_node;
raster_info.raster_edge=raster_edge;
