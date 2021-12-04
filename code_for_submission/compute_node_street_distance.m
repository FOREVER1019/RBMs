function [dist,loc,end_tag,loc_ang,new_street]=compute_node_street_distance(node,street)
%node(1) is node ID, node(2) is the coordinate x, node(3) is the coordinate y
%edge(1:2,1) is the coordinate x, and edge(1:2,2) is the coordinate y
%end_tag=1 means the minimum point on the edge from the node is the first edge endpoint
%end_tag=2 means the minimum point on the edge from the node is the second edge endpoint
%end_tag=0 means the minimum point on the edge from the node is on the edge
%street(:,1) is the node_id, street(:,2:3) is the coordinate x,y
nx=node(2);ny=node(3);
node_street_dist=sqrt((street(:,2)-nx).^2+(street(:,3)-ny).^2);
cn1=find(node_street_dist==min(node_street_dist));
cn1=cn1(1);
if cn1==1
    [dist,loc,end_tag]=compute_node_edge_distance([nx,ny],street(cn1:cn1+1,2:3));
    loc_ang=compute_edge_angle(street(cn1:cn1+1,2),street(cn1:cn1+1,3));
    new_street=[street(1,:);node(1) loc(1) loc(2);street(2:end,:)];
else
    if cn1==length(street(:,1))
        [dist,loc,end_tag]=compute_node_edge_distance([nx,ny],street(cn1-1:cn1,2:3));
        loc_ang=compute_edge_angle(street(cn1-1:cn1,2),street(cn1-1:cn1,3));
        new_street=[street(1:end-1,:);node(1) loc(1) loc(2);street(end,:)];
    else
        [dist_left,loc_left,end_tag_left]=compute_node_edge_distance([nx,ny],street(cn1-1:cn1,2:3));
        [dist_right,loc_right,end_tag_right]=compute_node_edge_distance([nx,ny],street(cn1:cn1+1,2:3));
        if dist_left<=dist_right
            dist=dist_left;loc=loc_left;end_tag=end_tag_left;
            loc_ang=compute_edge_angle(street(cn1-1:cn1,2),street(cn1-1:cn1,3));
            new_street=[street(1:cn1-1,:);node(1) loc(1) loc(2);street(cn1:end,:)];
        else
            dist=dist_right;loc=loc_right;end_tag=end_tag_right;
            loc_ang=compute_edge_angle(street(cn1:cn1+1,2),street(cn1:cn1+1,3));
            new_street=[street(1:cn1,:);node(1) loc(1) loc(2);street(cn1+1:end,:)];
        end
    end
end