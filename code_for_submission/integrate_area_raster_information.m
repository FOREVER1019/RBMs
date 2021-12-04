function area_raster_info=integrate_area_raster_information(node_data,edge_data,edge_str,net_raster_info)
%raster_para.center: with city center as default, and can be also adjusted around city center
%raster_para.size:the width and length of each square raster
%raster_para.log_lat_step: the longtitude and latitude interval per km
%raster_para.boundary_X and .boundary_Y: with NaN to differentiate diffe_user_definedrent boundary component
%area_raster_info.log_lat_step,area_raster_info.radius,area_raster_info.raster_size,area_raster_info.city_center
%area_raster_info.raster_data:raster_id,raster_longitude,raster_latitude,speed,population,raster_type(1 or 2 or 3)
%area_raster_info.node_raster:node_id,raster_id,covered_node_component_id,raster_node_id
%area_raster_info.edge_raster:edge_id,raster_id,p_longtiude,p_latitude,dist_p_fnode,dist_p_tnode
%area_raster_info.raster_node:raster_node_id, raster_node_type,raster_id,covered_node_component_id,number_of_covered_component_nodes,typical_node_id1,typical_node_id2,typical_node_id3.)
%typical_node_id1 is the node id with the minimum ecludean distance to raster center;
%typical_node_id2 is the node id with the mimumum average ecludean distance to all other component nodes
%typical_node_id3 is the node id with the mimumum average shortest network distance to all other component nodes
%typical_node_id4 is the node id with the minimum average fastest travel time to all other component nodes
%area_raster_info.raster_edge: raster_edge_id, raster_edge_type,from_raster_node_id, to_raster_node_id,0 or from_node_id, 0 or to_node_id, 0 or org_edge_id

define_constants;
clog=net_raster_info.center(1);clat=net_raster_info.center(2);%city center longitude,city center latitude
log_step=net_raster_info.log_lat_step(1);lat_step=net_raster_info.log_lat_step(2);%the longtitude/latitude interval per raster

%compute the number of raster nodes in the longtitude and latitude horizons in the area
min_log=min([net_raster_info.boundary_X node_data(:,NX)']);max_log=max([net_raster_info.boundary_X node_data(:,NX)']);
min_lat=min([net_raster_info.boundary_Y node_data(:,NY)']);max_lat=max([net_raster_info.boundary_Y node_data(:,NY)']);
nsize_x=ceil(abs(min_log-clog)/log_step)+ceil(abs(max_log-clog)/log_step);
nsize_y=ceil(abs(min_lat-clat)/lat_step)+ceil(abs(max_lat-clat)/lat_step);

% generate and record the new raster location data, those rasters passing road edges without nodes, and those rasters in the city study area
new_raster_data=zeros(nsize_x*nsize_y,6);%raster_id,longtitude,latitude,speed,population,type(1 or 2 or 3)
rid=length(net_raster_info.raster_data(:,1));new_raster_data(1:rid,1:3)=net_raster_info.raster_data;new_raster_data(1:rid,6)=1;
left_most_x=clog-ceil(abs(min_log-clog)/log_step)*log_step;
bottom_most_y=clat-ceil(abs(min_lat-clat)/lat_step)*lat_step;
for r=1:nsize_y
    rlat=bottom_most_y+(r-1/2)*lat_step;
    for c=1:nsize_x
        rlog=left_most_x+(c-1/2)*log_step;
        %first check whether the raster covers nodes
        if sum(abs(net_raster_info.raster_data(:,2)-rlog)<=0.01*log_step & abs(net_raster_info.raster_data(:,3)-rlat)<=0.01*lat_step)==0
           %second check whether the raster is covered inside a boundary
            bound_id=[0 find(isnan(net_raster_info.boundary_X))];
            for b=2:length(bound_id)
                temp_X=net_raster_info.boundary_X(bound_id(b-1)+1:bound_id(b)-1);
                temp_Y=net_raster_info.boundary_Y(bound_id(b-1)+1:bound_id(b)-1);
                if any(inpolygon([rlog-log_step/2,rlog+log_step/2,rlog+log_step/2,rlog-log_step/2],[rlat-lat_step/2,rlat-lat_step/2,rlat+lat_step/2,rlat+lat_step/2],temp_X,temp_Y))
                   rid=rid+1;new_raster_data(rid,1:3)=[rid rlog rlat];
                   break;
                end
            end
        end
    end
end
raster_data=new_raster_data(1:rid,:);

