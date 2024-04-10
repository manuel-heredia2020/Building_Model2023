### A Pluto.jl notebook ###
# v0.19.38

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
end

# ╔═╡ 67d3c84f-d79f-474a-8843-78a09bc43db1
using Pkg #activating Packages

# ╔═╡ adc54d72-52a7-41d9-8671-9d96c78c94dc
Pkg.activate("Project.toml") # This line activates the environment

# ╔═╡ 4e4464ed-78e1-42cc-9c18-fd0358c8bcf4
begin # I am using the downloaded Packages
	using CSV # this package allows import CSV files
	using DataFrames # This package allow using DataFrame
	using PlutoUI # This pacakge allow using Pluto input tables and slides
	using Plots
	using StateSpaceModels
	using GLM
	using StatsBase
	using Lathe
	using MLBase
end

# ╔═╡ ea3c0c67-7526-42db-966e-3ec4639450de
using Lathe.preprocess: TrainTestSplit

# ╔═╡ 0b4a67d2-29d2-11ed-1855-2b1556a523ec
md"# Data analysis for Buildings Model"

# ╔═╡ d7231f03-5e73-4d89-8b85-416c6fceafe4
md"""
The purpose of this file is to evaluate and analyze data that can be used for modelling Buildings sector. The reason of using Pluto and Julia is the interactivy of the notebook, the capability to move easily between sources and economies. I personally found Julia quite fast to recalculate and to evaluate preliminary results.

Some results obtained here can be elevated into more complex models using Python, R, Matlab or other tools.
"""

# ╔═╡ c1d940b2-3ba2-4558-b121-babada1cbfdd
Pkg.status() # This land 

# ╔═╡ 9389bbd1-1a1e-4734-b702-3f63a93e7882
md"## Loading Energy Balance Data

The primary data source is the Energy Balance form ESTO it contains the variable to predict. Annual data do not allow to work this data as time series as it contains too little data. I am considering is using bootstrapping techniques.

First approach, Energy balances contains the dependent variables
"

# ╔═╡ 759da63d-54f8-40f7-a5b4-fbc357c544a4
begin; # Load the Energy Balance file
	eb_csv=CSV.File("Data/EGEDA_2020_created_14112022_updating.csv");
	eb_data=DataFrame(eb_csv);
end ;

# ╔═╡ aae74f0c-fbe1-45ef-b489-5bebaf654884
describe(eb_data)

# ╔═╡ f164c81a-0b6e-4dd3-bc91-f33c5a505c4a
md"# Data Visualization
"

# ╔═╡ bce57717-2a3d-4d53-bd76-0753a4b26f42
md"### Energy Balance Data"

# ╔═╡ cf2dba12-085f-44ee-91d1-50e327cc71e2
begin ; # this code identifies the classifying variables
	economy_list=unique(eb_data[:,"economy"]);
	fuel_list=unique(eb_data[:,"product_code"]);
	sector_list=unique(eb_data[:,"item_code"]);
end;
	

# ╔═╡ af140502-afa8-4b0f-88c4-2de3c7f2e242
md""" **Economy Selection**
"""

# ╔═╡ 50bb5914-f7c9-4561-b208-e4527b470e84
@bind economy_sel Select(economy_list)

# ╔═╡ 02986bc4-2f57-46a9-a27e-c6a29d21ba3e
typeof(economy_sel)

# ╔═╡ b70da966-dec9-4cb7-a518-34723a75fe49
md""" **Fuel Selection**
"""

# ╔═╡ 6c863c40-5ccb-4b65-8c8d-4fd814d6a3c0
@bind fuel_sel MultiSelect(fuel_list)

# ╔═╡ c6a7b1b7-fac1-4303-abfe-f29c89112dc1
md""" **Sector Selection (Requires 2 sectors. The first one is used in later analysis)**
"""

# ╔═╡ 0680bf4e-d67f-4b87-ae01-2a7d86672f79
@bind sector_sel MultiSelect(sector_list)

# ╔═╡ 5d297f68-3ce1-4949-8890-0bb2b1b1a044
@bind beginyear Slider(1990:2021)

# ╔═╡ 1f70ff6a-363d-4817-8b39-8ea76c432a6a
beginyear

# ╔═╡ def2d821-1649-4871-b0c8-e04aad347da8
begin;
filtered_economy=filter(row->row.economy==economy_sel, eb_data);
filtered_sample=filter(row->row.item_code==sector_sel[1],filter(row->row.product_code==fuel_sel[1], filtered_economy));
 filtered_sample2=filter(row->row.item_code==sector_sel[2],filter(row->row.product_code==fuel_sel[1], filtered_economy));
end;

