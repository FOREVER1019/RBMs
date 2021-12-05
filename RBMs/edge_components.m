function [edge_com,bound_edge]=edge_components(edge_data,del_edge)
%del_edge: the set of deleted edge ids;edge_com is the component id for each edge, bound_edge is the connection between del_edge and remained edge
define_constants;
edge_com=edge_data(:,EI)*0;
if ~isempty(del_edge)
   edge_com(del_edge)=-1;   
   del_node=unique([edge_data(del_edge,EF);edge_data(del_edge,ET)]);
   bound_edge=zeros(length(del_edge)*5,3);be_tag=0;%subnetwork_component_id,local_node_id,del_node_id 
else
   del_node=[];bound_edge=[];be_tag=0;
end
uncheck_edge=edge_data(edge_com==0,EI);
E=length(edge_data(:,EI));com_id=0;
while ~isempty(uncheck_edge)
    com_uncheck_edge=zeros(ceil(0.1*E),1);ctag=1;
    com_uncheck_edge(1)=uncheck_edge(1);
    com_id=com_id+1;
    edge_com(com_uncheck_edge(1))=com_id;
    while ctag>0
        to_check_edge=com_uncheck_edge(1);
        en1=edge_data(to_check_edge,EF);en2=edge_data(to_check_edge,ET);
        if ~ismember(en1,del_node)
            next_check_edge=edge_data((edge_data(:,EF)==en1 | edge_data(:,ET)==en1) & edge_com==0,EI);
            if ~isempty(next_check_edge)
               edge_com(next_check_edge)=com_id;
               com_uncheck_edge(ctag+1:ctag+length(next_check_edge))=next_check_edge;
               ctag=ctag+length(next_check_edge);
            end
        end
        if ~ismember(en2,del_node)
            next_check_edge=edge_data((edge_data(:,EF)==en2 | edge_data(:,ET)==en2) & edge_com==0,EI);
            if ~isempty(next_check_edge)
               edge_com(next_check_edge)=com_id;
               com_uncheck_edge(ctag+1:ctag+length(next_check_edge))=next_check_edge;
               ctag=ctag+length(next_check_edge);
            end
        end
        if ismember(en1,del_node) && ~ismember(en2,del_node)
           be_tag=be_tag+1;bound_edge(be_tag,:)=[com_id en2 en1];
        end
        if ~ismember(en1,del_node) && ismember(en2,del_node)
            be_tag=be_tag+1;bound_edge(be_tag,:)=[com_id en1 en2];
        end
        if ismember(en1,del_node) && ismember(en2,del_node)
            be_tag=be_tag+1;bound_edge(be_tag,:)=[com_id en1 en2];
        end
        com_uncheck_edge=com_uncheck_edge(1:ctag);com_uncheck_edge(1)=[];ctag=ctag-1;
    end
    uncheck_edge=edge_data(edge_com==0,EI);
end
if be_tag>0
   bound_edge=bound_edge(1:be_tag,:);
end