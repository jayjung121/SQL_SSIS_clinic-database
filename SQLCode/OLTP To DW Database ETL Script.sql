/***************************************************************************
Info498 Final Project
Dev: Byungsu Jung
Date:2/21/2017
Desc: This file syncronize OLTP and OLAP. The flush and fill technique is used.
-- Change Log: When,Who,What
-- 08/15/2018,ByungsuJung,Created File..
*****************************************************************************/

Use [DWClinicReportData]
SET NoCount ON;
go
----------------- Drop views and procedures if exist. ----------------------
	If Exists(Select * from Sys.objects where Name = 'pETLDropForeignKeyConstraints')
   Drop Procedure pETLDropForeignKeyConstraints;
go
	If Exists(Select * from Sys.objects where Name = 'pETLTruncateTables')
   Drop Procedure pETLTruncateTables;
go
	If Exists(Select * from Sys.objects where Name = 'vETLDimClinics')
   Drop View vETLDimClinics;
go
	If Exists(Select * from Sys.objects where Name = 'pETLFillDimClinics')
   Drop Procedure pETLFillDimClinics;
go
	If Exists(Select * from Sys.objects where Name = 'vETLDimDoctors')
   Drop View vETLDimDoctors;
go
	If Exists(Select * from Sys.objects where Name = 'pETLFillDimDoctors')
   Drop Procedure pETLFillDimDoctors;
go
	If Exists(Select * from Sys.objects where Name = 'pETLFillDimDates')
   Drop Procedure pETLFillDimDates;
go
	If Exists(Select * from Sys.objects where Name = 'vETLDimPatients')
   Drop View vETLDimPatients;
go
	If Exists(Select * from Sys.objects where Name = 'pETLFillDimPatients')
   Drop Procedure pETLFillDimPatients;
go
	If Exists(Select * from Sys.objects where Name = 'vETLDimProcedures')
   Drop View vETLDimProcedures;
go
	If Exists(Select * from Sys.objects where Name = 'pETLFillDimProcedures')
   Drop Procedure pETLFillDimProcedures;
go
	If Exists(Select * from Sys.objects where Name = 'vETLDimShifts')
   Drop View vETLDimShifts;
go
	If Exists(Select * from Sys.objects where Name = 'pETLFillDimShifts')
   Drop Procedure pETLFillDimShifts;
go
	If Exists(Select * from Sys.objects where Name = 'vETLFactDoctorShifts')
   Drop View vETLFactDoctorShifts;
go
	If Exists(Select * from Sys.objects where Name = 'pETLFillFactDoctorShifts')
   Drop Procedure pETLFillFactDoctorShifts;
go
	If Exists(Select * from Sys.objects where Name = 'vETLFactVisits')
   Drop View vETLFactVisits;
go
	If Exists(Select * from Sys.objects where Name = 'pETLFillFactVisits')
   Drop Procedure pETLFillFactVisits;
go
	If Exists(Select * from Sys.objects where Name = 'pETLAddForeignKeyConstraints')
   Drop Procedure pETLAddForeignKeyConstraints;
go

-------------------------------- Drop foreignkey constraint ------------------------------------
Create Procedure pETLDropForeignKeyConstraints
/* Author: <ByungSu Jung>
** Desc: Removed FKs before truncation of the tables
** Change Log: When,Who,What
** 08/15/2018,<ByungSu Jung>,Created Sproc.
*/
AS
 Begin
  Declare @RC int = 0;
  Begin Try

-----------------FactVisit------------------------

    Alter Table [DWClinicReportData].dbo.FactVisits
	  Drop Constraint fkFactVisitsToDimClinics; 
	
	Alter Table DWClinicReportData.dbo.FactVisits
	  Drop Constraint fkFactVisitsToDimDates

    Alter Table [DWClinicReportData].dbo.FactVisits
	   Drop Constraint fkFactVisitsToDimDoctors;

    Alter Table [DWClinicReportData].dbo.FactVisits
	   Drop Constraint fkFactVisitsToDimPatients;

	Alter Table [DWClinicReportData].dbo.FactVisits
	   Drop Constraint [fkFactVisitsToDimProcedures];