# ╔═╡ 3e2f408a-b122-439d-bc43-4e1b47a1dcca
begin;
energy_df=DataFrames.stack(select(select(filtered_sample,Not(:product_code)),Not(:item_code)),Not(:economy));
energy_df2=DataFrames.stack(select(select(filtered_sample2,Not(:product_code)),Not(:item_code)),Not(:economy));
energy_df1=select( energy_df,Not(:economy))
energy_df22=select(energy_df2,Not(:economy))
energy_df_filtered1=energy_df1[beginyear-1979:42,:];    # filtered of data 11-1990   29-2020
energy_df_filtered2=energy_df22[beginyear-1979:42,:];	# filtered of data 11-1990   29-2020
energy_df_filtered1.value=float.(energy_df_filtered1.value) # convert any to float
energy_df_filtered2.value=float.(energy_df_filtered2.value) # convert any to float
end;

# ╔═╡ 6ce8cd1a-6a3f-49a9-b81d-8991208b202b
begin;
years=beginyear:2021; # historical years
energy_result1=Matrix(energy_df_filtered1);
energy_result2=Matrix(energy_df_filtered2);	
end;

# ╔═╡ a3cc3ecf-2891-48d8-bae5-0c44a19b8c55
rename!(energy_df_filtered1,:value => :energy);

# ╔═╡ 38cd86fb-8936-478a-bccd-8aeb4ed238bf
begin
plotly()
plot(years,energy_result1[:,2],label=sector_sel[1],legendfont=font(5));
plot!(years,energy_result2[:,2],label=sector_sel[2],legendfont=font(5),legend=:outertopright)
end

# ╔═╡ 09a3e9ca-8236-4fd8-a59e-4b2389f7d8f0
md""" ### Macroeconomic Data
"""

# ╔═╡ 313c787d-3c87-48d9-8b3f-1b36b0c72b96
md"""
The main Macroeconomic Data that are explored are Population, GDP, GDP current, Electrification (relevant in economies with % <<100), GNI per Capita and urbanization. GNI or GDP current seem better variables than GDP PPP. 

"""

# ╔═╡ 40ebd078-99b7-485d-bb4a-ff867de21b2f
begin;
	GDP_csv=CSV.File("Data/GDP.csv");
	GDP_data=DataFrame(GDP_csv);
	Population_csv=CSV.File("Data/Population.csv");
	Population_data=DataFrame(Population_csv);
	Electrification_csv=CSV.File("Data/Electrification.csv");
	Electrification_data=DataFrame(Electrification_csv);
	GNIpercapita_csv=CSV.File("Data/GNIpercapita.csv");
	GNIpercapita_data=DataFrame(GNIpercapita_csv);
	GDPcurrent_csv=CSV.File("Data/GDPcurrentDollar.csv");
	GDPcurrent_data=DataFrame(GDPcurrent_csv);
	AddVal_csv=CSV.File("Data/Servic_addVal.csv");
	AddVal_data=DataFrame(AddVal_csv);
	Urbanization_csv=CSV.File("Data/urbanization.csv");
	Urbanization_data=DataFrame(Urbanization_csv);
	daysinyear_csv=CSV.File("Data/Daysinyear.csv");	
	daysinyear_data=DataFrame(daysinyear_csv);
	daysinyear_df=select(DataFrames.stack(daysinyear_data,Not(:Unit)),Not(:Unit)); 
	rename!(daysinyear_df,:value => :number_days_year);
	#************************************GDP****************************************
	GDP_filtered_economy=filter(row->row.Economy==economy_sel, GDP_data);

	GDP_result=transpose(Matrix(select(GDP_filtered_economy,Between("1990","2021"))));# modify date range
	GDP_df_filtered=DataFrame(GDP_result)
	rename!(GDP_df_filtered,"x1"=>"GDP")
	GDP_df_filtered.variable=energy_df_filtered1.variable
	
	#**********************************Population***********************************
	Population_filtered_economy=filter(row->row.Economy==economy_sel, Population_data);
	Population_result=transpose(Matrix(select(Population_filtered_economy,Between("1990","2021"))));# modify date range
	Population_df_filtered=DataFrame(Population_result)
	rename!(Population_df_filtered,"x1"=>"Population")
	Population_df_filtered.variable=energy_df_filtered1.variable
	#*****************************Electrification***********************************
	Electrification_filtered_economy=filter(row->row.Economy==economy_sel, Electrification_data);
	Electrification_result=transpose(Matrix(select(Electrification_filtered_economy,Between("1990","2021"))));# modify date range
	Electrification_df_filtered=DataFrame(Electrification_result)
	rename!(Electrification_df_filtered,"x1"=>"Electrification")
	Electrification_df_filtered.variable=energy_df_filtered1.variable
    #****************************GNI per capita ***********************************
	GNIpercapita_filtered_economy=filter(row->row.Economy==economy_sel, GNIpercapita_data);
	GNIpercapita_result=transpose(Matrix(select(GNIpercapita_filtered_economy,Between("1990","2021"))));# modify date range
	GNIpercapita_df_filtered=DataFrame(GNIpercapita_result)
	rename!(GNIpercapita_df_filtered,"x1"=>"GNIpercapita")
	GNIpercapita_df_filtered.variable=energy_df_filtered1.variable
	#******************************GDPCurrent***********************************
	GDPcurrent_filtered_economy=filter(row->row.Economy==economy_sel, GDPcurrent_data);
	GDPcurrent_result=transpose(Matrix(select(GDPcurrent_filtered_economy,Between("1990","2021"))));# modify date range
	GDPcurrent_df_filtered=DataFrame(GDPcurrent_result)
	rename!(GDPcurrent_df_filtered,"x1"=>"GDPcurrent")
	GDPcurrent_df_filtered.variable=energy_df_filtered1.variable
	#******************************Add Value***********************************
	AddVal_filtered_economy=filter(row->row.Economy==economy_sel, AddVal_data);
	AddVal_result=transpose(Matrix(select(AddVal_filtered_economy,Between("1990","2021"))));# modify date range
	AddVal_df_filtered=DataFrame(AddVal_result)
	rename!(AddVal_df_filtered,"x1"=>"AddVal")
	AddVal_df_filtered.variable=energy_df_filtered1.variable
	#******************************Urbanization***********************************	
	Urbanization_filtered_economy=filter(row->row.Economy==economy_sel, Urbanization_data);
	Urbanization_result=transpose(Matrix(select(Urbanization_filtered_economy,Between("1990","2021"))));# modify date range
	Urbanization_df_filtered=DataFrame(Urbanization_result)
	rename!(Urbanization_df_filtered,"x1"=>"Urbanization")
	Urbanization_df_filtered.variable=energy_df_filtered1.variable

