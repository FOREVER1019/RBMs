
clc;clear variables;
define_constants;
city_id=178;
[~,~,raw_cities]=xlsread('city_basic_data.xlsx');
city_name=cell2mat(raw_cities(city_id,CN));
load(strcat(num2str(city_id),city_name,'\rs1_net_raster_info.mat'),'net_raster_info');
bounding_box=[min(net_raster_info.boundary_X) min(net_raster_info.boundary_Y);max(net_raster_info.boundary_X) max(net_raster_info.boundary_Y)];
N=10000;Numsim=1;

% N:number of nodes£»E:number of edges£» node_data: the information of raod nodes[ node_id, log, lat]
% bounding_boxt:the scope of the generate DT network [min log,  min lat; max log max lat]
% DT_node£ºnode_id, log, lat
% DT_edge£ºedge_id, fnode_id, tnode_id, length(m), highway type, speed(km/h)
% MST_edge_id: the id of edges in MST in DT
% DT_edge_save£ºthe edge left after the edge is deleted

%% generate 100 types of DT networks with a number of 10,000 nodes and an edge density from 0.33:0.01:1
mkdir(strcat('./DT10000/S',num2str(sim)));
for sim=1:Numsim
    sim
    [DT_node,DT_edge]=create_DT([],N,bounding_box,2); % randomly generate nodes within the bounding_box
    % [DT_node,DT_edge]=create_DT(node_data,[],[],1); % keep the position of the road network node i
    DT_edge=[(1:length(DT_edge(:,1)))' DT_edge];
    DT_edge(:,5)=3; DT_edge(:,6)=60; %set the DT network edge speed
    
    % generate MST corresponding to DT
    G=graph(DT_edge(:,2),DT_edge(:,3),DT_edge(:,4));
    [MST_net,~]=minspantree(G,'root',1);
    MST_net=table2array(MST_net.Edges);
    MST_edge=MST_net(:,[1,2]);
    [~,MST_edge_id]=ismember(MST_edge,DT_edge(:,2:3),'rows');
    
    % Given edge density, dilute DT
    edge_density=0.33:0.01:1;
    for k=1:length(edge_density)
        if k==1
           E=length(MST_edge_id(:,1));
        else
           E=edge_density(k)*length(DT_edge(:,1));
        end
        delete_edge_id=setdiff((1:length(DT_edge(:,1)))',MST_edge_id); % the edge that can be deleted
        rand_edge=randperm(length(delete_edge_id(:,1)));
        delete_edge_id=delete_edge_id(rand_edge(1:length(DT_edge(:,1))-E));
        DT_edge_save=DT_edge;
        DT_edge_save(delete_edge_id,:)=[];
        DT_edge_save(:,1)=(1:length(DT_edge_save(:,1)))';
        DT_edge_str=struct;
        for e=1:length(DT_edge_save(:,5))
            DT_edge_str(e).X=[DT_node(DT_edge_save(e,2),2) DT_node(DT_edge_save(e,3),2) NaN];
            DT_edge_str(e).Y=[DT_node(DT_edge_save(e,2),3) DT_node(DT_edge_save(e,3),3) NaN];
        end
        DT_node_data=DT_node;DT_edge_data=DT_edge_save;
        node_data=DT_node_data;edge_data=DT_edge_data;edge_str=DT_edge_str;
        mkdir(strcat('./DT10000/S',num2str(sim),'\edge_density_',num2str(edge_density(k)*100)));
        save(strcat('./DT10000/S',num2str(sim),'\edge_density_',num2str(edge_density(k)*100),'/node_data.mat'),'node_data');
        save(strcat('./DT10000/S',num2str(sim),'\edge_density_',num2str(edge_density(k)*100),'/edge_data.mat'),'edge_data');
        save(strcat('./DT10000/S',num2str(sim),'\edge_density_',num2str(edge_density(k)*100),'/edge_str.mat'),'edge_str');
    end
end