------------- FactDoctorShifts--------------------

    Alter Table [DWClinicReportData].dbo.FactDoctorShifts
	   Drop Constraint fkFactDoctorShiftsToDimClinics;

    Alter Table [DWClinicReportData].dbo.FactDoctorShifts
	   Drop Constraint [fkFactDoctorShiftsToDimDates];

	Alter Table [DWClinicReportData].dbo.FactDoctorShifts
	   Drop Constraint fkFactDoctorShiftsToDimDoctors;

	Alter Table [DWClinicReportData].dbo.FactDoctorShifts
	   Drop Constraint fkFactDoctorShiftsToDimShifts;
   Set @RC = +1
  End Try
  Begin Catch
   Print Error_Message()
   Set @RC = -1
  End Catch
  Return @RC;
 End
go

-------------------------------------- Truncate ----------------------------------
Create Procedure pETLTruncateTables
/* Author: <ByungSu Jung>
** Desc: Flushes all date from the tables
** Change Log: When,Who,What
** 08/15/2018,<ByungSu Jung>,Created Sproc.
*/
AS
 Begin
  Declare @RC int = 0;
  Begin Try
    -- ETL Processing Code --
    Truncate Table DWClinicReportData.dbo.DimClinics
    Truncate Table DWClinicReportData.dbo.DimDates
    Truncate Table DWClinicReportData.dbo.DimDoctors
    Truncate Table DWClinicReportData.dbo.DimPatients
    Truncate Table DWClinicReportData.dbo.DimProcedures
    Truncate Table DWClinicReportData.dbo.DimShifts
    Truncate Table DWClinicReportData.dbo.FactDoctorShifts
    Truncate Table DWClinicReportData.[dbo].[FactVisits]
   Set @RC = +1
  End Try
  Begin Catch
   Print Error_Message()
   Set @RC = -1
  End Catch
  Return @RC;
 End
go


------------------------------------ Clinics--------------------------------
Create View vETLDimClinics
/* Author: <ByungsuJung>
** Desc: Extracts and transforms data for DimClinics
** Change Log: When,Who,What
** 08/15/2018,<ByungsuJung>,Created Sproc.
*/
As
  Select
   [ClinicID] = c.ClinicID, 
   [ClinicName] = Cast(IsNull(c.ClinicName, 'Missing Data') as nvarchar(100)), 
   [ClinicCity] = Cast(IsNull(c.City, 'Missing Data') as nvarchar(100)), 
   [ClinicState] = Cast(IsNull(c.State, 'Missing Data') as nvarchar(100)), 
   [ClinicZip] = Cast(IsNull(c.Zip, 'Missing Data') as nvarchar(100))
  FROM DoctorsSchedules.dbo.Clinics as c
go

Create Procedure pETLFillDimClinics
/* Author: <ByungSu Jung>
** Desc: Inserts data into DimClinics using the vETLDimClinics view
** Change Log: When,Who,What
** 08/15/2018,<ByungSu Jung>,Created Sproc.
*/
AS
 Begin
  Declare @RC int = 0;
  Begin Try
    -- ETL Processing Code --
    IF ((Select Count(*) From DimClinics) = 0)
     Begin
      INSERT INTO DWClinicReportData.dbo.DimClinics
       ([ClinicID], [ClinicName], [ClinicCity], [ClinicState], [ClinicZip])
      Select
	   [ClinicID], [ClinicName], [ClinicCity], [ClinicState], [ClinicZip]
      FROM vETLDimClinics
    End
   Set @RC = +1
  End Try
  Begin Catch
   Print Error_Message()
   Set @RC = -1
  End Catch
  Return @RC;
 End
go

------------------------------------Doctors--------------------------------