end ;

# ╔═╡ 6af62de0-e8bd-487f-9c8f-dc60e501cbed
begin;
Variables=innerjoin(energy_df_filtered1,GDP_df_filtered, on=:variable);
Variables2=innerjoin(Variables,Population_df_filtered,on=:variable);
Variables3=innerjoin(Variables2,GDPcurrent_df_filtered,on=:variable);
Variables4=innerjoin(Variables3,Electrification_df_filtered,on=:variable);
Variables5=innerjoin(Variables4,GNIpercapita_df_filtered,on=:variable);
Variables6=innerjoin(Variables5,AddVal_df_filtered,on=:variable);
Variables7=innerjoin(Variables6,Urbanization_df_filtered,on=:variable);
Variables8=innerjoin(Variables7,daysinyear_df[beginyear-1989:32,:],on=:variable); 
Variables8.logenergy=log.(Variables8.energy);
Variables8.logGDP=log.(Variables8.GDP);
Variables8.logPopulation=log.(Variables8.Population);
Variables8.logcurrent=log.(Variables8.GDPcurrent);
Variables8.logElectrification=log.(Variables8.Electrification);
Variables8.logGNIpercapita=log.(Variables8.GNIpercapita);
Variables8.logAddVal=log.(Variables8.AddVal);
Variables8.logUrbanization=log.(Variables8.Urbanization);
Variables8.energy_percapita_day=Variables8.energy./Variables8.number_days_year./Variables8.Population.*100000;
Variables8.logenergy_percapita_day=log.(Variables8.energy_percapita_day);
Variables8.GDPpercapita=Variables8.GDP./Variables8.Population./10000000;
Variables8.logGDP_percapita=log.(Variables8.GDPpercapita);
Variables8.PopulationUrban=Variables8.Population.*Variables8.Urbanization/100;
Variables8.PopulationRural=Variables8.Population-Variables8.PopulationUrban;
Variables8.Populationelectrified=Variables8.Population.*Variables8.Electrification./100;
Variables8.energy_elec_percapita_day=Variables8.energy./Variables8.number_days_year./Variables8.Populationelectrified.*100000;
Variables8.energy_percapitaRural_day=Variables8.energy./Variables8.number_days_year./Variables8.PopulationRural.*100000;
Variables8.logenergy_elec_percapita_day=log.(Variables8.energy_elec_percapita_day);
Variables8[!,:Population]=convert(Array{Float64,1},Variables8[!,:Population]);
end;

# ╔═╡ 8054c344-b13d-4ef5-88df-16ee914046b9
describe(Variables8)

# ╔═╡ 0020c8af-410a-4b86-a670-0a3cb689e0ae
begin;
	p1=plot(years,Population_result, title="Population");
	p2=plot(years,GDP_result,title="GDP PPP");
	p3=plot(years,Electrification_result,title="Electrification");
	p4=plot(years,GNIpercapita_result, title="GNI per Capita");
	p5=plot(years,GDPcurrent_result, title="GDP current");
	p6=plot(years,AddVal_result, title="Services add Value");
	p7=plot(years,Urbanization_result, title="Urbanization");
end;

# ╔═╡ e52baf82-266f-4689-a26d-71179a4f7b1b
begin 
plotly()
plot(p1,p2,p3,p4,p5,p6,p7,layout=(4,2),xtickfontsize=5,ytickfontsize=5,legend = false)
end

