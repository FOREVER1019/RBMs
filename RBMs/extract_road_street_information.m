function street_info=extract_road_street_information (node_data, edge_data, edge_str, rule_type)
define_constants;E=length(edge_data(:,1));
%compute the information based accessibility in terms of the ecludian radius distance
edge_street=assign_road_edge_street_ID(node_data,edge_data,edge_str,rule_type);
street_info=struct;

if rule_type==5
    %% assign street id to each network edge (with directions, 2*E edges in total)
    street_ids=[edge_street(:,1) edge_street(:,1)*0];edge_street(E+1:end,1)=(E+1:2*E)';sid=0;
    while sum(street_ids(:,2)==0)>0
        sid
        temp_street=edge_street(street_ids(:,2)==0,:);fe=temp_street(1,:);
        check_edge=fe(1);fi=fe(1);
        while edge_street(fi,5)~=0 && street_ids(fi,2)==0 && ~ismember(edge_street(fi,5),check_edge)
            check_edge=[check_edge;edge_street(fi,5)];fi=edge_street(fi,5);
        end
        if street_ids(fi,2)==0
            sid=sid+1;street_ids(check_edge,2)=sid;
        else
            street_ids(check_edge,2)=street_ids(fi,2);
        end
    end
    
    %% compute the length of each street
    street_len=zeros(sid,2);
    for s=1:sid
        street_len(s,:)=[s sum(edge_data(street_ids(street_ids(:,2)==s,1),EL))];
    end
    
    street_info.edge_street=edge_street;
    street_info.ids=street_ids;
    street_info.length=street_len;
end

if rule_type==1 || rule_type==2
    %% assign street id to each network edge (with directions, 2*E edges in total)
    street_ids=[edge_street(:,1) edge_street(:,1)*0];
    
    [~,street_ids(:,2)]=ismember(edge_street(:,2),unique(edge_street(:,2)));
    %% compute the length of each street
    street_len=zeros(max(street_ids(:,2)),2);
    for s=1:max(street_ids(:,2))
        street_len(s,:)=[s sum(edge_data(street_ids(street_ids(:,2)==s,1),EL))];
    end
    
    street_info.edge_street=[];
    street_info.ids=street_ids;
    street_info.length=street_len;
end
% load(strcat('results\',num2str(city_id),city_name,'\',city_name,'_edge_street.mat'),'edge_street');
% street_len(street_len(:,2)==0,:)=[];
% % [bins,bc_prob]=plot_powerlaw_pdf(street_len(:,2));
% 
% [N E]
% save(strcat('results\',num2str(city_id),city_name,'\',city_name,'_street_len.mat'),'street_len');
% end
% min_len=min(street_len(:,2));max_len=max(street_len(:,2));
% prob_len=zeros(100,2);tag=0;
% for s=min_len:(max_len-min_len)/100:max_len
%     tag=tag+1;
%     prob_len(tag,:)=[s sum(street_len(:,2)>=s)/length(street_len(:,1))];
% end
% figure;
% plot(prob_len(:,1),prob_len(:,2),'b.-');hold on;
