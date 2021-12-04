function node_info=get_node_info(net_raster_info,node_data,edge_data,type)

raster_data=net_raster_info.raster_data;raster_node=net_raster_info.raster_node;
node_raster=net_raster_info.node_raster;
log_step=net_raster_info.log_lat_step(1);lat_step=net_raster_info.log_lat_step(2);
clear raster_info

Np=length(node_data(:,1));
node_info=zeros(Np,1);
%% 节点的速度等级  sqr60_node_type.mat   直接找速度最大的，因为不同国家等级与速度的大小关系并不一致
if type==1
%     org_edge_data(org_edge_data(:,5)~=fix(org_edge_data(:,5)),5)=8;
%     for n=1:Np
%         node_info(n)=min(org_edge_data(ismember(org_edge_data(:,2),n) | ismember(org_edge_data(:,3),n),5));
%     end
    for n=1:Np
        node_info(n)=max(edge_data(ismember(edge_data(:,2),n) | ismember(edge_data(:,3),n),6));
    end
end

%% 节点的9栅格区域介数  sqr60_rs1_node_local_r9_betweenness.mat
if type==2
    for r=1:length(raster_data(:,1))
        local_raster_id=raster_data(abs(raster_data(:,2)-raster_data(r,2))<=1.1*log_step & abs(raster_data(:,3)-raster_data(r,3))<=1.1*lat_step,1);
        local_node=node_raster(ismember(node_raster(:,2),local_raster_id),1);
        local_edge=edge_data(ismember(edge_data(:,2),local_node(:,1)) & ismember(edge_data(:,3),local_node(:,1)),[2 3 4 6]);
        [~,local_edge(:,1)]=ismember(local_edge(:,1),local_node);
        [~,local_edge(:,2)]=ismember(local_edge(:,2),local_node);
        local_net= sparse([local_edge(:,1);local_edge(:,2)],[local_edge(:,2);local_edge(:,1)],[local_edge(:,3)./(local_edge(:,4)*1000/60);local_edge(:,3)./(local_edge(:,4)*1000/60)],length(local_node),length(local_node));    
        
        [node_bc,~]=betweenness_centrality(sparse(local_net));
        rnodes=node_raster(node_raster(:,2)==r,1);
        [~,loc]=ismember(rnodes,local_node);
        node_info(rnodes)=node_bc(loc);
    end
end
    
%% 节点的25栅格区域介数  sqr60_rs1_node_local_r25_betweenness.mat
if type==3
    for r=1:length(raster_data(:,1))
        local_raster_id=raster_data(abs(raster_data(:,2)-raster_data(r,2))<=2.1*log_step & abs(raster_data(:,3)-raster_data(r,3))<=2.1*lat_step,1);
        local_node=node_raster(ismember(node_raster(:,2),local_raster_id),1);
        local_edge=edge_data(ismember(edge_data(:,2),local_node(:,1)) & ismember(edge_data(:,3),local_node(:,1)),[2 3 4 6]);
        [~,local_edge(:,1)]=ismember(local_edge(:,1),local_node);
        [~,local_edge(:,2)]=ismember(local_edge(:,2),local_node);
        local_net= sparse([local_edge(:,1);local_edge(:,2)],[local_edge(:,2);local_edge(:,1)],[local_edge(:,3)./(local_edge(:,4)*1000/60);local_edge(:,3)./(local_edge(:,4)*1000/60)],length(local_node),length(local_node));    
        
        [node_bc,~]=betweenness_centrality(sparse(local_net));
        rnodes=node_raster(node_raster(:,2)==r,1);
        [~,loc]=ismember(rnodes,local_node);
        node_info(rnodes)=node_bc(loc);
    end
end
    
%% 节点的49栅格区域介数  sqr60_rs1_node_local_r49_betweenness.mat
if type==4
    for r=1:length(raster_data(:,1))
        local_raster_id=raster_data(abs(raster_data(:,2)-raster_data(r,2))<=3.1*log_step & abs(raster_data(:,3)-raster_data(r,3))<=3.1*lat_step,1);
        local_node=node_raster(ismember(node_raster(:,2),local_raster_id),1);
        local_edge=edge_data(ismember(edge_data(:,2),local_node(:,1)) & ismember(edge_data(:,3),local_node(:,1)),[2 3 4 6]);
        [~,local_edge(:,1)]=ismember(local_edge(:,1),local_node);
        [~,local_edge(:,2)]=ismember(local_edge(:,2),local_node);
        local_net= sparse([local_edge(:,1);local_edge(:,2)],[local_edge(:,2);local_edge(:,1)],[local_edge(:,3)./(local_edge(:,4)*1000/60);local_edge(:,3)./(local_edge(:,4)*1000/60)],length(local_node),length(local_node));    
        
        [node_bc,~]=betweenness_centrality(sparse(local_net));
        rnodes=node_raster(node_raster(:,2)==r,1);
        [~,loc]=ismember(rnodes,local_node);
        node_info(rnodes)=node_bc(loc);
    end
