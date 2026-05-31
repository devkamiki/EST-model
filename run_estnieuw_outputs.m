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

dt    = 900;                 % sample interval (15 min)
time  = (0:N-1)' * dt;
t_day = time / 86400;

supplyPower = supply_MW * 1e6;     % [W]
demandPower = demand_MW * 1e6;     % [W]

supply_ts = timeseries(supplyPower, time);
demand_ts = timeseries(demandPower, time);

V_line       = 220e3;     % [V]  transmission voltage
R_line       = 30;        % [ohm] 0.3 ohm/km * 100 km
eta_turbine  = 0.4;       % [-]  heat -> electricity (discharge efficiency)
T_min        = 300;       % [K]  minimum allowed PCM temperature

set_param([model '/voltage'], 'Value', 'V_line');
set_param([model '/multiply I^2 with total resistance'], 'Gain', 'R_line');
set_param([model '/turbine efficiency (required heat)'], 'Gain', '1/eta_turbine');

stop_time = time(end);
set_param(model, 'StopTime', num2str(stop_time));


out = sim(model);


I_A         = demandPower ./ V_line;          % [A]
lineLoss_W  = I_A.^2 .* R_line;               % [W] I^2 R loss
Preq_W      = demandPower + lineLoss_W;        % [W] power required at supply node

%% ------------------------------------------------------------------ %%
%  Storage + grid buy/sell parameters
%% ------------------------------------------------------------------ %%
eta_charge    = 0.95;        % [-] electricity -> stored heat
eta_discharge = eta_turbine; % [-] stored heat -> electricity (turbine)
k_loss        = 1e-7;        % [1/s] standby thermal loss coefficient
Emax          = 1718.75e9;   % [J] usable PCM energy capacity (size of the store)

% --- WITH thermal storage ---
S = dispatch(supplyPower, Preq_W, dt, Emax, eta_charge, eta_discharge, k_loss);

% --- WITHOUT thermal storage (baseline: every deficit bought, every surplus sold) ---
B = dispatch(supplyPower, Preq_W, dt, 0, eta_charge, eta_discharge, k_loss);

%% ------------------------------------------------------------------ %%
%  Energy totals (J)
%% ------------------------------------------------------------------ %%
Ein_supply = trapz(time, supplyPower);    % received from solar park
Edemand    = trapz(time, demandPower);    % electricity consumed by households
Elineloss  = trapz(time, lineLoss_W);

% with storage
E_direct   = trapz(time, S.Pdirect);
E_toStore  = trapz(time, S.Pto_storage);
E_fromStore= trapz(time, S.Pfrom_storage);
E_sell     = trapz(time, S.Psell);
E_buy      = trapz(time, S.Pbuy);
E_storeLoss= trapz(time, S.Ploss);

% baseline (no storage)
E_buy0     = trapz(time, B.Pbuy);
E_sell0    = trapz(time, B.Psell);

% received / delivered totals for pie normalisation
E_received  = E_direct + E_toStore + E_sell;     % = available solar
E_delivered = E_direct + E_fromStore + E_buy;    % = required (demand + loss)

fprintf('\n=============== Energy summary (with storage) ===============\n');
fprintf('Solar supply received : %10.3e J  (%8.1f MWh)\n', Ein_supply, Ein_supply/3.6e9);
fprintf('Household demand       : %10.3e J  (%8.1f MWh)\n', Edemand,    Edemand/3.6e9);
fprintf('Transmission loss      : %10.3e J  (%8.1f MWh)\n', Elineloss,  Elineloss/3.6e9);
fprintf('Direct supply->demand  : %10.3e J  (%8.1f MWh)\n', E_direct,   E_direct/3.6e9);
fprintf('Charged into storage   : %10.3e J  (%8.1f MWh)\n', E_toStore,  E_toStore/3.6e9);
fprintf('Discharged from storage: %10.3e J  (%8.1f MWh)\n', E_fromStore,E_fromStore/3.6e9);
fprintf('Energy SOLD to grid    : %10.3e J  (%8.1f MWh)\n', E_sell,     E_sell/3.6e9);
fprintf('Energy BOUGHT from grid: %10.3e J  (%8.1f MWh)\n', E_buy,      E_buy/3.6e9);
fprintf('Storage standby loss   : %10.3e J  (%8.1f MWh)\n', E_storeLoss,E_storeLoss/3.6e9);

fprintf('\n--------------- Comparison: storage vs no storage ----------\n');
fprintf('Bought  no-storage : %8.1f MWh   with-storage : %8.1f MWh   (-%4.1f%%)\n', ...
    E_buy0/3.6e9, E_buy/3.6e9, 100*(E_buy0-E_buy)/max(E_buy0,eps));
fprintf('Sold    no-storage : %8.1f MWh   with-storage : %8.1f MWh   (-%4.1f%%)\n', ...
    E_sell0/3.6e9, E_sell/3.6e9, 100*(E_sell0-E_sell)/max(E_sell0,eps));
fprintf('Self-sufficiency   no-storage : %4.1f%%   with-storage : %4.1f%%\n', ...
    100*(1 - E_buy0/E_delivered), 100*(1 - E_buy/E_delivered));


