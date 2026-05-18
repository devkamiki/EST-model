clear; clc; close all;
model = 'estnieuw';
load_system(model);
supplyRaw = readmatrix('data/Team07_supply.csv');
demandRaw = readmatrix('data/Team07_demand.csv');
supplyPower = supplyRaw(~all(isnan(supplyRaw),2), end) * 1e6;
demandPower = demandRaw(~all(isnan(demandRaw),2), end) * 1e6;
dt = 900;
N = min(length(supplyPower), length(demandPower));
supplyPower = supplyPower(1:N);
demandPower = demandPower(1:N);
time = (0:N-1)' * dt;
supply_ts = timeseries(supplyPower, time); %W
demand_ts = timeseries(demandPower, time);  %W