# ╔═╡ 588729b3-ba96-474c-a240-dfc23207cd89
Variables8

# ╔═╡ 731ec994-1075-40cc-ac37-3933b28b196d
# We test different model. The main idea  is to identify relevant predicting variables more than defining a model
begin
model_lineal1=lm(@formula(energy~GDP/10000000000000),Variables8)
model_lineal2=lm(@formula(energy~GDP/10000000000000+Population/1000),Variables8)
#model_lineal3=lm(@formula(energy~GDPcurrent+Population),Variables8)
#model_lineal4=lm(@formula(energy~GNIpercapita+Population),Variables8)
#model_lineal5=lm(@formula(energy~GNIpercapita),Variables8)
model_lineal6=lm(@formula(logenergy~log(GDP/10000000000000)+log(Population/1000)),Variables8)
model_lineal7=lm(@formula(logenergy_percapita_day~logGDP_percapita),Variables8)
#model_lineal8=lm(@formula(energy_percapita_day~GNIpercapita),Variables8)
model_lineal9=lm(@formula(energy_percapita_day~GDP/10000000000000),Variables8)
#model_lineal10=lm(@formula(energy_percapitaRural_day~GDPpercapita),Variables8)
#model_lineal11=lm(@formula(energy~PopulationUrban+PopulationRural),Variables8)
model_lineal12=lm(@formula(logenergy_percapita_day~log(GDP/10000000000000)),Variables8)
#model_lineal13=lm(@formula(logenergy_elec_percapita_day~logGDP_percapita),Variables8)
#model_lineal14=lm(@formula(logenergy~log(PopulationUrban)+log(GDP/10000000000000)),Variables8)
#model_lineal15=lm(@formula(energy_percapita_day~AddVal/100000000000),Variables8)
#model_lineal16=lm(@formula(energy_elec_percapita_day~GDP/10000000000000),Variables8)
model_lineal17=lm(@formula(energy~Population/1000),Variables8)	
#Model_lineal2=lm(@formula(energy~GDP+Population+GDPcurrent+Electrification+GNIpercapita+AddVal),Variables7)
end

# ╔═╡ e4a93d99-8429-433c-8c8b-b3282c253612
md""" ## Assessing models  """

# ╔═╡ f01c4b27-c016-4db6-aea6-27bc28bec232
adjr2.((model_lineal1, model_lineal2,model_lineal6,model_lineal7,model_lineal9,model_lineal12,model_lineal17))

# ╔═╡ 02892065-dc1e-439e-8e91-fc0d760646b0
aic.((model_lineal1,model_lineal2, model_lineal6,model_lineal7,model_lineal9,model_lineal12,model_lineal17))

# ╔═╡ e598b75a-7a0d-4c70-8c03-3b6aa6a1d8b4
md""" # Testing model
"""

# ╔═╡ d2e960af-3c6d-4db4-8374-20e653d59409
md"""
We split data into train and test data
"""

# ╔═╡ 56941b74-65f8-42c8-a873-5bb514271afa
train,test = TrainTestSplit(Variables8,.75);

# ╔═╡ ffd191f1-e66f-43bf-a88a-ccf0f75ddac1
md"""Here we define the model to test usually of the form
## Energy ⟶  α₀ + α₁*GNIₚ + α₂* Population + ...

Now, the idea is to identify forces not to determine the final form of the equation.

"""

# ╔═╡ fa050dec-82d6-4cf0-bb38-79de11dcfa4d
fm=@formula(energy_percapita_day~GDP/10000000000000)# make sure this model is the one you are studying

# ╔═╡ 0a809920-5a9e-4592-a62c-50dfd7a28642
linearRegressor=lm(fm,train)

# ╔═╡ 407c1130-1e5b-4d85-a83e-f776b361692d
ypredicted_test=predict(linearRegressor,test)

# ╔═╡ 2a70c5af-f880-48f1-b1f6-ae6d11b38eba
ypredicted_train=predict(linearRegressor,train)

# ╔═╡ 9780d9c4-c5fd-4463-bb7e-ddfc8d2e336c
#performance_testdf=DataFrame(y_actual=test[!,:energy],y_predicted=ypredicted_test);
performance_testdf=DataFrame(y_actual=test[!,:energy_percapita_day],y_predicted=(ypredicted_test));
#performance_testdf=DataFrame(y_actual=test[!,:logenergy_percapita_day],y_predicted=(ypredicted_test));
#performance_testdf=DataFrame(y_actual=test[!,:logenergy],y_predicted=ypredicted_test);
# change in test [!, XXX] depending ong the type or y result

