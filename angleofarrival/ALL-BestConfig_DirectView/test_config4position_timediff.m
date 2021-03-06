%function [ind_min_both_dev, ind_min_mse_view, mean_R] = test_config4position_timediff(s) %ind_min_both_dev
%--------------------------------------------------------------------------
% Description: 
%--------------------------------------------------------------------------
% Author : Paula Graça (paula.graca@fe.up.pt), April 2020
%--------------------------------------------------------------------------
clear

%----test options----------------------------------------------------------
% for single source position
plot_Hconfig = 0;
plot_mse_deviation = 0;
plot_dev_overlaid = 0;
plot_vec_Restimations = 1;

rotation_ptcloud = 1;

%-----parameters-----------------------------------------------------------
accum_samples = 1000;   %nº accumulated samples w/ random error for same position
max_dev = 0.5e-6;      %max deviation of injected error in time differences
                       %0.5us => [-2.5º,2.5º]
%--------------------------------------------------------------------------

%initialize variables
error_azimuth = zeros();   %azimuth error for all hydrophone configurations
error_elevation = zeros(); %elevation error for all hydrophone configurations
%s = zeros(3,1);           %source positions 
%spherical = zeros(3,1);   %spherical values of source position
gen_mse = 0;           %accumulate MSE of each hydrophone configuration
gen_dev_azimuth = 0;   %accumulate azimuth deviation of each hydrophone configuration
gen_dev_elevation = 0; %accumulate elevation deviation of each hydrophone configuration
accum_R = zeros(3,1);  %accumulate R from each sample

%--------------------------------------------------------------------------
%Definition of hydrophone matrix

q=0.1; %distance from origin to nose hydrophone
w=0.1; %radius of hydrophone circle
e=sqrt(2)/2 * w;  % distance from axis to intermediate hydrophones

% hydrophones configuration [r1 r2 r3 r4 r5 r6 r7 r8 r9];
% r1 -> front; circle: r2:top; r3:bottom; r4:right; r5:left; 
% r6:right-top; r7:righ-bottom; r8:left-top; r9:left-bottom;
ri = [q   0   0    0    0    0   0    0    0  ;
      0   0   0    w    -w   e   e    -e   -e ;
      0   w   -w   0    0    e   -e   e    -e];
%-------------------------------------------------------------------------- 

s = [10;10;10]; %single source position for test

[rownum,n_samples] = size(s); %number of samples to compute

%rotation of hydrophone configuration
[rot_az,rot_el,rot_norm] = cart2sph(s(1,1),s(2,1),s(3,1));

cnt_comb =1; %initialize counter of all hydrophone combinations

%h1 = ri(:,1); %h1 = nose hydrophone gives the 3rd dimension
h1 = ri(:,1);