% judge whether an edge passes some rasters without nodes located in and record it in edge_raster
edge_raster=zeros(length(edge_data(:,1)),6);etag=0;%edge_id,raster_id,p_longtiude,p_latitude,dist_p_fnode,dist_p_tnode
raster_X=uniquetol([raster_data(:,2)+log_step/2;raster_data(:,2)-log_step/2],err);
raster_Y=uniquetol([raster_data(:,3)+lat_step/2;raster_data(:,3)-lat_step/2],err);
for e=1:size(edge_data,1)
    edge_bound=[min(edge_str(e).X) min(edge_str(e).Y);max(edge_str(e).X) max(edge_str(e).Y)];
    %if the edge_bound is fully covered inside a raster, it does not need to check
    if sum(raster_data(:,2)-log_step/2<=edge_bound(1,1) & raster_data(:,3)-lat_step/2<=edge_bound(1,2) & raster_data(:,2)+log_step/2>=edge_bound(2,1) & raster_data(:,3)+lat_step/2>=edge_bound(2,2))==0
        eff_raster=raster_data(raster_data(:,2)<=edge_bound(2,1)+0.6*log_step & raster_data(:,2)>=edge_bound(1,1)-0.6*log_step & raster_data(:,3)<=edge_bound(2,2)+0.6*lat_step & raster_data(:,3)>=edge_bound(1,2)-0.6*lat_step,:);
        fid=net_raster_info.node_raster(edge_data(e,EF),2);tid=net_raster_info.node_raster(edge_data(e,ET),2);
        eff_raster(eff_raster(:,1)==fid,:)=[];eff_raster(eff_raster(:,1)==tid,:)=[];
        if ~isempty(eff_raster)
            edge_xy=[edge_str(e).X(1:end-1)' edge_str(e).Y(1:end-1)'];
            cx=raster_X(raster_X<=max(edge_xy(:,1)) & raster_X>=min(edge_xy(:,1)));
            cy=raster_Y(raster_Y<=max(edge_xy(:,2)) & raster_Y>=min(edge_xy(:,2)));
            temp_xy=compute_edge_intersection_given_cxy(edge_xy,cx,cy);%point id, lon, lat, distance_to_cx(1)cy(1),1 for intersection point
            new_edge_xy=[temp_xy temp_xy(:,1:2)*0];
            for n=1:length(new_edge_xy(:,1))
                if new_edge_xy(n,5)==1
                    raster_id=eff_raster(abs(eff_raster(:,2)-new_edge_xy(n,2))<=log_step/2+err & abs(eff_raster(:,3)-new_edge_xy(n,3))<=lat_step/2+err,1);
                    temp_raster=sortrows([raster_id abs(raster_data(raster_id,2)-new_edge_xy(n,2))+abs(raster_data(raster_id,3)-new_edge_xy(n,3))],2);
                    if length(temp_raster(:,2))>=2
                        new_edge_xy(n,6:7)=temp_raster(1:2,1)';
                    else
                        if  length(temp_raster(:,2))==1
                            new_edge_xy(n,6)=temp_raster(1,1);
                        end
                    end
                end
            end
            
            cross_raster=setdiff(unique([new_edge_xy(:,6);new_edge_xy(:,7)]),0);
            
            for n=1:length(cross_raster)
                tempA=new_edge_xy(new_edge_xy(:,6)==cross_raster(n) | new_edge_xy(:,7)==cross_raster(n),1);
                if length(tempA)>1
                    tempA=sortrows(tempA);
                    [~,loc,~,~,new_XY]=compute_node_street_distance([-1 raster_data(cross_raster(n),2:3)],[ones(max(tempA)-min(tempA)+1,1) new_edge_xy(min(tempA):max(tempA),2:3)]);
                    left_XY=new_XY(1:find(new_XY(:,1)==-1),:);
                    left_dist=new_edge_xy(min(tempA),4);  %首先加上到边的起点的距离
                    for k=2:length(left_XY(:,1))
                        left_dist=left_dist+longitude_latitude(left_XY(k,2),left_XY(k,3),left_XY(k-1,2),left_XY(k-1,3));
                    end
                    right_dist=edge_data(e,4)*0.001-left_dist;
                    etag=etag+1;edge_raster(etag,:)=[e cross_raster(n) loc(1) loc(2) left_dist right_dist];
                end
            end
        end
    end
end
edge_raster=edge_raster(1:etag,:);

