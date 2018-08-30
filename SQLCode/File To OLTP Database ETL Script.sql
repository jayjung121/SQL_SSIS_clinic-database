/***************************************************************************
Info498 Final Project
Dev: Byungsu Jung
--Date: 08/15/2018
Desc: This file extract data from raw data to OLTP database.
-- Change Log: When,Who,What
-- 2018-02-28,ByungsuJung,Created File..
*****************************************************************************/

Use tempdb;

If Exists(Select * from Sys.objects where Name = 'pCreateOrTruncateStagingTable')
   Drop Proc pCreateOrTruncateStagingTable;
go
If Exists(Select * from Sys.objects where Name = 'pETLImportDataIntoStagingTables')
   Drop Proc pETLImportDataIntoStagingTables;
go
If Exists(Select * from Sys.objects where Name = 'pCreateAndUpdateCombinedStagingTable')
   Drop Proc pCreateAndUpdateCombinedStagingTable;
go


Create Procedure pCreateOrTruncateStagingTable
/* Author: <ByungSu Jung>
** Desc: Flushes all date from the tables
** Change Log: When,Who,What
** 20189-01-17,<ByungSu Jung>,Created Sproc.
*/
AS
 Begin
  Declare @RC int = 0;
  Begin Try
    -- ETL Processing Code --
    If (Select Object_ID('stagingBellevue')) Is Not Null
		Truncate Table stagingBellevue
	Else
	 Create Table stagingBellevue(
		[Time] nvarchar(100),
		[Patient] nvarchar(100),
		[Doctor] nvarchar(100),
		[Procedure] nvarchar(100),
		[Charge] nvarchar(100)
     );
	 If (Select Object_ID('stagingKirkland')) Is Not Null
		Truncate Table stagingKirkland
	 Else
	 Create Table stagingKirkland(
		[Time] nvarchar(100),
		[Patient] nvarchar(100),
		[Clinic] nvarchar(100),
		[Doctor] nvarchar(100),
		[Procedure] nvarchar(100),
		[Charge] nvarchar(100)
	);
	If (Select Object_ID('stagingRedmond')) Is Not Null
		Truncate Table stagingRedmond
	Else
	 Create Table stagingRedmond(
		[Time] nvarchar(100),
		[Clinic] nvarchar(100),
		[Patient] nvarchar(100),
		[Doctor] nvarchar(100),
		[Procedure] nvarchar(100),
		[Charge] nvarchar(100)
	); 
   Set @RC = +1
  End Try
  Begin Catch
   Print Error_Message()
   Print 'Error in excuting pCreateOrTruncateStagingTable. Common error: incorrect variable type'
   Set @RC = -1
  End Catch
  Return @RC;
 End
go

Execute pCreateOrTruncateStagingTable;
Go
-------------- Create procedure and make sure to include errror message!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
-- Import data from different csv files into the tables created in tempdb. 

Create Procedure pETLImportDataIntoStagingTables
/* Author: <ByungSu Jung>
** Desc: Flushes all date from the tables
** Change Log: When,Who,What
** 20189-01-17,<ByungSu Jung>,Created Sproc.
*/
AS
 Begin
  Declare @RC int = 0;
  Begin Try   
	
	Bulk Insert 
	TempDB.dbo.stagingBellevue
	From 'C:\Users\jbsoo\Desktop\Info498\Info 498 Final\DataFiles\Bellevue\20100102Visits.csv'
	With(FirstRow = 2,Fieldterminator = ',',Rowterminator = '\n')

	Bulk Insert 
	TempDB.dbo.stagingKirkland
	From 'C:\Users\jbsoo\Desktop\Info498\Info 498 Final\DataFiles\Kirkland\20100102Visits.csv'
	With(FirstRow = 2,Fieldterminator = ',',Rowterminator = '\n')

	Bulk Insert 
	Tempdb.dbo.stagingRedmond
	From 'C:\Users\jbsoo\Desktop\Info498\Info 498 Final\DataFiles\Redmond\20100102Visits.csv'
	With(FirstRow = 2,Fieldterminator = ',',Rowterminator = '\n')
   Set @RC = +1
  End Try
  Begin Catch
   Print Error_Message()
   Print 'Error in excuting pETLImportDataIntoStagingTables. Common error: incorrect file name.'
   Set @RC = -1
  End Catch
  Return @RC;
 End
go

Execute pETLImportDataIntoStagingTables;
Go