%Loop: observe variations of best hydro config due to injected error in TDOA
for gen_test=1:10

    min_dev_azimuth = 1000;
    min_dev_elevation = 1000;
    min_mse = 1000;

    %Loop: all possible hydrophones for h2
    for i_h2 = 2:7
        h2 = ri(:,i_h2);

        %Loop: all possible hydrophones for h3
        for i_h3 = (i_h2+1):9
            if(i_h2 < i_h3)
                h3 = ri(:,i_h3);
            end

            %Loop: all possible hydrophones for h4
            for i_h4 = (i_h3+1):9
                if(i_h3 < i_h4)
                    h4 = ri(:,i_h4);
                end
                
                hconfig_ind = [1 i_h2 i_h3 i_h4];
                hconfig = [h1 h2 h3 h4]; %configuration composed by this iteration hydrophones

                %all possible combinations that exist
                %can be consulted associating the collumn index to a calculated error
                hydro_comb(:,cnt_comb) = [1 i_h2 i_h3 i_h4]; 
                
                
                %compute error for i different samples -> currently 1
                for i=1:n_samples

                    %calculate real spherical coordinates
                    [real_azimuth,real_elevation,real_norm] = cart2sph(s(1,i),s(2,i),s(3,i));
                     real_azimuth_d = real_azimuth*180/pi;
                     real_elevation_d = real_elevation*180/pi;

                    for k=1:accum_samples

                       %-----------ESTIMATOR--------------------------------------------
                        %----------------------------------------------------------------
                         %----------------------------------------------------------------
                          %----------------------------------------------------------------
                           %----------------------------------------------------------------
                           
                        [R,a,azimuth,elevation,norm] = testTOA_timediff(s(:,i), hconfig, max_dev);

                         %----------------------------------------------------------------
                          %----------------------------------------------------------------
                           %----------------------------------------------------------------
                            %----------------------------------------------------------------
                             %----------------------------------------------------------------
                              %----------------------------------------------------------------
                        
                        errorx(k) = abs(R(1)-s(1));       %x coordinate
                        errory(k) = abs(R(2)-s(2));       %y coordinate
                        errorz(k) = abs(R(3)-s(3));       %z coordinate      
                              
                        %----------ERROR OF INJECTED RANDOM DEVIATION----------------------
                        %difference between calculated and real azimuth
                        error_i_azimuth(k) = azimuth - real_azimuth*180/pi; % azimuth angle

                        % amend variations around -180 and 180
                        if (error_i_azimuth(k) > 350)
                            error_i_azimuth(k) = abs(error_i_azimuth(k) - 360);
                        end

                        %difference between calculated and real elevation
                        error_i_elevation(k) = elevation - real_elevation*180/pi; %elevation angle
                        
                        % accumulate estimated position to calculate a mean estimation
                        accum_R = accum_R + R;
                        
                        
                        %-----------------------------------------------------------------------
                        %for a single source position, accumulate estimated samples
                         ce = [1 2 7 9];
                        if gen_test == 1 && isequal(hconfig_ind,ce) && i == 1
                            R_estimations(:,k) = R;   %accumulate estimated R of 1 position (to be plotted)
                        end 
                        
                    end
                    
                    mean_R = accum_R/accum_samples;
                    
                    %standard deviation of azimuth
                    deviation_azimuth(cnt_comb) = std(error_i_azimuth);
                    %standard deviation of elevation
                    deviation_elevation(cnt_comb) = std(error_i_elevation);

                    %absolute values of error
                    error_i_azimuth = abs(error_i_azimuth);
                    %azimuth error for a single source position
                    error_azimuth(cnt_comb) = mean(error_i_azimuth);

                    %absolute values of error
                    error_i_elevation = abs(error_i_elevation);
                    %elevation error for a single source position
                    error_elevation(cnt_comb) = mean(error_i_elevation);
                  
                    error_x(cnt_comb) = mean(errorx);
                    error_y(cnt_comb) = mean(errory);
                    error_z(cnt_comb) = mean(errorz);

                    % Mean squared error (of a certain hydrophone configuration)
                    %---spheric---------------------------------------------
                    mse_config(cnt_comb) = sqrt(error_azimuth(cnt_comb)^2 + error_elevation(cnt_comb)^2);
                    %---cartesian---------------------------------------------
                    %mse_config(cnt_comb) = sqrt(error_x(cnt_comb)^2 + error_y(cnt_comb)^2 + error_z(cnt_comb)^2);
                    if min_mse > mse_config(cnt_comb)
                        min_mse = mse_config(cnt_comb);
                        hconfig_best_mse = hconfig;
                        hconfig_best_mse_index = hydro_comb(:,cnt_comb);
                     end

                    % saves minimum deviation in azimuth and its hydro config
                    if min_dev_azimuth > deviation_azimuth(cnt_comb)
                        min_dev_azimuth = deviation_azimuth(cnt_comb);
                        hconfig_best_az = hconfig;
                        hconfig_best_az_index = hydro_comb(:,cnt_comb);
                    end
                    % saves minimum deviation in elevation and its hydro config
                    if min_dev_elevation > deviation_elevation(cnt_comb)
                        min_dev_elevation = deviation_elevation(cnt_comb);
                        hconfig_best_el = hconfig;
                        hconfig_best_el_index = hydro_comb(:,cnt_comb);
                    end

                    cnt_comb=cnt_comb+1;
                    accum_R=0;
                    
                end
            end
        end
    end
    
    % -----------------------------------------------------------------
    % definition of hydrophones w/ direct view to the source position
    mean_R(2,1) = mean_R(2,1) + s(2,1);
    mean_R(3,1) = mean_R(3,1) + s(3,1);
    
    [h_view] = hydro_direct_view(mean_R, ri, w, q); %mean_R instead of s

    % -----------------------------------------------------------------
    %define which configurations have direct view to the source position
    [row,col_hcomb] = size(hydro_comb);
    index_view = zeros(1);
    cnt_hydro_with_view = 0;
    [row,col_h_view] = size(h_view);
    sig_comb_view = 0;
    
    for index_comb = 1:col_hcomb
        for row = 2:4
            for cnt_array = 1:col_h_view
                if hydro_comb(row,index_comb) == h_view(cnt_array)
                    cnt_hydro_with_view = cnt_hydro_with_view + 1;
                    if cnt_hydro_with_view == 3
                        index_view = [index_view index_comb];
                    end
                    sig_comb_view = 1;
                    break;
                end
            end
            if sig_comb_view == 0
                break;
            else
                sig_comb_view = 0;
            end
        end
        cnt_hydro_with_view = 0;
    end
    
    index_view = index_view(2:end);
    % -----------------------------------------------------------------
    
    %accumulate MSE error of all configurations
    gen_mse = gen_mse + mse_config;
    
    %accumulate azimuth deviation of all configurations
    gen_dev_azimuth = gen_dev_azimuth + deviation_azimuth;
    
    %accumulate elevation deviation of all configurations
    gen_dev_elevation = gen_dev_elevation + deviation_elevation;
    
    
    %matrix which accumulates best config in terms of MSE for gen_test number of tests
    gen_hconfig_best_mse(:,gen_test) = hconfig_best_mse_index;

    %matrix which accumulates best config in terms of AZIMUTH for gen_test number of tests
    gen_hconfig_best_az(:,gen_test) = hconfig_best_az_index;

    %matrix which accumulates best config in terms of ELEVATION for gen_test number of tests
    gen_hconfig_best_el(:,gen_test) = hconfig_best_el_index;

    cnt_comb = 1;
    
