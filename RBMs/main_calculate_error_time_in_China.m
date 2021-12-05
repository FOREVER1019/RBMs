
%% raster information
load('.\China_data\node_data','node_data');
load('.\China_data\edge_data','edge_data');
load('.\China_data\edge_str','edge_str');
load('.\China_data\area_raster_info','area_raster_info');
raster_para.boundary_X=area_raster_info.boundary_X;raster_para.boundary_Y=area_raster_info.boundary_Y;
raster_para.center=[];raster_para.log_lat_step=area_raster_info.log_lat_step;
area_raster_data=area_raster_info.raster_data;clear area_raster_info;
area_raster_data(:,5:6)=0;

[net_raster_info,area_raster_data]=generate_network_raster_information_friction_map(node_data,edge_data,raster_para,area_raster_data);
save('.\China\admin_fs_net_raster_info.mat','net_raster_info');
save('.\China\admin_fs_area_raster_data.mat','area_raster_data');
area_raster_info=integrate_area_raster_information_friction_map(edge_data,edge_str,net_raster_info,area_raster_data);
save('.\China\admin_fs_area_raster_info.mat','area_raster_info');

%% 处理医院数据--该区域内医院，及每个医院所属路网节点
load('.\China_data\hospitals.mat','hospitals');  % hos_id, log, lat, nearest_node_id
load('.\China_data\China_node_data','node_data');
hospitals=hospitals(:,1:4);
for h=1:length(hospitals(:,1))
    hospitals(h,4)=node_data(sum(abs(node_data(:,2:3)-hospitals(h,2:3)),2)==min(sum(abs(node_data(:,2:3)-hospitals(h,2:3)),2)),1);
end
save('.\China_data\hospitals.mat','hospitals');  % hos_id, log, lat, nearest_node_id

%% VBM
% 计算type1栅格到医院的可达性---主图法
define_constants;
edge_speed_time=update_road_edge_speed_time(edge_data);
fnet=sparse([edge_data(:,EF);edge_data(:,ET)],[edge_data(:,ET);edge_data(:,EF)],[edge_speed_time(:,2);edge_speed_time(:,2)],length(node_data(:,1)),length(node_data(:,1)));%for calculating the shortest paths

Ns=800;Nh=length(hospitals(:,1));Np=length(node_data(:,1));
for sid=1:ceil(Nh/Ns)
    if sid<ceil(Nh/Ns)
        hset=Ns*(sid-1)+1:Ns*sid;
    else
        hset=Ns*(sid-1)+1:Nh;
    end
    primary_hos_acc=zeros(length(hset),Np);
    for h=1:length(hset)
        [sid h]
        primary_hos_acc(h,:)=shortest_paths(fnet,hospitals(hset(h),4));
    end
    save(strcat('.\China_data\primary_hos_acc',num2str(sid),'.mat'),'primary_hos_acc','-v7.3');
end

raster_node=net_raster_info.raster_node;node_raster=net_raster_info.node_raster;
Nr=length(raster_node(:,1));
primary_net_hos_acc=zeros(length(hospitals(:,1)),Nr);
for sid=1:ceil(Nh/Ns)
    if sid<ceil(Nh/Ns)
        hset=Ns*(sid-1)+1:Ns*sid;
    else
        hset=Ns*(sid-1)+1:Nh;
    end
    load(strcat('.\China_data\primary_hos_acc',num2str(sid),'.mat'),'primary_hos_acc');
    for h=1:length(hset)
        [sid h]
        primary_net_hos_acc(hset(h),:)=accumarray(node_raster(:,4),primary_hos_acc(h,:))./(raster_node(:,4));
    end
end
save('.\China_data\primary_net_hos_acc.mat', 'primary_net_hos_acc','-v7.3');

% 以栅格间可达性为基准
node_raster=net_node_raster;raster_node=net_raster_node;
Nr=length(raster_node(:,1));Np=length(node_data(:,1));
primary_net_hos_acc=zeros(length(hospitals(:,1)),Nr);
for h=1:length(hospitals(:,1))
    h
    hos_raster_id=node_raster(hospitals(h,4),4);
    rnode=node_raster(node_raster(:,4)==hos_raster_id,1);Rn=length(rnode);
    rdist=zeros(Np*Rn,1);%destination_node_raster_id,time
    for k=1:Rn
        rdist((k-1)*Np+(1:Np),1)=shortest_paths(fnet,rnode(k));
    end
    primary_net_hos_acc(h,:)=accumarray(repmat(node_raster(:,4),Rn,1),rdist)./(Rn*raster_node(:,4));
end
[primary_net_hos_acc_min,primary_min_hos_id]=min(primary_net_hos_acc);
save('.\China_data\primary_net_hos_acc.mat', 'primary_net_hos_acc','-v7.3');
save('.\China_data\primary_net_hos_acc_min.mat', 'primary_net_hos_acc_min');
save('.\China_data\primary_min_hos_id.mat', 'primary_min_hos_id');

%% 计算传统栅格网络/区域可达性
traditional_raster_net=compute_traditional_net_time_r2r(edge_data,area_raster_info);
save('.\China\admin_fs_traditional_net_rnet.mat', 'traditional_net_rnet','-v7.3');

traditional_net_hos_acc=zeros(length(hospitals(:,1)),length(traditional_raster_net(:,1)));
for h=1:length(hospitals(:,1))
    raster_id=net_raster_info.node_raster(hospitals(h,4),2);
    traditional_net_hos_acc(h,:)=shortest_paths(traditional_raster_net,raster_id);
