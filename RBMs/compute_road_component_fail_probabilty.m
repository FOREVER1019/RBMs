function [prob,pgd]=compute_road_component_fail_probabilty(mag,long,lat,cx,cy,type)
%Roadways
fragility_coefficient(1,1:2,1)=[0.15, 0.7];    %Slight
fragility_coefficient(2,1:2,1)=[0.30, 0.7];    %Moderate
fragility_coefficient(3,1:2,1)=[0.61, 0.7];    %Extensive
fragility_coefficient(4,1:2,1)=[0.61, 0.7];    %Complete
%Bridges
fragility_coefficient(1,1:2,2)=[0.10, 0.2]; 
fragility_coefficient(2,1:2,2)=[0.10, 0.2]; 
fragility_coefficient(3,1:2,2)=[0.10, 0.2]; 
fragility_coefficient(4,1:2,2)=[0.35, 0.2];
%Tunnels
fragility_coefficient(1,1:2,3)=[0.15, 0.7];
fragility_coefficient(2,1:2,3)=[0.15, 0.7];
fragility_coefficient(3,1:2,3)=[0.30, 0.5];
fragility_coefficient(4,1:2,3)=[1.52, 0.5];

longitude1=long*pi/180;latitude1=lat*pi/180;
longitude2=cx*pi/180;latitude2=cy*pi/180;
dist=2*asin(sqrt((sin((latitude1-latitude2)/2))^2+cos(latitude1)*cos(latitude2)*(sin((longitude1-longitude2)/2))^2))*6371;
% pga= exp(2.20+0.81*(mag-6.0)-1.27*log(sqrt(dist^2+9.3^2))+0.11*max(log(dist/100),0)-0.0021*sqrt(dist^2+9.3^2));
% pgd=exp((-5.27+1.6*mag-0.07*(mag-5.5)+(-2.0+0.17*mag)*log(sqrt(dist^2+4^2)))/100);
lgpgd=-2.06+0.7212*mag-1.168*log10(dist+0.3268*exp(0.6135*mag))+0.2896;pgd=(10^lgpgd)/100;
prob=zeros(4,1);
for p=1:4
    prob(p,1)=0.5+0.5.*erf((log(pgd)-log(fragility_coefficient(p,1,type)))./(1.4142.*fragility_coefficient(p,2,type)));
end

% mag=8;long=120;lat=30;cx=120.5;cy=30.5;type=1;[prob,pgd]=compute_road_component_fail_probabilty(mag,long,lat,cx,cy,type)