Create View vETLDimDoctors
/* Author: <ByungsuJung>
** Desc: Extracts and transforms data for DimDoctors
** Change Log: When,Who,What
** 08/15/2018,<ByungsuJung>,Created Sproc.
**
*/
As
  Select
   [DoctorID] = Cast(IsNull(d.DoctorID, 'Missing Data') as nvarchar(100)), 
   [DoctorFullName] =  Cast(IsNull(d.FirstName + d.LastName, 'Missing Data') as nvarchar(100)), 
   [DoctorEmailAddress] = Cast(IsNull(d.EmailAddress, 'Missing Data') as nvarchar(100)), 
   [DoctorCity] = Cast(IsNull(d.City, 'Missing Data') as nvarchar(100)), 
   [DoctorState] = Cast(IsNull(d.State, 'Missing Data') as nvarchar(100)), 
   [DoctorZip] = Cast(IsNull(d.Zip, 'Missing Data') as nvarchar(100))
  FROM DoctorsSchedules.dbo.Doctors as d
go

Create Procedure pETLFillDimDoctors
/* Author: <ByungSu Jung>
** Desc: Inserts data into DimDoctors using the vETLDimDoctors view
** Change Log: When,Who,What
** 08/15/2018,<ByungSu Jung>,Created Sproc.
*/
AS
 Begin
  Declare @RC int = 0;
  Begin Try
    -- ETL Processing Code --
    IF ((Select Count(*) From DimDoctors) = 0)
     Begin
      INSERT INTO DWClinicReportData.dbo.DimDoctors
       ([DoctorID], [DoctorFullName], [DoctorEmailAddress], [DoctorCity], [DoctorState], [DoctorZip])
      Select
	   [DoctorID], [DoctorFullName], [DoctorEmailAddress], [DoctorCity], [DoctorState], [DoctorZip]
      FROM vETLDimDoctors
    End
   Set @RC = +1
  End Try
  Begin Catch
   Print Error_Message()
   Set @RC = -1
  End Catch
  Return @RC;
 End
go

------------------------------------ Patients--------------------------------
Create View vETLDimPatients
/* Author: <ByungsuJung>
** Desc: Extracts and transforms data for DimPatients
** Change Log: When,Who,What
** 08/15/2018,<ByungsuJung>,Created Sproc.
Cast(IsNull(c.ClinicName, 'Missing Data') as nvarchar(100))
*/
As
  Select
   [PatientID] = p.ID, 
   [PatientFullName] = Cast(IsNull(p.FName + p.LName, 'Missing Data') as nvarchar(100)), 
   [PatientCity] = Cast(IsNull(p.City, 'Missing Data') as nvarchar(100)), 
   [PatientState] = Cast(IsNull(p.State, 'Missing Data') as nvarchar(100)), 
   [PatientZipCode] = Cast(IsNull(p.ZipCode, 0) as int)
  FROM Patients.dbo.Patients as p

go

	---- ETL Processing Code --
 --   IF ((Select Count(*) From DimPatients) = 0)
 --    Begin
 --     INSERT INTO DWClinicReportData.dbo.DimPatients
 --      ([PatientID], [PatientFullName], [PatientCity], [PatientState], [PatientZipCode], [StartDate], [EndDate], [IsCurrent])
 --     Select
	--   [PatientID], 
	--   [PatientFullName], 
	--   [PatientCity], 
	--   [PatientState], 
	--   [PatientZipCode], 
	--   [StartDate] = getdate(), 
	--   [EndDate] = Null, 
	--   [IsCurrent] = 1
 --     FROM vETLDimPatients
