%% Team 07 - Weekly Summer vs Winter Comparison (15-Min Intervals)
clear; clc; close all;

%% 1. Load the Data
% Read the CSV files, skipping the 4 lines of comments at the top
Supply_Raw = readmatrix('data/Team07_supply.csv', 'NumHeaderLines', 4);
Demand_Raw = readmatrix('data/Team07_demand.csv', 'NumHeaderLines', 4);

% Extract time (Column 1) and power (Column 2)
time_s = Supply_Raw(:, 1); 
supply_MW = Supply_Raw(:, 2);
demand_MW = Demand_Raw(:, 2);

% Automatically calculate the time step (dt) and points per day
dt = time_s(2) - time_s(1); % This will result in 900 seconds
points_per_day = (24 * 3600) / dt; % 86400 / 900 = 96 points per day

%% 2. Define Our Example Weeks
% --- SUMMER WEEK (e.g., Days 150 to 156) ---
summer_start_day = 150;
summer_end_day = 156;
% Calculate exact row indices based on 96 points per day
summer_start_idx = (summer_start_day - 1) * points_per_day + 1;
summer_end_idx = summer_end_day * points_per_day;

summer_supply = supply_MW(summer_start_idx:summer_end_idx);
summer_demand = demand_MW(summer_start_idx:summer_end_idx);

% --- WINTER WEEK (e.g., Days 15 to 21) ---
winter_start_day = 15;
winter_end_day = 21;
winter_start_idx = (winter_start_day - 1) * points_per_day + 1;
winter_end_idx = winter_end_day * points_per_day;

winter_supply = supply_MW(winter_start_idx:winter_end_idx);
winter_demand = demand_MW(winter_start_idx:winter_end_idx);

% Create a time vector in HOURS for the X-axis (0 to 168 hours)
time_hours = linspace(0, 168, length(summer_supply));

%% 3. Plotting the Comparison
figure('Name', 'Summer vs Winter Weekly Profiles', 'Color', 'w', 'Position', [100, 100, 1000, 600]);

% SUMMER
subplot(2,1,1);
hold on; grid on;
plot(time_hours, summer_supply, 'b', 'LineWidth', 1.5, 'DisplayName', 'Supply');
plot(time_hours, summer_demand, 'r', 'LineWidth', 1.5, 'DisplayName', 'Demand');

title(sprintf('Example Summer Week (Days %d to %d)', summer_start_day, summer_end_day), 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Power (MW)', 'FontWeight', 'bold');
legend('Location', 'northeast');
xlim([0 168]);
% days
for h = 24:24:168
    xline(h, 'k:', 'HandleVisibility', 'off');
end
hold off;

% WINTER
subplot(2,1,2);
hold on; grid on;
plot(time_hours, winter_supply, 'b', 'LineWidth', 1.5, 'DisplayName', 'Supply');
plot(time_hours, winter_demand, 'r', 'LineWidth', 1.5, 'DisplayName', 'Demand');

title(sprintf('Example Winter Week (Days %d to %d)', winter_start_day, winter_end_day), 'FontSize', 12, 'FontWeight', 'bold');
xlabel('Hours (1 Week)', 'FontWeight', 'bold');
ylabel('Power (MW)', 'FontWeight', 'bold');
legend('Location', 'northeast');
xlim([0 168]);

for h = 24:24:168
    xline(h, 'k:', 'HandleVisibility', 'off');
end
hold off;