clear all
clc
close all force hidden

csv_output_header = ["Biological Replicate","Condition","ID (well location)",...
    "Is Dead","Is Last Day Censored","Last Day of Observation","First Day of nonzero data",...
    ...
    "Intensity at First Day of Infection","Intensity at Last Day of Observation",...
    "Intensity Regression Slope","Intensity Regresstion intercept",...
    "Intensity Integrated Across Time","Max Intensity Slope to a Point"...
    ...
    "Area at First Day of Infection","Area at Last Day of Observation",...
    "Area Regression Slope","Area Regresstion intercept",...
    "Area Integrated Across Time","Max Area Slope to a Point"];

% get csv
[CSV_filename,CSV_filepath] = uigetfile('/Volumes/Sutphin server/Users/Luis Espejo/SICKO/Experiments/*.csv',...
    'Select the Compiled csv File');
% read table
csv_table= readtable(fullfile(CSV_filepath,CSV_filename),'VariableNamingRule','preserve'); % Your parsing will be different

% get conditions
conditions = string(natsort(unique((csv_table.Condition))));
condition_idx = 1:length(conditions);

% get names of the csv
csv_names = csv_table.Properties.VariableNames;

% set up variables
col_intensity = contains(string(csv_names),"Intensity");
col_area = contains(string(csv_names),"Area");
col_censor = contains(string(csv_names),"Censored");
col_dead = contains(string(csv_names),"Dead");
col_defaults = zeros(size(col_dead)); col_defaults(1:3) = 1;

%isolate tables
table_inten = csv_table(:,logical(col_defaults+col_intensity));
table_area = csv_table(:,logical(col_defaults+col_area));

% isolate datasets
data_intensity = table2array(csv_table(:,col_intensity));
data_area = table2array(csv_table(:,col_area));
data_censor = table2array(csv_table(:,col_censor));
data_dead = table2array(csv_table(:,col_dead));

% initalize datasets
data_sess_died = zeros(length(data_dead),1);
data_sess_censored = zeros(length(data_dead),1);

% get all the days that a worm died on
% effective lifespan

%step through all data_dead
for i = 1:length(data_dead)
    % find the first time there is a 1 in the dead section
    sess_died = find(data_dead(i,:)>0,1,'first');
    % if its not empty then make a sess_died
    if ~isempty(sess_died)
        data_sess_died(i) = sess_died;
    end
    % do the same thing but find the censored day
    sess_censored = find(data_censor(i,:)>0,1,'first');
    if ~isempty(sess_censored)
        data_sess_censored(i) = sess_censored;
    end
    
end
clear sess_censored sess_died i

% if the worm was not dead then set its day of death to end + 1
data_sess_died_plot = data_sess_died;
data_sess_died_plot(data_sess_died_plot==0) = (size(data_dead,2) + 1);

% initalize indexing variables for
% worms that got infected
idx_infected = (mean(data_area,2,'omitnan')>0);
% that are NOT censored
idx_good_wells = (data_sess_censored==0);
% that are not dead
idx_not_dead = (data_sess_died==0);
% worms that only have a single data point that didnt die
idx_only_single_point = (sum(data_area>0,2)==1).*(~(data_sess_died>0));

idx_yes = logical(~idx_only_single_point);

% start with keep everything
idx_2d_data_to_keep = ones(size(data_dead));
% remove all censored data
idx_2d_data_to_keep(data_censor==1) = NaN;
% remove all dead data
for i = 1:length(data_sess_died)
    if data_sess_died(i) > 0 
        idx_2d_data_to_keep(i,data_sess_died(i):end) = -1;
    end
end

non_cen_data_area = data_area.*idx_2d_data_to_keep;
non_cen_data_area(idx_2d_data_to_keep==-1) = -1;
non_cen_data_intensity = data_intensity.*idx_2d_data_to_keep;
non_cen_data_intensity(idx_2d_data_to_keep==-1) = -1;

data_to_csv(csv_output_header,csv_table,...
    CSV_filename,CSV_filepath,...
    data_intensity,data_area,data_censor,data_dead,...
    data_sess_died,non_cen_data_area,non_cen_data_intensity);

display_data(non_cen_data_area,logical(idx_infected.*(~idx_only_single_point)),...
    conditions,csv_table,data_censor,'Integrated_Area')

heatmap_data(non_cen_data_area,idx_yes,conditions,csv_table,data_sess_died_plot,'Integrated_Area')
heatmap_data(non_cen_data_intensity,idx_yes,conditions,csv_table,data_sess_died_plot,'Integrated_Intensity')



function heatmap_data(this_data,idx_yes,conditions,csv_table,data_sess_died,title_ext)

overall_max = max(max(this_data(idx_yes,:)));

figure('units','normalized','outerposition',[0 0 1 1]);