Create Procedure pETLFillDimPatients
/* Author: <ByungSu Jung>
** Desc: Inserts data into DimPatients using the vETLDimPatients view ------------------------------Incremental use it
** Change Log: When,Who,What
** 08/15/2018,<ByungSu Jung>,Created Sproc.
*/
AS
 Begin
  Declare @RC int = 0;
  Begin Try
   With ChangedPatients
   As(
      Select [PatientID], [PatientFullName], [PatientCity], [PatientState], [PatientZipCode] From vETLDimPatients
	  Except 
	  Select [PatientID], [PatientFullName], [PatientCity], [PatientState], [PatientZipCode] From DimPatients
    Where IsCurrent = 1
   )UPDATE DWClinicReportData.dbo.DimPatients
   Set EndDate = Convert(nvarchar(50), GetDate(), 112) 
      ,IsCurrent = 0
   Where PatientID IN (Select PatientID From ChangedPatients)
   ;
    -- 2) For INSERT or UPDATES: Add new rows to the table
		With AddedORChangedPatients
		As(
      Select [PatientID], [PatientFullName], [PatientCity], [PatientState], [PatientZipCode] From vETLDimPatients
	  Except 
	  Select [PatientID], [PatientFullName], [PatientCity], [PatientState], [PatientZipCode] From DimPatients
	  Where IsCurrent = 1
	)INSERT INTO DWClinicReportData.dbo.DimPatients
      ([PatientID], [PatientFullName], [PatientCity], [PatientState], [PatientZipCode],[StartDate],[EndDate],[IsCurrent])
      SELECT
        [PatientID], 
		[PatientFullName], 
		[PatientCity], 
		[PatientState], 
		[PatientZipCode]
       ,[StartDate] = Convert(nvarchar(50), GetDate(), 112)
       ,[EndDate] = Null
       ,[IsCurrent] = 1
      FROM vETLDimPatients
      WHERE PatientID IN (Select PatientID From AddedORChangedPatients)
    ;
	With DeletedPatients
		As(
			Select [PatientID], [PatientFullName], [PatientCity], [PatientState], [PatientZipCode] From DimPatients
       Where IsCurrent = 1 -- We do not care about row already marked zero!
 			Except            			
      Select [PatientID], [PatientFullName], [PatientCity], [PatientState], [PatientZipCode] From vETLDimPatients
   	)UPDATE DWClinicReportData.dbo.DimPatients
      SET EndDate = Convert(nvarchar(50), GetDate(), 112)
         ,IsCurrent = 0
       WHERE PatientID IN (Select PatientID From DeletedPatients)
   ;
   Set @RC = +1
  End Try
  Begin Catch
   Print Error_Message()
   Set @RC = -1
  End Catch
  Return @RC;
 End
go

------------------------------------ Procedure--------------------------------

Create View vETLDimProcedures
/* Author: <ByungsuJung>
** Desc: Extracts and transforms data for DimProcedures
** Change Log: When,Who,What
** 08/15/2018,<ByungsuJung>,Created Sproc.
*/
As
  Select
   [ProcedureID] = p.ID, 
   [ProcedureName] = Cast(IsNull(p.Name, 'Missing Data') as nvarchar(100)), 
   [ProcedureDesc] = Cast(IsNull(p.[Desc], 'Missing Data') as nvarchar(100)), 
   [ProcedureCharge] = Cast(IsNull(p.Charge, 0) as money)
  FROM Patients.dbo.Procedures as p
go

Create Procedure pETLFillDimProcedures
/* Author: <ByungSu Jung>
** Desc: Inserts data into DimProcedures using the vETLDimProcedures view
** Change Log: When,Who,What
** 08/15/2018,<ByungSu Jung>,Created Sproc.
*/
AS
 Begin
  Declare @RC int = 0;
  Begin Try
    -- ETL Processing Code --
    IF ((Select Count(*) From DimProcedures) = 0)
     Begin
      INSERT INTO DWClinicReportData.dbo.DimProcedures
       ([ProcedureID], [ProcedureName], [ProcedureDesc], [ProcedureCharge])
      Select
	   [ProcedureID], 
	   [ProcedureName], 
	   [ProcedureDesc], 
	   [ProcedureCharge]
      FROM vETLDimProcedures
    End
   Set @RC = +1
  End Try
  Begin Catch
   Print Error_Message()
   Set @RC = -1
  End Catch
  Return @RC;
 End
go

------------------------------------ Shifts--------------------------------

Create View vETLDimShifts
/* Author: <ByungsuJung>
** Desc: Extracts and transforms data for DimShifts ------------- 1:00 is 1 pm
** Change Log: When,Who,What
** 08/15/2018,<ByungsuJung>,Created Sproc.
*/
As
 Select
  [ShiftID] = s.ShiftID,
  [ShiftStart] = Case When Cast(s.ShiftStart as time(0)) = '01:00:00' Then '13:00:00'
                 Else s.ShiftStart  
  End,
  [ShiftEnd] = Case When Cast(s.ShiftEnd as time(0)) = '05:00:00' Then '17:00:00'
                 Else s.ShiftEnd
  End
  FROM DoctorsSchedules.dbo.Shifts as s
