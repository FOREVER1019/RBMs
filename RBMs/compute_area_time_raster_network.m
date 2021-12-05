function area_time_rnet=compute_area_time_raster_network(edge_data,net_time_rnet,area_raster_info)
define_constants;
edge_speed_time=update_road_edge_speed_time(edge_data);
Nr=length(area_raster_info.raster_node(:,1));Nn=length(net_time_rnet(:,1));area_raster_edge=zeros(Nn*Nn*2,3);
[i,j,k]=find(net_time_rnet);area_raster_edge(1:length(i),:)=[i j k];rtag=length(i);
%assign the weight coefficients for those type-2 and type-3 raster edges
for e=1:length(area_raster_info.raster_edge(:,1))
    %assign weights for those type-2 raster edges
    if area_raster_info.raster_edge(e,7)==2
       rtag=rtag+1;
       area_raster_edge(rtag,:)=[area_raster_info.raster_edge(e,2),area_raster_info.raster_edge(e,3),60*area_raster_info.raster_edge(e,5)/edge_speed_time(area_raster_info.raster_edge(e,6),1)];
    end
    %assign weights for those type-3 raster edges
    if area_raster_info.raster_edge(e,7)==3
        fid=area_raster_info.raster_edge(e,2);tid=area_raster_info.raster_edge(e,3);
        fcell=area_raster_info.raster_node(fid,2);tcell=area_raster_info.raster_node(tid,2);
        rdist=longitude_latitude(area_raster_info.raster_data(fcell,2),area_raster_info.raster_data(fcell,3),area_raster_info.raster_data(tcell,2),area_raster_info.raster_data(tcell,3));
        if area_raster_info.raster_node(fid,9)==3
            fspeed=area_raster_info.raster_data(area_raster_info.raster_node(fid,2),4)*1000;%the unit is minute/km
        else
            cover_node=area_raster_info.node_raster(area_raster_info.node_raster(:,4)==fid,1);
            if ~isempty(cover_node)
               fspeed=max(edge_speed_time(ismember(edge_data(:,EF),cover_node) | ismember(edge_data(:,ET),cover_node),1));
            else
               fspeed=0;
            end
            temp_edge=area_raster_info.edge_raster(area_raster_info.edge_raster(:,2)==fcell,1);
            if  ~ismepty(temp_edge)
               fspeed=60/max(fspeed,max(edge_speed_time(temp_edge,1)));%the unit is also minute/km
            else
               fspeed=60/fspeed;
            end
        end
        if area_raster_info.raster_node(tid,9)==3
            tspeed=area_raster_info.raster_data(area_raster_info.raster_node(tid,2),4)*1000;%the unit is minute/km
        else
            cover_node=area_raster_info.node_raster(area_raster_info.node_raster(:,4)==tid,1);
            if ~isempty(cover_node)
               tspeed=max(edge_speed_time(ismember(edge_data(:,EF),cover_node) | ismember(edge_data(:,ET),cover_node),1));
            else
                tspeed=0;
            end
            temp_edge=area_raster_info.edge_raster(area_raster_info.edge_raster(:,2)==tcell,1);
            if ~isempty(temp_edge)
                tspeed=60/max(tspeed,max(edge_speed_time(temp_edge,1)));%the unit is also minute/km
            else
                tspeed=60/tspeed;
            end
        end
        rtag=rtag+1;area_raster_edge(rtag,:)=[fid,tid,(rdist*fspeed+rdist*tspeed)/2];
    end
end
area_raster_edge=area_raster_edge(1:rtag,:);
area_time_rnet=sparse([area_raster_edge(:,1);area_raster_edge(:,2)],[area_raster_edge(:,2);area_raster_edge(:,1)],[area_raster_edge(:,3);area_raster_edge(:,3)],Nr,Nr);