end
traditional_net_hos_acc=traditional_net_hos_acc(net_raster_info.raster_node(:,2));
traditional_net_hos_acc_min=min(traditional_net_hos_acc);
save('.\China\admin_fs_traditional_net_hos_acc.mat', 'traditional_net_hos_acc','-v7.3');
save('.\China\admin_fs_traditional_net_hos_acc_min.mat', 'traditional_net_hos_acc_min','-v7.3');
trad_err=mean(abs(traditional_net_hos_acc_min-primary_net_hos_acc_min));
save('.\China\trad_err.mat', 'trad_err');

%% 改进栅格方法的网络/区域可达性及误差
load('.\China\node_data','node_data');
load('.\China\edge_data','edge_data');
load('.\China\edge_str','edge_str');
load('.\China\admin_fs_net_raster_info.mat','net_raster_info');
load('.\China\admin_fs_area_raster_info.mat','area_raster_info');
%获取特征节点---可单独算
node_type=get_node_info(net_raster_info,node_data,edge_data,1);
save('.\China\node_type.mat','node_type');

street_info=extract_road_street_information(node_data,edge_data,edge_str, 2);
node_street_len=zeros(Np,4);%max_street_len,sum_street_len,max_number_of_nodes_along_a_street, sum numer of nodes along all streets passing through the node
for n=1:Np
    temp_edge=edge_data(edge_data(:,2)==n | edge_data(:,3)==n,1);
    sid=unique(street_info.ids(temp_edge,2));temp_len=street_info.length(sid,2);temp_sid=zeros(length(sid),1);
    for k=1:length(sid)
        temp_sid(k)=length(unique(edge_data(street_info.ids(street_info.ids(:,2)==sid(k),1),[2 3])));
    end
    node_street_len(n,:)=[max(temp_len) sum(temp_len) max(temp_sid) sum(temp_sid)];
end
node_street_len(:,1:2)=node_street_len(:,1:2)*0.001;

raster_data=net_raster_info.raster_data;raster_node=net_raster_info.raster_node;
node_raster=net_raster_info.node_raster;
raster_typical_nodes=get_representative_nodes(raster_node,node_raster,[-node_type -node_street_len(:,1)],2);
save('.\China\admin_fs_raster_typical_nodes.mat','raster_typical_nodes');
% % 网络部分可达性
neibor_edge=get_typical_nodes_connection_information(net_raster_info,edge_data,raster_typical_nodes);
raster_edge=net_raster_info.raster_edge;
raster_node=net_raster_info.raster_node;
raster_edge_long=raster_edge(raster_edge(:,4)~=0,1:6);
raster_edge_long(:,4)=edge_data(raster_edge_long(:,6),4)./(edge_data(raster_edge_long(:,6),6)*1000/60);
raster_edge_typ=zeros(length(raster_edge(:,1)),4);
raster_edge_typ(length(neibor_edge(:,1))+1:length(raster_edge(:,1)),:)=raster_edge_long(:,1:4);
raster_edge_typ(1:length(neibor_edge(:,1)),:)=neibor_edge(:,1:4);
raster_net_typ=sparse([raster_edge_typ(:,2);raster_edge_typ(:,3)],[raster_edge_typ(:,3);raster_edge_typ(:,2)],[raster_edge_typ(:,4);raster_edge_typ(:,4)]);
save('.\China\admin_fs_nrm_net_rnet.mat','nrm_net_rnet','-v7.3');

nrm_net_hos_acc=zeros(length(hospitals(:,1)),length(raster_net_typ(:,1)));
for h=1:length(hospitals(:,1))
    raster_id=net_raster_info.node_raster(hospitals(h,4),4);
    nrm_net_hos_acc(h,:)=shortest_paths(raster_net_typ,raster_id);
end
save('.\China_data\nrm_net_hos_acc.mat', 'nrm_net_hos_acc','-v7.3');
nrm_net_hos_acc_min=min(nrm_net_hos_acc);
save('.\China_data\nrm_net_hos_acc_min.mat', 'nrm_net_hos_acc_min');
nrm_err=mean(abs(nrm_net_hos_acc_min-primary_net_hos_acc_min));
save('.\China\nrm_err.mat', 'nrm_err');

% 区域可达性
nrm_area_rnet=compute_area_time_raster_network(edge_data,raster_net_typ,area_raster_info);
save('.\China_data\nrm_area_rnet.mat', 'nrm_area_rnet','-v7.3');
hos_r=net_raster_info.node_raster(hospitals(:,4),4);
nrm_area_rnet(length(nrm_area_rnet(:,1))+1,hos_r)=0.0001;
nrm_area_rnet(hos_r,length(nrm_area_rnet(:,1)))=0.0001;
nrm_area_hos_acc_min=shortest_paths(nrm_area_rnet,length(nrm_area_rnet(:,1)));
save('.\China_data\nrm_area_hos_acc_min.mat', 'nrm_area_hos_acc_min','-v7.3');

% 转化为栅格形式存储
nrm_area_hos_acc_min_raster=zeros(length(area_raster_info.raster_data(:,1)),1);
raster_data_id_t3=area_raster_info.raster_node(area_raster_info.raster_node(:,9)==3,1:2);ntag3=0;
for r=1:length(area_raster_info.raster_data(:,1))
    r
    if area_raster_info.raster_data(r,6)==3
        ntag3=ntag3+1;
        nrm_area_hos_acc_min_raster(r)=nrm_area_hos_acc_min(raster_data_id_t3(ntag3,1));
    else
        area_raster_node_temp=area_raster_node_loc_set{area_raster_data_loc(r,1),1};
        nrm_area_hos_acc_min_raster(r)=mean(nrm_area_hos_acc_min(area_raster_node_temp(area_raster_node_temp(:,2)==r,1)));
    end
end
save('.\China_data\nrm_area_hos_acc_min_raster.mat', 'nrm_area_hos_acc_min_raster','-v7.3');