# ╔═╡ c2f2a01a-fe13-418f-a8ea-711612a113ff
#performance_traindf=DataFrame(y_actual=train[!,:energy],y_predicted=(ypredicted_train)); 
#performance_traindf=DataFrame(y_actual=train[!,:logenergy],y_predicted=(ypredicted_train)); 
performance_traindf=DataFrame(y_actual=train[!,:energy_percapita_day],y_predicted=(ypredicted_train));
#performance_traindf=DataFrame(y_actual=train[!,:logenergy_percapita_day],y_predicted=(ypredicted_train)); 
#performance_traindf=DataFrame(y_actual=train[!,:logenergy_percapita_day],y_predicted=(ypredicted_train)); 
# change in test [!, XXX] depending ong the type or y result

# ╔═╡ ea3962f0-9dd0-4032-ae56-151e3ee44e6d
performance_testdf.error = performance_testdf[!,:y_actual] - performance_testdf[!,:y_predicted];


# ╔═╡ 5ba683b0-aac6-42da-98ae-864a35aa32fc
performance_testdf.error_sq = performance_testdf.error.*performance_testdf.error;

# ╔═╡ c35c6f96-d78d-4092-96e7-305af7c615a2
performance_traindf.error = performance_traindf[!,:y_actual] - performance_traindf[!,:y_predicted];

# ╔═╡ 94ceea4f-0b84-416d-b97c-c9701bfa4b62
performance_traindf.error_sq = performance_traindf.error.*performance_traindf.error; 

# ╔═╡ 2fd2b252-7a7b-4878-ac56-6057c1564db3
begin
	plotly()
	xrange1=range(minimum(performance_testdf[!,:y_actual]),maximum(performance_testdf[!,:y_actual]),100);
	test_plot=scatter(performance_testdf[!,:y_actual], performance_testdf[!,:y_predicted], legend=false)
	plot!(xrange1,xrange1)

end

# ╔═╡ ee36d8d9-3e1d-4d3a-a20a-f2e4012fd6e5
begin
	plotly()
	xrange2=range(minimum(performance_traindf[!,:y_actual]),maximum(performance_traindf[!,:y_actual]),100);
	train_plot=scatter(performance_traindf[!,:y_actual], performance_traindf[!,:y_predicted],legend=false)
	plot!(xrange2,xrange2)
end

# ╔═╡ a340c071-2d20-4176-a7cb-ba5f6d096210
md"""
The best models have normal distributed errors. In reality there are slim chances to get a zero-mean normal distributed error. However you need to pay special attention to errors to identify trends
"""

# ╔═╡ 193169e2-ef37-484b-a462-adddb081a59b
histogram(performance_testdf.error, bins = 7, title = "Test Error Analysis", ylabel = "Frequency", xlabel = "Error",legend = false)


# ╔═╡ 1d6cd51b-c84c-45fb-8cf6-b1afd8681714
histogram(performance_traindf.error, bins = 5, title = "Training Error Analysis", ylabel = "Frequency", xlabel = "Error",legend = false)


# ╔═╡ bac7e0dc-0837-46ec-b7cf-a311635e61b1
scatter(performance_traindf.y_actual,performance_traindf.error) # error must not have trend

# ╔═╡ b43b0ade-3fb3-458e-b216-1351e0a29c60
scatter(performance_testdf.y_actual,performance_testdf.error) # error must not have trend

# ╔═╡ 22f61d96-da98-4e7a-8fbd-1e7ae513b2f3
function cross_validation(train,k,fm=@formula(energy_percapita_day~GDP/10000000000000)) # change in @formula
    a = collect(Kfold(size(train)[1], k))
    for i in 1:k
        row = a[i]
        temp_train = train[row,:]
        temp_test = train[setdiff(1:end, row),:]
        linearRegressor = lm(fm, temp_train)
        performance_testdf = DataFrame(y_actual = temp_test[!,:energy_percapita_day], y_predicted = predict(linearRegressor, temp_test)) # change in temp_test[!: XXX]
        performance_testdf.error = performance_testdf[!,:y_actual] - performance_testdf[!,:y_predicted]

        println("Mean error for set $i is ",mean(abs.(performance_testdf.error)))
    end
end

# ╔═╡ f7c1bed5-762c-4caa-a50b-ded41128c09e
cross_validation(train,10) # indicates the Std deviation taking 10 random samples

# ╔═╡ dfd0ec0d-61b8-4547-a953-7e0c62ea9ac4
md""" # Model Forecasting
"""