go

Create Procedure pETLFillDimShifts
/* Author: <ByungSu Jung>
** Desc: Inserts data into DimShifts using the vETLDimShifts view
** Change Log: When,Who,What
** 08/15/2018,<ByungSu Jung>,Created Sproc.
*/
AS
 Begin
  Declare @RC int = 0;
  Begin Try
    -- ETL Processing Code --
    IF ((Select Count(*) From DimShifts) = 0)
     Begin
      INSERT INTO DWClinicReportData.dbo.DimShifts
       ([ShiftID], [ShiftStart], [ShiftEnd])
      Select
	   [ShiftID], 
	   [ShiftStart], 
	   [ShiftEnd]
      FROM vETLDimShifts
    End
   Set @RC = +1
  End Try
  Begin Catch
   Print Error_Message()
   Set @RC = -1
  End Catch
  Return @RC;
 End
go

/****** [dbo].[DimDates] ******/
Create Procedure pETLFillDimDates
/* Author: <ByungSu Jung>
** Desc: Inserts data into DimDates
** Change Log: When,Who,What
** 08/15/2018,<ByungSu Jung>,Created Sproc.
*/
AS
 Begin
  Declare @RC int = 0;
  Begin Try
    -- ETL Processing Code --
      Declare @StartDate datetime = '01/01/2000'
      Declare @EndDate datetime = '12/31/2020' 
      Declare @DateInProcess datetime  = @StartDate
      -- Loop through the dates until you reach the end date
	  Set Identity_Insert DimDates On
      While @DateInProcess <= @EndDate
       Begin
       -- Add a row into the date dimension table for this date
       Insert Into DWClinicReportData.dbo.DimDates 
        ([DateKey],[FullDate], [FullDateName], [MonthID], [MonthName], [YearID], [YearName])
       Values ( 
         Cast(Convert(nVarchar(50), @DateInProcess, 112) as int) -- [DateKey]
        ,@DateInProcess -- [FullDate]
        ,DateName(YEAR, @DateInProcess) + ' - ' + DateName(month, @DateInProcess) + ' - ' + DateName(DAY, @DateInProcess)-- [FullDateName]
        ,Cast(Month(@DateInProcess) as int) -- [MonthID]
		,DateName(month, @DateInProcess) + ' - ' + DateName(YYYY,@DateInProcess) -- [MonthName]
        ,Cast(Year(@DateInProcess) as int)  -- [YearID]
        ,Cast(Year(@DateInProcess ) as nVarchar(50)) -- [YearName] 
        )
		Set @DateInProcess = dateAdd(DAY, 1, @DateInProcess)
        End
   Set @RC = +1
  End Try
  Begin Catch
   Print Error_Message()
   Set @RC = -1
  End Catch
  Return @RC;
 End
go

 
------------------------------------ FactDoctorShifts--------------------------------

Create --drop 
View vETLFactDoctorShifts
/* Author: <ByungsuJung>
** Desc: Extracts and transforms data for FactDoctorShifts
** Change Log: When,Who,What
** 08/15/2018,<ByungsuJung>,Created Sproc.
*/
As
  Select
   [DoctorsShiftID] = ds.DoctorsShiftID,
   [ShiftDateKey] = d.DateKey,  -------------------------- fix it  Cast(Convert(ncarchar(100),[shiftdate],112)as int)
   [ClinicKey] = c.ClinicKey, -- cast as int
   [ShiftKey] = s.ShiftKey,  -- cast as int
   [DoctorKey] = doc.DoctorKey, -- cast as int
   [HoursWorked] = Cast(abs(DateDiff(HOUR, s.ShiftStart , s.ShiftEnd )) as int) -- Need to be fixed
   -- starttime endtime
   From DoctorsSchedules.dbo.DoctorShifts as ds
   Join DimClinics as c
   On ds.ClinicID = c.ClinicID
   Join DimDates as d
   On ds.ShiftDate = d.FullDate
   Join DimShifts as s
   On ds.ShiftID = s.ShiftID
   Join DimDoctors as doc
   On doc.DoctorID = ds.DoctorID
go