-------------------------------------------------------------------------------------------------------------
Create Procedure pCreateAndUpdateCombinedStagingTable
/* Author: <ByungSu Jung>
** Desc: Flushes all date from the tables
** Change Log: When,Who,What
** 20189-01-17,<ByungSu Jung>,Created Sproc.
*/
AS
 Begin
  Declare @RC int = 0;
  Begin Try   

	--------------------Create combine table -----------------
	If (Select Object_ID('stagingCombined')) Is Not Null
		Drop Table stagingCombined
	Create Table stagingCombined(
	[Time] nvarchar(100),
	[Clinic] nvarchar(100),
	[Patient] nvarchar(100),
	[Doctor] nvarchar(100),
	[Procedure] nvarchar(100),
	[Charge] nvarchar(100)
	)
	Insert Into stagingCombined
	([Time], [Clinic], [Patient], [Doctor], [Procedure], [Charge])
	Select 
	[Time], [Clinic], [Patient], [Doctor], [Procedure], [Charge]
	From tempdb.dbo.stagingRedmond;

	Insert Into stagingCombined
	([Time], [Clinic], [Patient], [Doctor], [Procedure], [Charge])
	Select 
	[Time], [Clinic] = '1', [Patient], [Doctor], [Procedure], [Charge]
	From tempdb.dbo.stagingBellevue

	Insert Into stagingCombined
	([Time], [Clinic], [Patient], [Doctor], [Procedure], [Charge])
	Select 
	[Time], [Clinic], [Patient], [Doctor], [Procedure], [Charge]
	From tempdb.dbo.stagingKirkland

   Set @RC = +1
  End Try
  Begin Catch
   Print Error_Message()
   Print 'Error in excuting pCreateAndUpdateCombinedStagingTable. Common error: incorrect variable type.'
   Set @RC = -1
  End Catch
  Return @RC;
 End
go

Execute pCreateAndUpdateCombinedStagingTable;
Go
Select * From stagingCombined;
Go
------------------------------------------------------------------------------------------------------


/****** DoctorsSchedule.[dbo].[Clinics] ******/

--Use Patients;
--Go
If Exists(Select * from Sys.objects where Name = 'vETLVisit')
   Drop View vETLVisit;
go
If Exists(Select * from Sys.objects where Name = 'pETLSyncVisit')
   Drop Procedure pETLSyncVisit;
go

Create -- Drop 
View vETLVisit
/* Author: <ByungsuJung>
** Desc: Extracts and transforms data from stagingCombined to creat view.
** Change Log: When,Who,What
** 20189-01-17,<ByungsuJung>,Created Sproc.

*/
As
  SELECT
   [Date] = CONVERT(datetime, '2010-01-02' + ' '+ CONVERT(char(8), c.time, 108)), ----------------getdate?
   [Clinic] = Cast(c.Clinic as int) * 100,
   [Patient] = c.Patient, 
   [Doctor] = c.Doctor, 
   [Procedure] = c.[Procedure], 
   [Charge] = c.Charge
From tempdb.dbo.stagingCombined as c
Go

Select * From vETLVisit;
GO

Create Procedure pETLSyncVisit
/* Author: <ByungsuJung>
** Desc: Inserts data into FactOrders
** Change Log: When,Who,What
** 20189-01-17,<ByungsuJung>,Created Sproc.
*/
AS
 Begin
  Declare @RC int = 0;
  Begin Try
	Merge Into Patients.dbo.Visits as TargetTable
	Using vETLVisit as SourceTable
		On TargetTable.[Date] = SourceTable.[Date] And
		   TargetTable.[Clinic] = SourceTable.[Clinic] And
		   TargetTable.[Patient] = SourceTable.[Patient] And
		   TargetTable.[Doctor] = SourceTable.[Doctor] And
		   TargetTable.[Procedure] = SourceTable.[Procedure] And
		   TargetTable.[Charge] = SourceTable.[Charge]
		When Not Matched
			Then
			Insert
			Values (SourceTable.[Date], SourceTable.[Clinic], SourceTable.[Patient], SourceTable.[Doctor], SourceTable.[Procedure], SourceTable.[Charge])
		--When Matched
		--And SourceTable.[Date] <> TargetTable.[Date]
		--	Or SourceTable.[Clinic] <> TargetTable.[Clinic]
		--	Or SourceTable.[Patient] <> TargetTable.[Patient]
		--	Or SourceTable.[Doctor] <> TargetTable.[Doctor]
		--	Or SourceTable.[Procedure] <> TargetTable.[Procedure]
		--	Or SourceTable.[Charge] <> TargetTable.[Charge]
		--	Then
		--		Update
		--		Set TargetTable.[Date] = SourceTable.[Date] ,
		--			TargetTable.[Clinic] = SourceTable.[Clinic],
		--			TargetTable.[Patient] = SourceTable.[Patient],
		--			TargetTable.[Doctor] = SourceTable.[Doctor],
		--			TargetTable.[Procedure] = SourceTable.[Procedure],
		--			TargetTable.[Charge] = SourceTable.[Charge]
		--When Not Matched By Source
			--Then
				--Delete
   ;
   Set @RC = +1
  End Try
  Begin Catch
   Print Error_Message()
   Print 'Error in excuting pETLSyncVisit. Common error: incorrect column match.'
   Set @RC = -1
  End Catch
  Return @RC;
 End
go

-- Test
Execute pETLSyncVisit;
