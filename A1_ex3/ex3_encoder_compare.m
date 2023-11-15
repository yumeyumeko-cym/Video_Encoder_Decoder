clear
clc

% parameters
test_file_path = 'foreman_cif.yuv';
width = 352; % default width of cif format
height = 288; % default height of cif format
frame_num = 10; % number of frames to operate
% i=[2, 8, 64], i is the block dimension
% r=[1, 4, 8], r is the search range
% n=[1, 2, 3], n is Approximated Residual Block Argument


%% varying i plots
psnr_i_varying = zeros(1,30);
%mae_i_varying = zeros(1,30);
index_varing_i = 1;



% Varying i, r=4, n=3
for i = [2,8,64]
    
    r = 4;
    n = 3;
    [paddedFileName, padWidth, padHeight] = file_preparation(test_file_path, width, height, i); % This build padded yuv file if needed
    paddedWidth = width + padWidth;
    paddedHeight = height + padHeight;
    [psnrValues,maeValues]=exercise3(paddedFileName, paddedWidth, paddedHeight, frame_num, i, r, n);
    psnr_i_varying(index_varing_i:index_varing_i+9) = psnrValues;
    mae_i_varying(index_varing_i:index_varing_i+9) = maeValues;
    index_varing_i = index_varing_i + 10;
end

% Plot PSNR_varying_i
figure;

plot(1:frame_num, psnr_i_varying(1:10), '-o');
hold on;
plot(1:frame_num, psnr_i_varying(11:20), '-o');
plot(1:frame_num, psnr_i_varying(21:30), '-o');
xlabel('Frame Index');
ylabel('PSNR');
title('Per-frame PSNR, varying i');
legend('i=2','i=8','i=64');
hold off;

% % Plot MAE
% figure;
% plot(1:frame_num, mae(1:10), '-o');
% hold on;
% plot(1:frame_num, mae(11:20), '-o');
% plot(1:frame_num, mae(21:30), '-o');
% xlabel('Frame Index');
% ylabel('Average MAE');
% title('Per-frame Average MAE');
% legend('i=2','i=8','i=64');
% hold off;
% 


%% varying r plots
psnr_r_varying = zeros(1,30);
%mae_r_varying = zeros(1,30);
index_varing_r = 1;



% Varying i=8, r=[1,4,8], n=3
for r = [1,4,8]
    i = 8;
    n = 3;
    [paddedFileName, padWidth, padHeight] = file_preparation(test_file_path, width, height, i); 
    paddedWidth = width + padWidth;
    paddedHeight = height + padHeight;
    [psnrValues,maeValues]=exercise3(paddedFileName, paddedWidth, paddedHeight, frame_num, i, r, n);
    psnr_r_varying(index_varing_r:index_varing_r+9) = psnrValues;
    mae_r_varying(index_varing_r:index_varing_r+9) = maeValues;
    index_varing_r = index_varing_r + 10;
end

% Plot PSNR_varying_r
figure;
plot(1:frame_num, psnr_r_varying(1:10), '-o');
hold on;
plot(1:frame_num, psnr_r_varying(11:20), '-o');
plot(1:frame_num, psnr_r_varying(21:30), '-o');
xlabel('Frame Index');
ylabel('PSNR');
title('Per-frame PSNR, varying r');
legend('r=1','r=4','r=8');
hold off;
% 
% % Plot MAE
% figure;
% plot(1:frame_num, mae(1:10), '-o');
% hold on;
% plot(1:frame_num, mae(11:20), '-o');
% plot(1:frame_num, mae(21:30), '-o');
% xlabel('Frame Index');
% ylabel('Average MAE');
% title('Per-frame Average MAE');
% legend('r=1','r=4','r=8');
% hold off;
% 

%% varying n plots
psnr_n_varying = zeros(1,30);
%mae_n_varying = zeros(1,30);
index_varing_n = 1;



