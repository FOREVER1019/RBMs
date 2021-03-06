function raster_info=generate_network_raster_information(node_data,edge_data,raster_para)
%raster_para.center: with city center as default, and can be also adjusted around city center
%raster_para.size:the width and length of each square raster
%raster_para.log_lat_step: the longtitude and latitude interval per km
%raster_para.boundary_X and boundary_Y: with NaN to differentiate different boundary component
%raster_info.log_lat_step;
%raster_info.raster_data:raster_id,raster_longitude, raster_latitude;
%raster_info.node_raster:node_id,raster_id,covered_node_component_id
%raster_info.raster_node:raster_id,covered_node_component_id,number_of_covered_component_nodes,typical_node_id1,typical_node_id2,typical_node_id3.)
%raster_edge: edge_id, from_raster_node_id, to_raster_node_id,0 or from_node_id, 0 or to_node_id, 0 or org_edge_id
define_constants;
clog=raster_para.center(1);%city center longitude
clat=raster_para.center(2);%%city center latitude
log_step=raster_para.log_lat_step(1);%*raster_para.raster_size;%the longtitude interval for each raster size
lat_step=raster_para.log_lat_step(2);%*raster_para.raster_size;% the latitude interval for each raster size

%% extract the network area bounding box
min_log=min([raster_para.boundary_X node_data(:,NX)']);max_log=max([raster_para.boundary_X node_data(:,NX)']);
min_lat=min([raster_para.boundary_Y node_data(:,NY)']);max_lat=max([raster_para.boundary_Y node_data(:,NY)']);

%% compute the number of raster nodes in the longtitude and latitude horizons
nsize_x=ceil(abs(min_log-clog)/log_step)+ceil(abs(max_log-clog)/log_step);
nsize_y=ceil(abs(min_lat-clat)/lat_step)+ceil(abs(max_lat-clat)/lat_step);

%% generate and record each raster location data
raster_data=zeros(nsize_x*nsize_y,3);rid=0;
node_raster=node_data(:,[1 1 1 1]);node_raster(:,2)=0;
left_most_x=clog-ceil(abs(min_log-clog)/log_step)*log_step;
bottom_most_y=clat-ceil(abs(min_lat-clat)/lat_step)*lat_step;
for r=1:nsize_y
    rlat=bottom_most_y+(r-1/2)*lat_step;
    for c=1:nsize_x
        rlog=left_most_x+(c-1/2)*log_step;
        rnode=node_data(abs(node_data(:,NX)-rlog)<=1/2*log_step & abs(node_data(:,NY)-rlat)<=1/2*lat_step,:);
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
        dist_raster=sortrows([raster_data(:,1) abs(raster_data(:,2)-node_data(temp_node(i),NX))+abs(raster_data(:,3)-node_data(temp_node(i),NY))],2);
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
    local_edge=edge_data(ismember(edge_data(:,2),local_node(:,1)) & ismember(edge_data(:,3),local_node(:,1)),:);
    
    % renumber local nodes and edges
    [~,local_edge(:,2)]=ismember(local_edge(:,2),local_node);
    [~,local_edge(:,3)]=ismember(local_edge(:,3),local_node);
    [~,new_raster_node]=ismember(org_raster_node,local_node);
    
    % find the component where the node in the grid r is located, and determine the corresponding relationship between each node and the raster point
    snet= sparse([local_edge(:,2);local_edge(:,3)],[local_edge(:,3);local_edge(:,2)],[local_edge(:,4);local_edge(:,4)],length(local_node),length(local_node));
    [ci,~] = components(snet); %there might be some isolated node
    raster_com=unique(ci(new_raster_node)); % the component number of the node in the raster r
        
    % divide raster c into multiple rasters according to the number of components in raster c
    for cid=1:length(raster_com)
        raster_node_com=intersect(local_node(ci==raster_com(cid)),org_raster_node);
        node_raster(raster_node_com,3)=cid; 
        rid=rid+1;raster_node(rid,1:4)=[rid r cid length(raster_node_com)];        
    end  
end
raster_node=raster_node(1:rid,:);

%construct the raster edge data among raster nodes
raster_edge=zeros(rid*3,6);eid=0;%raster_edge_id, from_raster_node_id, to_raster_node_id, from_node_id (for long edges, 0 otherwise),to_node_id (for long edges, 0 otherwise),long_edge_id_in_org_edge_data
for r=1:Nr
    basic_raster_node=node_raster(node_raster(:,2)==r,1);
    local_raster_id=raster_data(abs(raster_data(:,2)-raster_data(r,2))<=1.1*log_step & abs(raster_data(:,3)-raster_data(r,3))<=1.1*lat_step,1);
    local_node=node_raster(ismember(node_raster(:,2),local_raster_id),1);
    local_edge=edge_data(ismember(edge_data(:,2),local_node(:,1)) & ismember(edge_data(:,3),local_node(:,1)),:);

    % Renumber the nodes and edges in order
    [~,local_edge(:,2)]=ismember(local_edge(:,2),local_node);[~,local_edge(:,3)]=ismember(local_edge(:,3),local_node);
    [~,new_raster_node]=ismember(basic_raster_node,local_node);
    
    %Find the componet where the node in the raster r is located, and determine the corresponding relationship between each node and the raster point
    net= sparse([local_edge(:,2);local_edge(:,3)],[local_edge(:,3);local_edge(:,2)],[local_edge(:,4);local_edge(:,4)],length(local_node),length(local_node));
    [ci,~] = components(net);  %there might be some isolated node
    raster_com=unique(ci(new_raster_node)); % the component number of the node in the raster r
    %  divide raster c into multiple rasters according to the number of components in raster c
    for cid=1:length(raster_com)
        center_rid=raster_node(raster_node(:,2)==r & raster_node(:,3)==cid,1);
        com_node=node_raster(local_node(ci==raster_com(cid)),:);
        neighbor_rnode=setdiff(unique(com_node(:,2:3),'rows'),[r cid],'rows');
        neighbor_rnode=neighbor_rnode(ismember(neighbor_rnode(:,1),local_raster_id),:);
        
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
for e=1:length(edge_data(:,1))
    fnode=edge_data(e,2);tnode=edge_data(e,3);
    fraster=node_raster(fnode,2);fcell=node_raster(fnode,4);     
    traster=node_raster(tnode,2);tcell=node_raster(tnode,4); 
    if abs(raster_data(fraster,2)-raster_data(traster,2))>1.1*log_step||abs(raster_data(fraster,3)-raster_data(traster,3))>1.1*lat_step
        temp_raster=raster_edge((raster_edge(1:eid,2)==fcell & raster_edge(1:eid,3)==tcell) | (raster_edge(1:eid,3)==fcell & raster_edge(1:eid,2)==tcell),:);
        if isempty(temp_raster)
           eid=eid+1;raster_edge(eid,:)=[eid fcell tcell fnode tnode e];
        else
            if edge_data(e,EH)<edge_data(temp_raster(1,6),EH)
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
raster_info.raster_size=raster_para.raster_size;
raster_info.raster_data=raster_data;
raster_info.node_raster=node_raster;
raster_info.log_lat_step=[log_step lat_step];
raster_info.raster_node=raster_node;
raster_info.raster_edge=raster_edge;
