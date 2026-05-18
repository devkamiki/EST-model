clear; clc; close all;

%folder = 'C:\EST';
%if ~exist(folder,'dir')
 %   mkdir(folder);
%end
%cd(folder);

supplyFile = 'data/Team07_supply.csv';
demandFile = 'data/Team07_demand.csv';

supplyRaw = readmatrix(supplyFile);
demandRaw = readmatrix(demandFile);

supplyRaw = supplyRaw(~all(isnan(supplyRaw),2),:);
demandRaw = demandRaw(~all(isnan(demandRaw),2),:);

dt = 900; 

if size(supplyRaw,2) == 1
    supplyPower = supplyRaw(:,1);
else
    supplyPower = supplyRaw(:,end);
end

if size(demandRaw,2) == 1
    demandPower = demandRaw(:,1);
else
    demandPower = demandRaw(:,end);
end

supplyPower = supplyPower * 1e6;
demandPower = demandPower * 1e6;


N = min(length(supplyPower), length(demandPower));
supplyPower = supplyPower(1:N);
demandPower = demandPower(1:N);

time = (0:N-1)' * dt;


supply_ts = timeseries(supplyPower, time);
demand_ts = timeseries(demandPower, time);

assignin('base','supply_ts',supply_ts);
assignin('base','demand_ts',demand_ts);

model = 'Thermal_EST_Group7_CSV';

if bdIsLoaded(model)
    close_system(model,0);
end

if exist([model '.slx'],'file')
    delete([model '.slx']);
end

new_system(model);
open_system(model);

add_block('simulink/Sources/From Workspace', [model '/Supply CSV'], ...
    'VariableName','supply_ts', ...
    'Position',[50 100 180 130]);

add_block('simulink/Sources/From Workspace', [model '/Demand CSV'], ...
    'VariableName','demand_ts', ...
    'Position',[50 190 180 220]);

add_block('simulink/User-Defined Functions/MATLAB Function', ...
    [model '/Thermal Storage System'], ...
    'Position',[300 90 600 300]);

add_block('simulink/Discrete/Unit Delay', [model '/Stored Energy Memory'], ...
    'InitialCondition','0', ...
    'Position',[670 100 740 140]);

add_block('simulink/Sinks/Scope', [model '/Scope Stored Energy'], ...
    'Position',[880 70 930 110]);

add_block('simulink/Sinks/Scope', [model '/Scope Delivered Power'], ...
    'Position',[880 130 930 170]);

add_block('simulink/Sinks/Scope', [model '/Scope Bought Power'], ...
    'Position',[880 190 930 230]);

add_block('simulink/Sinks/Scope', [model '/Scope Sold Power'], ...
    'Position',[880 250 930 290]);

add_block('simulink/Sinks/Scope', [model '/Scope Thermal Loss'], ...
    'Position',[880 310 930 350]);

add_block('simulink/Sinks/To Workspace', [model '/E_storage_out'], ...
    'VariableName','E_storage_out', ...
    'SaveFormat','Timeseries', ...
    'Position',[1020 70 1140 100]);

add_block('simulink/Sinks/To Workspace', [model '/P_delivered_out'], ...
    'VariableName','P_delivered_out', ...
    'SaveFormat','Timeseries', ...
    'Position',[1020 130 1140 160]);

add_block('simulink/Sinks/To Workspace', [model '/P_bought_out'], ...
    'VariableName','P_bought_out', ...
    'SaveFormat','Timeseries', ...
    'Position',[1020 190 1140 220]);

add_block('simulink/Sinks/To Workspace', [model '/P_sold_out'], ...
    'VariableName','P_sold_out', ...
    'SaveFormat','Timeseries', ...
    'Position',[1020 250 1140 280]);

add_block('simulink/Sinks/To Workspace', [model '/P_loss_out'], ...
    'VariableName','P_loss_out', ...
    'SaveFormat','Timeseries', ...
    'Position',[1020 310 1140 340]);

rt = sfroot;
chart = rt.find('-isa','Stateflow.EMChart','Path',[model '/Thermal Storage System']);

