# mini-dbt
Bare bones DBT project

Structure your data analysis projects DBT style. Useful when `dbt` is not available in your organisation but you prefer structure in your projects. Nothing fancy here. Just a fallible `bash` script that works if used correctly :sunglasses:.
Unfortunately this only works with `sqlcmd` (SQLSERVER) but can easily be re-written for other RDBMSs (You'll have to change one line of code :cowboy_hat_face:).

If you're not familiar with the data-buid-tool then check it out [here](https://docs.getdbt.com/). If your organisation allows the use of `dbt` then don't waste your time reading further :v:. 

<br/>

# Install

Create a `.bashrc` file in your home directory 

```bash 
vi ~/.bashrc 
```

and paste the snippet below.

```bash 
export PATH=/this/directory/contains/mini-dbt:$PATH
alias mini-dbt=mini-dbt.sh
```

You can also just use the shell script directly. No need to add to `$PATH`.

```bash
# chmod if you need to
./mini-dbt.sh --help
```

<br/>

# Create a project 

```bash 
mkdir my-awesome-mini-dbt-project && cd my-awesome-mini-dbt-project
mini-dbt init 
```

Start your Analyses :rocket:

<br/>

# Commands 

- Help
```bash
mini-dbt --help
```

- Start a `mini-dbt` project

```bash
mini-dbt init 
```

- Build the entire project (Run all models `.sql` files). This excludes models in the `tests` and `cleanup` directories. 

```bash 
mini-dbt --all
```

- Build models in the staging folder
    
```bash
mini-dbt --build-models-in-folder staging
```
    
- Build entire project excluding cleanup and analyses folders

```bash 
mini-dbt --exclude-folder cleanup/ analyses/
```
    

- Build a single model

```bash 
mini-dbt --build-model stg_res_mod__rabbits.sql
```
    
    
- Build models in a directory excluding selected models 

```bash 
mini-dbt --exclude-models-in-folder staging stg_res_mod__rabbits.sql
```

<br/>


# Directory Structure 

# staging 
This is where you create `sql` scripts that generate the base tables (views) of your project.

## Example

***Filename:*** `stg_schema__rabbits.sql`
```sql 

-- Idempotency is a rabbit's best friend. Be like a rabbit 
drop view if exists schema.stg_schema__rabbits;

create view schema.stg_schema__rabbits 
as 
select * 
from schema.rabbits 
```

This allows you to analyse the base tables before you start joining them onto others. Might be useful to add an `Id` column to track duplicates after joins, etc. Normally, there'll be no joins here but the choice is yours.


# intermediate 
Want to do some pivoting, unpivoting, grouping, etc? Then this is a great folder to place those `sql` scripts in.

## Example
***Filename:*** `pivot_rabbits_by_age_range.sql`

```sql  

drop view if exists pivot_rabbits_by_age_range;

create view pivot_rabbits_by_age_range 
as 
select 
  rabbit_name,
  sum(case when age between 0 and 10 then 1 end) as YoungRabbits,
  sum(case when age between 11 and 20 then 1 end) as OldRabbits 
from schema.stg_schema__rabbits 
group by 
  rabbit_name 
 ```
 
 You might want to join a base view with the results of this view in the `serving` folder.

# serving 
Typically, you'll join all base views to create one big view and export the view to your semantic layer of choice in this folder. If your semantic layer supports normalized relations, then you can export the views generated from the **staging**/**intermediate** folders.

## Example

***Filename:*** `serving_rabbits.sql`

```sql 

-- Yes these rabbits have babies and we're categorising them by age!
with rabbits as (
  select * 
  from schema.stg_schema__rabbits 
),

number_of_rabbits_in_diff_age_ranges as (
  select 
    rabbit_name,
    YoungRabbits,
    OldRabbits 
  from pivot_rabbits_by_age_range
),

merged as (
  select * 
  from rabbits 
  inner join number_of_rabbits_in_diff_age_ranges
    on rabbits.rabbit_name = number_of_rabbits_in_diff_age_ranges.rabbit_name
)

select * from merged;
```


# analyses 
The analyses folder should contain `.sql` scripts that generate datasets you wish to analyse. For example, say you want to generate a dataset containing rabbits that live in the same shelter, this is where you place such a query. This is useful because you might want to show the results to your manager, teammate, etc. It can be a great extension of the `serving` folder. 


## Example

***Filename:*** `rabbits_with_same_shelters.sql`

```sql 

with rabbits as (
  select * 
  from serving_rabbits
),

rabbits_sharing_shelters as (
  select 
    rabbit_name
  from rabbits
  group by shelters 
  having count(*) > 1
),

merged as (
  select *
  from rabbits 
  where rabbit_name in (select rabbit_name from rabbits_sharing_shelters)
) 

select * from merged;

```

# assets 
Have photos/any static files? Place them here please.

# tests 
With DBT the test folder contains scripts used to create singular tests however for `mini-dbt`, this is where you run some `select` statements on the outputs generated from the `analyses` folder. For example, find all rabbits that are white, 6ft tall and called `Harry`. Think of it as an extension of the `analyses` folder. No relations are created here.

## Example

Show the results to your teammates

```sql  

select * 
from rabbits_with_same_shelters 
where rabbit_name = 'Harry';
go

select * 
from rabbits_with_same_shelters
where rabbit_height = 6ft
order by rabbit_name 
offset 0 rows fetch next 10 rows only;

```

# cleanup
Remember you generated this project because of an adhoc request? Well, now that the manager is satisfied, there's no need to leave all the objects you generated in the database. Create a `cleanup.sql` script that contains `drop` statements to remove all objects generated from this project. 

## Example 

***Filename:*** `cleanup.sql`

```sql 
drop view schema.stg_schema__rabbits;
drop view schema.rabbits_with_same_shelters; 
```

and run 

```bash 
mini-dbt -build-model cleanup.sql
```
to run the script. Models are supposed to contain DML statements but this is the only exception. 

<br/>


# References 
## You don't know Bash
- https://opensource.com/article/18/5/you-dont-know-bash-intro-bash-arrays

## `SQLCMD`
- https://learn.microsoft.com/en-us/sql/tools/sqlcmd-utility?view=sql-server-ver16

## Add to Path 
- https://www.folkstalk.com/tech/how-to-setup-path-using-git-bash-in-windows-with-code-examples/

## Find an element in a list
- https://stackoverflow.com/questions/3685970/check-if-a-bash-array-contains-a-value/8574392#8574392
