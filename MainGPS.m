%%%%%%%%%%%%%%%%%Main Run File%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Global Positioning System Simulation Matlab Tool        
%   Author: Saurav Agarwal   
%   Email:  saurav6@gmail.com
%   Date:   January 1, 2011  
%   Place:  Dept. of Aerospace Engg., IIT Bombay, Mumbai, India 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   All i/o units are specified in brackets 
%   The terms user/aircraft have been used interchangeably 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                  Features   
% 1. Plot Groundtrack of any GPS Satellite
% 2. Track Single Satellite: Plot errors in propogation of signals, Skyplots, Elevation, No. of Satellites Visible
% 3. Pure Dual Frequency GPS: Plot error in gps position/velocity for point to point flight at user defined altitude
% 4. Carrier Phase DGPS autopilot landing (B747 aircraft)
% 5. GPS + Flight Dynamics: Plot error in gps position/velocity for a flight with low dynamics
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load autopilot controller state space system
clear all;
clc;
format long;
load autopilotplant
autopilotplant = errd2d;
% load landing_trajectory
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%       Constants                                 %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

c = 2.99792458e8;% speed of light (m/s)
rtd = 180/3.14159; % radians to degree
dtr = 3.14159/180;
initial_clk_bias = 1e-6; %(s)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%       Load Data                                 %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Read GPS alamanac data from the m-file gps_alamanac_data
gps_sat = gps_alamanac_data();

% Read locations of INRES data from the m-file inres_pos_data
list_stations = inres_pos_data();

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  Taking User Choices                  %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf(' List of Airports \n')
fprintf(' 1. Delhi\n')
fprintf(' 2. Jammu\n')
fprintf(' 3. Ahmedabad\n')
fprintf(' 4. Jodhpur\n')
fprintf(' 5. Lucknow\n')
fprintf(' 6. Bhopal \n')
fprintf(' 7. Bagdogra\n')
fprintf(' 8. Guwahati\n')
fprintf(' 9. Aizwal \n')
fprintf(' 10. Dibrugarh\n')
fprintf(' 11. Raipur\n')
fprintf(' 12. Kolkata\n')
fprintf(' 13. Mumbai\n')
fprintf(' 14. Hyderabad\n')
fprintf(' 15. Vishakhapatnam\n')
fprintf(' 16. Bangalore\n')
fprintf(' 17. Chennai\n')
fprintf(' 18. Agatti \n')
fprintf(' 19. Trivandrum\n')
fprintf(' 20. Port Blair\n')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf(' Please choose from the following list of modes of operation \n')
fprintf(' 1. Plot Groundtrack of any GPS Satellite\n')
fprintf(' 2. Track Single Satellite: Plot errors in propogation of signals, Skyplots, Elevation, No. of Satellites Visible\n')
fprintf(' 3. Pure Dual Frequency GPS: Plot error in gps position for point to point flight at user defined altitude\n')
fprintf(' 4. Carrier Phase DGPS Autopilot Landing (B747 Aircraft)\n')
fprintf(' 5. GPS + Flight Dynamics: Plot error in gps position for a flight with low dynamics\n')

