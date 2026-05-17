% Post-processing script for the EST Simulink model. This script is invoked
% after the Simulink model is finished running (stopFcn callback function).

close all;
figure;

%% Supply and demand
subplot(2,2,1);
plot(tout/unit("day"), PSupply/unit("W"));
hold on;
plot(tout/unit("day"), PDemand/unit("W"));
xlim([0 tout(end)/unit("day")]);
grid on;
title('Supply and demand');
xlabel('Time [day]');
ylabel('Power [W]');
legend("Supply","Demand");
%% daily energy demand average
%avgSupply = mean(PSupply);
avgDemand = mean(PDemand);

%% Stored energy
subplot(2,2,2);
plot(tout/unit("day"), EStorage/unit("J"));
xlim([0 tout(end)/unit("day")]);
grid on;
title('Storage');
xlabel('Time [day]');
ylabel('Energy [J]');

%% Energy losses
subplot(2,2,3);
plot(tout/unit("day"), D/unit("W"));
xlim([0 tout(end)/unit("day")]);
grid on;
title('Losses');
xlabel('Time [day]');
ylabel('Dissipation rate [W]');

%% Load balancing
subplot(2,2,4);
plot(tout/unit("day"), PSell/unit("W"));
hold on;
plot(tout/unit("day"), PBuy/unit("W"));
xlim([0 tout(end)/unit("day")]);
grid on;
title('Load balancing');
xlabel('Time [day]');
ylabel('Power [W]');
legend("Sell","Buy");
%% Supply - Demand difference
PDiff = PSupply - PDemand;
tday = tout/unit("day");
PDiffW = PDiff/unit("W");
dt = tout(2) - tout(1);        % [s]

ESurplus = sum(max(PDiff,0))*dt;     % [J]
EDeficit = sum(max(-PDiff,0))*dt;    % [J]

PeakSurplus = max(PDiff);            % [W]
PeakDeficit = min(PDiff);            % [W]

ESurplus_MWh = ESurplus / 3.6e9;
EDeficit_MWh = EDeficit / 3.6e9;
figure;
area(tday, PDiffW);
hold on;
yline(0, 'k--');
xlim([0 tday(end)]);
grid on;
title('Supply - Demand difference');
xlabel('Time [day]');
ylabel('Power difference [W]');
txt = sprintf([ ...
    'Peak surplus: %.2e W\n' ...
    'Peak deficit: %.2e W\n' ...
    'Annual surplus: %.2f MWh\n' ...
    'Annual deficit: %.2f MWh'], ...
    PeakSurplus, PeakDeficit, ESurplus_MWh, EDeficit_MWh);

text(0.02*tday(end), 0.9*max(PDiffW), txt, ...
    'FontSize', 10, ...
    'BackgroundColor', 'white', ...
    'EdgeColor', 'black', ...
    'Margin', 6, ...
    'VerticalAlignment', 'top');
%% Pie charts

% integrate the power signals in time
EfromSupplyTransport = trapz(tout, PfromSupplyTransport);
EtoDemandTransport   = trapz(tout, PtoDemandTransport);
ESell                = trapz(tout, PSell);
EBuy                 = trapz(tout, PBuy);
EtoInjection         = trapz(tout, PtoInjection);
EfromExtraction      = trapz(tout, PfromExtraction);
EStorageDissipation  = trapz(tout, DStorage);
EDirect              = EfromSupplyTransport - ESell - EtoInjection;
ESurplus             = EtoInjection-EfromExtraction-EStorageDissipation;

figure;
tiles = tiledlayout(1,2);

ax = nexttile;
pie(ax, [EDirect, EtoInjection, ESell]/EfromSupplyTransport);
lgd = legend({"Direct to demand", "To storage", "Sold"});
lgd.Layout.Tile = "south";
title(sprintf("Received energy %3.2e [J]", EfromSupplyTransport/unit('J')));

ax = nexttile;
pie(ax, [EDirect, EfromExtraction, EBuy]/EtoDemandTransport);
lgd = legend({"Direct from supply", "From storage", "Bought"});
lgd.Layout.Tile = "south";
title(sprintf("Delivered energy %3.2e [J]", EtoDemandTransport/unit('J')));