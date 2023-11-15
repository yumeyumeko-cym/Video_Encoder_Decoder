% parameters
approx_residuals_path = 'approx_residuals.bin';
mv_path = 'motion_vectors.txt';
width = 352; % default width of cif format
height = 288; % default height of cif format

num_frames = 10; % number of frames to operate
i = 64; % i=[2, 8, 64], i is the block dimension

% check pad
if i == 64
    width = 384;
    height = 320;
end


r = 8; % search range
n = 2; % n=[1, 2, 3], n is Approximated Residual Block Argument
%read_residual(approx_residuals_path)
decoder(mv_path, approx_residuals_path, width, height, i);


function decoder(mv_path, approx_residuals_path, width, height, i)
    % Initialize a reference frame filled with 128
    reference = 128 * ones(height, width);

    % Open the motion vectors
    mv_fid = fopen(mv_path, 'r');

    % Create a file to save the Y-only-decoded frames
    y_decoded_fid = fopen('Y_decoded.yuv', 'wb');


    % Read approximated residual
    % Open the binary residuals file with read permission
    res_bin_fid = fopen(approx_residuals_path, 'rb');
    % Read metadata from the binary file
    dims = fread(res_bin_fid, 3, 'int');
    num_frames = dims(3);


    

    for frame = 1:num_frames

        % Read the approximated residual block data from the binary file
        % Read block dimensions from the binary file
        blockDims = fread(res_bin_fid, 2, 'int');
        blockHeight = blockDims(1);
        blockWidth = blockDims(2);
        
        
        % Read the approximated residual block data from the binary file
        
        approx_residual_frame = fread(res_bin_fid, [blockHeight, blockWidth], 'int16');
        
        % Display the approximated residual block
        %figure;
        %imshow(approx_residual_frame, [0,255]);  % auto scale
        %title(['Approximated Residual Frame ', num2str(frame)]);


        % Build decoded frames
        decoded_frame = zeros(height, width);
        

        for row = 1:i:height
            for col = 1:i:width
                % Read the motion vector for the current block
                mv_data = fscanf(mv_fid, '%d,%d,%d,%d\n', [4 1]);
                dx = mv_data(3);
                dy = mv_data(4);
                % Form the predicted block
                
                predicted_block = reference(row+dy:min(row+dy+i-1, height), col+dx:min(col+dx+i-1, width));
                approx_residual_block = approx_residual_frame(row:min(row+i-1, height), col:min(col+i-1, width));

                % Add the approximated residual block to the predicted block to get the decoded block
                decoded_block = predicted_block + approx_residual_block;
                decoded_frame(row:min(row+i-1, height), col:min(col+i-1, width)) = decoded_block;
                
                
                

            end
        end
        figure;
        imshow(decoded_frame, [0, 255]);
        title(['Decoded Frame ', num2str(frame)])
        
        % Write the decoded frame to the Y-only-decoded file
        fwrite(y_decoded_fid, uint8(decoded_frame)', 'uint8');

        % Update the reference frame
        reference = decoded_frame;
    end
    
    % Close the files
    fclose(mv_fid);
    fclose(res_bin_fid);
    fclose(y_decoded_fid);
end






function read_residual(filename)
    % Open the binary residuals file with read permission
    res_bin_fid = fopen(filename, 'rb');

    % Read metadata from the binary file
    dims = fread(res_bin_fid, 3, 'int');
    num_frames = dims(3);
    
    for frame = 1:num_frames
        % Read block dimensions from the binary file
        blockDims = fread(res_bin_fid, 2, 'int');
        blockHeight = blockDims(1);
        blockWidth = blockDims(2);
        
        
        % Read the approximated residual block data from the binary file
        
        approxResidualBlock = fread(res_bin_fid, [blockHeight, blockWidth], 'int16');
        
        % Display the approximated residual block
        figure;
        imshow(approxResidualBlock, [0,255]);  % auto scale
        title(['Approximated Residual Frame ', num2str(frame)]);
    end
    
    % Close the binary residuals file
    fclose(res_bin_fid);
end