x = 1:size(this_data,2);
for i = 1:length(conditions)
    subplot(2,3,i)
    
    % find the index that represents this condition
    this_condition_idx = string(csv_table.Condition) == conditions(i);
    this_condition_idx = logical(idx_yes.*this_condition_idx);
    % isolate its data
    this_conditions_data = this_data(this_condition_idx,:);
    this_conditions_death = data_sess_died(this_condition_idx);
    % integrate across time for sorting
    data_across_time_integrated = sum(...
        (this_conditions_data.*(this_conditions_data>0))...
        ,2,'omitnan');
    % invert the data 
    data_across_time_integrated_inverted = 1-...
        (data_across_time_integrated/max(data_across_time_integrated(:)));
    % find if infeected at all
    data_is_infected_bool = ~(data_across_time_integrated>0);
    % find number of censored points 
    censor_across_time_integrated = sum(~isnan(this_conditions_data),2);
    % invert the censor 
    censor_across_time_integrated_inverted = 1-...
        (censor_across_time_integrated/max(censor_across_time_integrated(:)));
    % combine first the death then integrated datats into a single martrix
    combined_data_for_sorting = [data_is_infected_bool,...
        this_conditions_death,...
        data_across_time_integrated_inverted,...
        censor_across_time_integrated_inverted];
    % first sort by day of death then sort by integrated data across time
    % categorically 
    [~,sort_idx] = sortrows(combined_data_for_sorting,[1,2,3,4]);
    % get the final data representation
    this_conditions_data = this_conditions_data(sort_idx,:);
    % scale the data
    this_scale = round((max(this_conditions_data(:))/overall_max)*255);
    % to rgb
    temp_img = ind2rgb(round(rescale(this_conditions_data,0,this_scale))...
        , parula(256));
    % make it square
    temp_img = imresize(temp_img,[size(temp_img,1),size(temp_img,1)],'nearest');
    this_conditions_data_sq = imresize(this_conditions_data,[size(temp_img,1),size(temp_img,1)],'nearest');
    % find deaths and censors
    [row_death,col_death] = find(this_conditions_data_sq == -1);
    [row_nan,col_nan] = find(isnan(this_conditions_data_sq));
    % replace death with red and nan with black
    for j = 1:length(row_death)
        temp_img(row_death(j),col_death(j),:) = [255,0,0];
    end
    for j = 1:length(row_nan)
        temp_img(row_nan(j),col_nan(j),:) = [0,0,0];
    end
    
    infection_seperation_idx = find(data_is_infected_bool(sort_idx)==1,1,'first');
    
    if ~isempty(infection_seperation_idx)
        white_line = 255*ones(1,size(temp_img,2),3);
        temp_img2 = [temp_img(1:infection_seperation_idx-1,:,:);...
            white_line;...
            temp_img(infection_seperation_idx:end,:,:)];
    else
        temp_img2 = temp_img;
    end
    
    num_dead = length(unique(row_death));
    num_worms = sum(this_condition_idx);
    num_infected = sum(data_across_time_integrated>0);
    
    temp_img2 = imresize(temp_img2,[1000,1000],'nearest');
    imshow(temp_img2);
    xlabel('sessions');
    ylabel(["individual animals", ...
        string([num2str(num_dead) '/' num2str(num_worms) ' dead']), ...
        string([num2str(num_infected) '/' num2str(num_worms) ' infected'])]);
    title([char(conditions(i)) '_' char(title_ext)],'interpreter','none');

    
end

end


function display_data(this_data,idx_yes,conditions,csv_table,data_censor,title_ext)

non_cen_data = this_data.*imcomplement(data_censor);

for i = 1:length(conditions)
    
    disp([char(conditions(i)) '_' char(title_ext)])
    
    this_condition_idx = string(csv_table.Condition) == conditions(i);
    
    this_condition_idx = logical(idx_yes.*this_condition_idx);
    
    disp([num2str(sum(this_condition_idx)) ' Infected Worms'])
    
    this_conditon = this_data(this_condition_idx,:);
    
end

end



function data_to_csv(csv_output_header,csv_table,...
    CSV_filename,CSV_filepath,...
    data_intensity,data_area,data_censor,data_dead,...
    data_sess_died,non_cen_data_area,non_cen_data_intensity)

% get names of the csv
csv_names = csv_table.Properties.VariableNames;

% get first three headers 
col_biorep = contains(string(csv_names),"Biological Replicate");
col_condition = contains(string(csv_names),"Condition");
col_location = contains(string(csv_names),"ID (well location)");

% get all the data as a cell array
data_cells = table2cell(csv_table);

% get the bioreps 
bioreps = data_cells(:,col_biorep);
conditions = data_cells(:,col_condition);
locations = data_cells(:,col_location);

