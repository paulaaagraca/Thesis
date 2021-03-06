function [h_view] = hydro_direct_view(R, ri, w, q)
%--------------------------------------------------------------------------
% Description: For each hydrophone in a certain
%--------------------------------------------------------------------------
% Author : Paula Graça (paula.graca@fe.up.pt), May 2020
%--------------------------------------------------------------------------

    h_view = zeros(1);

    source_x = R(1,1);
    source_y = R(2,1);
    source_z = R(3,1);
    
    r6 = ri(:,6);
    r7 = ri(:,7);
    r8 = ri(:,8);
    r9 = ri(:,9);
    
    %---------rotation of hydrophones 6,7,8,9---------
    [rot_az,rot_el,rot_norm] = cart2sph(r6(1,1),r6(2,1),r6(3,1));
    %matrix with hydrophones 6,7,8,9
    mat2rot_h = [r6' 1;
                r7' 1;
                r8' 1;
                r9' 1];
           
    mat2rot_s = [source_x source_y source_z 1;
                 1 1 1 1;
                 1 1 1 1;
                 1 1 1 1];

    %rotation matrix around x axis
    rot_x = rotX3D(rot_el); 
    
    %rotate hydrophones
    rot_mat   = (rot_x * mat2rot_h')';
    rot_mat_s = (rot_x * mat2rot_s')';
    
    %extract rotated hydrophones
    h_rot_mat = rot_mat(:,1:3)';
    rot_r6 = h_rot_mat(:,1);
    rot_r7 = h_rot_mat(:,2);
    rot_r8 = h_rot_mat(:,3);
    rot_r9 = h_rot_mat(:,4);
    
    s_rot_mat = rot_mat_s(:,1:3)';
    s_rot = s_rot_mat(:,1);
    s_rot_x = s_rot(1,1);
    s_rot_y = s_rot(2,1);
    s_rot_z = s_rot(3,1);
    %--------------------------------------------------
    
    % E DEFINIR EQUAÇÕES DIREITAS PARA ISTO COM INCLINAÇÃO
    %hydrohphone 2
    if (source_x > 0 && source_z >= -(w/q)*source_x + w) || (source_x <= 0 && source_z > ri(3,2))
        h_view = [h_view 2]; %hydro top (yz plan)
    end

    %hydrohphone 3
    if (source_x > 0 && source_z <= (w/q)*source_x - w) || (source_x <= 0 && source_z < ri(3,3))
        h_view = [h_view 3]; %hydro bottom (yz plan)
    end 

    %hydrohphone 4
    if (source_x > 0 && source_y >= -(w/q)*source_x + w) || (source_x <= 0 && source_y > ri(2,4))
        h_view = [h_view 4]; %hydro in y positive axis (yz plan)
    end 

    %hydrohphone 5
    if (source_x > 0 && source_y <= (w/q)*source_x - w) || (source_x <= 0 && source_y < ri(2,5))
        h_view = [h_view 5]; %hydro in y negative axis (yz plan)
    end 

    
    %---------rotate before evaluate-----------
    % 6 rotates to position of H 2 
    %hydrohphone 6
    if (s_rot_x > 0 && s_rot_z >= -(w/q)*s_rot_x + w) || (s_rot_x <= 0 && s_rot_z > rot_r6(3,1))

        h_view = [h_view 6]; %hydro in 45º (yz plan)
    end 

   % 7 rotates to position of H 4 
   %hydrohphone 7
    if (s_rot_x > 0 && s_rot_y >= -(w/q)*s_rot_x + w) || (s_rot_x <= 0 && s_rot_y > rot_r7(2,1))

        h_view = [h_view 7]; %hydro in -45º (yz plan)
    end 

    % 8 rotates to position of H 5 
    %hydrohphone 8
    if (s_rot_x > 0 && s_rot_y <= (w/q)*s_rot_x - w) || (s_rot_x <= 0 && s_rot_y < rot_r8(2,1))

        h_view = [h_view 8]; %hydro in 135º (yz plan)
    end 

    % 9 rotates to position of H 3 
    %hydrohphone 9
    if (s_rot_x > 0 && s_rot_z <= (w/q)*s_rot_x - w) || (s_rot_x <= 0 && s_rot_z < rot_r9(3,1))

        h_view = [h_view 9]; %hydro in -135º (yz plan)
    end 

    h_view = h_view(2:end);
    
end