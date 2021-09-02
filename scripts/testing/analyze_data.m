clear all

CSV_filepath = "test.csv";
csv_table= readtable(CSV_filepath,'VariableNamingRule','preserve'); % Your parsing will be different

conditions = string(natsort(unique((csv_table.Condition))));
condition_idx = 1:length(conditions);

csv_names = csv_table.Properties.VariableNames;

col_intensity = contains(string(csv_names),"Intensity");
col_area = contains(string(csv_names),"Area");
col_censor = contains(string(csv_names),"Censored");
col_dead = contains(string(csv_names),"Dead");

data_intensity = table2array(csv_table(:,col_intensity));
data_area = table2array(csv_table(:,col_area));
data_censor = table2array(csv_table(:,col_censor));
data_dead = table2array(csv_table(:,col_dead));

data_sess_died = zeros(length(data_dead),1);
data_sess_censored = zeros(length(data_dead),1);

for i = 1:length(data_dead)
    
    sess_died = find(data_dead(i,:)>0,1,'first');
    
    if ~isempty(sess_died)
        data_sess_died(i) = sess_died;
    end
    
    sess_censored = find(data_censor(i,:)>0,1,'first');
    
    if ~isempty(sess_censored)
        data_sess_censored(i) = sess_censored;
    end
    
end
clear sess_censored sess_died i 

idx_infected = (mean(data_area,2,'omitnan')>0);
idx_good_wells = (data_sess_censored==0);
idx_not_dead = (data_sess_died==0);

idx_only_single_point = (sum(data_area>0,2)==1).*(~(data_sess_died>0));

idx_yes = logical(idx_infected.*idx_good_wells.*(~idx_only_single_point));

data_AUC = ((data_intensity+.01)./(data_area+.01));
data_AUC(data_AUC==1) = 0;

for i = 1:length(data_sess_died)
    
    if data_sess_died(i) > 0 
        data_AUC(i,data_sess_died(i):end) = NaN;
    end
    
end

data_to_plot2 = data_AUC(idx_yes,:);

figure;

x = 1:size(data_area,2);
for i = 1:length(conditions)
    
    subplot(ceil(length(conditions)/2),2,i)
    
    title(conditions(i),'interpreter','none');
    hold on
   
    this_condition_idx = string(csv_table.Condition) == conditions(i);
    
    this_condition_idx = logical(idx_yes.*this_condition_idx);
    
    this_conditon = data_AUC(this_condition_idx,:);
    
    for j = 1:size(this_conditon,1) + 1
        
        if isequal(j,size(this_conditon,1) + 1)
            
            this_conditon2 = this_conditon;
            this_conditon2(this_conditon2==0) = NaN;
            
            this_worm = mean(this_conditon2,1,'omitnan');
            
            plot(x,this_worm,'LineWidth',4,'Color','k')
            
        else
            this_worm = this_conditon(j,:);
            
            plot(x,this_worm);
        end
        
    end
    
    hold off
    
end


