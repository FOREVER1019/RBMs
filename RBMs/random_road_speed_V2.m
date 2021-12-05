function new_edge_data=random_road_speed_V2(city_id,edge_data)

% change the speed to keep the total network traversal time unchanged
define_constants;
[~,~,raw_cities]=xlsread('city_basic_data.xlsx');
country_id=cell2mat(raw_cities(city_id,13));
[~,~,raw_cities]=xlsread('country_road_speed.xlsx');
basic_road_speed(1:15)=cell2mat(raw_cities(country_id,3:17));
basic_road_speed(16)=min(basic_road_speed(1:15));
basic_road_speed(isnan(basic_road_speed))=basic_road_speed(16);

E=length(edge_data(:,1));
edge_type=unique(edge_data(:,5));
edge_type_length=zeros(length(edge_type),1); 
for t=1:length(edge_type)
    edge_type_length(t)=sum(edge_data(edge_data(:,5)==edge_type(t),4));
end
type_length_temp=zeros(length(edge_type),1);
new_edge_data=edge_data;
for e=1:E
    for t=1:length(edge_type)
        if type_length_temp(t)>=edge_type_length(t)
            edge_type(edge_type==t)=[];
        end
    end
    index=randperm(length(edge_type),1);
    new_edge_data(e,5)=edge_type(index);
    new_edge_data(e,6)=basic_road_speed(new_edge_data(e,5));
    type_length_temp(index)=type_length_temp(index)+edge_data(e,4);
end
        
    
    
    
