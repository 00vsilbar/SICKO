# SICKO - _**S**ystematic **I**maging of **C**. elegans **K**illing **O**rganisms_ 
![default_img](https://github.com/Sam-Freitas/SICKO/blob/main/scripts/analysis/out1.png)
###### Developed by [Samuel Freitas](https://github.com/Sam-Freitas), Luis Espejo, and George Sutphin (PI) at the [University of Arizona](https://mcb.arizona.edu/)
This repository is a complete data computation and analysis package for the SICKO -- Patent pending -- system.
SICKO was initially developed to qualtitively analyze infection progression of fluorescently tagged E. coli and P. aeruginosa in a C. elegans system, consequently SICKO can analyze any fluorescent-type signal in a longitudinal analysis of C. elegans

## Features

- Invidiualized longitudinal analysis of infected C. elegans
- Automatic comparison and analysis
- Automatic Heatmap creation 

## Required Packages
 - MATLAB 2020+
 - Image processing toolbox

## Installation (github desktop)
 - copy this URL
 ```
 https://github.com/Sam-Freitas/SICKO
 ```
 - Go to File>Clone repository (Ctrl+Shift+O)
 - On the top bar click on the URL tab
 - Paste the previously copied URL and click 'Clone'
## Installation (git)

```sh
cd Documents
git clone https://github.com/Sam-Freitas/SICKO
```

## Common errors that crop up
  - "erase" or any error during combine_csv.m
    - Make sure that there are the correct amount of csvs (6) for the associated conditions*days
    - Delete the extra csvs or make sure that you ran the SICKO script on all the data
    - Extra csvs can crop up when incorrect folders are present
  - Heatmap only showing one (or just a few) of the data points
    - One (or a few) of the data points might have not been censored when necessary
    - You can manually find the **non-matching** data using the compiled csv
    - Once identified find the corresponding censor.csv and rerun the combine/compile/analyze scripts 


## Example data (publication coming soon)
![default_img2](https://github.com/Sam-Freitas/SICKO/blob/main/scripts/analysis/out2.png)

![default_img3](https://github.com/Sam-Freitas/SICKO/blob/main/scripts/analysis/out3.png)
