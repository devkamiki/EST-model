clear; clc; close all;

model = 'estnieuw';
load_system(model);

supplyRaw = readmatrix('data/Team07_supply.csv');
demandRaw = readmatrix('data/Team07_demand.csv');

supply_MW = supplyRaw(~all(isnan(supplyRaw),2), end);
demand_MW = demandRaw(~all(isnan(demandRaw),2), end);

N = min(length(supply_MW), length(demand_MW));
supply_MW = supply_MW(1:N);
demand_MW = demand_MW(1:N);

dt = 900;                 
time = (0:N-1)' * dt;      
t_day = time / 86400;      

supplyPower = supply_MW * 1e6;     
demandPower = demand_MW * 1e6;    

supply_ts = timeseries(supplyPower, time);
demand_ts = timeseries(demandPower, time);


V_line = 220e3;        
R_line =  30        % 0.3 ohm/km *100km
eta_turbine = 0.4;    
T_min = 300;       % K, minimum allowed PCM temperature

set_param([model '/voltage'], 'Value', 'V_line');
set_param([model '/multiply I^2 with total resistance'], 'Gain', 'R_line');
set_param([model '/turbine efficiency (required heat)'], 'Gain', '1/eta_turbine');


stop_time = time(end);
%stop_time =   6*3600;
set_param(model, 'StopTime', num2str(stop_time));

out = sim(model);


I_A = demandPower ./ V_line;                
lineLoss_W = I_A.^2 .* R_line;               
requiredHeat_W = (demandPower + lineLoss_W) ./ eta_turbine;

Qin_W = supplyPower;                        
Qout_W = requiredHeat_W;                     
Qnet_W = Qin_W - Qout_W;                     

E_relative_J = cumtrapz(time, Qnet_W);       
E_relative_MWh = E_relative_J / 3.6e9;       

E_in_MWh = trapz(time, Qin_W) / 3.6e9;
E_out_MWh = trapz(time, Qout_W) / 3.6e9;
E_loss_MWh = trapz(time, lineLoss_W) / 3.6e9;
E_demand_MWh = trapz(time, demandPower) / 3.6e9;

fprintf('\n=== Energy summary ===\n');
fprintf('Input supply energy:      %.2f MWh\n', E_in_MWh);
fprintf('Demand electricity:       %.2f MWh\n', E_demand_MWh);
fprintf('Line loss energy:         %.2f MWh\n', E_loss_MWh);
fprintf('Required heat energy:     %.2f MWh\n', E_out_MWh);
fprintf('Net storage change:       %.2f MWh\n', E_relative_MWh(end));


fig1 = figure('Color','w','Position',[100 100 1500 850]);

subplot(2,1,1);
plot(t_day, supplyPower/1e6, 'b');
hold on;
plot(t_day, demandPower/1e6, 'c');
grid on;
xlim([0 t_day(end)]);
title('Supply and demand');
xlabel('Time [day]');
ylabel('Power [MW]');
legend('Supply','Demand');

subplot(2,1,2);
plot(t_day, Qin_W/1e6, 'b');
hold on;
plot(t_day, Qout_W/1e6, 'r');
grid on;
xlim([0 t_day(end)]);
title('Heat input and required heat output');
xlabel('Time [day]');
ylabel('Heat flow rate [MW]');
legend('Q_{in} from supply','Q_{out} required by demand');

exportgraphics(fig1, 'runoutput1.png', 'Resolution', 200);


fig2 = figure('Color','w','Position',[100 100 1500 850]);

subplot(2,2,1);
plot(t_day, lineLoss_W/1e6, 'r');
grid on;
xlim([0 t_day(end)]);
title('Line loss');
xlabel('Time [day]');
ylabel('Loss [MW]');

subplot(2,2,2);
plot(t_day, requiredHeat_W/1e6, 'r');
grid on;
xlim([0 t_day(end)]);
title('Required heat');
xlabel('Time [day]');
ylabel('Heat flow [MW]');

subplot(2,2,3);
area(t_day, Qnet_W/1e6);
hold on;
yline(0, 'k--');
grid on;
xlim([0 t_day(end)]);
title('Net heat into storage');
xlabel('Time [day]');
ylabel('Q_{in} - Q_{out} [MW]');

subplot(2,2,4);
plot(t_day, E_relative_MWh, 'k');
grid on;
xlim([0 t_day(end)]);
title('Relative stored energy change');
xlabel('Time [day]');
ylabel('Energy [MWh]');

txt = sprintf([ ...
    'Supply energy: %.1f MWh\n' ...
    'Demand energy: %.1f MWh\n' ...
    'Line loss: %.1f MWh\n' ...
    'Required heat: %.1f MWh\n' ...
    'Net change: %.1f MWh'], ...
    E_in_MWh, E_demand_MWh, E_loss_MWh, E_out_MWh, E_relative_MWh(end));

annotation(fig2, 'textbox', [0.62 0.12 0.25 0.18], ...
    'String', txt, ...
    'FitBoxToText', 'on', ...
    'BackgroundColor', 'white', ...
    'EdgeColor', 'black');

exportgraphics(fig2, 'runoutput2.png', 'Resolution', 200);