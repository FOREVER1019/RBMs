function edge_street=assign_road_edge_street_ID(node_data,edge_data,edge_str,alg_type)
%edge_street:(:,1)=edge_id,(:,2)=street_id
define_constants;
node_edge=zeros(length(node_data(:,1))*5,3);ntag=0;%(:,1)=node_id,(:,2)=edge_ids (or 0),(:,3)=1,2,or NaN...for continuty
node_edge_ang=zeros(length(edge_data(:,1))*2,3);atag=0;%node_id,edge_id,ang_from_node_along_edge
for n=1:length(node_data(:,1))
    nedge=edge_data(edge_data(:,EF)==node_data(n,1) | edge_data(:,ET)==node_data(n,1),:);%(:,4):the edge angle leaving node_data(n,1)
    for e=1:length(nedge(:,1))
        if nedge(e,EF)==node_data(n,1)
           nedge(e,4)=compute_edge_angle(edge_str(nedge(e,EI)).X([1 2]),edge_str(nedge(e,EI)).Y([1 2])); 
        else
           nedge(e,4)=compute_edge_angle(edge_str(nedge(e,EI)).X([end-1 end-2]),edge_str(nedge(e,EI)).Y([end-1 end-2])); 
        end
        atag=atag+1;node_edge_ang(atag,:)=[node_data(n,1) nedge(e,1) nedge(e,4)];
    end 
end
%define edge type,as a rule to judge whether two edges belong to the same street
edge_type=edge_data(:,1)*0;
%alg_type=1 for not considering edge types and edge directions, alg_type=3 for not considering edge types but considering edge directions
if alg_type==1 || alg_type==3
   edge_type(:,1)=1;
end

%group edges according to their EH values, not considering teh travel directions along edges
if alg_type==2
   edge_type(:,1)=edge_data(:,EH);
end

%group edges to two types: link-type edges and non-link-type edges, not considering the travel directions along edges
if alg_type==2.5
   edge_type(:,1)=1;edge_type(ceil(edge_data(:,EH))-edge_data(:,EH)~=0)=2;%for link_type edges
   for e=1:length(edge_type(:,1))
      fn_edge=node_edge_ang(node_edge_ang(:,1)==edge_data(e,EF),:);
      tn_edge=node_edge_ang(node_edge_ang(:,1)==edge_data(e,ET),:);
      fn_tn_ang=fn_edge(fn_edge(:,2)==edge_data(e,1),3);
      tn_fn_ang=tn_edge(tn_edge(:,2)==edge_data(e,1),3);
      
      fn_ang=zeros(length(fn_edge(:,1)),2);
      tn_ang=zeros(length(tn_edge(:,1)),2);
      for i=1:length(fn_edge(:,1))
          fn_ang(i,:)=[fn_edge(i,2) min(2*pi-abs(fn_edge(i,3)-fn_tn_ang),abs(fn_edge(i,3)-fn_tn_ang))];
      end
      for i=1:length(tn_edge(:,1))
          tn_ang(i,:)=[tn_edge(i,2) min(2*pi-abs(tn_edge(i,3)-tn_fn_ang),abs(tn_edge(i,3)-tn_fn_ang))];
      end
      fn_ang(fn_ang(:,1)==edge_data(e,1),:)=[];tn_ang(tn_ang(:,1)==edge_data(e,1),:)=[];
      if ~isempty(fn_ang) && ~isempty(tn_ang)   
          if edge_type(e,1)==1 
              [min_fn_ang,min_fn_tag]=min(fn_ang(:,2));[min_tn_ang,min_tn_tag]=min(tn_ang(:,2));
             if min_fn_ang<=pi/12 && min_tn_ang<=pi/12
                cnode=intersect(edge_data(edge_data(:,1)==fn_ang(min_fn_tag,1),[EF,ET]),edge_data(edge_data(:,1)==tn_ang(min_tn_tag,1),[EF,ET]));
                ex=edge_str(edge_data(e,1)).X(1:end-1);ey=edge_str(edge_data(e,1)).Y(1:end-1);
                if ~isempty(cnode) || min(2*pi-abs(fn_tn_ang-tn_fn_ang),abs(fn_tn_ang-tn_fn_ang))<=pi*2/3 || edge_data(e,EL)>=2*sqrt((ex(1)-ex(end))^2+(ey(1)-ey(end))^2)
                   edge_type(e,1)=2;
                end
             end
          else
            if sum(fn_ang(:,2)>=pi*11/12)==1 && sum(fn_ang(:,2)>=pi/3)==length(fn_ang(:,1))
               edge_type(e,1)=1;
            else
               if sum(tn_ang(:,2)>=pi*11/12)==1 && sum(tn_ang(:,2)>=pi/3)==length(tn_ang(:,1))
                  edge_type(e,1)=1;
               end
            end
          end
      end
   end
