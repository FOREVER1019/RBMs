
%% initial information solution
% get road network information
clc;clear global;
define_constants;%define constants parameters
city_id=181;
city_name='Qujing';%city name
load(strcat(num2str(181),'Qujing','\Qujing_org_node_data'),'org_node_data');
load(strcat(num2str(181),'Qujing','\Qujing_org_edge_data'),'org_edge_data');
load(strcat(num2str(181),'Qujing','\Qujing_org_edge_str'),'org_edge_str');
load(strcat(num2str(181),'Qujing','\qj_hospitals'),'qj_hospitals');

%% get the damage probability of each hypermap point under a given earthquake source
mag=8;cx=103.00;cy=25.200;
fra_snode=zeros(length(org_edge_data(:,1))*10,6);ntag=0;
edge_type=zeros(length(org_edge_data(:,1)),1);
for e=1:length(org_edge_data(:,1))
    edge_X=org_edge_str(e).X;edge_Y=org_edge_str(e).Y;
    if org_edge_data(e,7)==1  %ordinary road
        ttype=1; 
    elseif org_edge_data(e,7)==2 %only tunnel
        ttype=3;
    else
        ttype=2;   % bridge¡¢viaduct¡¢bridge/viaduct+tunnel
    end
    edge_type(e)=ttype;
    for k=1:length(edge_X)-1  
        ntag=ntag+1;fra_snode(ntag,1)=e;
        [fra_snode(ntag,2:5),~]=compute_road_component_fail_probabilty(mag,cx,cy,edge_X(k),edge_Y(k),ttype);
    end
end

%% get the disaster situation, get the speed reduction rate under each disaster situation
road_fra=[0.5 0.3 0.2 0.2 0];
damage_effect=[1 0.8 0.5 0 0;1 0.8 0.325 0 0;1 0.8 0.325 0 0]; % the impact of the fault corresponding to the fault state --- ordinary roads, bridges, and tunnels
Numsim=100; %simulation times
edam_speed=zeros(length(org_edge_data(:,1)),Numsim);
edam_state=zeros(length(org_edge_data(:,1)),Numsim);
for sim=1:Numsim
    % failure status of bridge and tunnel
    randnum=rand(length(fra_snode(:,1)),1); % get the random failure probability of each hypergraph point
    damage_speed=zeros(length(fra_snode(:,1)),3);
    damage_speed(:,1)=fra_snode(:,1);
    for n=1:length(fra_snode(:,1))
        etype=edge_type(fra_snode(n,1));
        damage_speed(n,3)=find(fra_snode(n,2:6)<=randnum(n),1);
        damage_speed(n,2)=damage_effect(etype,find(fra_snode(n,2:6)<=randnum(n),1));
    end
    [damage_speed,index]=sortrows(damage_speed,2);
    [a,index2,~]=unique(damage_speed(:,1));
    edam_speed(:,sim)=damage_speed(index2,2);
    edam_state(:,sim)=damage_speed(index2,3);
    % Failure status of ordinary roads
    road_edge=find(edge_type==1);
    randnum=rand(length(road_edge),1); 
    for n=1:length(road_edge)
        etype=1;
        edam_state(road_edge(n),sim)=find(road_fra<=randnum(n),1);
        edam_speed(road_edge(n),sim)=damage_effect(etype,find(road_fra<=randnum(n),1));
    end    
end
save(strcat(num2str(181),'Qujing','\edam_speed'),'edam_speed');
save(strcat(num2str(181),'Qujing','\edam_state'),'edam_state');

%% three methods of medical service accessibility results under a given edge speed reduction
load(strcat(num2str(181),'Qujing','\admin_rs1_area_raster_info.mat'),'area_raster_info');
load(strcat(num2str(181),'Qujing','\admin_rs1_net_raster_info.mat'),'net_raster_info');
load(strcat(num2str(181),'Qujing','\qj_hospitals'),'qj_hospitals');
load(strcat(num2str(181),'Qujing','\edam_speed'),'edam_speed');
load(strcat(num2str(181),'Qujing','\edam_state'),'edam_state');

pop_prop_org=calculate_population_proportion_under_random_speed(org_node_data,org_edge_data,org_edge_str,net_raster_info,area_raster_info,qj_hospitals);
pop_prop_dam=zeros(Numsim,2,3);
for sim=1:Numsim
    sim
    edge_data_dam=org_edge_data;edge_str_dam=org_edge_str;
    edge_data_dam(:,6)=org_edge_data(:,6).*edam_speed(:,sim);
    edge_str_dam(edge_data_dam(:,6)==0)=[];
    edge_data_dam(edge_data_dam(:,6)==0,:)=[];
    edge_data_dam(:,1)=1:length(edge_data_dam(:,1));
    
    net_raster_info=generate_network_raster_information(org_node_data,edge_data_dam,net_raster_info);
    area_raster_info=integrate_area_raster_information(org_node_data,edge_data_dam,edge_str_dam,net_raster_info);

    pop_prop_dam(sim,:,:)=calculate_population_proportion_under_random_speed(org_node_data,edge_data_dam,edge_str_dam,net_raster_info,area_raster_info,qj_hospitals);
end
err=[pop_prop_dam(:,1,2)./pop_prop_dam(:,1,1)-1 pop_prop_dam(:,1,3)./pop_prop_dam(:,1,1)-1 pop_prop_dam(:,2,2)./pop_prop_dam(:,2,1)-1 pop_prop_dam(:,2,3)./pop_prop_dam(:,2,1)-1];