end

%************__EXTRACT (MEAN) BEST CONFIGURATION__*************************
%best MSE
[sets_config_mse] = extract_mean_best_config(gen_hconfig_best_mse,index_view);

%best azimuth deviation
[sets_config_d_az] = extract_mean_best_config(gen_hconfig_best_az,index_view);

%best elevation deviation
[sets_config_d_el] = extract_mean_best_config(gen_hconfig_best_el,index_view);

% -----------------------------------------------------------------
%mean MSE of each configuration
mean_mse_per_config = gen_mse/gen_test; %col_hcomb
%mean azimuth deviation of each configuration
mean_dev_azimuth_per_config = gen_dev_azimuth/gen_test;
%mean elevation deviation of each configuration
mean_dev_elevation_per_config = gen_dev_elevation/gen_test;

mse_view = zeros(1);
dev_azimuth_view = zeros(1);
dev_elevation_view = zeros(1);

%form matrixes with errors from config with view
for i = 1:length(index_view)
    
    ind = index_view(i); %ind contains index of hydro configuration (out of 56)
    
    %accumulate mse values for index of configurations with view
    mse_view = [mse_view mean_mse_per_config(ind)];
    %accumulate deviation in azimuth values for index of configurations with view
    dev_azimuth_view = [dev_azimuth_view mean_dev_azimuth_per_config(ind)];
    %accumulate deviation in elevation values for index of configurations with view    
    dev_elevation_view = [dev_elevation_view mean_dev_elevation_per_config(ind)];
end

%remove first element of each array
mse_view = mse_view(2:end);
dev_azimuth_view = dev_azimuth_view(2:end);
dev_elevation_view = dev_elevation_view(2:end);

% -----------------------------------------------------------------
%index and value of minimum MSE (configuration)
[min_mse_view,ind_min_mse_view] = min(mse_view);
%index and value of minimum azimuth deviation (configuration)
[dev_az_mse_view,ind_dev_az_mse_view]=min(dev_azimuth_view);
%index and value of minimum elevation deviation (configuration)
[dev_el_mse_view,ind_dev_el_mse_view]=min(dev_elevation_view);

ind_min_mse_view = index_view(ind_min_mse_view);
ind_dev_az_mse_view = index_view(ind_dev_az_mse_view);
ind_dev_el_mse_view = index_view(ind_dev_el_mse_view);
% -----------------------------------------------------------------
% mse of deviations 
for i = 1:length(index_view)
    %mse_both_dev(i) = sqrt(dev_azimuth_view(i)^2+dev_elevation_view(i)^2);
    mse_both_dev(i) = mean([dev_azimuth_view(i) dev_elevation_view(i)]);
end
[min_both_dev,ind_min_both_dev] = min(mse_both_dev);
ind_min_both_dev = index_view(ind_min_both_dev);


