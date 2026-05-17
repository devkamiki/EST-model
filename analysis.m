
addpath('scripts');

dt = 3600; % 1 hour in seconds

% 1. Load the data, skipping the 4 lines of comments/headers
Supply_Raw = readmatrix('Team07_supply.csv', 'NumHeaderLines', 4);
Demand_Raw = readmatrix('Team07_demand.csv', 'NumHeaderLines', 4);

% 2. Extract ONLY the Power column (Column 2)
Supply_Power_MW = Supply_Raw(:, 2);
Demand_Power_MW = Demand_Raw(:, 2);

%% Year Overall Metrics
year_supply_MJ = calculateEnergy(Supply_Power_MW, dt);
year_demand_MJ = calculateEnergy(Demand_Power_MW, dt);


%% Seasonal Supply Metrics
% Define the row indices for Summer (Day 100 to 250)
summer_start = 100 * 24;
summer_end = 250 * 24;

% Slice the Power array to only include summer rows
summer_supply_data = Supply_Power_MW(summer_start:summer_end);

% Calculate energy for just those summer rows
summer_supply_MJ = calculateEnergy(summer_supply_data, dt);

% Winter is simply the rest of the year
winter_supply_MJ = year_supply_MJ - summer_supply_MJ;

%% Daily Average Metrics
% Since we know the total yearly energy, we divide by 365
daily_avg_demand_MJ = year_demand_MJ / 365;
daily_avg_supply_MJ = year_supply_MJ / 365;
