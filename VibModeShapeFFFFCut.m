function ModeShape_Free_plate_gui()
    % Clear workspace for a clean start
    clear
    clc;

    % Main interactive UI window
    fig = uifigure('Name', 'Plate Geometry & Mode Shape Preview', 'Position', [100 100 950 600]);

    % Plotting canvas dimensions
    ax = uiaxes(fig, 'Position', [340 50 560 510]); % plotting canvas distance from left, bottom, and its width and height, [left, bottom, width, height]
    title(ax, 'Geometry Preview (Flat Plate)');
  
    % Input parameters
    labels = {'Plate length a (m):', ...
              'Plate width b (m):', ...
              'Cutout # along x (mx):', ...
              'Cutout # along y (ny):', ...
              'Cutout size c (m):', ...
              'Mesh step d:'};
              
    defaults = [0.35, 0.35, 3, 3, 0.04, 0.005];
    fields = gobjects(6, 1);

    % Create labels and numeric edit fields on the left panel
    for i = 1:6
        uilabel(fig, 'Position', [30, 520 - (i*45), 140, 22], 'Text', labels{i});
        fields(i) = uieditfield(fig, 'numeric', 'Position', [180, 520 - (i*45), 120, 26], 'Value', defaults(i));
    end

    % "Apply" Button (Previews 2D Geometry)
    uibutton(fig, 'Position', [30, 245, 270, 40], ...
        'Text', 'Apply (Preview Geometry)', ...
        'BackgroundColor', 'Yellow', ...
        'FontColor', 'black', ...
        'FontWeight', 'bold', ...
        'ButtonPushedFcn', @(btn,event) previewGeometry());

    % "OK" Button (Finalizes and shows Mode Shape)
    uibutton(fig, 'Position', [30, 190, 270, 40], ...
        'Text', 'OK (Show Deformed Mode Shape)', ...
        'BackgroundColor', 'green', ...
        'FontColor', 'black', ...
        'FontWeight', 'bold', ...
        'ButtonPushedFcn', @(btn,event) finalizeModeShape());

    % Run initial geometry preview automatically when window opens
    previewGeometry();

    % --- Helper Function: Preview Flat Geometry ---
    function previewGeometry()
        [ex, ey, gx, gy, success] = calculateGeometry();
        if ~success, return; end

        % Clear axes and plot flat plate patches at z = 0
        cla(ax);
        hold(ax, 'on');
        for i = 1:numel(ex)-1
            for j = 1:numel(ey)-1
                if mod(i,2) == 0 && mod(j,2) == 0      % cutout cell: skip
                    continue
                end
                nx_pts = max(2, round((ex(i+1)-ex(i))/fields(6).Value) + 1);
                ny_pts = max(2, round((ey(j+1)-ey(j))/fields(6).Value) + 1);
                [x,y] = meshgrid(linspace(ex(i),ex(i+1),nx_pts), linspace(ey(j),ey(j+1),ny_pts));
                % Plot flat surface at z = 0 for geometry inspection
                surf(ax, x, y, zeros(size(x)), 'FaceColor', [0.85 0.85 0.85], 'EdgeColor', 'none');
            end
        end
        hold(ax, 'off');
        title(ax, 'Geometry Preview (Flat Plate with Cutouts)');
        xlabel(ax, 'x (m)'); ylabel(ax, 'y (m)'); zlabel(ax, 'z');
        view(ax, 0, 90); % Top view for 2D geometry check
        axis(ax, 'tight');
        grid(ax, 'on');
    end

    % --- Helper Function: Finalize and Show Deformed Mode Shape ---
    function finalizeModeShape()
        [ex, ey, gx, gy, success] = calculateGeometry();
        if ~success, return; end

        a = fields(1).Value;
        b = fields(2).Value;
        d = fields(6).Value;
        w = @(x,y) cos(pi*x/a).*cos(pi*y/b);   % first mode shape

        % Clear axes and plot the 3D deformed mode shape
        cla(ax);
        hold(ax, 'on');
        for i = 1:numel(ex)-1
            for j = 1:numel(ey)-1
                if mod(i,2) == 0 && mod(j,2) == 0      % cutout cell: skip
                    continue
                end
                nx_pts = max(2, round((ex(i+1)-ex(i))/d) + 1);
                ny_pts = max(2, round((ey(j+1)-ey(j))/d) + 1);
                [x,y] = meshgrid(linspace(ex(i),ex(i+1),nx_pts), linspace(ey(j),ey(j+1),ny_pts));
                surf(ax, x, y, w(x,y));
            end
        end
        hold(ax, 'off');
        title(ax, 'Vibration Mode Shape');
        xlabel(ax, 'x (m)'); ylabel(ax, 'y (m)'); zlabel(ax, 'w');
        view(ax, 16, 0.2); % 3D mode shape view
        axis(ax, 'tight');
        grid(ax, 'off');
    end

    % --- Common Geometry Calculation & Validation Function ---
    function [ex, ey, gx, gy, success] = calculateGeometry()
        success = false;
        a  = fields(1).Value;
        b  = fields(2).Value;
        mx = fields(3).Value;
        ny = fields(4).Value;
        c  = fields(5).Value;

        gx = (a - mx*c)/(mx+1);
        gy = (b - ny*c)/(ny+1);
        
        if gx <= 0 || gy <= 0
            uialert(fig, 'Cutouts do not fit in the plate! Reduce cutout size (c) or the number of cutouts.', 'Geometry Error', 'Icon', 'error');
            ex = []; ey = [];
            return;
        end

        hxs = gx + (0:mx-1)*(gx + c);   hxe = hxs + c;
        hys = gy + (0:ny-1)*(gy + c);   hye = hys + c;

        ex = sort([0 hxs hxe a]);
        ey = sort([0 hys hye b]);
        success = true;
    end
end
