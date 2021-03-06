%aerodynamics: input lt, tt, vs; iterate: mt, b<5, S, power, thrust, m_prop
%output: banner length, vc, n laps
%use the outputs for scoring
tic
warning off;
Q = table;
%iter = 0; %iteration count
global p foil
p = getConstants();
foil = get_Airfoil('mh32_200000.txt', 'mh32_500000.txt');
fprintf('loaded airfoil data');

for mt = 1:0.5:3
    for b = 0.5:0.1:1.524
        for P = 300:20:600
            for T = 25:5:50
                for xl = 0.254:0.127:0.5%1.524 %banner length in m; minumum: 10 inches = 0.254m, max 5 feet?
%                     fprintf('%f %f %f %f %f\n', mt, b, P, T, xl);
                    try
                        [SM2, vcM2, vtM2, lapsM2, flyM2, M2, peeps] = calculate_valuesM2(mt,b,P,T,xl);
                        [SM3, vcM3, vtM3, lapsM3, flyM3, M3] = calculate_valuesM3(mt,b,P,T,xl);
                    catch
                        continue;
                    end
                    if flyM2 == 0 || flyM3 == 0
                        continue
                    end
                    %iter = iter + 1;
                    
                    total_score = M2 + M3;
                    
                    %new = table(iter,mt,b,P,T, S, vcM2, vcM3, vt,xl,peeps, M2, M3, total_score);
                    new = table(mt,b,P,T,SM2,SM3,vcM2,vtM2,lapsM2,xl,peeps,vcM3,vtM3,lapsM3,M2,M3,total_score);
                    Q = [Q; new];
                    
                    %fprintf('iter = %.3f, mt = %.3f, b = %.3f, P = %.3f, T = %.3f, S = %.3f, vcM2 = %.3f, vcM3 = %.3f, vtM2 = %.3f, vtM3 = %.3f, xl = %.3f, peeps = %.3f, M2 = %.3f, M3 = %.3f \n', ...
                           %iter, mt, b, P, T, S, vc, vt, M3)
                       
                end
            end
        end
    end
end

idx = height(Q);
[~,idx] = max(Q.M2);
max_M2 = Q(idx,:)

[~,idx] = max(Q.M3);
max_M3 = Q(idx,:)

[~,idx] = max(Q.total_score);
max_total_score = Q(idx,:)

toc


function p = getConstants()
    global p
    p.e = 0.95; %Oswald spanwise efficiency
    p.rho = 1.180; %density in wichita kg/m^3
    p.g = 9.81; %gravitational acceleration in m/s^2
    p.nu = 2; %load factor
    p.lt = 6.096; %takeoff distance 20ft in m
    p.mu = 17.97E-6; %dynamic viscosity of air; Wichita at averge 62deg F
    p.mu_roll = 0.02; %rolling friction during taxi
    p.f = 1.3; %factor of safety vt = fvs; otherwise, plane cannot takeoff
    p.vmax = 14.67; % CHANGEmaximum airspeed in Wichita; used for banner Cf calculation;
    p.mu_bat = (0.490/4); %mass/cell for 4s battery %change to make dependent on how many no cells
    p.eta = 0.4; %mechanical efficiency factor
    p.nom_volt = 3.7; %in volts; nominal voltage for lipos
    p.capacity = 5000; %battery capacity in mAh
    p.I_pack = (p.capacity*10^-3)/(5/60); %current draw of pack in Amps; 10/60 = mission time in hours
    %m_bat = 0.17803 ; %battery weight in kg; Venom Lipo
    %voltage = 9; %total battery voltage; Venom Lipo
    %I = 42; %current in amps; Venom Lipo
    p.m_mot = 0.3 ; %upper limit for motor weight in kg; fixed

end

function foil = get_Airfoil(airofil_takeoff, airfoil_cruise)
    global foil
    
    % Takeoff, Re = 200000
    file = textread(airofil_takeoff, '%s', 'delimiter', '\n','whitespace', ' ');
    i = 12; % Find where the data begins

    % Store all results in arrays
    alphas = []; CLs = []; CDs = []; CDps = [];
    if(i ~= length(file) && ~isempty(file(i+1)))
        j = i+1;
        while (j<=length(file) && ~isempty(file(j)))
            results = textscan(char(file(j)), '%f');
            alphas(j-i) = results{1}(1);
            CLs(j-i) = results{1}(2);
            CDs(j-i) = results{1}(3);
            CDps(j-i) = results{1}(4);
            j = j+1;
        end
    end

    Cl0t=min(abs(CLs)); % smallest cl in file (closest to zero lift)
    foil.Cd0t=CDs(abs(CLs)==Cl0t); % Cd at zero lift; used for vt calculations
    foil.Clmax = max(CLs); %2d wing maximum CL
    
    % Cruise, Re = 500000;
    file = textread(airfoil_cruise, '%s', 'delimiter', '\n','whitespace', ' ');
    i = 12; % Find where the data begins

    % Store all results in arrays
    alphas = []; CLs = []; CDs = []; CDps = [];
    if(i ~= length(file) && ~isempty(file(i+1)))
        j = i+1;
        while (j<=length(file) && ~isempty(file(j)))
            results = textscan(char(file(j)), '%f');
            alphas(j-i) = results{1}(1);
            CLs(j-i) = results{1}(2);
            CDs(j-i) = results{1}(3);
            CDps(j-i) = results{1}(4);
            j = j+1;
        end
    end

    Cl0c=min(abs(CLs)); % smallest cl in file (closest to zero lift)
    foil.Cl0c = Cl0c;
    foil.Cd0c = CDs(abs(CLs)==Cl0c); %zero lift coefficient of drag at cruise; used to solve for vc and vb

end