% udapte raster_node and raster_edge information by considering those rasters with edges passing through
Er=length(net_raster_info.raster_edge(:,1));Nr=length(net_raster_info.raster_node(:,1));eid=0;nid=Nr;
new_raster_node=zeros(nid+length(raster_data(:,1))-Nr,9);%raster_node_id,raster_id,covered_node_component_id,number_of_covered_component_nodes,typical_node_id1,typical_node_id2,typical_node_id3,typical_node_id4, raster_node_type)
new_raster_node(1:nid,1:8)=net_raster_info.raster_node;new_raster_node(1:nid,9)=1;
new_raster_edge=zeros((length(raster_data(:,1))-length(net_raster_info.raster_data(:,1)))*4,7);%raster_edge_id, from_raster_node_id, to_raster_node_id,0 or from_node_id, 0 or to_node_id, 0 or org_edge_id,edge_type

cross_edge_raster=edge_raster(raster_data(edge_raster(:,2),6)==0,:);
fids=net_raster_info.node_raster(edge_data(cross_edge_raster(:,1),EF),4);
tids=net_raster_info.node_raster(edge_data(cross_edge_raster(:,1),ET),4);
cross_edge_raster=[cross_edge_raster,min(fids,tids),max(fids,tids)];
while ~isempty(cross_edge_raster)
    if cross_edge_raster(1,7)==56&&cross_edge_raster(1,8)==519
        break;
    end
    temp_edge_raster=cross_edge_raster(cross_edge_raster(:,7)==cross_edge_raster(1,7) & cross_edge_raster(:,8)==cross_edge_raster(1,8),:);
    
    %add the type-2 new nodes
    raster_data(temp_edge_raster(:,2),6)=2;unique_raster=unique(temp_edge_raster(:,2));
    for k=1:length(unique_raster)
         nid=nid+1;new_raster_node(nid,[1 2 3 9])=[nid unique_raster(k) sum(new_raster_node(Nr+1:nid-1,2)==unique_raster(k))+1 2];  
%          temp_edge_raster(temp_edge_raster(:,2)==unique_raster(k),2)=nid;% the second column is updated as the new added raster node id
    end
    temp_raster_node=new_raster_node(nid-length(unique_raster)+1:nid,1:2);
    [~,loc]=ismember(temp_edge_raster(:,2),temp_raster_node(:,2));
    temp_edge_raster(:,2)=temp_raster_node(loc,1);
    
    %establish the links between the above new nodes
    unique_edge=unique(temp_edge_raster(:,1));
    for k=1:length(unique_edge)
        temp_seq=sortrows(temp_edge_raster(temp_edge_raster(:,1)==unique_edge(k),1:6),5);fnode=edge_data(unique_edge(k),EF);tnode=edge_data(unique_edge(k),ET);
        edge_seq=[unique_edge(k) net_raster_info.node_raster(fnode,4) 0 0 0 0;temp_seq;unique_edge(k) net_raster_info.node_raster(tnode,4) 0 0 edge_data(unique_edge(k),EL)*0.001 0];
        for s=2:length(edge_seq(:,1)) 
            temp_raster=new_raster_edge((new_raster_edge(1:eid,2)==edge_seq(s-1,2) & new_raster_edge(1:eid,3)==edge_seq(s,2)) | (new_raster_edge(1:eid,3)==edge_seq(s-1,2) & new_raster_edge(1:eid,2)==edge_seq(s,2)),:);
            if isempty(temp_raster)
                eid=eid+1;new_raster_edge(eid,:)=[Er+eid,edge_seq(s-1,2),edge_seq(s,2),fnode,abs(edge_seq(s,5)-edge_seq(s-1,5)),edge_seq(s,1),2];
            else
                if edge_data(edge_seq(s,1),EH)<edge_data(temp_raster(1,6),EH) || (edge_data(edge_seq(s,1),EH)==edge_data(temp_raster(1,6),EH) && abs(edge_seq(s,5)-edge_seq(s-1,5))<temp_raster(1,5))
                    new_raster_edge(temp_raster(1,1),2:7)=[edge_seq(s-1,2),edge_seq(s,2),fnode,abs(edge_seq(s,5)-edge_seq(s-1,5)),edge_seq(s,1),2];
                end
            end
        end
    end
    cross_edge_raster(cross_edge_raster(:,7)==cross_edge_raster(1,7) & cross_edge_raster(:,8)==cross_edge_raster(1,8),:)=[];           
end

