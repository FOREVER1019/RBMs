function edge_speed_time=update_road_edge_speed_time(org_edge_data)
define_constants;
edge_speed_time=abs([org_edge_data(:,ES) org_edge_data(:,EL)*0.06./org_edge_data(:,ES)]);
end