% Varying i=8, r=4, n=[1,2,3]
for n = [1,2,3]
    i = 8;
    r = 4;
    [paddedFileName, padWidth, padHeight] = file_preparation(test_file_path, width, height, i); 
    paddedWidth = width + padWidth;
    paddedHeight = height + padHeight;
    [psnrValues,maeValues]=exercise3(paddedFileName, paddedWidth, paddedHeight, frame_num, i, r, n);
    psnr_n_varying(index_varing_n:index_varing_n+9) = psnrValues;
    mae_n_varying(index_varing_n:index_varing_n+9) = maeValues;
    index_varing_n = index_varing_n + 10;
end

% Plot PSNR_varying_r
figure;
plot(1:frame_num, psnr_n_varying(1:10), '-o');
hold on;
plot(1:frame_num, psnr_n_varying(11:20), '-o');
plot(1:frame_num, psnr_n_varying(21:30), '-o');
xlabel('Frame Index');
ylabel('PSNR');
title('Per-frame PSNR, varying n');
legend('r=1','r=4','r=8');
hold off;
% 
% % Plot MAE
% figure;
% plot(1:frame_num, mae(1:10), '-o');
% hold on;
% plot(1:frame_num, mae(11:20), '-o');
% plot(1:frame_num, mae(21:30), '-o');
% xlabel('Frame Index');
% ylabel('Average MAE');
% title('Per-frame Average MAE');
% legend('r=1','r=4','r=8');
% hold off;
% 