pd_mse_view = min_mse_view;
pa_dev_azimuth_view = dev_az_mse_view;
pb_dev_elevation_view = dev_el_mse_view;
pc_min_both_dev = min_both_dev;

%//////////////////_PLOT OPTIONS_//////////////////////////////////////////
%plot MSE and deviation in azimuth and elevation for every configuration
if plot_mse_deviation == 1
    f2 = figure;
    
    subplot(1,3,1)
    plot(mean_mse_per_config)
    hold on 
    plot(index_view,mse_view,'o')
    hold on
    plot(ind_min_mse_view,min_mse_view,'Marker','*','Color','g','MarkerSize',9)
    title('MSE');
    xlabel('Config Number');
    ylabel('MSE');
    
    subplot(1,3,2)
    plot(mean_dev_azimuth_per_config)
    hold on 
    plot(index_view,dev_azimuth_view,'o')
    hold on
    plot(ind_dev_az_mse_view,dev_az_mse_view,'Marker','*','Color','g','MarkerSize',9)
    title('Azimuth deviation');
    xlabel('Config Number');
    ylabel('Azimuth Deviation (deg)');

    subplot(1,3,3)
    plot(mean_dev_elevation_per_config)
    hold on 
    plot(index_view,dev_elevation_view,'o')
    hold on
    plot(ind_dev_el_mse_view,dev_el_mse_view,'Marker','*','Color','g','MarkerSize',9)
    title('Elevation deviation');
    xlabel('Config Number');
    ylabel('Elevation Deviation (deg)');
    
    set(gcf, 'Units', 'Normalized', 'OuterPosition', [0.1, 0.3, 0.7, 0.5]);
    
    %saveas(f2,'plots/plot-[10,10,10]-1000s-errors-pseudo','jpg')

end

if plot_dev_overlaid == 1
    f1 = figure;

    plot(mean_dev_azimuth_per_config,'Color','b','LineWidth',0.5)
    hold on 
    plot(index_view,dev_azimuth_view,'o')
    hold on
    plot(ind_dev_az_mse_view,dev_az_mse_view,'Marker','*','Color','g','MarkerSize',9)
    hold on
    plot(mean_dev_elevation_per_config, 'Color','m','LineWidth',0.5)
    hold on 
    plot(index_view,dev_elevation_view,'o')
    hold on
    plot(ind_dev_el_mse_view,dev_el_mse_view,'Marker','*','Color','g','MarkerSize',9)
    hold on 
    plot(ind_min_both_dev,min_both_dev,'Marker','d','MarkerFaceColor','c','MarkerEdgeColor','c','MarkerSize',7)
    
    legend('Dev Az', 'View Az', 'BestView Az','Dev El', 'View El', 'BestView El');
    title('Deviation in azimuth and elevation');
    xlabel('Configuration Number');
    ylabel('Deviation (deg)');
    
    %saveas(f1,'plots/plot-[10,10,10]-1000s-both-pseudo','jpg')

end
    
%plot a specific hydrophone configuration
if plot_Hconfig == 1
	figure
    
    plot_h = hconfig_best_az;
    
    X = ri(1,:); 
	Y = ri(2,:); 
	Z = ri(3,:); 
	% plot hydrophones location
	scatter3(X, Y, Z, 100, 'b', 'o')
	legend('Hydrophones')
    
    hold on 
    
    plot_ha = hconfig_best_az;
    X = plot_ha(1,:); 
	Y = plot_ha(2,:); 
	Z = plot_ha(3,:); 
	% plot hydrophones location
	scatter3(X, Y, Z, 100, 'r', '+')
	%legend('Best Azimuth')
    
    hold on 
   
    plot_he = hconfig_best_el;
    X = plot_he(1,:); 
	Y = plot_he(2,:); 
	Z = plot_he(3,:); 
	% plot hydrophones location
	scatter3(X, Y, Z, 100, 'g', 'x')
	%legend('Best Elevation')
    
    hold on 
    
    X = s(1,:); 
	Y = s(2,:); 
	Z = s(3,:); 
	% plot hydrophones location
	scatter3(X, Y, Z, 200, 'c', 'filled')
	%legend('Hydrophones')
    
end

if plot_vec_Restimations == 1

