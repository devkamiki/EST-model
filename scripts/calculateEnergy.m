function energy_MJ = calculateEnergy(power_data_MW, dt)
    % CALCULATEENERGY Calculates total energy from an array of power data.
    % Inputs:
    %   power_data_MW - 1D Array of power values in Megawatts
    %   dt            - Time step in seconds (e.g., 3600 for hourly)
    % Output:
    %   energy_MJ     - The integrated energy in Megajoules
    
    % Sum up the power values and integrate over time
    energy_MJ = sum(power_data_MW) * dt;
end