end

%group edge links according to EH, and consider the travel directions along edges
if alg_type==4
    for e=1:length(edge_data(:,1))
        if edge_data(e,EH)==1
            edge_type(e)=1;
        elseif edge_data(e,EH)==1.5
            edge_type(e)=1.5;
        elseif edge_data(e,EH)==2
            edge_type(e)=1;
        elseif edge_data(e,EH)==2.5
            edge_type(e)=1.5;
        elseif edge_data(e,EH)==3
            edge_type(e)=2;
        elseif edge_data(e,EH)==3.5
            edge_type(e)=2.5;
        elseif edge_data(e,EH)==4
            edge_type(e)=3;
        elseif edge_data(e,EH)==4.5
            edge_type(e)=3.5;
        elseif edge_data(e,EH)==5
            edge_type(e)=4;
        elseif edge_data(e,EH)==5.5
            edge_type(e)=4.5;
        else
            edge_type(e)=4;
        end
    end  
end


if alg_type==1 || alg_type==2 || alg_type==2.5
    %construct the node_edge matrix to get the street direction at each node with angle difference larger than 3/4*pi
    for n=1:length(node_data(:,1))
        nedge=node_edge_ang(node_edge_ang(:,1)==node_data(n,1),:);
        ang_diff=zeros(length(nedge(:,1))*(length(nedge(:,1))-1)/2,3);tag=0;
        for i=1:length(nedge(:,1))
            for j=(i+1):length(nedge(:,1))
                if edge_type(nedge(i,2))==edge_type(nedge(j,2))
                    tag=tag+1;ang_diff(tag,:)=[nedge(i,2) nedge(j,2) min(2*pi-abs(nedge(i,3)-nedge(j,3)),abs(nedge(i,3)-nedge(j,3)))];
                else
                    tag=tag+1;ang_diff(tag,:)=[nedge(i,2) nedge(j,2) -1];
                end
            end
        end
        
        ang_diff=sortrows(ang_diff,-3);rank_id=0;
        while ~isempty(ang_diff)
            if ang_diff(1,3)>=street_ang
                rank_id=rank_id+1;
                ntag=ntag+1;node_edge(ntag,:)=[node_data(n,1) ang_diff(1,1) rank_id];
                ntag=ntag+1;node_edge(ntag,:)=[node_data(n,1) ang_diff(1,2) rank_id];
                temp_edge=ang_diff(1,1:2);
                ang_diff(ismember(ang_diff(:,1),temp_edge),[1,3])=0;ang_diff(ismember(ang_diff(:,2),temp_edge),[2 3])=0;%set judged edges' IDs as zero
            else
                for k=1:2
                    if ang_diff(1,k)~=0 && sum(node_edge(1:ntag,1)==node_data(n,1) & node_edge(1:ntag,2)==ang_diff(1,k))==0
                        ntag=ntag+1;node_edge(ntag,:)=[node_data(n,1) ang_diff(1,k) NaN];
                    end
                end
            end
            ang_diff(1,:)=[];
        end
    end
    node_edge=node_edge(1:ntag,:);
    
    edge_street=[edge_data(:,1) edge_data(:,1)*0 edge_type];stag=0;%edge_id,street_id
    while sum(edge_street(:,2)==0)>0
        stag=stag+1;
        temp_edge=edge_street(edge_street(:,2)==0,:);
        left_edge=temp_edge(1,1);right_edge=temp_edge(1,1);
        edge_street(edge_street(:,1)==left_edge,2)=stag;
        left_node=edge_data(edge_data(:,EI)==left_edge,EF);
        right_node=edge_data(edge_data(:,EI)==left_edge,ET);
        while ~isempty(left_node)
            left_node_edge=node_edge(node_edge(:,1)==left_node,:);
            if ~isempty(left_node_edge)
                neigbor_edge=setdiff(edge_data(edge_data(:,EF)==left_node | edge_data(:,ET)==left_node,EI),left_edge);
                if sum(edge_street(neigbor_edge,2)==stag)>=1
                    left_node=[];
                else
                    left_temp=left_node_edge(left_node_edge(:,2)==left_edge,:);%note that length(left_temp(:,1))=1
                    if isnan(left_temp(1,3))
                        left_node=[];
                    else
                        left_edge=setdiff(left_node_edge(left_node_edge(:,3)==left_temp(1,3),2),left_edge);
                        if edge_street(edge_street(:,1)==left_edge,2)==0
                            edge_street(edge_street(:,1)==left_edge,2)=stag;
                            left_node=setdiff(edge_data(edge_data(:,EI)==left_edge,[EF,ET]),left_node);
                        else
                            left_node=[];
                        end
                    end
                end
            else
                left_node=[];
            end
        end
        while ~isempty(right_node)
            right_node_edge=node_edge(node_edge(:,1)==right_node,:);
            if ~isempty(right_node_edge)
                neigbor_edge=setdiff(edge_data(edge_data(:,EF)==right_node | edge_data(:,ET)==right_node,EI),right_edge);
                if sum(edge_street(neigbor_edge,2)==stag)>=1
                    right_node=[];
                else
                    right_temp=right_node_edge(right_node_edge(:,2)==right_edge,:);%length(right_temp(:,1))=1
                    if isnan(right_temp(1,3))
                        right_node=[];
                    else
                        right_edge=setdiff(right_node_edge(right_node_edge(:,3)==right_temp(1,3),2),right_edge);
                        if edge_street(edge_street(:,1)==right_edge,2)==0
                            edge_street(edge_street(:,1)==right_edge,2)=stag;
                            right_node=setdiff(edge_data(edge_data(:,EI)==right_edge,[EF,ET]),right_node);
                        else
                            right_node=[];
                        end
                    end
                end
            else
                right_node=[];
            end
        end
    end
