%Real time loop for DC

function realtimeloop(Ppv_k,Pload,efficiency_k,step_time,eff_round_trip,capacitaMinima,capacitaMassima,Ebatt_k)
Pbatt=zeros(1440,4,3);
Penel=zeros(1440,4,3);
Pvendibile=zeros(1440,4,3);
Ebatt=zeros(1440,4,3);
Ebatt(1,:,:)=capacitaMassima;

for month=1:1:4
    for caso=1:1:3
        for time=1:1:1440
            Presdc(time,month,caso)=[Ppv(time,month,caso)-Pload(time,month,caso)]/efficiency(time,month,caso);
            if(Presdc <= 0 && Ebatt(time-1,month,caso) >= capacitaMinima) %deficit e batteria pronta
                Pbatt(time,month,caso)=-Presdc/eff_round_trip; %scarica
                Ebatt(time,month,caso)=Ebatt(time-1,month,caso)+(Pbatt(time-1,month,caso)+Pbatt(time,month,caso))*step_time/2;
            elseif (Presdc <= 0 && Ebatt(time-1,month,caso) == capacitaMinima
                Penel(time,month,caso)=Presdc(time,month,caso);
            elseif (Presdc > 0 && batteryIsNotEmpty)
                Pbatt(time,month,caso)=Presdc/eff_round_trip;
            elseif( Presdc > 0 && batteryIsFull)
                Pvendibile(time,month,caso)=Presdc;
            end
        end
    end
end