%      [rownum,n_samples_R_estimations] = size(R_estimations); %number of samples to compute
% 
%      %--plot connector vectors from origin to estimated source positions--
%      figure
% 
%      for i=1:n_samples_R_estimations
%          plot3([R_estimations(1,i),0],[R_estimations(2,i),0],[R_estimations(3,i),0],'g')
%          hold on
%      end
% 
%      plot3([s(1,1),0],[s(2,1),0],[s(3,1),0],'b')   
%      title('Estimated Vectors w/ injected error');
%      xlabel('y');
%      ylabel('x');
%      zlabel('z');
     
     %--plot estimated source positions------------------------------
    
    if rotation_ptcloud == 1
        R_estimations_mat = [R_estimations' ones(length(R_estimations),1)];
        s_rot_mat = [s' 1; 0 0 0 1; 0 0 0 1; 0 0 0 1];

        %rotation in elevaton - around y axis
        rot_elevation_y = rotY3D(-(-rot_el)); %z axis is inverted
        %rotation in azimuth - around z axis
        rot_azimuth_z = rotZ3D(-rot_az); 
        %total rotation matrix
        rot_mat = rot_elevation_y *  rot_azimuth_z ;

        %apply rotation matrix to hydroophone possible positions
        for i = 1:4:length(R_estimations_mat)
            R_estimations_rot(i:i+3,:) = ( rot_mat * R_estimations_mat(i:i+3,:)' )';
        end
        s_rot = rot_mat * s_rot_mat';
        R_estimations_rott(1:3,:) = R_estimations_rot(:,1:3)';
        
        s_rott = s_rot(1,1:3)';
        %------------
        f_est = figure;
        subplot(1,3,1)
        scatter(R_estimations_rott(1,:),R_estimations_rott(3,:),5)
        xlabel('x');
        ylabel('z');
        hold on
        scatter(s_rott(1,1),s_rott(3,1),30,'g','filled')
        title('Side view');
        axis equal
        
        subplot(1,3,2)
        scatter(R_estimations_rott(2,:),R_estimations_rott(3,:),5)
        xlabel('y');
        ylabel('z');
        hold on
        scatter(s_rott(2,1),s_rott(3,1),30,'g','filled')
        title('Front view'); 
        axis equal
        
        subplot(1,3,3)
        scatter(R_estimations_rott(1,:),R_estimations_rott(2,:),5)
        xlabel('x');
        ylabel('y');
        hold on
        scatter(s_rott(1,1),s_rott(2,1),30,'g','filled')
        title('Upper view'); 
        axis equal
        
        set(gcf, 'Units', 'Normalized', 'OuterPosition', [0.1, 0.3, 0.7, 0.5]);
        %saveas(f_est,'plots/plot-compare-[100,100,100]-1279-1000s-pseudo.jpg','jpg')
        %------------
        
%         for asd=1:3
            figure
            scatter3(R_estimations_rott(1,:),R_estimations_rott(2,:),R_estimations_rott(3,:),40,'r','filled')
            hold on
            scatter3(s_rott(1,1),s_rott(2,1),s_rott(3,1),40,'b','filled')
            hold on
            %scatter3(0,0,0,40,'b','filled')
            %hold on
%             if asd == 1
%                 %zx
%                 view(0,0)
%                 axis equal
%                 %------- 
%             end
%             if asd == 2
%                 %zy
%                 view(90,0)
%                 axis equal
%                 %--------
%             end
%             if asd == 3
%                 %yx
%                 view(0,90)
%                 axis equal
%                 %--------
%             end
%         end
    end

   %plot original 
     figure
     scatter3(R_estimations(1,:),R_estimations(2,:),R_estimations(3,:),40,'g','filled')
     hold on
     scatter3(s(1,1),s(2,1),s(3,1),40,'b','filled')
     hold on
    % scatter3(0,0,0,40,'b','filled')
    % hold on
    % scatter3([ri(1,ce(1)) ri(1,ce(2)) ri(1,ce(3)) ri(1,ce(4))],[ri(2,ce(1)) ri(2,ce(2)) ri(2,ce(3)) ri(2,ce(4))], [ri(3,ce(1)) ri(3,ce(2)) ri(3,ce(3)) ri(3,ce(4))],40,'k','filled')
     
     %xlim([560 660])
     %ylim([150 250])
     %zlim([-1100 -900])

     title('Estimated source position w/ injected error');
     xlabel('x');
     ylabel('y');
     zlabel('z');
     axis equal
end
%end

%save('../study_Cramer-Rao/plots/clouds/estim_[1000,0,0]_1249_10000samp.mat', 'R_estimations_rott', '-mat')

