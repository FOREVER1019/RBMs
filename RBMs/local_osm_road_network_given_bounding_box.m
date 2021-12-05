function local_edge=local_osm_road_network_given_bounding_box(org_edge,boundary)
% given city_id, and a rectangular area, return the edge information for the paritial netork
% % %%% extract the basic information (latitude, longtitude) of the city from saved files
define_constants;
local_edge=struct;tag=0;
E=size(org_edge,1);
for e=1:E
    if inpolygon(org_edge(e).X(1),org_edge(e).Y(1),boundary.X,boundary.Y) && inpolygon(org_edge(e).X(end-1),org_edge(e).Y(end-1),boundary.X,boundary.Y)
        tag=tag+1;
        local_edge(tag).Geometry=org_edge(e).Geometry;
        local_edge(tag).BoundingBox=org_edge(e).BoundingBox;
        local_edge(tag).X=org_edge(e).X;
        local_edge(tag).Y=org_edge(e).Y;
        %           local_edge(tag).access=org_edge(e).access;
        %           local_edge(tag).bridge=org_edge(e).bridge;
        if isfield(org_edge,'from') 
            if ischar(org_edge(e).from)
               local_edge(tag).from=str2double(org_edge(e).from);
            else
               local_edge(tag).from=org_edge(e).from;
            end
        else
            if ischar(org_edge(e).from_)
               local_edge(tag).from=str2double(org_edge(e).from_);
            else
               local_edge(tag).from=org_edge(e).from_;
            end
            
        end
        local_edge(tag).highway=org_edge(e).highway;
        %           local_edge(tag).junction=org_edge(e).junction;
        %           local_edge(tag).key=org_edge(e).key;
        %           local_edge(tag).lanes=org_edge(e).lanes;
        if ischar(org_edge(e).length)
            local_edge(tag).length=str2double(org_edge(e).length);
        else
            local_edge(tag).length=org_edge(e).length;
        end
        if isfield(org_edge(e),'maxspeed')
            if ischar(org_edge(e).maxspeed)
                local_edge(tag).maxspeed=str2double(org_edge(e).maxspeed);
            else
                local_edge(tag).maxspeed=org_edge(e).maxspeed;
            end
        else
            local_edge(tag).maxspeed=0;
        end
        %           local_edge(tag).name=org_edge(e).name;
        %           local_edge(tag).oneway=org_edge(e).oneway;
        if ischar(org_edge(e).osmid)
            local_edge(tag).osmid=str2double(org_edge(e).osmid);
        else
            local_edge(tag).osmid=org_edge(e).osmid;
        end
        %           local_edge(tag).ref=org_edge(e).ref;
        if ischar(org_edge(e).to)
            local_edge(tag).to=str2double(org_edge(e).to);
        else
            local_edge(tag).to=org_edge(e).to;
        end
        %           local_edge(tag).tunnel=org_edge(e).tunnel;
        %           local_edge(tag).width=org_edge(e).width;
    end
end
% save(strcat(num2str(city_id),city_name,'\all_edge.mat'),'local_edge');