chart.Script = [
"function [E_next, P_delivered, P_bought, P_sold, P_loss] = fcn(supply, demand, E_old)" newline ...
"" newline ...
"% Parameters" newline ...
"dt = 900;" newline ...
"Emax = 1718.75e9;" newline ...
"eta_charge = 0.95;" newline ...
"eta_discharge = 0.33;" newline ...
"k_loss = 1e-7;" newline ...
"" newline ...
"% Surplus and deficit" newline ...
"P_surplus = max(supply - demand, 0);" newline ...
"P_deficit = max(demand - supply, 0);" newline ...
"" newline ...
"% Charging" newline ...
"E_charge_possible = P_surplus * eta_charge * dt;" newline ...
"E_space = max(Emax - E_old, 0);" newline ...
"E_charge = min(E_charge_possible, E_space);" newline ...
"" newline ...
"% Discharging" newline ...
"E_needed = P_deficit * dt / eta_discharge;" newline ...
"E_discharge = min(E_needed, E_old);" newline ...
"P_delivered = E_discharge * eta_discharge / dt;" newline ...
"" newline ...
"% Thermal loss" newline ...
"E_loss = k_loss * E_old * dt;" newline ...
"P_loss = E_loss / dt;" newline ...
"" newline ...
"% New stored energy" newline ...
"E_next = E_old + E_charge - E_discharge - E_loss;" newline ...
"E_next = min(max(E_next, 0), Emax);" newline ...
"" newline ...
"% Bought and sold power" newline ...
"P_bought = max(P_deficit - P_delivered, 0);" newline ...
"P_sold = max(P_surplus - E_charge/(eta_charge*dt), 0);" newline ...
];

set_param(model,'SimulationCommand','update');

add_line(model,'Supply CSV/1','Thermal Storage System/1','autorouting','on');
add_line(model,'Demand CSV/1','Thermal Storage System/2','autorouting','on');
add_line(model,'Stored Energy Memory/1','Thermal Storage System/3','autorouting','on');

add_line(model,'Thermal Storage System/1','Stored Energy Memory/1','autorouting','on');

add_line(model,'Thermal Storage System/1','Scope Stored Energy/1','autorouting','on');
add_line(model,'Thermal Storage System/2','Scope Delivered Power/1','autorouting','on');
add_line(model,'Thermal Storage System/3','Scope Bought Power/1','autorouting','on');
add_line(model,'Thermal Storage System/4','Scope Sold Power/1','autorouting','on');
add_line(model,'Thermal Storage System/5','Scope Thermal Loss/1','autorouting','on');

add_line(model,'Thermal Storage System/1','E_storage_out/1','autorouting','on');
add_line(model,'Thermal Storage System/2','P_delivered_out/1','autorouting','on');
add_line(model,'Thermal Storage System/3','P_bought_out/1','autorouting','on');
add_line(model,'Thermal Storage System/4','P_sold_out/1','autorouting','on');
add_line(model,'Thermal Storage System/5','P_loss_out/1','autorouting','on');

set_param(model,'Solver','FixedStepDiscrete');
set_param(model,'FixedStep','900');
set_param(model,'StopTime',num2str(time(end)));

save_system(model);

sim(model);

figure;
plot(E_storage_out.Time/3600, E_storage_out.Data/1e9);
xlabel('Time [hours]');
ylabel('Stored energy [GJ]');
title('Thermal stored energy');
grid on;

figure;
plot(P_delivered_out.Time/3600, P_delivered_out.Data/1e6);
xlabel('Time [hours]');
ylabel('Power [MW]');
title('Power delivered from storage');
grid on;

figure;
plot(P_bought_out.Time/3600, P_bought_out.Data/1e6);
xlabel('Time [hours]');
ylabel('Power [MW]');
title('Power bought from grid');
grid on;

figure;
plot(P_sold_out.Time/3600, P_sold_out.Data/1e6);
xlabel('Time [hours]');
ylabel('Power [MW]');
title('Power sold or wasted');
grid on;

figure;
plot(P_loss_out.Time/3600, P_loss_out.Data/1e6);
xlabel('Time [hours]');
ylabel('Power [MW]');
title('Thermal power losses');
grid on;

open_system(model);
Simulink.BlockDiagram.arrangeSystem(model);

disp('DONE: Model created, connected to CSV files, simulated, and plotted.');