# ╔═╡ 51d6b4d5-4f69-496c-810b-b3c068b6d90c
begin;
#********************************GDP***********************************************	
GDP_prediction=transpose(Matrix(select(GDP_filtered_economy,Between("2021","2070"))));GDP_df_prediction=DataFrame(GDP_prediction);
rename!(GDP_df_prediction,"x1"=>"GDP")
GDP_df_prediction.variable=daysinyear_df.variable[32:81];
#****************************Population********************************************	
Population_prediction=transpose(Matrix(select(Population_filtered_economy,Between("2021","2070"))));
Population_df_prediction=DataFrame(Population_prediction);
rename!(Population_df_prediction,"x1"=>"Population")
Population_df_prediction.variable=daysinyear_df.variable[32:81];
#****************************Electrification*****************************************
Electrification_prediction=transpose(Matrix(select(Electrification_filtered_economy,Between("2021","2070"))));
Electrification_df_prediction=DataFrame(Electrification_prediction);
rename!(Electrification_df_prediction,"x1"=>"Electrification")
Electrification_df_prediction.variable=daysinyear_df.variable[32:81];
#****************************GNI per Capita****************************************	
#GNIpercapita_prediction=transpose(Matrix(select(GNIpercapita_filtered_economy,Between("2021","2070"))));
#GNIpercapita_df_prediction=DataFrame(GNIpercapita_prediction);
#rename!(GNIpercapita_df_prediction,"x1"=>"GNIpercapita")
# GNIpercapita_df_prediction=GNIpercapita_df1[32:81,:];
# GDPcurrent_df_prediction=GDPcurrent_df1[32:81,:];
#****************************Electrification*************************************
AddVal_prediction=transpose(Matrix(select(AddVal_filtered_economy,Between("2021","2070"))));
AddVal_df_prediction=DataFrame(AddVal_prediction);
rename!(AddVal_df_prediction,"x1"=>"AddVal")
AddVal_df_prediction.variable=daysinyear_df.variable[32:81];
#****************************Electrification*************************************
Urbanization_prediction=transpose(Matrix(select(Urbanization_filtered_economy,Between("2021","2070"))));
Urbanization_df_prediction=DataFrame(Urbanization_prediction);
rename!(Urbanization_df_prediction,"x1"=>"Urbanization")
Urbanization_df_prediction.variable=daysinyear_df.variable[32:81];

end;

# ╔═╡ f534f051-102f-4080-beb2-3d271ee7e470
begin;
	predictors=innerjoin(GDP_df_prediction,Population_df_prediction, on=:variable);
	predictors2=innerjoin(predictors,daysinyear_df[32:81,:],on=:variable);
	predictors2.GDPpercapita=predictors2.GDP./predictors2.Population./10000000;
	predictors3=innerjoin(predictors2,Urbanization_df_prediction,on=:variable);
	predictors3.PopulationRural=predictors3.Population.-predictors3.Population.*predictors3.Urbanization./100;
	predictors3.PopulationUrban=predictors3.Population.-predictors3.PopulationRural;
	predictors3.logGDP_percapita=log.(predictors3.GDPpercapita);
	predictors4=innerjoin(predictors3,AddVal_df_prediction, on=:variable);
end;

# ╔═╡ 2194a740-9912-498f-8462-8b781db0836b

dependent_projected=(predict(linearRegressor,predictors2)).*predictors2.number_days_year.*predictors2.Population/100000
#dependent_projected=(predict(linearRegressor,predictors4))
#dependent_projected=predict(linearRegressor,predictors4).*predictors4.number_days_year.*predictors4.Population/100000
#dependent_projected=exp.(predict(linearRegressor,predictors4));
#dependent_projected=exp.(predict(linearRegressor,predictors4)).*predictors4.number_days_year.*predictors4.Population/100000;
#dependent_projected=exp.(predict(linearRegressor,predictors4))
# This formula depends on the dependent variables

# ╔═╡ 1b6dded5-56d8-418b-8a13-affb4db60e34
years2=2021:2070;

# ╔═╡ 74921f53-52b7-4951-9999-4f190ddd47bb
begin 
plotly()
scatter(years,energy_result1[:,2],label=sector_sel[1]);
scatter!(years2,(dependent_projected),legend=false)
end

# ╔═╡ ba31474e-2676-4ef0-bcee-1e7b18e5ac10
plotly()

# ╔═╡ e53b7691-a002-4904-9895-f5059633533f
df_result_fuel=DataFrame(permutedims(dependent_projected))

# ╔═╡ 5be3e7c4-c66d-48ff-b712-bab28242ef2b
#test_historical_total=(predict(linearRegressor,Variables8))
#test_historical_total=exp.(predict(linearRegressor,Variables8)).*Variables8.number_days_year.*Variables8.Population./100000
#test_historical_total=exp.(predict(linearRegressor,Variables8))
test_historical_total=predict(linearRegressor,Variables8).*Variables8.number_days_year.*Variables8.Population./100000# Verify the 
#test_historical_total=predict(linearRegressor,Variables8)# Verify the 

# ╔═╡ 4838fc08-723b-4c91-a871-85c264e50cb9
begin 
plotly()
scatter(years,energy_result1[:,2],label=sector_sel[1],legend=10);
scatter!(years,test_historical_total,title="Comparison between model and historical",legend=5)
end

# ╔═╡ 4394d866-6467-417d-bd99-952199216b4f
CSV.write("results/Residential_China.CSV",df_result_fuel)

# ╔═╡ b8249291-d2bb-4279-9d2c-4494976c7f7c
md"### Additional Data
"

