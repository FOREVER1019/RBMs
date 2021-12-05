function ang=compute_edge_angle(edge_X,edge_Y)
% the outout is from 0 to 2*pi, with the from_node as the center... from_node(1) (to_node(1)) is the coordinate x and from_node(2)(to_node(2)) is the coordinate y
ang=zeros(length(edge_X)-1,1);
for n=2:length(edge_X)
    from_node=zeros(2,1);to_node=zeros(2,1);
    from_node(1)=edge_X(n-1);from_node(2)=edge_Y(n-1);
    to_node(1)=edge_X(n);to_node(2)=edge_Y(n);
    if from_node(1)==to_node(1)
        if from_node(2)==to_node(2)
            ang(n-1)=NaN;
        end
        if from_node(2)<to_node(2)
            ang(n-1)=pi/2;
        end
        if from_node(2)>to_node(2)
            ang(n-1)=3*pi/2;
        end
    end
    if from_node(1)<to_node(1)
        if from_node(2)==to_node(2)
            ang(n-1)=0;
        end
        if from_node(2)<to_node(2)
            ang(n-1)=acos((to_node(1)-from_node(1))/sqrt((to_node(1)-from_node(1))^2+(to_node(2)-from_node(2))^2));
        end
        if from_node(2)>to_node(2)
            ang(n-1)=2*pi-acos((to_node(1)-from_node(1))/sqrt((to_node(1)-from_node(1))^2+(to_node(2)-from_node(2))^2));
        end
    end
    if from_node(1)>to_node(1)
        if from_node(2)==to_node(2)
            ang(n-1)=pi;
        end
        if from_node(2)<to_node(2)
            ang(n-1)=acos((to_node(1)-from_node(1))/sqrt((to_node(1)-from_node(1))^2+(to_node(2)-from_node(2))^2));
        end
        if from_node(2)>to_node(2)
            ang(n-1)=pi+acos((from_node(1)-to_node(1))/sqrt((to_node(1)-from_node(1))^2+(to_node(2)-from_node(2))^2));
        end
    end
end