Create Procedure pETLFillFactDoctorShifts
/* Author: <ByungSu Jung>
** Desc: Inserts data into FactDoctorShifts using the vETLFactDoctorShifts view
** Change Log: When,Who,What
** 08/15/2018,<ByungSu Jung>,Created Sproc.
*/
AS
 Begin
  Declare @RC int = 0;
  Begin Try
    -- ETL Processing Code --
    IF ((Select Count(*) From FactDoctorShifts) = 0)
     Begin
      INSERT INTO DWClinicReportData.dbo.FactDoctorShifts
       ([DoctorsShiftID], [ShiftDateKey], [ClinicKey], [ShiftKey], [DoctorKey], [HoursWorked])  
      Select
	   [DoctorsShiftID], 
	   [ShiftDateKey], 
	   [ClinicKey], 
	   [ShiftKey], 
	   [DoctorKey], 
	   [HoursWorked]
      FROM vETLFactDoctorShifts
    End
   Set @RC = +1
  End Try
  Begin Catch
   Print Error_Message()
   Set @RC = -1
  End Catch
  Return @RC;
 End
go


------------------------------------ FactVisits--------------------------------------

Create -- Drop
View vETLFactVisits
/* Author: <ByungsuJung>
** Desc: Extracts and transforms data for FactDoctorShifts
** Change Log: When,Who,What
** 08/15/2018,<ByungsuJung>,Created Sproc.
*/
As
  Select top 10000000
   [VisitKey] = v.ID, 
   [DateKey] = d.DateKey, 
   [ClinicKey] = c.ClinicKey, 
   [PatientKey] = p.PatientKey, 
   [DoctorKey] = doc.DoctorKey, 
   [ProcedureKey] = pr.ProcedureKey, 
   [ProcedureVistCharge] = pr.ProcedureCharge
  From Patients.dbo.Visits as v
  Join DimClinics as c
  On v.Clinic = Cast(c.ClinicID as int) * 100
  Join DimDates as d
  On Cast(Convert(nvarchar(50), v.Date, 112) as int) = d.DateKey
  Join DimPatients as p
  On p.PatientID = v.Patient
  Join DimDoctors as doc
  On doc.DoctorID = v.Doctor
  Join DimProcedures as pr
  On pr.ProcedureID = v.[Procedure]
  Order by VisitKey
  --Group by 
  --v.ID, 
  --d.DateKey, 
  --c.ClinicKey, 
  --p.PatientKey, 
  --doc.DoctorKey, 
  --pr.ProcedureKey
Go


Create Procedure pETLFillFactVisits
/* Author: <ByungSu Jung>
** Desc: Inserts data into FactVisits using the vETLFactVisits view
** Change Log: When,Who,What
** 08/15/2018,<ByungSu Jung>,Created Sproc.
*/
AS
 Begin
  Declare @RC int = 0;
  Begin Try
    -- ETL Processing Code --
    IF ((Select Count(*) From FactVisits) = 0)
     Begin
      INSERT INTO DWClinicReportData.dbo.FactVisits
       ([VisitKey], [DateKey], [ClinicKey], [PatientKey], [DoctorKey], [ProcedureKey], [ProcedureVistCharge]) 
      Select
	   [VisitKey], 
	   [DateKey], 
	   [ClinicKey], 
	   [PatientKey], 
	   [DoctorKey], 
	   [ProcedureKey], 
	   [ProcedureVistCharge]
      FROM vETLFactVisits
    End
   Set @RC = +1
  End Try
  Begin Catch
   Print Error_Message()
   Set @RC = -1
  End Catch
  Return @RC;
 End
go


--------------------------------- Add Foreignkey constraints ------------------------