end

if alg_type==3
    node_edge=zeros(2*length(edge_data(:,1)),3);etag=0;%node_id,from_edge_id,to_edge_id (0 if from_edge is the end of the street)
    for n=1:length(node_data(:,1))
        nedge=node_edge_ang(node_edge_ang(:,1)==node_data(n,1),:);
        ang_diff=zeros(length(nedge(:,1))*(length(nedge(:,1))-1)/2,3);tag=0;
        for i=1:length(nedge(:,1))
            for j=(i+1):length(nedge(:,1))
                if edge_type(nedge(i,2))==edge_type(nedge(j,2))
                    tag=tag+1;ang_diff(tag,:)=[nedge(i,2) nedge(j,2) min(2*pi-abs(nedge(i,3)-nedge(j,3)),abs(nedge(i,3)-nedge(j,3)))];
                else
                    tag=tag+1;ang_diff(tag,:)=[nedge(i,2) nedge(j,2) -1];
                end
            end
        end
        
        %if two edges have the angle less than pi/12, it's hard to diffiante them, so they will be regarded as different street id.
        for i=1:length(nedge(:,1))
            fedge=nedge(i,2);
            if length(nedge(:,1))==1
               etag=etag+1;node_edge(etag,:)=[node_data(n,1) fedge 0];
            else
                fe_ang=sortrows(ang_diff(ang_diff(:,1)==fedge | ang_diff(:,2)==fedge,:),-3);
                if length(nedge(:,1))==2
                    if fe_ang(1,3)>=street_ang
                        etag=etag+1;node_edge(etag,:)=[node_data(n,1) fedge setdiff(fe_ang(1,1:2),fedge)];
                    else
                        etag=etag+1;node_edge(etag,:)=[node_data(n,1) fedge 0];
                    end
                else
                    if fe_ang(1,3)>=street_ang && abs(fe_ang(1,3)-fe_ang(2,3))>par_street_ang
                        etag=etag+1;node_edge(etag,:)=[node_data(n,1) fedge setdiff(fe_ang(1,1:2),fedge)];
                    else
                        etag=etag+1;node_edge(etag,:)=[node_data(n,1) fedge 0];
                    end
                end
            end
        end
    end
    
    edge_street=[edge_data(:,[EI EF ET EL ET ET]);edge_data(:,[EI ET EF EL ET ET])];edge_street(:,5:6)=0;%edge_id,from_node,to_node,edge_length,next_edge_id,loop_tag
    for k=1:length(edge_street)
        eid=edge_street(k,1);
        nid=edge_street(k,ET);
        nedge=node_edge(node_edge(:,1)==nid & node_edge(:,2)==eid,:);
        if nedge(1,3)~=0
           edge_street(k,5)=find(edge_street(:,1)==nedge(1,3) & edge_street(:,2)==nid);
        else
           edge_street(k,5)=0; 
        end
    end
    
    edge_street(:,6)=1;Ns=find(edge_street(:,5)==0);
    for s=1:length(Ns)
        pid=Ns(s);edge_street(pid,6)=0;
        cid=find(edge_street(:,5)==pid);
        while ~isempty(cid)
            edge_street(cid,6)=0;
            temp_cid=[];
            for k=1:length(cid)
                temp_cid=[temp_cid;find(edge_street(:,5)==cid(k))];
            end
            cid=temp_cid;
        end
    end