mode = input('Please input your mode of operation (1,2,3,4,5):');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if mode == 1
    
    sv_id = input('Choose which satellite (1.2...31) to plot ground track:');
    
    t_max = 24*3600; % Time of run for simulation 
    h = 1000; % discretisation
    dt = t_max/h; % time-step
    
    for j =1:h 
          
        gps_time = j*dt;
 
        [sv_x,sv_y,sv_z,Vsat_ecef] = calc_sat_pos_ecef(gps_sat,gps_time,sv_id) ;% The true position of satellite based on ephemeris data and the gps time

        true_sat_pos_ecef = struct('x',sv_x,'y',sv_y,'z',sv_z);
        
        sat_geodetic = ecef_to_latlong(true_sat_pos_ecef); % Geodetic Coordinates needed for plotting ground track
        
        lat_sv(j) = sat_geodetic.lat;
        long_sv(j) = sat_geodetic.long;
    end;
    
   
    % Plot ground track of any one satellite for 24 hrs %
    %Load the atlas to display groundtracks
    figure(1)
    worldmap('World')
    load coast
    plotm(lat,long)
    linem(lat_sv*rtd,long_sv*rtd); % Plot Ground Track 
    
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if mode == 2
     
     station_id = input('Please choose your reference station (Enter the number of the airport given in list of airports):'); 
     
     sv_id_track = input('Choose which satellite to track(1.2...31):'); % choose which satellite to track;
     
     true_user_pos_geodetic =  list_stations(station_id); %  coordinates in geodetic frame
     
     true_user_pos_ecef = latlong_to_ecef(true_user_pos_geodetic); % Coordinates of Reference station in geodetic system
    
     t_max = 12*3600; % Time of run for simulation 
     
     visi_count = 0;

    for gps_time=1:1:t_max % gps_time is the true gps time

        current_time_hours = gps_time/3600

        time(gps_time) = gps_time;

        no_of_vis_sats = 0;
        
        % To compute the number of visible satellites from station
        for sv_id=1:31 % space vehicle number

            [sv_x,sv_y,sv_z] = calc_sat_pos_ecef(gps_sat,gps_time,sv_id); % The true position of satellite based on ephemeris data and the gps time

            true_sat_pos_ecef = struct('x',sv_x,'y',sv_y,'z',sv_z);

            [elev,azim,is_visible] = eval_el_az(true_user_pos_geodetic,true_user_pos_ecef,true_sat_pos_ecef); % gives elevation and azim in radians

            if is_visible == 1
                
                no_of_vis_sats = no_of_vis_sats + 1; % storing the number of visibile satellites
            end
         end;
         
         vis_sats(gps_time) = no_of_vis_sats; % storing the number of visibile satellites
         
        % Computing errors in measurement at station for selected satellite
        
        [sv_x,sv_y,sv_z] = calc_sat_pos_ecef(gps_sat,gps_time,sv_id_track); % The true position of satellite based on ephemeris data and the gps time

        track_sat_pos_ecef = struct('x',sv_x,'y',sv_y,'z',sv_z);

        [elev,azim,is_visible] = eval_el_az(true_user_pos_geodetic,true_user_pos_ecef,track_sat_pos_ecef); % gives elevation and azim in radians
         
         if is_visible == 1
             
            visi_count = visi_count+1;
            
            elevation_visi(visi_count) = elev;
            
            azimuth_visi(visi_count) = azim;

            time_visi(visi_count) = gps_time;
            
            slant_iono_delay_L1(visi_count) = eval_delay_iono(true_user_pos_geodetic,elev,azim,gps_time); % calculate L1 ionospheric delay in seconds

            slant_iono_delay_L2(visi_count) = 1.6469*slant_iono_delay_L1(visi_count); %calculate L2 ionospheric delay in seconds (from paper" a systems approach to ionospheric delay compenstaion")

            slant_tropo_delay(visi_count) = eval_delay_tropo(elev,true_user_pos_geodetic.alt); % calculate tropospheric delay in seconds

            rcvr_clk_error(visi_count) = 1*(10^-6)*randn; % white noise = clockppm*randomnumber
                
                    
         end;
        
   
    end;
    %%%%%%%%%%   Plots %%%%%
    figure(2)
    plot(time_visi/3600, slant_iono_delay_L1*c,'.')
    xlabel('Time (Hrs)')
    ylabel('L1 Iono Error (m)')
    figure(3)
    plot(time_visi/3600, slant_iono_delay_L2*c,'.')
    xlabel('Time (Hrs)')
    ylabel('L2 Iono Error (m)')
    figure(4)
    plot(time_visi/3600, rcvr_clk_error*c,'.')
    xlabel('Time (Hrs)')
    ylabel('Clock Error (m)')
    ylim([-1 +1])
    figure(5)
    plot(time_visi/3600, slant_tropo_delay*c,'.')
    xlabel('Time (Hrs)')
    ylabel('Tropo Error (m)')
    figure(6)
    bar(time/3600, vis_sats)
    xlabel('Time (Hrs)')
    ylabel('No. of Satellites')
    figure(7)
    polar(azimuth_visi,(elevation_visi*rtd-90),'.')
    figure(8)
    plot(time_visi/3600,elevation_visi*rtd,'.')
    xlabel('Time (Hrs)')
    ylabel('Elevation Angle (Degrees)')