Create Procedure pETLAddForeignKeyConstraints
/* Author: <ByungSu Jung>
** Desc: Removed FKs before truncation of the tables
** Change Log: When,Who,What
** 08/15/2018,<ByungSu Jung>,Created Sproc.
*/
AS
 Begin
  Declare @RC int = 0;
  Begin Try
		 Alter Table [DWClinicReportData].dbo.FactVisits
		  Add Constraint fkFactVisitsToDimClinics
		  FOREIGN KEY (ClinicKey) REFERENCES DimClinics(ClinicKey);

		Alter Table DWClinicReportData.dbo.FactVisits
		  Add Constraint fkFactVisitsToDimDates
		  FOREIGN KEY (DateKey) REFERENCES DimDates(DateKey);

    Alter Table [DWClinicReportData].dbo.FactVisits
	   Add Constraint fkFactVisitsToDimDoctors
	   FOREIGN KEY (DoctorKey) REFERENCES DimDoctors(DoctorKey);

    Alter Table [DWClinicReportData].dbo.FactVisits
	   Add Constraint fkFactVisitsToDimPatients
	   FOREIGN KEY (PatientKey) REFERENCES DimPatients(PatientKey);

	Alter Table [DWClinicReportData].dbo.FactVisits
	   Add Constraint [fkFactVisitsToDimProcedures]
	   FOREIGN KEY (ProcedureKey) REFERENCES DimProcedures(ProcedureKey);

------------- FactDoctorShifts--------------------

    Alter Table [DWClinicReportData].dbo.FactDoctorShifts
	   Add Constraint fkFactDoctorShiftsToDimClinics
	   FOREIGN KEY (ClinicKey) REFERENCES DimClinics(ClinicKey);

    Alter Table [DWClinicReportData].dbo.FactDoctorShifts
	   Add Constraint fkFactDoctorShiftsToDimDates
	   FOREIGN KEY (ShiftDateKey) REFERENCES DimDates(DateKey);

	Alter Table [DWClinicReportData].dbo.FactDoctorShifts
	   Add Constraint fkFactDoctorShiftsToDimDoctors
	   FOREIGN KEY (DoctorKey) REFERENCES DimDoctors(DoctorKey);

	Alter Table [DWClinicReportData].dbo.FactDoctorShifts
	   Add Constraint fkFactDoctorShiftsToDimShifts
	   FOREIGN KEY (ShiftKey) REFERENCES DimShifts(ShiftKey);
   Set @RC = +1
  End Try
  Begin Catch
   Print Error_Message()
   Set @RC = -1
  End Catch
  Return @RC;
 End
go

--------------------------------------Excute procedures ------------------------------
Declare @Status int;

Exec @Status = pETLDropForeignKeyConstraints;
Select [Object] = 'pETLDropForeignKeyConstraints', [Status] = @Status;

Exec @Status = pETLTruncateTables;
Select [Object] = 'pETLTruncateTables', [Status] = @Status;

Exec @Status = pETLFillDimClinics;
Select [Object] = 'pETLFillDimClinics', [Status] = @Status;

Exec @Status = pETLFillDimDates;
Select [Object] = 'pETLFillDimDates', [Status] = @Status;

Exec @Status = pETLFillDimDoctors;
Select [Object] = 'pETLFillDimDoctors', [Status] = @Status;

Exec @Status = pETLFIllDImPatients;
Select [Object] = 'pETLFIllDimPatients', [Status] = @Status;

Exec @Status = pETLFIllDImProcedures;
Select [Object] = 'pETLFIllDimProcedures', [Status] = @Status;

Exec @Status = pETLFIllDimShifts;
Select [Object] = 'pETLFIllDimShifts', [Status] = @Status;

Exec @Status = pETLFillFactDoctorShifts;
Select [Object] = 'pETLFillFactDoctorShifts', [Status] = @Status;

Exec @Status = pETLFillFactVisits;
Select [Object] = 'pETLFillFactVisits', [Status] = @Status;

Exec @Status = pETLAddForeignKeyConstraints;
Select [Object] = 'pETLAddForeignKeyConstraints', [Status] = @Status;

Go




Select * From DWClinicReportData.dbo.DimClinics
Select * From DWClinicReportData.dbo.DimDates
Select * From DWClinicReportData.dbo.DimDoctors
Select * From DWClinicReportData.dbo.DimPatients
Select * From DWClinicReportData.dbo.DimProcedures
Select * From DWClinicReportData.dbo.DimShifts
Select * From DWClinicReportData.dbo.FactDoctorShifts
Select * From DWClinicReportData.[dbo].[FactVisits]