end

if alg_type==4
    node_edge=zeros(2*length(edge_data(:,1)),3);etag=0;%node_id,from_edge_id,to_edge_id (0 if from_edge is the end of the street)
    for n=1:length(node_data(:,1))
        nedge=node_edge_ang(node_edge_ang(:,1)==node_data(n,1),:);
        ang_diff=zeros(length(nedge(:,1))*(length(nedge(:,1))-1)/2,3);tag=0;
        for i=1:length(nedge(:,1))
            for j=(i+1):length(nedge(:,1))
                if edge_type(nedge(i,2))==edge_type(nedge(j,2))
                    tag=tag+1;ang_diff(tag,:)=[nedge(i,2) nedge(j,2) min(2*pi-abs(nedge(i,3)-nedge(j,3)),abs(nedge(i,3)-nedge(j,3)))];
                else
                    tag=tag+1;ang_diff(tag,:)=[nedge(i,2) nedge(j,2) -1];
                end
            end
        end
        
        %if two edges have the angle less than pi/12, it's hard to diffiante them, so they will be regarded as different street id.
        for i=1:length(nedge(:,1))
            fedge=nedge(i,2);
            if length(nedge(:,1))==1
               etag=etag+1;node_edge(etag,:)=[node_data(n,1) fedge 0];
            else
                fe_ang=sortrows(ang_diff(ang_diff(:,1)==fedge | ang_diff(:,2)==fedge,:),-3);
                if length(nedge(:,1))==2
                    if fe_ang(1,3)>=street_ang
                        etag=etag+1;node_edge(etag,:)=[node_data(n,1) fedge setdiff(fe_ang(1,1:2),fedge)];
                    else
                        etag=etag+1;node_edge(etag,:)=[node_data(n,1) fedge 0];
                    end
                else
                    if fe_ang(1,3)>=street_ang && abs(fe_ang(1,3)-fe_ang(2,3))>par_street_ang
                        etag=etag+1;node_edge(etag,:)=[node_data(n,1) fedge setdiff(fe_ang(1,1:2),fedge)];
                    else
                        etag=etag+1;node_edge(etag,:)=[node_data(n,1) fedge 0];
                    end
                end
            end
        end
    end
    
    edge_street=[edge_data(:,[EI EF ET EL ET ET]);edge_data(:,[EI ET EF EL ET ET])];edge_street(:,5:6)=0;%edge_id,from_node,to_node,edge_length,next_edge_id,loop_tag
    for k=1:length(edge_street)
        eid=edge_street(k,1);
        nid=edge_street(k,ET);
        nedge=node_edge(node_edge(:,1)==nid & node_edge(:,2)==eid,:);
        if nedge(1,3)~=0
           edge_street(k,5)=find(edge_street(:,1)==nedge(1,3) & edge_street(:,2)==nid);
        else
           edge_street(k,5)=0; 
        end
    end
    
    edge_street(:,6)=1;Ns=find(edge_street(:,5)==0);E=length(edge_data(:,1));%edge_street(:,6)==1 indicates the edge is a part of a loop
    for s=1:length(Ns)
        pid=Ns(s);all_cid=pid;
        cid=find(edge_street(:,5)==pid);
        while ~isempty(cid)
            all_cid=[all_cid;cid];
            temp_cid=[];
            for k=1:length(cid)
                temp_cid=[temp_cid;find(edge_street(:,5)==cid(k))];
            end
            cid=temp_cid;
        end
        check_cid=all_cid;check_cid(check_cid>E)=check_cid(check_cid>E)-E;
        if length(unique(check_cid))==length(all_cid)
           edge_street(all_cid,6)=0;
        end
    end
end