fig1 = figure('Color','w','Position',[100 100 1400 850]);

subplot(2,2,1);                                  % Supply and demand
plot(t_day, supplyPower/1e6, 'b'); hold on;
plot(t_day, demandPower/1e6, 'r');
grid on; xlim([0 t_day(end)]);
title('Supply and demand'); xlabel('Time [day]'); ylabel('Power [MW]');
legend('Supply','Demand');

subplot(2,2,2);                                  % Storage state
plot(t_day, S.E/1e9, 'b');
grid on; xlim([0 t_day(end)]);
title('Storage'); xlabel('Time [day]'); ylabel('Stored energy [GJ]');

subplot(2,2,3);                                  % Losses
plot(t_day, lineLoss_W/1e6, 'r'); hold on;
plot(t_day, S.Ploss/1e6, 'b');
grid on; xlim([0 t_day(end)]);
title('Losses'); xlabel('Time [day]'); ylabel('Dissipation rate [MW]');
legend('Transmission (I^2R)','Storage standby');

subplot(2,2,4);                                  % Load balancing
plot(t_day, S.Psell/1e6, 'b'); hold on;
plot(t_day, S.Pbuy/1e6, 'r');
grid on; xlim([0 t_day(end)]);
title('Load balancing'); xlabel('Time [day]'); ylabel('Power [MW]');
legend('Sell','Buy');

exportgraphics(fig1, 'runoutput1.png', 'Resolution', 200);

%% ================================================================== %%
%  FIGURE 2  ->  runoutput2.png   (pie charts + storage benefit)
%% ================================================================== %%
fig2 = figure('Color','w','Position',[100 100 1100 650]);
tl = tiledlayout(fig2,1,2);

ax = nexttile;                                   % Received energy
pie(ax, [E_direct, E_toStore, E_sell]/E_received);
lgd = legend({'Direct to demand','To storage','Sold'});
lgd.Layout.Tile = 'south';
title(sprintf('Received energy %3.2e [J]', E_received));

ax = nexttile;                                   % Delivered energy
pie(ax, [E_direct, E_fromStore, E_buy]/E_delivered);
lgd = legend({'Direct from supply','From storage','Bought'});
lgd.Layout.Tile = 'south';
title(sprintf('Delivered energy %3.2e [J]', E_delivered));

% storage benefit reported as a clean header (keeps the pies uncluttered)
title(tl, sprintf(['Bought %.0f \\rightarrow %.0f MWh (-%.0f%%)     ' ...
                   'Sold %.0f \\rightarrow %.0f MWh (-%.0f%%)     ' ...
                   'Self-sufficiency %.0f%% \\rightarrow %.0f%%'], ...
    E_buy0/3.6e9,  E_buy/3.6e9,  100*(E_buy0-E_buy)/max(E_buy0,eps), ...
    E_sell0/3.6e9, E_sell/3.6e9, 100*(E_sell0-E_sell)/max(E_sell0,eps), ...
    100*(1-E_buy0/E_delivered), 100*(1-E_buy/E_delivered)), ...
    'FontWeight','normal','FontSize',10);

exportgraphics(fig2, 'runoutput2.png', 'Resolution', 200);

disp('DONE: characteristic graph (runoutput1.png) and pie charts (runoutput2.png) written.');

%% ================================================================== %%
%  Local function: time-stepped dispatch with grid buy/sell
%% ================================================================== %%
function S = dispatch(supply, Preq, dt, Emax, eta_c, eta_d, k_loss)
% Marches a bounded thermal store and splits the flows into the EST
% categories (direct / to-storage / from-storage / sold / bought).
% Set Emax = 0 to get the no-storage baseline.
    n = numel(supply);
    [E, Pdirect, Pto_storage, Pfrom_storage, Psell, Pbuy, Ploss] = deal(zeros(n,1));
    Estate = 0;                                   % current stored energy [J]
    for i = 1:n
        Pdir = min(supply(i), Preq(i));
        surplus = supply(i) - Pdir;
        deficit = Preq(i)   - Pdir;

        % charge with surplus (limited by free space)
        Echg  = min(surplus*eta_c*dt, max(Emax - Estate, 0));
        Pchg  = Echg/(eta_c*dt);                  % electrical power into store
        Psll  = surplus - Pchg;                   % could not be stored -> sold

        % discharge to cover deficit (limited by stock)
        Edis  = min(deficit*dt/eta_d, Estate);
        Pdis  = Edis*eta_d/dt;                    % electrical power from store
        Pbuyi = deficit - Pdis;                   % store could not cover -> bought

        % standby loss and state update
        Eloss = k_loss*Estate*dt;
        Estate = min(max(Estate + Echg - Edis - Eloss, 0), Emax);

        E(i)=Estate; Pdirect(i)=Pdir; Pto_storage(i)=Pchg; Pfrom_storage(i)=Pdis;
        Psell(i)=Psll; Pbuy(i)=Pbuyi; Ploss(i)=Eloss/dt;
    end
    S = struct('E',E,'Pdirect',Pdirect,'Pto_storage',Pto_storage, ...
               'Pfrom_storage',Pfrom_storage,'Psell',Psell,'Pbuy',Pbuy,'Ploss',Ploss);
end