%%udapte raster_node by considering those rasters without covering any nodes and without edges passing through
for r=1:length(raster_data(:,1))
    if raster_data(r,6)==0
        raster_data(r,6)=3;nid=nid+1;new_raster_node(nid,[1 2 3 9])=[nid raster_data(r,1) 1 3];
    end
end
new_raster_node=new_raster_node(1:nid,:);

%establish the connect with those type-3 raster nodes
for r=1:length(new_raster_node(:,1))
    if new_raster_node(r,9)==3
        rid=new_raster_node(r,1);rlog=raster_data(new_raster_node(r,2),2);rlat=raster_data(new_raster_node(r,2),3);
        local_raster_id=raster_data(abs(raster_data(:,2)-rlog)<=1.1*log_step & abs(raster_data(:,3)-rlat)<=1.1*lat_step,1);
        temp_node=new_raster_node(ismember(new_raster_node(:,2),local_raster_id),1);temp_node(temp_node==rid)=[];
        temp_node=setdiff(temp_node,unique(new_raster_edge(new_raster_edge(1:eid,2)==rid | new_raster_edge(1:eid,3)==rid,2:3)));
        if ~isempty(temp_node)
            for k=1:length(temp_node)
                eid=eid+1;new_raster_edge(eid,:)=[Er+eid rid temp_node(k) 0 0 0 3];
            end
        end 
    end
end
raster_edge=[net_raster_info.raster_edge net_raster_info.raster_edge(:,1)*0+1;new_raster_edge(1:eid,:)];

% assign each raster the travel time data according to friction map data    
[Data,R] = geotiffread('friction_surface_2015_v1.0\friction_surface_2015_v1.0.tif');
fs_lat_step=R.CellExtentInLatitude;fs_log_step=R.CellExtentInLongitude;
sample_step=10;
for r=1:length(raster_data(:,1))
    if raster_data(r,6)==3
        rlog=raster_data(r,2);rlat=raster_data(r,3);
        yid=floor((R.LatitudeLimits(2)-rlat)/fs_lat_step)+1;xid=floor((rlog-R.LongitudeLimits(1))/fs_log_step)+1;
        
        %generate a lot of friction map points around the raster area
        sample_fs=zeros((2*ceil(lat_step/fs_lat_step)+1)*(2*ceil(log_step/fs_log_step)+1)*sample_step*sample_step,3);pk=0;
        for klat=-ceil(lat_step/fs_lat_step):ceil(lat_step/fs_lat_step)
            for klog=-ceil(log_step/fs_log_step):ceil(log_step/fs_log_step)
                lat_id=yid+klat;log_id=xid+klog;
                [sample_lat,sample_log]=intrinsicToGeographic(R,log_id,lat_id);
                for i=1:sample_step
                    temp_lat=sample_lat-fs_lat_step/2-fs_lat_step/(sample_step*2)+i*fs_lat_step/sample_step;
                    for j=1:sample_step
                        temp_log=sample_log-fs_log_step/2-fs_log_step/(sample_step*2)+j*fs_log_step/sample_step;
                        pk=pk+1;sample_fs(pk,:)=[temp_lat temp_log Data(lat_id,log_id)];
                    end
                end
            end
        end
        
        sample_fs=sample_fs(abs(sample_fs(:,1)-rlat)<=lat_step/2 & abs(sample_fs(:,2)-rlog)<=log_step/2,:);
        sample_fs=sample_fs(sample_fs(:,3)>0.003,:);%only considering those friction surface points with speeds less than 20km/h, or more than 0.003 minute/meter
        
        if ~isempty(sample_fs)
            [C,~,IC] = uniquetol(sample_fs(:,3),10^-5);
            temp_C=[C C];
            for k=1:length(C)
                temp_C(k,2)=sum(IC==k);
            end
            temp_C=sortrows(temp_C,-2);
            raster_data(r,4)=temp_C(1,1);
        else
            raster_data(r,4)=0.012;%5km/h, which means 0.012 minute/meter
        end
    end
end

area_raster_info=struct;
area_raster_info.center=net_raster_info.center;
area_raster_info.log_lat_step=net_raster_info.log_lat_step;
area_raster_info.boundary_X=net_raster_info.boundary_X;
area_raster_info.boundary_Y=net_raster_info.boundary_Y;
area_raster_info.raster_size=net_raster_info.raster_size;
area_raster_info.raster_data=raster_data;
area_raster_info.node_raster=net_raster_info.node_raster;
area_raster_info.edge_raster=edge_raster;
area_raster_info.raster_node=new_raster_node;
area_raster_info.raster_edge=raster_edge;
