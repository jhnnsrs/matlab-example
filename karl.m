

app = App();

fprintf('Hello from MATLAB!\n');

function outputPath = segmentImages(imagePath)
        
    % Read a TIFF file and print the maximum value


    % Read the TIFF image
    image_data = imread(imagePath);


    % Compute the maximum value
    max_value = max(image_data(:));

    % Print the maximum value
    fprintf('The maximum pixel value in the image is: %d\n', max_value);
    
    % Return the processed image path
    outputPath = imagePath;
end


app.register(@segmentImages, 'ComputeMaximumOnTheFly', {app.omeTiffPort('imagePath')}, {app.omeTiffPort('outputPath')});

app.run();