end;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if mode == 3
    
    start_airp_id = input('Please choose your starting point (Enter the number of the airport given in list of airports):');
    
    end_airp_id = input('Please choose your ending point (Enter the number of the airport given in list of airports):');
    
    ac_alt = input('Please input the altitude of flight (in m):');  % altitude of a/c in metres
    
    start_airp = list_stations(start_airp_id); % Geodetic Coordinates of start airport
    
    end_airp = list_stations(end_airp_id); % Geodetic Coordinates of end airport
    
    speed_ac = 800*1000/3600 ; %Speed of a commercial jet in m/s
    
    start_airp_ecef = latlong_to_ecef(start_airp);
    
    end_airp_ecef = latlong_to_ecef(end_airp);
    
    time_of_flight = round(compute_distance(start_airp_ecef,end_airp_ecef)/speed_ac); % time of flight in seconds
       
    roc_lat = (end_airp.lat - start_airp.lat)/time_of_flight ; % rate of change of latitude
    
    roc_long = (end_airp.long - start_airp.long)/time_of_flight ; % Rate of change of longitude
    
    initial_user_pos_estimate = struct('x',start_airp_ecef.x + 100*randn,'y',start_airp_ecef.y + 100*randn, 'z',start_airp_ecef.z + 100*randn); % A rough estimate of start position
    
    tcount = 0;
    
    start_time = 12*3600;
    
    R = ac_alt + 6378137;
    
    C_ECEF2NED = [-sin(start_airp.lat)*cos(start_airp.long) -sin(start_airp.lat)*sin(start_airp.long) cos(start_airp.lat);-sin(start_airp.long) cos(start_airp.long) 0; -cos(start_airp.lat)*cos(start_airp.long) -cos(start_airp.lat)*sin(start_airp.long) -sin(start_airp.lat)];

    TrueVelocityECEF = (C_ECEF2NED'*R*[roc_lat;roc_long;0])';
    
    estimate_user_vel_ecef = TrueVelocityECEF + randn(1,3);
    
    fprintf(' Please choose from the following list of modes of operation of GPS receiver \n')
    fprintf(' 1. All in view\n')
    fprintf(' 2. Tracking 4 satellites\n')
    GPSMODE = input('Please input the mode of operation of GPS receiver:');  % altitude of a/c in metres
        
    % Initialise
    optimum_sv_ids = zeros(time_of_flight,4);
    DOP = zeros(time_of_flight,4);
    error_in_pos = zeros(time_of_flight,1);
    error_in_x = zeros(time_of_flight,1);
    error_in_y = zeros(time_of_flight,1);
    error_in_z = zeros(time_of_flight,1);
    number_of_visible_sats = zeros(time_of_flight,1);
    ErrorSpeed = zeros(time_of_flight,3);
    time = zeros(time_of_flight,1);
    ac_lat = zeros(time_of_flight,1);
    ac_long = zeros(time_of_flight,1);
    
for gps_time= start_time:1:start_time+time_of_flight % gps_time is the true gps time
    
    tcount = tcount +1;
    
    ac_lat(tcount) = start_airp.lat + roc_lat*tcount ; % latitude of aircraft in radians
    
    ac_long(tcount) = start_airp.long + roc_long*tcount; % longitude of aircraft in radians
    
    true_user_pos_geodetic = struct('lat',ac_lat(tcount),'long',ac_long(tcount),'alt',ac_alt); % user coordinates in geodetic frame
    
    true_user_pos_ecef = latlong_to_ecef(true_user_pos_geodetic); %user coordinates in ECEF frame
    
    current_time_hours = (gps_time - start_time)/3600
   
    visible_sats_id = []; % To store the ids of visible satellites
       
    time(tcount) = gps_time;
    
    no_of_vis_sats = 0;
    
    C_ECEF2NED = [-sin(ac_lat(tcount))*cos(ac_long(tcount)) -sin(ac_lat(tcount))*sin(ac_long(tcount)) cos(ac_lat(tcount));-sin(ac_long(tcount)) cos(ac_long(tcount)) 0; -cos(ac_lat(tcount))*cos(ac_long(tcount)) -cos(ac_lat(tcount))*sin(ac_long(tcount)) -sin(ac_lat(tcount))];

    TrueVelocityECEF = (C_ECEF2NED'*R*[roc_lat;roc_long;0])';
    

    for sv_id=1:31 % space vehicle number
            
        [sv_x,sv_y,sv_z] = calc_sat_pos_ecef(gps_sat,gps_time,sv_id); % The true position of satellite based on ephemeris data and the gps time

        true_sat_pos_ecef = struct('x',sv_x,'y',sv_y,'z',sv_z);
         
        [elev,azim,is_visible] = eval_el_az(true_user_pos_geodetic,true_user_pos_ecef,true_sat_pos_ecef); % gives elevation and azim in radians
                            
        if is_visible == 1            
            
            SV_Elevation_Angles(tcount,sv_id) = elev*rtd;
            visible_sats_id = [visible_sats_id sv_id]; % create a list of the ids of visible satellites
            no_of_vis_sats = no_of_vis_sats + 1;                      
        end;   
        if is_visible == 0            
            
            SV_Elevation_Angles(tcount,sv_id) = 0;
                              
        end;   
        
    end;
    number_of_visible_sats(tcount) = no_of_vis_sats;    
    [user_pos_gps,optimum_sv_ids(tcount,:), DOP(tcount,:),estimate_user_vel_ecef] = Dual_Freq_GPS(initial_clk_bias,GPSMODE,gps_sat,gps_time,visible_sats_id,true_user_pos_ecef, initial_user_pos_estimate,inres_pos_data,estimate_user_vel_ecef,TrueVelocityECEF);
    initial_user_pos_estimate = user_pos_gps; % new estimate becomes the previous gps position
    ErrorSpeed(tcount,:) = estimate_user_vel_ecef - TrueVelocityECEF;
    error_in_pos(tcount) = compute_distance(user_pos_gps,true_user_pos_ecef); %user_pos_gps.x - true_user_pos_ecef.x ; % what the receiver thinks is true pseduo range
    error_in_x(tcount) = user_pos_gps.x - true_user_pos_ecef.x  ;
    error_in_y(tcount) = user_pos_gps.y - true_user_pos_ecef.y ;
    error_in_z(tcount) = user_pos_gps.z - true_user_pos_ecef.z ;
end;
RMS_Error = sqrt(norm(error_in_pos)^2/length(error_in_pos));
%%%%%%%%%%%%%%%%% Plots %%%%%%%%%%%%%%%%%%%%%%%%%%
figure(8)
plot(time/3600,error_in_pos,'.')
xlabel('Time(Hrs)')
ylabel('Error in Pos (m)')
figure(9)
plot(time/3600,error_in_x,'.')
xlabel('Time(Hrs)')
ylabel('Error in X (m)')
figure(10)
plot(time/3600,error_in_y,'.')
xlabel('Time(Hrs)')
ylabel('Error in Y (m)')
figure(11)
plot(time/3600,error_in_z,'.')
xlabel('Time(Hrs)')
ylabel('Error in Z (m)')
figure(12)
plot(time/3600,number_of_visible_sats)
xlabel('Time(Hrs)')
ylabel('Number of Visible Satellites')
ylim([4 15])
figure(13)
plot(time/3600, DOP)
xlabel('Time(Hrs)')
ylabel('DOP')
legend('GDOP','PDOP','HDOP','VDOP')
figure(14)
plot(time/3600,SV_Elevation_Angles)
xlabel('Time(Hrs)')
ylabel('Elevation (degrees)')
legend('SV1','SV2','SV3','SV4','SV5','SV6','SV7','SV8','SV9','SV10','SV11','SV12','SV13','SV14','SV15','SV16','SV17','SV18','SV19','SV20','SV21','SV22','SV23','SV24','SV25','SV26','SV27','SV28','SV29','SV30','SV31');
ylim([10 90])
figure(15)
plot(time/3600, ErrorSpeed)
xlabel('Time(Hrs)')
ylabel('Error in Speed')
legend('V_x','V_y','V_z')
figure(16)
worldmap('World')
load coast
plotm(lat, long)
linem(ac_lat*rtd,ac_long*rtd); % Plot Ground Track 

end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Landing With Integrity Beacons 
% Aircraft does a bubble pass at constant altitute over integrity beacons
% and then switches to carrier phase D-GPS after requisite epochs and
% starts descending on preset glide slope  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if mode == 4
    
       
    ref_station_id = input('Please choose your destination airport (Enter the number of the airport given in list of airports):'); % end airport has reference receiver
    
    ref_station = list_stations(ref_station_id); % Geodetic Coordinates of end airport
    
    ref_station_ecef = latlong_to_ecef(ref_station);
    
    ibeacon1_geo = struct('lat',ref_station.lat - 0.0025,'long',ref_station.long +.0004,'alt',ref_station.alt); % ~16 km from airport geodetic position of integrity beacon in goedetic coordinates
    
    ibeacon1_ecef = latlong_to_ecef(ibeacon1_geo);
    
    ibeacon2_geo = struct('lat',ref_station.lat - 0.0025,'long',ref_station.long -.0004,'alt',ref_station.alt); % geodetic position of integrity beacon in goedetic coordinates
    
    ibeacon2_ecef = latlong_to_ecef(ibeacon2_geo);
    
    compute_distance(ibeacon2_ecef,ref_station_ecef)
    
    ac_start_altitude = ref_station.alt+ 800; % metres
        
    speed_ac = 221*0.3048 ; % Speed of Boeing 747 in m/s during approach
    
    start_ac_pos_geodetic = struct('lat',ref_station.lat - 0.0030,'long',ref_station.long,'alt',ac_start_altitude); % ~26 km from airport, starting position of A/C in goedetic coordinates
    
    start_ac_ecef = latlong_to_ecef(start_ac_pos_geodetic);
      
    time_of_flight = 550;%compute_distance(start_ac_ecef,ref_station_ecef)/speed_ac; % time of flight in seconds
       
    roc_lat = (ref_station.lat - start_ac_pos_geodetic.lat)/time_of_flight ; % rate of change of latitude
    
    roc_long = (ref_station.long - start_ac_pos_geodetic.long)/time_of_flight ; % Rate of change of longitude
    
    initial_user_pos_estimate = struct('x',start_ac_ecef.x + 50,'y',start_ac_ecef.y + 50, 'z',start_ac_ecef.z + 50); % A rough estimate of start position
      
    data_collected = 0; % the nature of phase measurement data from reference station and integrity beacons
      
    no_of_measurement_epochs = 100;
    
    countme = 0;
    
    time_interval = 1; % seconds intervals at which measurements are taken
    
    tcount = 0;
    
    rod = (ac_start_altitude-ref_station.alt)/(time_of_flight-no_of_measurement_epochs*time_interval); % rate of decent
    
    C_ECEF2NED = [-sin(ref_station.lat)*cos(ref_station.long) -sin(ref_station.lat)*sin(ref_station.long) cos(ref_station.lat);-sin(ref_station.long) cos(ref_station.long) 0; -cos(ref_station.lat)*cos(ref_station.long) -cos(ref_station.lat)*sin(ref_station.long) -sin(ref_station.lat)];
    
    TrueVelocityECEF = [0 0 0];%(C_ECEF2NED'*R*[roc_lat;roc_long;0])';
    
    estimate_user_vel_ecef = [0 0 0];%TrueVelocityECEF + randn(1,3);
    
    initial_clk_bias_u = 1e-6;
    initial_clk_bias_r = 1e-6;
    autpilot_timer = 0;
    jcounter = 0;
    dt = 0.01;
    X(1,:) = [0 0 0 0 0 0 0 221 0 0 0 0 0 0 0];
%     glideslope_alt = linspace(0,0,time_of_flight/0.01);
    
    for gps_time = 0:0.01:round(time_of_flight) % gps_time is the true gps time
        
        current_time_seconds = gps_time
               
        tcount = tcount + 1;
        
        ac_lat(tcount) = start_ac_pos_geodetic.lat + roc_lat*gps_time ;% latitude of aircraft in radians
        
        ac_long(tcount) = start_ac_pos_geodetic.long  + roc_long*gps_time; % longitude of aircraft in radians
        
        ac_true_lat(tcount) = start_ac_pos_geodetic.lat + (221*gps_time+X(tcount,7))*0.3048/6378137 ;
    
        ac_true_long(tcount) = start_ac_pos_geodetic.long ;
    
        ac_true_height(tcount) = start_ac_pos_geodetic.alt + X(tcount,6)*0.3048;
        
        true_user_pos_geodetic = struct('lat',ac_true_lat(tcount),'long',ac_true_long(tcount),'alt',ac_true_height(tcount)); % user coordinates in geodetic frame

        true_user_pos_ecef = latlong_to_ecef(true_user_pos_geodetic); % user coordinates in ECEF frame
                       
          
          if  sqrt(-(ac_start_altitude)^2*(gps_time-time_of_flight)/time_of_flight) - ref_station.alt > 50
            glideslope_alt(tcount) = sqrt(-(ac_start_altitude)^2*(gps_time-time_of_flight)/time_of_flight); % parabolic descent path
                               
          end;
        
        if gps_time > 200
            
            if sqrt(-(ac_start_altitude)^2*(gps_time-time_of_flight)/time_of_flight) - ref_station.alt <= 50 
              
                glideslope_alt(tcount) = glideslope_alt(tcount-1)*exp(-2e-6*(glideslope_alt(tcount-1)-ref_station.alt+15)); % flare phase
            end;

        end;
        
                     
        visible_sats_id = []; % To store the ids of visible satellites

        time(tcount) = gps_time;
        
%         Distance_from_ibeacon1 = compute_distance(true_user_pos_ecef,ibeacon1_ecef)/1000
%         
%         Distance_from_airport(tcount) = (ref_station.lat-ac_true_lat(tcount))*6378.137;
        
%         Altitude_above_ref_station(tcount) = ac_alt(tcount)-ref_station.alt;
        
        for sv_id=1:31 % space vehicle number

            [sv_x,sv_y,sv_z] = calc_sat_pos_ecef(gps_sat,gps_time,sv_id); % The true position of satellite based on ephemeris data and the gps time

            true_sat_pos_ecef = struct('x',sv_x,'y',sv_y,'z',sv_z);

            [elev,azim,is_visible] = eval_el_az(true_user_pos_geodetic,true_user_pos_ecef,true_sat_pos_ecef); % gives elevation and azim in radians from user to gpssat

            [elev_ref,azim_ref,is_visible_ref] = eval_el_az(ref_station,ref_station_ecef,true_sat_pos_ecef); % gives elevation and azim in radians from reference station to gpssat

            [elev_ib1,azim_ib1,is_visible_ib1] = eval_el_az(ibeacon1_geo,ibeacon1_ecef,true_sat_pos_ecef);
            
            [elev_ib2,azim_ib2,is_visible_ib2] = eval_el_az(ibeacon2_geo,ibeacon2_ecef,true_sat_pos_ecef);
            
            if is_visible == 1  && is_visible_ref == 1  && is_visible_ib1 ==1 && is_visible_ib2 == 1        

                visible_sats_id = [visible_sats_id sv_id]; % create a list of the ids of satellites visible from both stations
                
            end;   

        end;
         
        no_of_visible_sats = length(visible_sats_id);
        
        if data_collected == 0 
            if rem(gps_time,time_interval)==0
                [user_pos_gps,optimum_sv_ids,DOP,Velocity_Ecef,initial_clk_bias]  = Dual_Freq_GPS(initial_clk_bias,2,gps_sat,gps_time,visible_sats_id,true_user_pos_ecef, initial_user_pos_estimate,inres_pos_data,estimate_user_vel_ecef,TrueVelocityECEF);
                initial_user_pos_estimate = user_pos_gps;
                user_pos_calculated = user_pos_gps;
                user_pos_calculated_latlong = ecef_to_latlong(user_pos_calculated);
                jcounter = jcounter+1;
                d(jcounter) = user_pos_calculated_latlong.alt - glideslope_alt(tcount);
                     
                countme = countme+1;
                time_of_epochs(countme) = gps_time;
                true_user_pos_geodetic_storage(countme) = true_user_pos_geodetic;
                true_user_pos_ecef_storage(countme) = true_user_pos_ecef;
                initial_user_pos_estimate_storage(countme) = initial_user_pos_estimate;
            end;
        end;
                          
        if countme == no_of_measurement_epochs && data_collected ==0
            data_collected = 1;
            [IntegerAmbiguities,AA,initial_clk_bias_u,initial_clk_bias_r] = eval_integer_ambiguity(no_of_measurement_epochs,time_of_epochs,countme,gps_sat,visible_sats_id,ref_station_ecef,ref_station,initial_user_pos_estimate_storage,true_user_pos_geodetic_storage,true_user_pos_ecef_storage,ibeacon1_geo,ibeacon1_ecef,ibeacon2_geo,ibeacon2_ecef,initial_clk_bias_u,initial_clk_bias_r); 
        end;
         
         if data_collected == 1
             
             if rem(gps_time,1) == 0
                                                      
                 [user_pos_cdgps2] = estimate_user_position_cdgps2(IntegerAmbiguities,gps_sat,gps_time,visible_sats_id,ref_station_ecef,ref_station,true_user_pos_geodetic,true_user_pos_ecef, initial_user_pos_estimate, ibeacon1_geo,ibeacon1_ecef,ibeacon2_geo,ibeacon2_ecef,initial_clk_bias_u,initial_clk_bias_r); % This function estimates the position of the user based on Carrier Phase Differential GPS

                 initial_user_pos_estimate = user_pos_cdgps2; % new estimate becomes the previous gps position

                 user_pos_calculated = user_pos_cdgps2;

                 user_pos_calculated_latlong = ecef_to_latlong(user_pos_calculated);
                 jcounter = jcounter + 1
                 d(jcounter) = user_pos_calculated_latlong.alt - glideslope_alt(tcount);
             end;
                        
             
         end;
         

         Z = X(tcount,:)+ randn(1,15); % measurement matrix
         Z(5) = d(jcounter)/0.3048; % d measurement comes from gps


         X(tcount+1,:) = RK4_autopilot(dt,X(tcount,:),Z,autopilotplant);
         user_pos_calculated_geodetic = ecef_to_latlong(user_pos_calculated);
         error_in_east(tcount) = (true_user_pos_geodetic.long - user_pos_calculated_geodetic.long)*6378137;
         error_in_down(tcount) = true_user_pos_geodetic.alt - user_pos_calculated_geodetic.alt;
         error_in_pos(tcount) = compute_distance(user_pos_calculated,true_user_pos_ecef); %user_pos_gps.x - true_user_pos_ecef.x ; % what the receiver thinks is true pseduo range
         error_in_x(tcount) = true_user_pos_ecef.x - user_pos_calculated.x ;
         error_in_y(tcount) = true_user_pos_ecef.y - user_pos_calculated.y ;
         error_in_z(tcount) = true_user_pos_ecef.z - user_pos_calculated.z ;
 
    end;
% RMS_Error = sqrt(norm(error_in_pos)^2/length(error_in_pos))
% Ambiguities = round(IntegerAmbiguities')
% AA = AA/0.19;
% MeanError_Vertical_DGPS = mean(error_in_down(no_of_measurement_epochs*time_interval:end))
% StdDev_Error_Vertical_DGPS = std(error_in_down(no_of_measurement_epochs*time_interval:end))
% MeanError_Horizontal_DGPS = mean(error_in_east(no_of_measurement_epochs*time_interval:end))
% StdDev_Error_Horizontal_DGPS = std(error_in_east(no_of_measurement_epochs*time_interval:end))
Comparison_alt = [glideslope_alt' ac_true_height'];
%%%%%%%%%%%%%%%%% Plots %%%%%%%%%%%%%%%%%%%%%%%%%%
plot(time,glideslope_alt-200)
% figure(1)
% plot(X(:,5)*0.3048)
figure(2)
plot(time,Comparison_alt-ref_station.alt);
legend('Desired Glideslope','Aircraft Trajectory')
xlabel('time')
ylabel('altitude (m)')
figure(3)
Error_traj = ac_true_height - glideslope_alt;
plot(time,Error_traj)
ylabel('Vertical Deviation from Glideslope')
xlabel('time')
% figure(13)
% plot(time,error_in_pos,'.')
% xlabel('Time(s)')
% ylabel('Error in Pos (m)')
% figure(14)
% plot(time,error_in_x,'.')
% xlabel('Time(s)')
% ylabel('Error in X (m)')
% figure(15)
% plot(time,error_in_y,'.')
% xlabel('Time(s)')
% ylabel('Error in Y (m)')
% figure(16)
% plot(time,error_in_z,'.')
% xlabel('Time(s)')
% ylabel('Error in Z (m)')
end;    
   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if mode == 5
    
    
    % Selecting GPS mode
    fprintf(' Please choose from the following list of modes of operation of GPS receiver \n')
    fprintf(' 1. All in view\n')
    fprintf(' 2. Tracking 4 satellites\n')
    GPSMODE = input('Please input the mode of operation of GPS receiver:');  % altitude of a/c in metres
    
    start_airp_id = 1;%input('Please choose your starting point (Enter the number of the airport given in list of airports):');
      
    start_airp = list_stations(start_airp_id); % Geodetic Coordinates of start airport
    
    ac_alt = 1000;%input('Please input the altitude of flight (in m):');  % altitude of a/c in metres
    
    true_user_pos_geodetic = struct('lat',start_airp.lat,'long',start_airp.long,'alt',ac_alt); % user coordinates in geodetic frame
    
    true_user_pos_ecef = latlong_to_ecef(true_user_pos_geodetic);
    
    % Defining the initial state of the aircraft
    % Where state X = [Vnorth Veast Vdown Phi Theta Psi P Q R lat long alt]
    % euler angles Phi Theta Psi are w.r.t local navigation frame
    X = [40 0 0 0 0 0 0 0 0 true_user_pos_geodetic.lat true_user_pos_geodetic.long true_user_pos_geodetic.alt];
         
    % Define Control Settings 
    dth = 240; %('Throttle (95-500):');
    dr = 0; % Rudder deflection in degrees
    da = 0; % Aileron deflection in degrees   
    de = 2; % Elevator deflection in degrees  
    
    time_of_flight = 1000;%input('Please input the time of flight (in seconds):'); % time of flight in seconds
    
    dt = 0.01;
    
    initial_user_pos_estimate = struct('x',true_user_pos_ecef.x + 500*randn,'y',true_user_pos_ecef.y + 500*randn, 'z',true_user_pos_ecef.z + 500*randn); % A rough estimate of start position
       
    gpscounter = 0;
    
    tcount= 0;
    
    %%% Initialise the storage arrays, results in faster iterations
    TrueAccelerationBody = zeros(4,3,time_of_flight/dt);
    TrueAngularVelocity = zeros(4,3,time_of_flight/dt);
    TruePos_Geodetic =  zeros(time_of_flight/dt,3);
    TrueVelocityNED = zeros(time_of_flight/dt,3);
    TrueAttitude = zeros(time_of_flight/dt,3);
    TrueVelocityECEF = zeros(time_of_flight/dt,3);
    VelocityGPS_ECEF = zeros(time_of_flight,3);
    optimum_sv_ids = zeros(time_of_flight,4);
    DOP = zeros(time_of_flight,4);
    error_in_pos = zeros(time_of_flight,1);
    error_in_x = zeros(time_of_flight,1);
    error_in_y = zeros(time_of_flight,1);
    error_in_z = zeros(time_of_flight,1);
    ErrorVelocity_NED = zeros(time_of_flight,3);
    time = zeros(time_of_flight,1);
    VelocityGPS_NED = zeros(time_of_flight,3);
    TrueVelocityNED(1,:) = X(1:3);
    TrueAttitude(1,:) = X(4:6);
    TruePos_Geodetic(1,:) = X(10:12);
    ErrorVelocity_ECEF = zeros(time_of_flight,3);
     
    C_ECEF2NED = [-sin(X(10))*cos(X(11)) -sin(X(10))*sin(X(11)) cos(X(10));-sin(X(11)) cos(X(11)) 0; -cos(X(10))*cos(X(11)) -cos(X(10))*sin(X(11)) -sin(X(10))];
    
    TrueVelocityECEF(1,:) = (C_ECEF2NED'*TrueVelocityNED(1,:)')';
       
    estimate_user_vel_ecef = TrueVelocityECEF(tcount+1,:) + randn(1,3); 
    
        
for gps_time=0:dt:time_of_flight % gps_time is the true gps time

    current_time_hours = gps_time
    
    tcount = tcount+1;
            
    [true_user_pos_ecef, true_user_pos_geodetic,TrueAccelerationBody(:,:,tcount),TrueAngularVelocity(:,:,tcount),X] = FlightMech_Model(dt,X,dth,de,da,dr);
      
    TruePos_Geodetic(tcount+1,:) = X(10:12);
    
    Altitude = X(12)
    
    TrueVelocityNED(tcount+1,:) = X(1:3);
    
    TrueAttitude(tcount+1,:) =  X(4:6);
    
    C_ECEF2NED = [-sin(X(10))*cos(X(11)) -sin(X(10))*sin(X(11)) cos(X(10));-sin(X(11)) cos(X(11)) 0; -cos(X(10))*cos(X(11)) -cos(X(10))*sin(X(11)) -sin(X(10))];
    
    TrueVelocityECEF(tcount+1,:) = (C_ECEF2NED'*TrueVelocityNED(tcount+1,:)')';
    
    if X(12) < 10
        fprintf('CRASH!!! \n')
        break;
    end;

    visible_sats_id = []; % To store the ids of visible satellites
           
    no_of_vis_sats = 0;
    
    % GPS updates come once a second
    if rem(gps_time,1)== 0
        gpscounter = gpscounter +1;
        time(gpscounter) = gps_time;
        ac_lat(gpscounter) = true_user_pos_geodetic.lat;
        ac_long(gpscounter) = true_user_pos_geodetic.long;
        for sv_id=1:31 % space vehicle number

            [sv_x,sv_y,sv_z] = calc_sat_pos_ecef(gps_sat,gps_time,sv_id); % The true position of satellite based on ephemeris data and the gps time

            true_sat_pos_ecef = struct('x',sv_x,'y',sv_y,'z',sv_z);

            [elev,azim,is_visible] = eval_el_az(true_user_pos_geodetic,true_user_pos_ecef,true_sat_pos_ecef); % gives elevation and azim in radians

            if is_visible == 1            
                SV_Elevation_Angles(gpscounter,sv_id) = elev*rtd;
                visible_sats_id = [visible_sats_id sv_id]; % create a list of the ids of visible satellites
                no_of_vis_sats = no_of_vis_sats + 1;                      
            end;
            
            if is_visible == 0            
            
                SV_Elevation_Angles(gpscounter,sv_id) = 0;
                              
            end;   

        end;
    % Use GPS to estimate Position and velocity
    [user_pos_gps,optimum_sv_ids(gpscounter,:),DOP(gpscounter,:),VelocityGPS_ECEF(gpscounter,:),initial_clk_bias] = Dual_Freq_GPS(initial_clk_bias,GPSMODE,gps_sat,gps_time,visible_sats_id,true_user_pos_ecef, initial_user_pos_estimate,inres_pos_data,estimate_user_vel_ecef,TrueVelocityECEF(tcount+1,:));
    
    estimate_user_vel_ecef = VelocityGPS_ECEF(gpscounter,:);
    
    VelocityGPS_NED(gpscounter,:) = (C_ECEF2NED*VelocityGPS_ECEF(gpscounter,:)')';
    
    ErrorVelocity_ECEF(gpscounter,:) = VelocityGPS_ECEF(gpscounter,:)-TrueVelocityECEF(tcount+1,:);
    
    ErrorVelocity_NED(gpscounter,:) = (C_ECEF2NED*(VelocityGPS_ECEF(gpscounter,:)-TrueVelocityECEF(tcount+1,:))')'; % VelocityGPS_NED(gpscounter,:) - TrueVelocityNED(tcount+1,:); % Error in estimated velocity in north,east,down
    
    initial_user_pos_estimate = user_pos_gps; % new gps position becomes the estimate for next iteration 
    
    number_of_visible_sats(gpscounter) = no_of_vis_sats;    
    
    error_in_pos(gpscounter) = compute_distance(user_pos_gps,true_user_pos_ecef);
    
    error_in_x(gpscounter) = user_pos_gps.x - true_user_pos_ecef.x ;
    
    error_in_y(gpscounter) = user_pos_gps.y - true_user_pos_ecef.y;
    
    error_in_z(gpscounter) = user_pos_gps.z - true_user_pos_ecef.z ;
    
    end;
        
end;
RMS_Error = sqrt(norm(error_in_pos)^2/length(error_in_pos));
%%%%%%%%%%%%%%%%% Plots %%%%%%%%%%%%%%%%%%%%%%%%%%
figure(8)
plot(time,error_in_pos,'.')
xlabel('Time(Hrs)')
ylabel('Error in Pos (m)')
figure(9)
plot(time,error_in_x,'.')
xlabel('Time(Hrs)')
ylabel('Error in X (m)')
figure(10)
plot(time,error_in_y,'.')
xlabel('Time(Hrs)')
ylabel('Error in Y (m)')
figure(11)
plot(time,error_in_z,'.')
xlabel('Time(Hrs)')
ylabel('Error in Z (m)')
figure(12)
plot(time,number_of_visible_sats)
xlabel('Time(Hrs)')
ylabel('Number of Visible Satellites')
ylim([4 15])
figure(13)
plot(time, DOP)
xlabel('Time(Hrs)')
ylabel('DOP')
legend('GDOP','PDOP','HDOP','VDOP')
figure(14)
plot(time,Altitude)
xlabel('Time(Hrs)')
ylabel('Altitude (m)')
figure(15)
plot(time,SV_Elevation_Angles)
xlabel('Time(Hrs)')
ylabel('Elevation (degrees)')
legend('SV1','SV2','SV3','SV4','SV5','SV6','SV7','SV8','SV9','SV10','SV11','SV12','SV13','SV14','SV15','SV16','SV17','SV18','SV19','SV20','SV21','SV22','SV23','SV24','SV25','SV26','SV27','SV28','SV29','SV30','SV31');
figure(16)
plot(time/3600, ErrorVelocity_ECEF)
xlabel('Time(Hrs)')
ylabel('Error in Velocity (ECEF)')
legend('V_x','V_y','V_z')
figure(17)
plot(ErrorVelocity_NED(1:end,2)*1e2,ErrorVelocity_NED(1:end,1)*1e2,'+')
xlabel('East Error (cm/s)')
ylabel('North Error (cm/s)')
% % Plot ground track of aeroplane %%
% figure(17)
% worldmap('World')
% load coast
% plotm(lat, long)
% linem(ac_lat*rtd,ac_long*rtd); % Plot Ground Track 

end;