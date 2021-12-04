clc;clear variables;
define_constants;
ids=178;
[~,~,raw_cities]=xlsread('city_basic_data.xlsx');
for id=1:length(ids)
    city_id=ids(id);
    city_name=cell2mat(raw_cities(city_id,CN));
    clog=cell2mat(raw_cities(city_id,CX));clat=cell2mat(raw_cities(city_id,CY));%city name
    load(strcat(num2str(city_id),city_name,'\node_data.mat'),'node_data');
    load(strcat(num2str(city_id),city_name,'\edge_data.mat'),'edge_data');
    load(strcat(num2str(city_id),city_name,'\edge_str.mat'),'edge_str');
    Np=length(node_data(:,1));
    
    %% generate network and raster information
    city_center=[clog clat];raster_size=1;
    log_lat_step=compute_log_lat_step_using_city_center(city_center,raster_size);
    city_para.log_lat_step=log_lat_step;city_para.raster_size=raster_size;city_para.center=city_center;
    city_para.boundary_X=[clog-log_lat_step(1)*30.5 clog+log_lat_step(1)*35 clog+log_lat_step(1)*30.5 clog-log_lat_step(1)*30.5 NaN];
    city_para.boundary_Y=[clat-log_lat_step(2)*30.5 clat-log_lat_step(2)*35 clat+log_lat_step(2)*30.5 clat+log_lat_step(2)*30.5 NaN];
    net_raster_info=generate_network_raster_information(node_data,edge_data,city_para);
    area_raster_info=integrate_area_raster_information(node_data,edge_data,edge_str,net_raster_info);
    save(strcat(num2str(city_id),city_name,'\rs1_net_raster_info.mat'),'net_raster_info');
    save(strcat(num2str(city_id),city_name,'\rs1_area_raster_info.mat'),'area_raster_info');
    
    %% compute travel time based accessibility derived from the VBM
    load(strcat(num2str(city_id),city_name,'\rs1_net_raster_info.mat'),'net_raster_info');
    net_r2r=compute_primary_net_time_r2r(node_data,edge_data,net_raster_info);
    save(strcat(num2str(city_id),city_name,'\rs1_primary_net_time_r2r.mat'),'net_r2r');
    
    %% compute node and edge betweenness
    edge_speed_time=update_road_edge_speed_time(edge_data);
    fnet=sparse([edge_data(:,EF);edge_data(:,ET)],[edge_data(:,ET);edge_data(:,EF)],[edge_speed_time(:,2);edge_speed_time(:,2)]);%for calculating the shortest paths
    [Bn,~]=betweenness_centrality(fnet);
    save(strcat(num2str(city_id),city_name,'\ft_Bn_NF.mat'),'Bn');
    
    %% get representative nodes for the LC&TN-RBM
    load(strcat(num2str(city_id),city_name,'\rs1_net_raster_info.mat'),'net_raster_info');
    % calculate node characterastic
    node_type=get_node_info(net_raster_info,node_data,edge_data,1); % node passing speed
    save(strcat(num2str(city_id),city_name,'\node_type.mat'),'node_type');
    node_local_betweenness=get_node_info(net_raster_info,node_data,edge_data,2); % node betweenness in local network
    save(strcat(num2str(city_id),city_name,'\rs1_node_local_betweenness.mat'),'node_local_betweenness');
    node_local_dist=zeros(Np,3);
    node_local_dist(:,1)=get_node_info(net_raster_info,node_data,edge_data,5);  % geometric distance to the cell center
    node_local_dist(:,2)=get_node_info(net_raster_info,node_data,edge_data,6);  % geometric distance to other nodes in the same cell
    node_local_dist(:,3)=get_node_info(net_raster_info,node_data,edge_data,8);  % network distance to other nodes in the same cell
    save(strcat(num2str(city_id),city_name,'\rs1_node_local_dist.mat'),'node_local_dist');
    
    % length of the longest straight street a node lie in
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
    save(strcat(num2str(city_id),city_name,'\node_street_len.mat'),'node_street_len');
    
    % generate representative nodes
    raster_data=net_raster_info.raster_data;raster_node=net_raster_info.raster_node;
    node_raster=net_raster_info.node_raster;
    raster_typical_nodes=zeros(length(raster_node(:,1)),15);
    
    raster_typical_nodes(:,1)=get_representative_nodes(raster_node,node_raster,node_local_dist(:,1),1); % CC
    raster_typical_nodes(:,2)=get_representative_nodes(raster_node,node_raster,node_local_dist(:,2),1); % GD
    raster_typical_nodes(:,3)=get_representative_nodes(raster_node,node_raster,node_local_dist(:,3),1); % ND
    raster_typical_nodes(:,4)=get_representative_nodes(raster_node,node_raster,-node_local_betweenness(:,1),1); % LB
    raster_typical_nodes(:,5)=get_representative_nodes(raster_node,node_raster,-node_type,1); % PS
    raster_typical_nodes(:,6)=get_representative_nodes(raster_node,node_raster,-node_street_len(:,1),1); % SL
    raster_typical_nodes(:,7)=get_representative_nodes(raster_node,node_raster,[-node_type node_local_dist(:,1)],2); % PS&CC
    raster_typical_nodes(:,8)=get_representative_nodes(raster_node,node_raster,[-node_type node_local_dist(:,2)],2); % PS&GD
    raster_typical_nodes(:,9)=get_representative_nodes(raster_node,node_raster,[-node_type node_local_dist(:,3)],2); % PS&ND
    raster_typical_nodes(:,10)=get_representative_nodes(raster_node,node_raster,[-node_type -node_local_betweenness(:,1)],2); % PS&LB
    raster_typical_nodes(:,11)=get_representative_nodes(raster_node,node_raster,[-node_type -node_street_len(:,1)],2); % PS&SL
    raster_typical_nodes(:,12)=get_representative_nodes(raster_node,node_raster,[-node_street_len(:,1) node_local_dist(:,1)],2); % SL&CC
    raster_typical_nodes(:,13)=get_representative_nodes(raster_node,node_raster,[-node_street_len(:,1) node_local_dist(:,2)],2); % SL&GD
    raster_typical_nodes(:,14)=get_representative_nodes(raster_node,node_raster,[-node_street_len(:,1) node_local_dist(:,3)],2); % SL&ND
    raster_typical_nodes(:,15)=get_representative_nodes(raster_node,node_raster,[-node_street_len(:,1) -node_local_betweenness(:,1)],2); % SL&LB
    rand_typical_nodes=zeros(length(raster_node(:,1)),100); %R
    for sim=1:100
        for c=1:length(raster_node(:,1))
            cnode=node_raster(node_raster(:,4)==c,1);
            rand_typical_nodes(c,sim)=cnode(randperm(length(cnode),1));
        end
    end
    save(strcat(num2str(city_id),city_name,'\rs1_raster_typical_nodes_LC_RN.mat'),'raster_typical_nodes');
    save(strcat(num2str(city_id),city_name,'\rs1_rand_typical_nodes_LC_RN.mat'),'rand_typical_nodes');
    
   %% get representative nodes for the NN&TN-RBM
   load(strcat(num2str(city_id),city_name,'\rs1_net_raster_info.mat'),'net_raster_info');
   load(strcat(num2str(city_id),city_name,'\node_type.mat'),'node_type');
   load(strcat(num2str(city_id),city_name,'\rs1_node_local_betweenness.mat'),'node_local_betweenness');
   load(strcat(num2str(city_id),city_name,'\rs1_node_local_dist.mat'),'node_local_dist');
   load(strcat(num2str(city_id),city_name,'\node_street_len.mat'),'node_street_len');
   
   % generate representative nodes
   raster_data=net_raster_info.raster_data;raster_node=net_raster_info.raster_node;
   node_raster=net_raster_info.node_raster;
   node_raster(:,4)=node_raster(:,2);
   raster_typical_nodes=zeros(length(raster_data(:,1)),15);
   
   raster_typical_nodes(:,1)=get_representative_nodes(raster_data,node_raster,node_local_dist(:,1),1); % CC
   raster_typical_nodes(:,2)=get_representative_nodes(raster_data,node_raster,node_local_dist(:,2),1); % GD
   raster_typical_nodes(:,3)=get_representative_nodes(raster_data,node_raster,node_local_dist(:,3),1); % ND
   raster_typical_nodes(:,4)=get_representative_nodes(raster_data,node_raster,-node_local_betweenness(:,1),1); % LB
   raster_typical_nodes(:,5)=get_representative_nodes(raster_data,node_raster,-node_type,1); % PS
   raster_typical_nodes(:,6)=get_representative_nodes(raster_data,node_raster,-node_street_len(:,1),1); % SL
   raster_typical_nodes(:,7)=get_representative_nodes(raster_data,node_raster,[-node_type node_local_dist(:,1)],2); % PS&CC
   raster_typical_nodes(:,8)=get_representative_nodes(raster_data,node_raster,[-node_type node_local_dist(:,2)],2); % PS&GD
   raster_typical_nodes(:,9)=get_representative_nodes(raster_data,node_raster,[-node_type node_local_dist(:,3)],2); % PS&ND
   raster_typical_nodes(:,10)=get_representative_nodes(raster_data,node_raster,[-node_type -node_local_betweenness(:,1)],2); % PS&LB
   raster_typical_nodes(:,11)=get_representative_nodes(raster_data,node_raster,[-node_type -node_street_len(:,1)],2); % PS&SL
   raster_typical_nodes(:,12)=get_representative_nodes(raster_data,node_raster,[-node_street_len(:,1) node_local_dist(:,1)],2); % SL&CC
   raster_typical_nodes(:,13)=get_representative_nodes(raster_data,node_raster,[-node_street_len(:,1) node_local_dist(:,2)],2); % SL&GD
   raster_typical_nodes(:,14)=get_representative_nodes(raster_data,node_raster,[-node_street_len(:,1) node_local_dist(:,3)],2); % SL&ND
   raster_typical_nodes(:,15)=get_representative_nodes(raster_data,node_raster,[-node_street_len(:,1) -node_local_betweenness(:,1)],2); % SL&LB
   rand_typical_nodes=zeros(length(raster_data(:,1)),100); %R
   for sim=1:100
       for c=1:length(raster_data(:,1))
           cnode=node_raster(node_raster(:,4)==c,1);
           rand_typical_nodes(c,sim)=cnode(randperm(length(cnode),1));
       end
   end
   save(strcat(num2str(city_id),city_name,'\rs1_raster_typical_nodes_NN_RN.mat'),'raster_typical_nodes');
   save(strcat(num2str(city_id),city_name,'\rs1_rand_typical_nodes_NN_RN.mat'),'rand_typical_nodes');

   %% get local transportation network information
   load(strcat(num2str(city_id),city_name,'\rs1_net_raster_info.mat'),'net_raster_info');
   node_pair=get_node_pair_information_noil(net_raster_info,node_data,edge_data);
   save(strcat(num2str(city_id),city_name,'\rs1_node_pair_time.mat'),'node_pair','-v7.3');
    
   %% estimate accessibility and calculate accessibility estimation error for the LC&RN-RBM
    if fun_type==601
        load(strcat(num2str(city_id),city_name,'\rs1_net_raster_info.mat'),'net_raster_info');
        load(strcat(num2str(city_id),city_name,'\rs1_primary_net_time_r2r.mat'),'net_r2r');
        load(strcat(num2str(city_id),city_name,'\rs1_raster_typical_nodes_LC_RN.mat'),'raster_typical_nodes');
        load(strcat(num2str(city_id),city_name,'\rs1_rand_typical_nodes_LC_RN.mat'),'rand_typical_nodes');

        load(strcat(num2str(city_id),city_name,'\rs1_node_pair_time.mat'),'node_pair');
        err_time=zeros(length(raster_typical_nodes(1,:)),9);
        for t=1:length(raster_typical_nodes(1,:))
            [err_time(t,:),net_r2r_LC_RN]=calculate_accessibility_error_for_LC_RN(net_raster_info,node_data,edge_data,net_r2r,raster_typical_nodes(:,t),node_pair);
             if t==11  % OLC-RBM
                save(strcat(num2str(city_id),city_name,'\rs1_net_r2r_LC_RN.mat'),'net_r2r_LC_RN');
             end
       end
       save(strcat(num2str(city_id),city_name,'\rs1_error_time_LC_RN.mat'),'err_time');
       err_time_rand=zeros(length(raster_typical_nodes(1,:)),9);
        for t=1:length(rand_typical_nodes(1,:))
            err_time_rand(t,:)=calculate_accessibility_error_for_LC_RN(net_raster_info,node_data,edge_data,net_r2r,rand_typical_nodes(:,t),node_pair);
        end
        save(strcat(num2str(city_id),city_name,'\rs1_error_time_LC_RN_rand.mat'),'err_time');
    end    

   %% estimate accessibility and calculate accessibility estimation error for the TMS-RBM
    if fun_type==602
        load(strcat(num2str(city_id),city_name,'\rs1_area_raster_info.mat'),'area_raster_info');
        [err_time,net_r2r_TMS]=calculate_accessibility_error_for_TMS(node_data,edge_data,area_raster_info,net_r2r);
        save(strcat(num2str(city_id),city_name,'\rs1_net_r2r_TMS.mat'),'net_r2r_TMS');
        save(strcat(num2str(city_id),city_name,'\rs1_err_time_TMS.mat'),'err_time');
    end
    
    %% estimate accessibility and calculate accessibility estimation error for the LC&MS-RBM
    if fun_type==603
        load(strcat(num2str(city_id),city_name,'\rs1_area_raster_info.mat'),'area_raster_info');
        load(strcat(num2str(city_id),city_name,'\rs1_primary_net_time_r2r.mat'),'net_r2r');
        [err_time,net_r2r_LC_MS]=calculate_accessibility_error_for_LC_MS(node_data,edge_data,area_raster_info,net_r2r);
        save(strcat(num2str(city_id),city_name,'\rs1_net_r2r_LC_MS.mat'),'net_r2r_TMS');
        save(strcat(num2str(city_id),city_name,'\rs1_err_time_LC_MS.mat'),'err_time');
    end
    
    %% estimate accessibility and calculate accessibility estimation error for the NN&RN-RBM
    if fun_type==604
        load(strcat(num2str(city_id),city_name,'\rs1_area_raster_info.mat'),'area_raster_info');
        load(strcat(num2str(city_id),city_name,'\rs1_net_raster_info.mat'),'net_raster_info');
        load(strcat(num2str(city_id),city_name,'\rs1_primary_net_time_r2r.mat'),'net_r2r');  
        load(strcat(num2str(city_id),city_name,'\rs1_node_pair_time.mat'),'node_pair');
        load(strcat(num2str(city_id),city_name,'\rs1_raster_typical_nodes_NN_RN.mat'),'raster_typical_nodes');
        load(strcat(num2str(city_id),city_name,'\rs1_rand_typical_nodes_NN_RN.mat'),'rand_typical_nodes');
        
        err_time=calculate_accessibility_error_for_NN_RN(node_data,edge_data,net_raster_info,area_raster_info,raster_typical_nodes,net_r2r,node_pair);
        save(strcat(num2str(city_id),city_name,'\rs1_error_time_NN_RN.mat'),'err_time');
        err_time_rand=zeros(length(raster_typical_nodes(1,:)),9);
        for t=1:length(rand_typical_nodes(1,:))
            err_time_rand(t,:)=calculate_accessibility_error_for_NN_RN(net_raster_info,node_data,edge_data,net_r2r,rand_typical_nodes(:,t),node_pair);
        end
        save(strcat(num2str(city_id),city_name,'\rs1_error_time_NN_RN_rand.mat'),'err_time');
    end    

    %% estimate accessibility and calculate accessibility estimation error for the HB-RBM
    if fun_type==605
        load(strcat(num2str(city_id),city_name,'\rs1_net_raster_info.mat'),'net_raster_info');
        load(strcat(num2str(city_id),city_name,'\rs1_primary_net_time_r2r.mat'),'net_r2r');
        load(strcat(num2str(city_id),city_name,'\rs1_node_pair_time.mat'),'node_pair');
        load(strcat(num2str(city_id),city_name,'\betweenness.mat'),'Bn');
        
        raster_node=net_raster_info.raster_node; node_raster=net_raster_info.node_raster;
        bc_typical_node=get_representative_nodes(raster_node,node_raster,-Bn,1);
        save(strcat(num2str(city_id),city_name,'\bc_typical_node'),'bc_typical_node');

        [err_time,net_r2r_HB]=calculate_accessibility_error_for_LC_RN(net_raster_info,node_data,edge_data,net_r2r,bc_typical_node,node_pair);
        save(strcat(filename,'\rs1_bc_err_time.mat'),'err_time');
        save(strcat(filename,'\rs1_net_r2r_HB'),'net_r2r_HB');
    end        
end

