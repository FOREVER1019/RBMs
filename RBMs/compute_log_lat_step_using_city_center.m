function log_lat_step=compute_log_lat_step_using_city_center(city_center,len)
define_constants;%define constants parameters
clog=city_center(1);%city center longitude
clat=city_center(2);%%city center latitude
%calculate the longitude step and latitude step per kilometer
x=0.0001;y=1;min_dist=longitude_latitude(clog,clat,clog-x,clat);max_dist=longitude_latitude(clog,clat,clog-y,clat);
while abs(min_dist-len)>=err || abs(max_dist-len)>=err
    z=(x+y)/2;mid_dist=longitude_latitude(clog,clat,clog-z,clat);
    if mid_dist>len
        y=z;max_dist=mid_dist;
    else
        x=z;min_dist=mid_dist;
    end
end
log_step=(x+y)/2;

x=0.0001;y=1;min_dist=longitude_latitude(clog,clat,clog,clat-x);max_dist=longitude_latitude(clog,clat,clog,clat-y);
while abs(min_dist-len)>=err || abs(max_dist-len)>=err
    z=(x+y)/2;mid_dist=longitude_latitude(clog,clat,clog,clat-z);
    if mid_dist>len
        y=z;max_dist=mid_dist;
    else
        x=z;min_dist=mid_dist;
    end
end
lat_step=(x+y)/2;

log_lat_step=[log_step lat_step];