# ╔═╡ a1e1a399-2109-4eef-b038-24c6a3178b5a
md"### Indicators

Indicators are possible only after 1990. If error appears, check years that were filtered in the energy balance data"

# ╔═╡ 0049c7f3-980d-4d83-abe7-f69b8a2c6a19
md"""## analysis per capita
"""

# ╔═╡ 0ea02eef-8d26-4675-bf30-2985f7b9d4a3
begin;
energy_per_capita=energy_result1[:,2]./Population_result;
dependent_percapita=dependent_projected./Population_df_prediction.Population;
end;

# ╔═╡ e1ebf690-20d5-4a8d-91f0-b58da67158ef
total_per_capita=[energy_per_capita;dependent_percapita];

# ╔═╡ 02695091-658e-4681-b5ff-d91f4d03f8b5
begin
	plotly()
	plot(years,energy_per_capita)
	plot!(years2,dependent_percapita)
end

# ╔═╡ fd07037f-379a-49b0-88af-519de23c631e
begin;
title1=string(fuel_sel);
economyStr=string(economy_sel);
end;

# ╔═╡ be424b5a-8ec3-4317-82b4-bc0da2bb8cef
pp3=plot(GNIpercapita_result,energy_per_capita,legend=false, title=economyStr*title1*"/capita*day Vs. GNI/capita")

# ╔═╡ 097aeed0-ab08-414a-a8e0-102aa7944417
XXX=LinRange(15000,70000,1000);

# ╔═╡ e7b6bd81-ab0b-4f48-b0f7-900b933355fe
xyline=plot(XXX,XXX,legend=false);

# ╔═╡ 4718a9c0-bf66-4183-913b-fcb301ca2ed7
pp4=plot(GNIpercapita_result,GDPcurrent_result./Population_result./1000);

# ╔═╡ baf95deb-8eb9-4c9c-a0d0-dcc29abd050f
plot(pp4)

# ╔═╡ 5c5b7dd4-4f0a-4d8a-a621-3a26ccc9c4b5
plot!(XXX,XXX,legend=false)

# ╔═╡ 932c7160-ee44-4346-ab97-646cd0abd56f
p4

# ╔═╡ 6867a82c-4591-41bd-8866-5b78bef28f8d
md"""# Forecasting
"""

# ╔═╡ 7e38e5a2-1470-40f3-afd4-200da8eef8ad
md"""
## Naïve method
"""

# ╔═╡ c2ab5d02-7934-4a9b-8d6e-73438a726992
md"""
## Moving Average
"""