% inialize the data 
intensity_regression_intercept = zeros(size(data_sess_died));
intensity_regression_slope = zeros(size(data_sess_died));
intensity_integrated_across_time = zeros(size(data_sess_died));
intensity_max_gradient_at_point = zeros(size(data_sess_died));
first_sess_of_infection_intensity = nan(size(data_sess_died));
last_sess_of_infection_intensity = nan(size(data_sess_died));

area_regression_slope = zeros(size(data_sess_died));
area_regression_intercept = zeros(size(data_sess_died));
area_integrated_across_time = zeros(size(data_sess_died));
area_max_gradient_at_point = zeros(size(data_sess_died));
first_sess_of_infection_area = nan(size(data_sess_died));
last_sess_of_infection_area = nan(size(data_sess_died));

final_data_censor = zeros(size(data_sess_died));
last_day_of_observation = nan(size(data_sess_died));
first_sess_nonzero_data = nan(size(data_sess_died));


%iterate through each animal
for i = 1:length(data_sess_died)
    % find the data for intesity or area doesnt really matter for this
    % animal in the data
    this_data_inten = data_intensity(i,:);
    this_data_area = data_area(i,:);
    x = 1:length(this_data_inten);
    
    % try to find the first session that it was infected
    this_first_sess_idx = find((this_data_inten>0) == 1, 1, 'first');
    % if there is a death detected find the last day of observation 
    % that would be the day of death -1
    this_last_sess_idx = data_sess_died(i) - 1;
    % if the value of death day is negative then it is still alive and then
    % so the length of the experiment is the last observed day
    this_last_sess_idx(this_last_sess_idx<0) = size(data_area,2);
    
    % if there is a session with nonzeros isolate the specifc data
    if ~isempty(this_first_sess_idx)
        first_sess_nonzero_data(i) = this_first_sess_idx;
        
        first_sess_of_infection_intensity(i) = data_intensity(i,this_first_sess_idx);
        last_sess_of_infection_intensity(i) = data_intensity(i,this_last_sess_idx);
        
        first_sess_of_infection_area(i) = data_area(i,this_first_sess_idx);
        last_sess_of_infection_area(i) = data_area(i,this_last_sess_idx);
        
        this_linear_regression_inten = polyfit(x,this_data_inten,1);
        intensity_regression_slope(i) = this_linear_regression_inten(1);
        intensity_regression_intercept(i) = this_linear_regression_inten(2);
        
        this_linear_regression_area = polyfit(x,this_data_area,1);
        area_regression_slope(i) = this_linear_regression_area(1);
        area_regression_intercept(i) = this_linear_regression_area(2);
        
        intensity_integrated_across_time(i) = sum(this_data_inten,'omitnan');
        area_integrated_across_time(i) = sum(this_data_area,'omitnan');
        
        intensity_max_gradient_at_point(i) = max(gradient(this_data_inten));
        area_max_gradient_at_point(i) = max(gradient(this_data_area));
        
    end
    
    last_day_of_observation(i) = this_last_sess_idx;
    
    if isnan(data_censor(i,end))
        cen_idx = find(~isnan(data_censor(i,:)) == 1,1,'last');
        final_data_censor(i) = data_censor(i,cen_idx);
    else
        final_data_censor(i) = data_censor(i,end);
    end
    
end



final_array = cell(size(data_area,1),length(csv_output_header));

for i = 1:size(data_area,1)
    
    final_array{i,1} = bioreps{i};
    final_array{i,2} = conditions{i};
    final_array{i,3} = locations{i};
    
    final_array{i,4} = logical(data_sess_died(i));
    final_array{i,5} = logical(final_data_censor(i));
    final_array{i,6} = last_day_of_observation(i);
    final_array{i,7} = first_sess_nonzero_data(i);
    
    final_array{i,8}  = first_sess_of_infection_intensity(i);    
    final_array{i,9}  = last_sess_of_infection_intensity(i);  
    final_array{i,10} = intensity_regression_slope(i);  
    final_array{i,11} = intensity_regression_intercept(i); 
    final_array{i,12} = intensity_integrated_across_time(i);  
    final_array{i,13} = intensity_max_gradient_at_point(i); 
    
    final_array{i,14} = first_sess_of_infection_area(i);    
    final_array{i,15} = last_sess_of_infection_area(i);  
    final_array{i,16} = area_regression_slope(i);  
    final_array{i,17} = area_regression_intercept(i); 
    final_array{i,18} = area_integrated_across_time(i);  
    final_array{i,19} = area_max_gradient_at_point(i); 
    
end

[~,out_name,~] = fileparts(char(CSV_filename));

output_name = [char(out_name) '_analyzed.csv'];

output_path = fullfile(CSV_filepath,output_name);

disp(output_path);

T = cell2table(final_array,'VariableNames',csv_output_header);

writetable(T,output_path);



end








