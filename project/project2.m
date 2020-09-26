k=1.38*10^(-23);%Boltzman's constant
T=273+27;% temperature in Kelvin degree
h_t=50+1.5;%height of building+height of transmitter
h_r=1.5;%height of receiver
Bandwidth=10^7;%10M
N_t=k*T*Bandwidth;%Thermal noise power in watt

Pt_b=3;%33dBm=3dB, base station's power
Pt_m=(-7);%23dBm=-7dB mobile's power
G_t=14;
G_r=14;

%BS_x BS_y is the x and y coordinate of other BS
for i=1:6
    BS_x(i)=500*cos(pi*(2*i-1)/6);
    BS_y(i)=500*sin(pi*(2*i-1)/6);
end

for i=7:12
    BS_x(i)=1000*cos(pi*(2*i-13)/6);
    BS_y(i)=1000*sin(pi*(2*i-13)/6);
end

for i=13:18
    BS_x(i)=1500*cos(pi*(i-13)/3)/sqrt(3);
    BS_y(i)=1500*sin(pi*(i-13)/3)/sqrt(3);
end
BS_x(19)=0;
BS_y(19)=0;

% To make the result repeatable
%rng('default');



%set 50 other mobile device in the cells
for j=1:19
i=1;
while i<=50
    tmp1=-500/sqrt(3)+1000/sqrt(3)*rand;
    tmp2=-250+500*rand;
    if (sqrt(3)*tmp1+tmp2>500)%rand出來點在右上那條邊外面
        
    elseif (sqrt(3)*tmp1-tmp2>500)%rand出來點在右下那條邊外面 
        
    elseif (sqrt(3)*tmp1-tmp2<-500)%rand出來點在左上那條邊外面 
        
    elseif (sqrt(3)*tmp1+tmp2<-500)%rand出來點在左下那條邊外面
        
    else
        x(50*j+i-50)=BS_x(j)+tmp1;
        y(50*j+i-50)=BS_y(j)+tmp2;
        i=i+1;
    end
end
end


for j=1:19
for i=1:50

    d(50*j+i-50)=sqrt((x(50*j+i-50)-BS_x(j))^2+(y(50*j+i-50)-BS_y(j))^2);
end
end

for j=1:19
for i=1:50
P_r(50*j+i-50)=10*log10((h_t*h_r)^2/(d(50*j+i-50))^4)+Pt_m+G_t+G_r;
end
end

Noise_b(1)=0;
for j=1:19
    sum=0;
    for i=1:50
    sum=sum+10^(P_r(50*j+i-50)/10);
    end
    Noise_b(j)=10*log10(sum+N_t);
end
%moving mobile uplink/downlinking, uplink file size=5MB, downlink
%filsize=100MB
count=1;
m_x=0;
m_y=0;
cellid=19;
ts=0;
transmitted_d=0;
transmitted_u=0;
H=zeros(1,4);
busy=0;
fail=0;

%Consider only UL/UL and DL/DL interference 
while (transmitted_u<=40||transmitted_d<=800)
    direction=2*pi*rand;
    v=1+4*rand;
    t=1000*randi(6);
    H(count,1)=m_x;
    H(count,2)=m_y;
    H(count,3)=v;
    H(count,4)=t/1000;
    for i=1:t
        m_x=m_x+v*sin(direction)/1000;
        m_y=m_y+v*cos(direction)/1000;
        d_present=sqrt((BS_x(cellid)-(m_x))^2+(BS_y(cellid)-(m_y))^2);
    for j=1:19
        if d_present>sqrt((BS_x(j)-(m_x))^2+(BS_y(j)-(m_y))^2)
            cellid=j;
            d_present=sqrt((BS_x(j)-(m_x))^2+(BS_y(j)-(m_y))^2);
            if transmitted_u<40
            transmitted_u=0;
            end
            if transmitted_d<800
            transmitted_d=0;
            end
        end
    end
    if (mod(i,10)>=3&&mod(i,10)<=5)% change based on which configuration
        
    
        Pr_b=10*log10((h_t*h_r)^2/(d_present)^4)+Pt_m+G_t+G_r;
        
        
            if Pr_b<Noise_b(cellid)%if noise>signal, can't send
                
                busy=busy+1;
            elseif Pr_b<(Noise_b(cellid)+10*log(2))
                transmitted_u=transmitted_u+0.025;
            else
                transmitted_u=transmitted_u+0.075;
            end
        
        
    elseif(mod(i,10)<=1||mod(i,10)>=6)
        Pr_m=10*log10((h_t*h_r)^2/(d_present)^4)+Pt_b+G_t+G_r;
        sum=0;
        for j=1:19
            if j~=cellid
                d_b=sqrt((BS_x(j)-(m_x))^2+(BS_y(j)-(m_y))^2);
                Pm_n=10*log10((h_t*h_r)^2/(d_b)^4)+Pt_b+G_t+G_r;%noise of other base
                sum=sum+10^(Pm_n/10);
            end
        end
        P_noise=10*log10(N_t+sum);
        if (P_noise+10*log10(2))<Pr_m
            transmitted_d=transmitted_d+0.3;
        elseif P_noise<Pr_m
            transmitted_d=transmitted_d+0.051;
        else 
            busy=busy+1;
        end
    end
    if transmitted_u>40 && transmitted_d>800
    break;
    end
    
    end
    if busy>300000
        fail=1;
        break;
    end
    ts=ts+i;
    count=count+1;
end