# ╔═╡ Cell order:
# ╟─0b4a67d2-29d2-11ed-1855-2b1556a523ec
# ╟─d7231f03-5e73-4d89-8b85-416c6fceafe4
# ╠═67d3c84f-d79f-474a-8843-78a09bc43db1
# ╠═adc54d72-52a7-41d9-8671-9d96c78c94dc
# ╠═c1d940b2-3ba2-4558-b121-babada1cbfdd
# ╠═4e4464ed-78e1-42cc-9c18-fd0358c8bcf4
# ╠═9389bbd1-1a1e-4734-b702-3f63a93e7882
# ╠═759da63d-54f8-40f7-a5b4-fbc357c544a4
# ╠═aae74f0c-fbe1-45ef-b489-5bebaf654884
# ╠═f164c81a-0b6e-4dd3-bc91-f33c5a505c4a
# ╠═bce57717-2a3d-4d53-bd76-0753a4b26f42
# ╠═cf2dba12-085f-44ee-91d1-50e327cc71e2
# ╠═af140502-afa8-4b0f-88c4-2de3c7f2e242
# ╠═50bb5914-f7c9-4561-b208-e4527b470e84
# ╠═02986bc4-2f57-46a9-a27e-c6a29d21ba3e
# ╠═b70da966-dec9-4cb7-a518-34723a75fe49
# ╠═6c863c40-5ccb-4b65-8c8d-4fd814d6a3c0
# ╟─c6a7b1b7-fac1-4303-abfe-f29c89112dc1
# ╠═0680bf4e-d67f-4b87-ae01-2a7d86672f79
# ╠═5d297f68-3ce1-4949-8890-0bb2b1b1a044
# ╠═1f70ff6a-363d-4817-8b39-8ea76c432a6a
# ╠═def2d821-1649-4871-b0c8-e04aad347da8
# ╠═3e2f408a-b122-439d-bc43-4e1b47a1dcca
# ╠═6ce8cd1a-6a3f-49a9-b81d-8991208b202b
# ╠═a3cc3ecf-2891-48d8-bae5-0c44a19b8c55
# ╠═38cd86fb-8936-478a-bccd-8aeb4ed238bf
# ╟─09a3e9ca-8236-4fd8-a59e-4b2389f7d8f0
# ╟─313c787d-3c87-48d9-8b3f-1b36b0c72b96
# ╠═40ebd078-99b7-485d-bb4a-ff867de21b2f
# ╠═6af62de0-e8bd-487f-9c8f-dc60e501cbed
# ╠═8054c344-b13d-4ef5-88df-16ee914046b9
# ╠═0020c8af-410a-4b86-a670-0a3cb689e0ae
# ╠═e52baf82-266f-4689-a26d-71179a4f7b1b
# ╠═588729b3-ba96-474c-a240-dfc23207cd89
# ╠═731ec994-1075-40cc-ac37-3933b28b196d
# ╟─e4a93d99-8429-433c-8c8b-b3282c253612
# ╠═f01c4b27-c016-4db6-aea6-27bc28bec232
# ╠═02892065-dc1e-439e-8e91-fc0d760646b0
# ╟─e598b75a-7a0d-4c70-8c03-3b6aa6a1d8b4
# ╠═ea3c0c67-7526-42db-966e-3ec4639450de
# ╟─d2e960af-3c6d-4db4-8374-20e653d59409
# ╠═56941b74-65f8-42c8-a873-5bb514271afa
# ╟─ffd191f1-e66f-43bf-a88a-ccf0f75ddac1
# ╠═fa050dec-82d6-4cf0-bb38-79de11dcfa4d
# ╠═0a809920-5a9e-4592-a62c-50dfd7a28642
# ╠═407c1130-1e5b-4d85-a83e-f776b361692d
# ╠═2a70c5af-f880-48f1-b1f6-ae6d11b38eba
# ╠═9780d9c4-c5fd-4463-bb7e-ddfc8d2e336c
# ╠═c2f2a01a-fe13-418f-a8ea-711612a113ff
# ╠═ea3962f0-9dd0-4032-ae56-151e3ee44e6d
# ╠═5ba683b0-aac6-42da-98ae-864a35aa32fc
# ╠═c35c6f96-d78d-4092-96e7-305af7c615a2
# ╠═94ceea4f-0b84-416d-b97c-c9701bfa4b62
# ╠═2fd2b252-7a7b-4878-ac56-6057c1564db3
# ╠═ee36d8d9-3e1d-4d3a-a20a-f2e4012fd6e5
# ╟─a340c071-2d20-4176-a7cb-ba5f6d096210
# ╠═193169e2-ef37-484b-a462-adddb081a59b
# ╠═1d6cd51b-c84c-45fb-8cf6-b1afd8681714
# ╠═bac7e0dc-0837-46ec-b7cf-a311635e61b1
# ╠═b43b0ade-3fb3-458e-b216-1351e0a29c60
# ╠═22f61d96-da98-4e7a-8fbd-1e7ae513b2f3
# ╠═f7c1bed5-762c-4caa-a50b-ded41128c09e
# ╟─dfd0ec0d-61b8-4547-a953-7e0c62ea9ac4
# ╠═51d6b4d5-4f69-496c-810b-b3c068b6d90c
# ╠═f534f051-102f-4080-beb2-3d271ee7e470
# ╠═2194a740-9912-498f-8462-8b781db0836b
# ╠═1b6dded5-56d8-418b-8a13-affb4db60e34
# ╠═74921f53-52b7-4951-9999-4f190ddd47bb
# ╠═ba31474e-2676-4ef0-bcee-1e7b18e5ac10
# ╠═e53b7691-a002-4904-9895-f5059633533f
# ╠═5be3e7c4-c66d-48ff-b712-bab28242ef2b
# ╠═4838fc08-723b-4c91-a871-85c264e50cb9
# ╠═4394d866-6467-417d-bd99-952199216b4f
# ╟─b8249291-d2bb-4279-9d2c-4494976c7f7c
# ╟─a1e1a399-2109-4eef-b038-24c6a3178b5a
# ╟─0049c7f3-980d-4d83-abe7-f69b8a2c6a19
# ╠═0ea02eef-8d26-4675-bf30-2985f7b9d4a3
# ╠═e1ebf690-20d5-4a8d-91f0-b58da67158ef
# ╟─02695091-658e-4681-b5ff-d91f4d03f8b5
# ╠═fd07037f-379a-49b0-88af-519de23c631e
# ╠═be424b5a-8ec3-4317-82b4-bc0da2bb8cef
# ╠═097aeed0-ab08-414a-a8e0-102aa7944417
# ╠═e7b6bd81-ab0b-4f48-b0f7-900b933355fe
# ╠═4718a9c0-bf66-4183-913b-fcb301ca2ed7
# ╠═baf95deb-8eb9-4c9c-a0d0-dcc29abd050f
# ╠═5c5b7dd4-4f0a-4d8a-a621-3a26ccc9c4b5
# ╠═932c7160-ee44-4346-ab97-646cd0abd56f
# ╟─6867a82c-4591-41bd-8866-5b78bef28f8d
# ╟─7e38e5a2-1470-40f3-afd4-200da8eef8ad
# ╟─c2ab5d02-7934-4a9b-8d6e-73438a726992
