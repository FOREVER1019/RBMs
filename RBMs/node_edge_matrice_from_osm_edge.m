function [node_data,edge_data,edge_str]=node_edge_matrice_from_osm_edge(city_id,osm_edge)
%according to the original osm_edge with the struct data structure,we
%generate the node and edge matric and also the edge_str with a struct data structure
define_constants;
E=max(size(osm_edge));
node_data=zeros(E,4);ntag=0;%node_new_id,node_osim_id,node_longtitude,node_latitude; the second column is used for re-ranking node_id purpose, and will be deleted in the end
edge_data=zeros(E,6);etag=0;%edge_id,from_node_id, to_node_id,edge_length,edge_highway,edge_maxspeed(NaN if no data);
%%highway=1 for motorway;1.5 for motorway_link;2 for trunk;2.5 for trunk_link;3 for primary; 3.5 for primary_link;
%%4 for secondary; 4.5 for secondary_link;5 for tertiary; 5.5 for tertiary link;6 for residential; 7 for unclassified or others
edge_str=struct;%X, Y, highway, maxspeed,bridge, tunnel
% mstruct=defaultm('mercator');mstruct.geoid=referenceEllipsoid('wgs84','meters');mstruct=defaultm(mstruct);[cx,cy]=projfwd(mstruct,clat,clog);

% get the speed information for this city
[~,~,raw_cities]=xlsread('city_basic_data.xlsx');
country_id=cell2mat(raw_cities(city_id,13));
[~,~,raw_cities]=xlsread('country_road_speed.xlsx');
basic_road_speed(1:15)=cell2mat(raw_cities(country_id,3:17));
basic_road_speed(16)=min(basic_road_speed(1:15));
basic_road_speed(isnan(basic_road_speed))=basic_road_speed(16);

for e=1:E
    new_ex=osm_edge(e).X;new_ey=osm_edge(e).Y;
    etag=etag+1;
    edge_str(etag).X=new_ex;edge_str(etag).Y=new_ey;
    edge_data(etag,1:4)=[etag osm_edge(e).from osm_edge(e).to osm_edge(e).length];
    if isempty(strfind(osm_edge(e).highway,'['))  % indicate that there is only one type,'primary'
        if strcmp(osm_edge(e).highway,'motorway')
            type=1;
        elseif strcmp(osm_edge(e).highway,'trunk')
            type=2;
        elseif strcmp(osm_edge(e).highway,'railroad')
            type=3;
        elseif strcmp(osm_edge(e).highway,'primary')
            type=4;
        elseif strcmp(osm_edge(e).highway,'secondary')
            type=5;
        elseif strcmp(osm_edge(e).highway,'tertiary')
            type=6;
        elseif strcmp(osm_edge(e).highway,'motorway_link')
            type=7;
        elseif strcmp(osm_edge(e).highway,'primary_link')
            type=8;
        elseif strcmp(osm_edge(e).highway,'unclassified')
            type=9;
        elseif strcmp(osm_edge(e).highway,'road')
            type=10;
        elseif strcmp(osm_edge(e).highway,'residential')
            type=11;
        elseif strcmp(osm_edge(e).highway,'service')
            type=12;
        elseif strcmp(osm_edge(e).highway,'track')
            type=13;
        elseif strcmp(osm_edge(e).highway,'pedestrian')
            type=14;
        elseif strcmp(osm_edge(e).highway,'other')
            type=15;
        else
            type=16;
        end
    else     % exsit many types of road segments, such as:  '[''primary'', ''secondary'']'
        type1=osm_edge(e).highway(strfind(osm_edge(e).highway,'[')+2:strfind(osm_edge(e).highway,',')-2);
        type2=osm_edge(e).highway(strfind(osm_edge(e).highway,',')+3:strfind(osm_edge(e).highway,']')-2);
        if strcmp(type1,'motorway')
            type(1)=1;
        elseif strcmp(type1,'trunk')
            type(1)=2;
        elseif strcmp(type1,'railroad')
            type(1)=3;
        elseif strcmp(type1,'primary')
            type(1)=4;
        elseif strcmp(type1,'secondary')
            type(1)=5;
        elseif strcmp(type1,'tertiary')
            type(1)=6;
        elseif strcmp(type1,'motorway_link')
            type(1)=7;
        elseif strcmp(type1,'primary_link')
            type(1)=8;
        elseif strcmp(type1,'unclassified')
            type(1)=9;
        elseif strcmp(type1,'road')
            type(1)=10;
        elseif strcmp(type1,'residential')
            type(1)=11;
        elseif strcmp(type1,'service')
            type(1)=12;
        elseif strcmp(type1,'track')
            type(1)=13;
        elseif strcmp(type1,'pedestrian')
            type(1)=14;
        elseif strcmp(type1,'other')
            type(1)=15;
        else
            type(1)=16;
        end
        if strcmp(type2,'motorway')
            type(2)=1;
        elseif strcmp(type2,'trunk')
            type(2)=2;
        elseif strcmp(type2,'railroad')
            type(2)=3;
        elseif strcmp(type2,'primary')
            type(2)=4;
        elseif strcmp(type2,'secondary')
            type(2)=5;
        elseif strcmp(type2,'tertiary')
            type(2)=6;
        elseif strcmp(type2,'motorway_link')
            type(2)=7;
        elseif strcmp(type2,'primary_link')
            type(2)=8;
        elseif strcmp(type2,'unclassified')
            type(2)=9;
        elseif strcmp(type2,'road')
            type(2)=10;
        elseif strcmp(type2,'residential')
            type(2)=11;
        elseif strcmp(type2,'service')
            type(2)=12;
        elseif strcmp(type2,'track')
            type(2)=13;
        elseif strcmp(type2,'pedestrian')
            type(2)=14;
        elseif strcmp(type2,'other')
            type(2)=15;
        else
            type(2)=16;
        end
    end
    edge_data(etag,6)=osm_edge(e).maxspeed;
    if isnan(edge_data(etag,6))
        edge_data(etag,6)=max(basic_road_speed(type));
        edge_data(etag,5)=type(find(basic_road_speed(type)==max(basic_road_speed(type)),1));
    end    
    
    if ntag==0 || (ntag>=1 && sum(node_data(1:ntag,2)==osm_edge(e).from)==0)
        ntag=ntag+1;node_data(ntag,:)=[ntag osm_edge(e).from new_ex(1) new_ey(1)];
        %           [node_data(ntag,3),node_data(ntag,4)]=projfwd(mstruct,lat_temp(1),log_temp(1));
    end
    if ntag==0 || (ntag>=1 && sum(node_data(1:ntag,2)==osm_edge(e).to)==0)
        ntag=ntag+1;node_data(ntag,:)=[ntag osm_edge(e).to new_ex(length(new_ex)-1) new_ey(length(new_ey)-1)];
        %           [node_data(ntag,3),node_data(ntag,4)]=projfwd(mstruct,lat_temp(length(lat_temp)-1),log_temp(length(log_temp)-1));
    end
