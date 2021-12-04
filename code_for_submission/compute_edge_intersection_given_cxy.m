function new_edge_xy=compute_edge_intersection_given_cxy(edge_xy,cx,cy)
%edge_xy(:,1) is the longtitude for each linear segment point along the edge
%edge_xy(:,2) is the latitude for each linear segment point along the edge
% cx is the set of all longtitude values of concern
% cy is the set of all latitude values of concer
%new_edge_xy updates edge_xy by considering all intersections between edge_xy and each x=cx(k) or each y=cy(k)
define_constants;fdist=0;
new_edge_xy=zeros(length(edge_xy(:,1))*2,5);ntag=0;%point id,longtitude,latitude,distance_to_start_node (km), 1 for newly added point and 0 otherwise
for n=2:length(edge_xy(:,1))
    ntag=ntag+1;new_edge_xy(ntag,1:4)=[ntag edge_xy(n-1,1:2) fdist];
    inter_node=zeros(length(cx)+length(cy),3);ptag=0;
    x1=edge_xy(n-1,1);y1=edge_xy(n-1,2);x2=edge_xy(n,1);y2=edge_xy(n,2);
    if abs(x1-x2)<=err
        for k=1:length(cy)
            if cy(k)>=min(y1,y2) && cy(k)<=max(y1,y2)
               ptag=ptag+1;inter_node(ptag,1:2)=[x1 cy(k)];
            end
        end
    else
        if abs(y1-y2)<=err
            for k=1:length(cx)
                if cx(k)>=min(x1,x2) && cx(k)<=max(x1,x2)
                    ptag=ptag+1;inter_node(ptag,1:2)=[cx(k) y1];
                end
            end
        else
            kc=(y2-y1)/(x2-x1);b=-(y2-y1)*x1/(x2-x1)+y1;
            for k=1:length(cx)
                if cx(k)>=min(x1,x2) && cx(k)<=max(x1,x2)
                   ptag=ptag+1;inter_node(ptag,1:2)=[cx(k) kc*cx(k)+b];
                end
            end
            for k=1:length(cy)
                if cy(k)>=min(y1,y2) && cy(k)<=max(y1,y2)
                   ptag=ptag+1;inter_node(ptag,1:2)=[(cy(k)-b)/kc cy(k)]; 
                end
            end   
        end
    end
    inter_node=inter_node(1:ptag,:);
    
    if ~isempty(inter_node)
        for i=1:length(inter_node(:,1))
            inter_node(i,3)=longitude_latitude(x1,y1,inter_node(i,1),inter_node(i,2));
        end
        inter_node=sortrows(inter_node,3);
        new_edge_xy(ntag+(1:ptag),:)=[ntag+(1:ptag)' inter_node(:,1:2) fdist+inter_node(:,3) ones(ptag,1)];ntag=ntag+ptag;
    end
    fdist=fdist+longitude_latitude(x1,y1,x2,y2);
end
ntag=ntag+1;new_edge_xy(ntag,1:4)=[ntag edge_xy(end,1:2) fdist];new_edge_xy=new_edge_xy(1:ntag,:);