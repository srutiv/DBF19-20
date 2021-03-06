function [S, vcM2,vtM2,lapsM2,flyM2,M2,peeps] = calculate_valuesM2(mt,b,P,T,xl)
%constants/fixed parameters
%S = area, vc = cruise velocity, x = banner length, laps = number of laps
global p foil

opt = optimset('Display', 'off'); %Turn of warnings from fzero
e = p.e; %Oswald spanwise efficiency
rho = p.rho; %density in wichita kg/m^3
g = p.g; %gravitational acceleration in m/s^2
nu = p.nu; %load factor
lt = p.lt; %takeoff distance 20ft in m
mu = p.mu; %dynamic viscosity of air; Wichita at averge 62deg F
mu_roll = p.mu_roll; %rolling friction during taxi
f = p.f; %factor of safety vt = fvs; otherwise, plane cannot takeoff
vmax = p.vmax; % CHANGEmaximum airspeed in Wichita; used for banner Cf calculation;

%drag
Clmax = foil.Clmax; %max coefficient of lift
Cd0c = foil.Cd0c; %zero lift coefficient of drag
Cd0t = foil.Cd0t;
Cl0c = foil.Cl0c;
Cdc = Cd0c + (Cl0c^2/(pi*0.9*0.8)); %cruise Cd
Cdmax = Cd0c + (Clmax^2/(pi*40*0.8));

%prop
mu_bat = p.mu_bat; %mass/cell
eta = p.eta; %mechanical efficiency factor
nom_volt = p.nom_volt; %in volts; nominal voltage for lipos
capacity = p.capacity; %battery capacity in mAh
I_pack = p.I_pack; %current draw of pack in Amps; 10/60 = mission time in hours
%m_bat = 0.17803 ; %battery weight in kg; Venom Lipo
%voltage = 9; %total battery voltage; Venom Lipo
%I = 42; %current in amps; Venom Lipo
m_mot = p.m_mot; %upper limit for motor weight in kg; fixed
m_prop = m_mot + ((mu_bat*P)/(nom_volt*I_pack*eta)); %total propulsion system mass


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% takeoff %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
S1 = @(Cd)(-mt./(lt*Cd*rho)).*log(1-((f^2*mt*g*Cd)/(Clmax*T)));
S2 = @(Cd)(pi*b^2*e*(Cd - Cd0t)/Clmax^2);
Cd = fzero(@(Cd) S1(Cd)-S2(Cd), 0.1, opt);
S = S1(Cd);
if (isnan(S))
    return;
end
% syms Cd S
% eqns = [ Cd - Cd0t - Clmax^2/(pi*(b^2/S)*e) == 0, ...
%     S - (-mt/(lt*Cd*rho))*log(1-((f^2*mt*g*Cd)/(Clmax*T))) == 0];
% K = solve(eqns, [Cd S]);
% Cd = double(K.Cd);
% S = double(K.S);

%S = (-mt/(lt*Cd*rho))*log(1-((f^2*mt*g*Cd)/(Clmax*T))); %takeoff distance, m, t
%AR = b^2/S; %aspect ratio

A = sqrt(2*T/(Cd*rho*S));
B  = sqrt((T*Cd*rho*S)/(2*mt^2));
tk = (1/B)*acosh(exp(lt*(B/A))); %takeoff time

vtM2 = A*tanh(B*tk); %takeoff velocity
vsM2 = vtM2/f; %stall speed

%banner and payload
Rex = rho*vmax*xl/mu; %Reynold's number experienced by banner
Cf = 0.664/sqrt(Rex); %estimated with Blassius solution
xh = xl/5; %banner must have minimum aspect ratio of 5
Cdb = 0; %banner drag;  not engaged in M2
t = 0.0035; %thickness of banner; used 1/8" ribbon
rho_banner = 1540; %density of cotton ribbon; in kg/m^3
m_banner = xl*xh*t*rho_banner; %mass of banner

%mo = 0.453592*(1.2*(-5.871+.8538*((S*10.764)+.5976)+.03113*(S+13.12).^2)); %poly fit for structural weight; input m^2, output kg; do we trust this
mo = 0.3*mt; 
m_pay = (mt - m_prop - mo); %mass ALLOCATED for banner and payload
peeps = (m_pay)/0.141748; %number of sets of passenger + luggage; 0.141748 = 5 ounces

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% cruise M2 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%cruise velocity when propulsion power is equal to drag power
%(Cd0 + Cdb)*vc^4 - (2*P/(rho*S))*vc + ((4*m^2*g^2)/(rho^2*S*b^2*pi*e)) = 0
%(Cd0 + Cdb)*vb^4 - (2*P/(rho*S))*vb + ((4*nu^2*m^2*g^2)/(rho^2*S*b^2*pi*e)) = 0
%use numerical root finder
%Cdb = 0.561 * (xl/xh).^-0.480; %no banner in M2
vc_matM2 = [Cdc 0 0 ((-2*P)/(rho*S)) ((4*mt^2*g^2)/(rho^2*S*b^2*pi*e))]; %what do we use for drag here?; used to be Cd0c
vb_matM2 = [Cdc 0 0 ((-2*P)/(rho*S)) ((4*nu^2*mt^2*g^2)/(rho^2*S*b^2*pi*e))]; %what do we use for drag here?; used to be Cd0c
rc = roots(vc_matM2);
rb = roots(vb_matM2);
vcM2 = max(rc(imag(rc)==0));
vbM2 = max(rb(imag(rb)==0));


tlM2 = (2000/vcM2) + ((2*pi*mt)/(Clmax*rho*5*vbM2)); %lap time function of power, total mass
lapsM2 = ceil(300/tlM2); %actual number laps the plane can take in 5 minutes; optimal plane x=N

flyM2 = 1;
% fprintf('%.2f vtm2\n', vtM2);
% fprintf('%.2f vcm2\n', vcM2);
% fprintf('%.2f lapsM2\n', lapsM2);
% if vtM2*3 < vcM2 || lapsM2 < 3
%     flyM2 = 0;
% end
% 
if vcM2 < 1.3*vsM2 || m_pay < 0
    flyM2 = 0;
end

M2 = 1 + (peeps * vcM2)/100; %FIX the denominator M3 score, we want the highest value possible

end