%% encoder functions
function [paddedFileName, padWidth, padHeight] = file_preparation(yuv_path, width, height, i)
    filename = yuv_path;
    fileID = fopen(filename,'r');
    y_only_filename = 'foreman_y_only.yuv';
    yFileID = fopen(y_only_filename, 'w');

    while ~feof(fileID)
        Y = fread(fileID, [width, height], 'uint8');
        if numel(Y) < width*height % Check if a full frame has been read
            break;
        end
        fwrite(yFileID, Y, 'uint8');
    
        % Skip U and V
        fseek(fileID, width * height /2, 'cof');
    end  
    fclose(fileID);
    fclose(yFileID);

    padWidth = i - mod(width, i);
    if padWidth == i
        padWidth = 0;
    end


    padHeight = i - mod(height, i);
    if padHeight == i
        padHeight = 0;
    end
    yFileID = fopen(y_only_filename, 'r');
    paddedYFileID = fopen('foreman_y_only_padded.yuv', 'w');
    frameCounter = 0;
    
    while ~feof(yFileID)
        Y = fread(yFileID, [width, height], 'uint8');
        if numel(Y) < width*height
            break;
        end
        frameCounter = frameCounter + 1;
        Y = padarray(Y', [padHeight, padWidth], 128, 'post');
        %imshow(Y, []);
        fwrite(paddedYFileID, Y', 'uint8');
        %pause(1/30);
    end
    fclose(yFileID);
    fclose(paddedYFileID);
    paddedFileName = 'foreman_y_only_padded.yuv';
end


function [psnrValues,maeValues]=exercise3(yuv_path, width, height, num_frames, i, r, n)

    frame_num = 10;

    % Initialize a reference frame filled with 128
    reference = 128 * ones(height, width);
    
    % Open the YUV file for reading
    fid = fopen(yuv_path, 'r');
    
    % Create a file to save motion vectors
    mv_fid = fopen('motion_vectors.txt', 'w');
    
    %y_bytes = width * height;
    %uv_bytes = y_bytes /2;
    
    % Create a file to save approximated residual values in binary format
    res_bin_fid = fopen('approx_residuals.bin', 'wb');
    fwrite(res_bin_fid, [height, width, num_frames], 'int');

    %Initialization
    psnrValues = zeros(1, frame_num);
    maeValues = zeros(1, frame_num);


    for frame = 1:num_frames
        Y = fread(fid, [width, height], 'uint8')'; % current frame
        %fseek(fid, uv_bytes, 'cof');  % skip the U and V components
        
        predicted_frame = zeros(size(Y));
        residual_frame_me = zeros(size(Y));
        approx_residual_frame = zeros(size(Y));
        reconstructed_frame = zeros(size(Y));


        for row = 1:i:height
            for col = 1:i:width
                block = Y(row:min(row+i-1, height), col:min(col+i-1, width)); % current block
                [dx, dy] = block_search(reference, block, row, col, r);
                
                % Save motion vector
                fprintf(mv_fid, '%d,%d,%d,%d\n', row, col, dx, dy);
                
                % Form the predicted block
                predicted_block = reference(row+dy:min(row+dy+size(block, 1)-1, height), col+dx:min(col+dx+size(block, 2)-1, width));
                residual_block_me = double(block) -double(predicted_block) ;
                approx_residual_block = round(residual_block_me / (2^n)) * (2^n);
                reconstructed_block = predicted_block + approx_residual_block;
              
                
                predicted_frame(row:min(row+i-1, height), col:min(col+i-1, width)) = predicted_block;
                residual_frame_me(row:min(row+i-1, height), col:min(col+i-1, width)) = residual_block_me;
                approx_residual_frame(row:min(row+i-1, height), col:min(col+i-1, width)) = approx_residual_block;
                reconstructed_frame(row:min(row+i-1, height), col:min(col+i-1, width)) = reconstructed_block;


            end
        end
        
        % Display the frames
        % figure;
        % subplot(3,3,1); imshow(reference, [0, 255]); title('Reference (previous) frame');
        % subplot(3,3,2); imshow(Y, [0, 255]); title('Source frame (to encode)');
        % subplot(3,3,3); imshow(abs(double(Y) - double(reference)), [0, 255]); title('Residual without motion compensation');
        % subplot(3,3,4); imshow(predicted_frame, [0, 255]); title('Predicted frame after motion compensation');
        % subplot(3,3,5); imshow(residual_frame_me, [0, 255]); title('Residual after motion compensation');

        

        % Write the dimensions of the approxResidualBlock to the binary file before the block data
        [blockHeight, blockWidth] = size(approx_residual_frame);
        fwrite(res_bin_fid, [blockHeight, blockWidth], 'int');
        % Dump the approximated residual values into the binary file
        fwrite(res_bin_fid, approx_residual_frame, 'int16');   

        % subplot(3,3,6); imshow(reconstructed_frame, [0, 255]); title('Reconstructed frame from approximated residual and predicted frame')
        % subplot(3,3,7); imshow(approx_residual_frame, [0,255]); title('Approximated residual frame')




        % Update the reference frame
        reference = reconstructed_frame;
       

        % Calculate PSNR
        
        psnrValues(frame) = psnr(reconstructed_frame, Y);


        % Calculate MAE
        maeValues(frame) = mean(abs(reconstructed_frame - Y), 'all');
    
        

        
    end


    
    fclose(fid);
    %fclose(mv_fid);

    fclose(res_bin_fid);  % close the binary residuals file

end

function [dx, dy] = block_search(reference, block, row, col, r)
    % Initialize
    best_mae = inf;
    dx = 0;
    dy = 0;
    
    % Define the search range
    start_row = max(1, row-r);
    end_row = min(size(reference, 1) - size(block, 1) + 1, row+r);
    start_col = max(1, col-r);
    end_col = min(size(reference, 2) - size(block, 2) + 1, col+r);
    
    % Search for the best match
    for y = start_row:end_row
        for x = start_col:end_col
            ref_block = reference(y:y+size(block, 1)-1, x:x+size(block, 2)-1);
            mae = mean(abs(double(block(:)) - double(ref_block(:))));
            
            if mae < best_mae
                best_mae = mae;
                dx = x - col;
                dy = y - row;
            end
        end
    end
end