if alg_type==5
    node_edge=zeros(2*length(edge_data(:,1)),3);etag=0;%node_id,from_edge_id,to_edge_id (0 if from_edge is the end of the street)
    for n=1:length(node_data(:,1))
        nedge=node_edge_ang(node_edge_ang(:,1)==node_data(n,1),:);
        ang_diff=zeros(length(nedge(:,1))*(length(nedge(:,1))-1)/2,3);tag=0;
        for i=1:length(nedge(:,1))
            for j=(i+1):length(nedge(:,1))
                tag=tag+1;ang_diff(tag,:)=[nedge(i,2) nedge(j,2) min(2*pi-abs(nedge(i,3)-nedge(j,3)),abs(nedge(i,3)-nedge(j,3)))];
            end
        end
        
        %if two edges have the angle less than pi/12, it's hard to diffiante them, so they will be regarded as different street id.
        for i=1:length(nedge(:,1))
            fedge=nedge(i,2);
            if length(nedge(:,1))==1
               etag=etag+1;node_edge(etag,:)=[node_data(n,1) fedge 0];
            else
                fe_ang=sortrows(ang_diff(ang_diff(:,1)==fedge | ang_diff(:,2)==fedge,:),-3);
                if length(nedge(:,1))==2
                   etag=etag+1;node_edge(etag,:)=[node_data(n,1) fedge setdiff(fe_ang(1,1:2),fedge)];
                else
                    if abs(fe_ang(1,3)-fe_ang(2,3))>diff_ang
                        etag=etag+1;node_edge(etag,:)=[node_data(n,1) fedge setdiff(fe_ang(1,1:2),fedge)];
                    else
                        temp_edge=fe_ang(edge_data(fe_ang(:,1),EH)==edge_data(fe_ang(:,2),EH),:);
                        if ~isempty(temp_edge)
                            if length(temp_edge(:,1))==1
                                etag=etag+1;node_edge(etag,:)=[node_data(n,1) fedge setdiff(temp_edge(1,1:2),fedge)];
                            else
                                if abs(temp_edge(1,3)-temp_edge(2,3))>diff_ang
                                    etag=etag+1;node_edge(etag,:)=[node_data(n,1) fedge setdiff(temp_edge(1,1:2),fedge)];
                                else
                                    etag=etag+1;node_edge(etag,:)=[node_data(n,1) fedge 0];
                                end
                            end
                        else
                           etag=etag+1;node_edge(etag,:)=[node_data(n,1) fedge 0]; 
                        end
                    end
                end
            end
        end
    end
    
    edge_street=[edge_data(:,[EI EF ET EL ET ET]);edge_data(:,[EI ET EF EL ET ET])];edge_street(:,5:6)=0;%edge_id,from_node,to_node,edge_length,next_edge_id,end_edge
    for k=1:length(edge_street)
        eid=edge_street(k,1);
        nid=edge_street(k,ET);
        nedge=node_edge(node_edge(:,1)==nid & node_edge(:,2)==eid,:);
        if nedge(1,3)~=0
           edge_street(k,5)=find(edge_street(:,1)==nedge(1,3) & edge_street(:,2)==nid);
        else
           edge_street(k,5)=0; 
        end
    end

%% the following codes is used to label whether an edge is included in a circle route, 1 for yes, 0 otherwise
%     edge_street(:,6)=1;Ns=find(edge_street(:,5)==0);E=length(edge_data(:,1));
%     for s=1:length(Ns)
%         pid=Ns(s);all_cid=pid;
%         cid=find(edge_street(:,5)==pid);
%         while ~isempty(cid)
%             all_cid=[all_cid;cid];
%             temp_cid=[];
%             for k=1:length(cid)
%                 temp_cid=[temp_cid;find(edge_street(:,5)==cid(k))];
%             end
%             cid=temp_cid;
%         end
%         check_cid=all_cid;check_cid(check_cid>E)=check_cid(check_cid>E)-E;
%         if length(unique(check_cid))==length(all_cid)
%            edge_street(all_cid,6)=0;
%         end
%     end
    
 %% use edge_street(:,6) to provide the end edge starting from edge edge_street(e,1)
     E=length(edge_data(:,1));edge_street(E+1:end,1)=(E+1:2*E)';
     for e=1:length(edge_street(:,1))
         edge_seq=edge_street(e,1);ce=edge_street(e,1);
         while edge_street(ce,5)~=0 && ~ismember(edge_street(ce,5),edge_seq)
            edge_seq=[edge_seq;edge_street(ce,5)];ce=edge_street(ce,5); 
         end
         if edge_street(ce,5)==0
            edge_street(e,6)=ce;
         end
         if ismember(edge_street(ce,5),edge_seq)
            edge_street(e,6)=edge_seq(end-1);
         end
     end
     edge_street(E+1:end,1)=(1:E)';
end