end

%% 节点的距离信息  sqr60_rs1_node_local_n2c_dist.mat，euc_dist.mat，net_dist.mat，net_time.mat
if type>=5
    for r=1:length(raster_data(:,1))
        local_raster_id=raster_data(abs(raster_data(:,2)-raster_data(r,2))<=1.1*log_step & abs(raster_data(:,3)-raster_data(r,3))<=1.1*lat_step,1);
        local_node=node_raster(ismember(node_raster(:,2),local_raster_id),1);
        local_edge=edge_data(ismember(edge_data(:,2),local_node(:,1)) & ismember(edge_data(:,3),local_node(:,1)),[2 3 4 6]);
        [~,local_edge(:,1)]=ismember(local_edge(:,1),local_node);
        [~,local_edge(:,2)]=ismember(local_edge(:,2),local_node);
        
       %% sqr60_rs1_node_local_n2c_dist.mat
        if type==5 
            rnodes=node_raster(node_raster(:,2)==r,1);
            for n=1:length(rnodes)
                node_info(rnodes(n),:)=longitude_latitude(node_data(rnodes(n),2),node_data(rnodes(n),3),raster_data(r,2),raster_data(r,3));
            end
        end
       %% sqr60_rs1_node_local_euc_dist.mat
        if type==6 
            cell_id=raster_node(raster_node(:,2)==r,1);
            for c=1:length(cell_id)
                icnodes=node_raster(node_raster(:,4)==cell_id(c),1);
                dist_temp=zeros(length(icnodes),length(icnodes));
                for i=1:length(icnodes)-1
                    for j=i+1:length(icnodes)
                        dist_temp(i,j)=longitude_latitude(node_data(icnodes(i),2),node_data(icnodes(i),3),node_data(icnodes(j),2),node_data(icnodes(j),3));
                        dist_temp(j,i)=dist_temp(i,j);
                    end
                end
                node_info(icnodes)=sum(dist_temp,2);
            end
        end
       %% sqr60_rs1_node_local_net_dist.mat
        if type==7
            snet= sparse([local_edge(:,1);local_edge(:,2)],[local_edge(:,2);local_edge(:,1)],[local_edge(:,3);local_edge(:,3)],length(local_node),length(local_node));
            sdist=all_shortest_paths(snet);
            cell_id=raster_node(raster_node(:,2)==r,1);
            for c=1:length(cell_id)
                icnodes=node_raster(node_raster(:,4)==cell_id(c),1);
                [~,loc]=ismember(icnodes,local_node);
                node_info(icnodes)=sum(sdist(loc,loc),2);
            end
        end
       %% sqr60_rs1_node_local_net_time.mat
        if type==8
            fnet= sparse([local_edge(:,1);local_edge(:,2)],[local_edge(:,2);local_edge(:,1)],[local_edge(:,3)./(local_edge(:,4)*1000/60);local_edge(:,3)./(local_edge(:,4)*1000/60)],length(local_node),length(local_node));    
            fdist=all_shortest_paths(fnet);
            cell_id=raster_node(raster_node(:,2)==r,1);
            for c=1:length(cell_id)
                icnodes=node_raster(node_raster(:,4)==cell_id(c),1);
                [~,loc]=ismember(icnodes,local_node);
                node_info(icnodes)=sum(fdist(loc,loc),2);
            end
        end            
    end
    
    %% 节点的速度等级  sqr60_node_type.mat   直接找速度最大的，因为不同国家等级与速度的大小关系并不一致
    if type==9
%         org_edge_data(org_edge_data(:,5)~=fix(org_edge_data(:,5)),5)=8;
        for n=1:Np
            node_info(n)=min(edge_data(ismember(edge_data(:,2),n) | ismember(edge_data(:,3),n),5));
        end
%         for n=1:Np
%             node_info(n)=max(edge_data(ismember(edge_data(:,2),n) | ismember(edge_data(:,3),n),6));
%         end
    end


end