end
node_data=node_data(1:ntag,:);edge_data=edge_data(1:etag,:);
[~,edge_data(:,2)]=ismember(edge_data(:,2),node_data(:,2));
[~,edge_data(:,3)]=ismember(edge_data(:,3),node_data(:,2));

%search the maximum edge component, and delete other isolated edge components
[edge_com,~]=edge_components(edge_data,[]);
num_edge_com=zeros(max(edge_com),2);
for c=1:max(edge_com)
    num_edge_com(c,:)=[c sum(edge_com==c)];
end
num_edge_com=sortrows(num_edge_com,-2);
del_edge=(edge_com~=num_edge_com(1,1));

%delete multiple edges
for e=1:length(edge_data(:,1))
    temp_edge=edge_data((edge_data(:,2)==edge_data(e,2) & edge_data(:,3)==edge_data(e,3))| (edge_data(:,2)==edge_data(e,3) & edge_data(:,3)==edge_data(e,2)),:);
    if length(temp_edge(:,1))>1
        temp_edge=sortrows(temp_edge,4);
        del_edge(temp_edge(2:length(temp_edge(:,1)),1))=1;
    end
end

%delete those nodes with the same coordinate
del_node=node_data(:,1)*0;
for n=1:length(node_data(:,1))
    if del_node(n)==0
        temp=find(abs(node_data(:,3)-node_data(n,3))+abs(node_data(:,4)-node_data(n,4))<=err);
        if length(temp)>1
            for k=2:length(temp)
                del_node(temp(k))=1;
                edge_data(edge_data(:,2)==node_data(temp(k),1),2)=node_data(temp(1),1);
                edge_data(edge_data(:,3)==node_data(temp(k),1),3)=node_data(temp(1),1);
            end
        end
    end
end
%delete edges with the same endpoint
del_edge(edge_data(edge_data(:,2)==edge_data(:,3),1))=1;
edge_data(del_edge==1,:)=[];
node_data(del_node==1,:)=[];

%sort out the final network with new node id and new edge id
[node_data,edge_data,edge_str]=sort_out_component_id(node_data(:,[1 3 4]),edge_data,edge_str);

%save the data for further coding
% city_name=cell2mat(raw_cities(city_id,4));
% save(strcat(num2str(city_id),city_name,'\test_node_data'),'node_data');
% save(strcat(num2str(city_id),city_name,'\test_edge_data'),'edge_data');
% save(strcat(num2str(city_id),city_name,'\test_edge_str'),'edge_str');
