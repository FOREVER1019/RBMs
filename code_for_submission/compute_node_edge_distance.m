function [dist,loc,end_tag]=compute_node_edge_distance(node,edge)
%node(1) is the coordinate x, node(2) is the coordinate y
%edge(1:2,1) is the coordinate x, and edge(1:2,2) is the coordinate y
%end_tag=1 means the minimum point on the edge from the node is the first edge endpoint
%end_tag=2 means the minimum point on the edge from the node is the second edge endpoint
%end_tag=0 means the minimum point on the edge from the node is on the edge
x1=edge(1,1);y1=edge(1,2);
x2=edge(2,1);y2=edge(2,2);
dist12=sqrt((x1-x2)^2+(y1-y2)^2);
if dist12<=10^-5
   dist=sqrt((x1-node(1))^2+(y1-node(2))^2);
   loc=[x1 y1];
   end_tag=1;
else
   dist1=sqrt((x1-node(1))^2+(y1-node(2))^2);dist2=sqrt((x2-node(1))^2+(y2-node(2))^2);
   if abs(dist1)<10^-5
      dist=0;
      loc=[x1 y1];
      end_tag=1;
   else
      if abs(dist2)<10^-5
         dist=0;
         loc=[x2 y2];
         end_tag=2; 
      else
         if x1==x2
             if node(2)<=max(y1,y2) && node(2)>=min(y1,y2)
                 dist=abs(x1-node(1));
                 loc=[x1 node(2)];
                 end_tag=0;
             else
                 dist=min(dist1,dist2);
                 if dist1<=dist2
                    loc=[x1 y1];end_tag=1;
                 else
                    loc=[x2 y2];end_tag=2; 
                 end
             end
         else
             if y1==y2
                 if node(1)<=max(x1,x2) && node(1)>=min(x1,x2)
                     dist=abs(y1-node(2));
                     loc=[node(1) y1];
                     end_tag=0;
                 else
                     dist=min(dist1,dist2);
                     if dist1<=dist2
                         loc=[x1 y1];end_tag=1;
                     else
                         loc=[x2 y2];end_tag=2;
                     end
                 end
             else
                 k1=(y2-y1)/(x2-x1);b1=-(y2-y1)*x1/(x2-x1)+y1;
                 inx=(node(1)/k1+node(2)-b1)/(k1+1/k1);iny=k1*inx+b1;
                 dist1in=sqrt((x1-inx)^2+(y1-iny)^2);dist2in=sqrt((x2-inx)^2+(y2-iny)^2);
                 if abs(dist12-(dist1in+dist2in))<=0.001
                     dist=sqrt((inx-node(1))^2+(iny-node(2))^2);
                     loc=[inx iny];end_tag=0;
                 else
                     dist=min([dist1 dist2]);
                     if dist1<=dist2
                         loc=[x1 y1];end_tag=1;
                     else
                         loc=[x2 y2];end_tag=2;
                     end
                 end
             end
         end
      end
   end
end