/*************************************************************             
 ** File:   [MigrateEmployeeRecords]
 ** Author:   Vishal Suthar
 ** Description: This stored procedure is used to Migrate Employee Records
 ** Purpose:           
 ** Date:   18/01/2024

 ** PARAMETERS:

 ** RETURN VALUE:

 **************************************************************
  ** Change History
 **************************************************************
 ** PR   Date         Author			Change Description
 ** --   --------     -------			-----------------------
    1    18/01/2024   Vishal Suthar		Created
  

declare @p5 int
set @p5=NULL
declare @p6 int
set @p6=NULL
declare @p7 int
set @p7=NULL
declare @p8 int
set @p8=NULL
exec sp_executesql N'EXEC MigrateEmployeeRecords @FromMasterComanyID, @UserName, @Processed OUTPUT, @Migrated OUTPUT, @Failed OUTPUT, @Exists OUTPUT',N'@FromMasterComanyID int,@UserName nvarchar(12),@Processed int output,@Migrated int output,@Failed int output,@Exists int output',@FromMasterComanyID=12,@UserName=N'ROGER BENTLY',@Processed=@p5 output,@Migrated=@p6 output,@Failed=@p7 output,@Exists=@p8 output
select @p5, @p6, @p7, @p8
**************************************************************/
CREATE   PROCEDURE [dbo].[MigrateEmployeeRecords]
(
	@FromMasterComanyID INT = NULL,
	@UserName VARCHAR(100) NULL,
	@Processed INT OUTPUT,
	@Migrated INT OUTPUT,
	@Failed INT OUTPUT,
	@Exists INT OUTPUT
)
AS
BEGIN
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  SET NOCOUNT ON
  
    BEGIN TRY  
    BEGIN TRANSACTION  
    BEGIN
		DECLARE @LoopID AS INT;

		IF OBJECT_ID(N'tempdb..#TempEmployee') IS NOT NULL
		BEGIN
			DROP TABLE #TempEmployee
		END

		CREATE TABLE #TempEmployee
		(
			ID bigint NOT NULL IDENTITY,
			[SysUserId] [bigint] NOT NULL,
			[UserName] [varchar](100) NULL,
			[EmployeeCode] [varchar](100) NULL,
			[EmailAddress] [varchar](100) NULL,
			[PhoneNumber] [varchar](50) NULL,
			[FaxNumber] [varchar](50) NULL,
			[FirstName] [varchar](50) NULL,
			[MiddleName] [varchar](50) NULL,
			[LastName] [varchar](50) NULL,
			[EmailSignature] [varchar](500) NULL,
			[StartDate] [datetime2](7) NULL,
			[EndDate] [datetime2](7) NULL,
			[CustomerId] [bigint] NULL,
			[BirthPlace] [varchar](100) NULL,
			[BirthDate] [datetime2](7) NULL,
			[Nationality] [varchar](50) NULL,
			[HomeCountry] [varchar](50) NULL,
			[BurdenRate] [decimal](18, 2) NULL,
			[FixedOverhead] [decimal](18, 2) NULL,
			[UrlLink] [varchar](500) NULL,
			[MasterCompanyId] [bigint] NULL,
			[Migrated_Id] [bigint] NULL,
			[SuccessMsg] [varchar](500) NULL,
			[ErrorMsg] [varchar](500) NULL
		)

		INSERT INTO #TempEmployee ([SysUserId],[UserName],[EmployeeCode],[EmailAddress],[PhoneNumber],[FaxNumber],[FirstName],[MiddleName],[LastName],[EmailSignature],[StartDate],[EndDate],[CustomerId],
		[BirthPlace],[BirthDate],[Nationality],[HomeCountry],[BurdenRate],[FixedOverhead],[UrlLink],[MasterCompanyId],[Migrated_Id],[SuccessMsg],[ErrorMsg])
		SELECT [SysUserId],[UserName],[EmployeeCode],[EmailAddress],[PhoneNumber],[FaxNumber],[FirstName],[MiddleName],[LastName],[EmailSignature],[StartDate],[EndDate],[CustomerId],
		[BirthPlace],[BirthDate],[Nationality],[HomeCountry],[BurdenRate],[FixedOverhead],[UrlLink],[MasterCompanyId],[Migrated_Id],[SuccessMsg],[ErrorMsg] 
		FROM [Quantum_Staging].dbo.[Employees] EMP WITH (NOLOCK) WHERE EMP.Migrated_Id IS NULL;

		DECLARE @ProcessedRecords INT = 0;
		DECLARE @MigratedRecords INT = 0;
		DECLARE @RecordsWithError INT = 0;
		DECLARE @RecordExits INT = 0;

		DECLARE @TotCount AS INT;
		SELECT @TotCount = COUNT(*), @LoopID = MIN(ID) FROM #TempEmployee;

		WHILE (@LoopID <= @TotCount)
		BEGIN
			SET @ProcessedRecords = @ProcessedRecords + 1;

			DECLARE @EmpUserCode VARCHAR(100) = NULL;
			DECLARE @CurrentSysUserId BIGINT = 0;
			DECLARE @EmpexpertiseID as bigint = 1;
			DECLARE @JobTitleID as bigint = 1;
			DECLARE @MSID as bigint = 1;
			DECLARE @LegalentityID as bigint = 1;
			DECLARE @CurrencyID as bigint = 1;

			DECLARE @FoundError BIT = 0;
			DECLARE @ErrorMsg VARCHAR(MAX) = '';

			SELECT @EmpexpertiseID = EmployeeExpertiseId  FROM  [dbo].EmployeeExpertise WHERE MasterCompanyId = @FromMasterComanyID AND EmpExpCode = 'ADMIN';
			SELECT @JobTitleID = JobTitleId  FROM  [dbo].JobTitle WHERE MasterCompanyId = @FromMasterComanyID AND UPPER(JobTitleCode) = 'ADMINISTRATION';

			SELECT @CurrentSysUserId = SysUserId, @EmpUserCode = ISNULL(T.EmployeeCode, T.FirstName) FROM #TempEmployee AS T WHERE ID = @LoopID;

			IF (ISNULL(@EmpUserCode, '') = '')
			BEGIN
				SET @FoundError = 1;
				SET @ErrorMsg = @ErrorMsg + '<p>Employee Code is missing</p>'
			END
			
			IF (@FoundError = 1)
			BEGIN
				UPDATE EMPs
				SET EMPs.ErrorMsg = @ErrorMsg
				FROM [Quantum_Staging].DBO.[Employees] EMPs WHERE EMPs.SysUserId = @CurrentSysUserId;

				SET @RecordsWithError = @RecordsWithError + 1;
			END

			IF (@FoundError = 0)
			BEGIN
				IF NOT EXISTS (SELECT 1 FROM DBO.[Employee] WITH (NOLOCK) WHERE [EmployeeCode] = @EmpUserCode AND MasterCompanyId = @FromMasterComanyID)
				BEGIN
					DECLARE @EmployeeIdAsPerPayroll VARCHAR(100) = '';
					DECLARE @MasterCompnanyCode as varchar(10) = '';
					DECLARE @MasterCompnanyName as varchar(10) = '';
					DECLARE @HourlyPay DECIMAL(18, 2);
					DECLARE @AdminEmpID as bigint = 1;
					DECLARE @RoleID as bigint = 1;

					SELECT @HourlyPay = HourlyPay FROM [dbo].[Employee] WHERE Employeeid in (2);
					SELECT @EmpexpertiseID = EmployeeExpertiseId FROM [dbo].[EmployeeExpertise] WHERE EmpExpCode = 'TECHNICIAN';
					SELECT @EmployeeIdAsPerPayroll = MasterCompanyCode, @MasterCompnanyCode = MasterCompanyCode, @MasterCompnanyName = CompanyName FROM [dbo].[MasterCompany] WHERE MasterCompanyId = @FromMasterComanyID;

					INSERT INTO [dbo].[Employee]
						([EmployeeCode],[EmployeeIdAsPerPayroll],[FirstName],[LastName],[MiddleName],[JobTitleId],[EmployeeExpertiseId],[DateOfBirth],[StartDate],[MobilePhone],
						 [WorkPhone],[Fax],[Email],[SSN],[InMultipleShifts],[AllowOvertime],[AllowDoubleTime],[IsHourly],[HourlyPay],[EmployeeCertifyingStaff],[SupervisorId],
						 [MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[ManagementStructureId],[LegalEntityId],[Memo],[CurrencyId],[StationId],[AttachmentId])
					SELECT T.EmployeeCode, @EmployeeIdAsPerPayroll , ISNULL(T.FirstName, ''), ISNULL(T.LastName, ''), T.MiddleName, @JobTitleID, @EmpexpertiseID, GETDATE(), GETDATE(), ISNULL(T.PhoneNumber, ''),
						ISNULL(T.PhoneNumber, ''), '', ISNULL(T.EmailAddress, 'support@poweraerosuites.com'), NULL, 0, 0, 0, 0, @HourlyPay, 0, NULL,
						@FromMasterComanyID, @UserName, @UserName, GETDATE(), GETDATE(), 1, 0, @MSID, @LegalentityID, '', @CurrencyID, NULL, NULL
					FROM #TempEmployee AS T WHERE ID = @LoopID;

					SET @AdminEmpID = SCOPE_IDENTITY();

					IF NOT EXISTS (SELECT * FROM [DBO].[EmployeeExpertiseMapping] WHERE EmployeeId = @AdminEmpID AND EmployeeExpertiseIds = @EmpexpertiseID)
					BEGIN
						INSERT INTO [DBO].[EmployeeExpertiseMapping] ([EmployeeId],[EmployeeExpertiseIds],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted])
						VALUES
						(@AdminEmpID, @EmpexpertiseID, @FromMasterComanyID, @UserName, @UserName, GETDATE(), GETDATE(), 1, 0)
					END

					DECLARE @EmployeeCode VARCHAR(100) = '';
					SELECT @EmployeeCode = EmployeeCode FROM [dbo].[Employee] WHERE EmployeeId = @AdminEmpID;

					IF NOT EXISTS (SELECT * FROM [dbo].[EmployeeManagementStructure] WHERE EmployeeId = @AdminEmpID AND ManagementStructureId = @MSID)
					BEGIN
						INSERT INTO [dbo].[EmployeeManagementStructure]
							([EmployeeId],[ManagementStructureId],[MasterCompanyId],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[IsActive],[IsDeleted])
						VALUES
							(@AdminEmpID, @MSID, @FromMasterComanyID, @UserName, GETDATE(), @UserName, GETDATE(), 1, 0)
					END

					SELECT @RoleID = Id FROM [dbo].[UserRole] WHERE MasterCompanyId = @FromMasterComanyID AND [NAME]= 'Administrator';

					IF NOT EXISTS (SELECT * FROM [dbo].[EmployeeUserRole] WHERE EmployeeId = @AdminEmpID ANd RoleId = @RoleID)
					BEGIN
						INSERT INTO [dbo].[EmployeeUserRole] ([EmployeeId], [RoleId], [CreatedBy], [CreatedDate], [UpdatedBy], [UpdatedDate], [IsActive], [IsDeleted])
						VALUES (@AdminEmpID, @RoleID, @UserName, GETDATE(), @UserName, GETDATE(), 1, 0)        
					END

					IF NOT EXISTS (SELECT * FROM [dbo].[AspNetUsers] WHERE [EmployeeId] = @AdminEmpID AND MasterCompanyId = @FromMasterComanyID)
					BEGIN
						DECLARE @PasswordHash NVARCHAR(MAX);
						SELECT @PasswordHash = [PasswordHash] FROM dbo.AspNetUsers WHERE MasterCompanyId = @FromMasterComanyID AND JobTitle = 'ADMIN';

						INSERT INTO [dbo].[AspNetUsers]
							([Id], [AccessFailedCount], [ConcurrencyStamp], [Configuration], [CreatedBy], [CreatedDate], [Email], [EmailConfirmed], [FullName], [IsEnabled], [JobTitle], [LockoutEnabled],
							[LockoutEnd], [NormalizedEmail], [NormalizedUserName], [PasswordHash], [PhoneNumber], [PhoneNumberConfirmed], [SecurityStamp], [TwoFactorEnabled], [UpdatedBy], [UpdatedDate],
							[UserName], [EmployeeId], [IsResetPassword],[MasterCompanyId])
						SELECT NEWID(), 0, NEWID(),NULL, @UserName, GETDATE(), ISNULL(T.EmailAddress, 'support@poweraerosuites.com'), 1, (T.FirstName + ' ' + T.LastName), 1, 'TECHNICIAN', 1,
							NULL, UPPER(ISNULL(T.EmailAddress, 'support@poweraerosuites.com')), @MasterCompnanyCode + '-' + UPPER(T.UserName), @PasswordHash, ISNULL(T.PhoneNumber, 0), 0, NEWID(), 0, @UserName, GETDATE(),
							@MasterCompnanyCode + '-' + T.UserName, @AdminEmpID, 1, @FromMasterComanyID 
							FROM #TempEmployee AS T WHERE ID = @LoopID;
					END

					IF NOT EXISTS (SELECT * FROM [dbo].[EmployeeManagementStructureDetails] WHERE MasterCompanyId = @FromMasterComanyID AND ReferenceID = (SELECT EmployeeId FROM [DBO].[Employee] WHERE EmployeeCode = @EmployeeCode AND MasterCompanyId = @FromMasterComanyID))
					BEGIN
						DECLARE @EntityStructureId BIGINT = NULL;
						SELECT TOP 1 @EntityStructureId = EntityStructureId FROM dbo.EntityStructureSetup ES WITH (NOLOCK) WHERE ES.MasterCompanyId = @FromMasterComanyID;

						INSERT INTO [dbo].[EmployeeManagementStructureDetails] ([ModuleID],[ReferenceID],[EntityMSID],[Level1Id],[Level1Name],[Level2Id],[Level2Name],[Level3Id],[Level3Name],[Level4Id],[Level4Name],[Level5Id],[Level5Name],[Level6Id],[Level6Name],
						[Level7Id],[Level7Name],[Level8Id],[Level8Name],[Level9Id],[Level9Name],[Level10Id],[Level10Name],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[LastMSLevel],[AllMSlevels])
	    
						SELECT (SELECT ManagementStructureModuleId FROM [DBO].[ManagementStructureModule] WHERE ModuleName = 'EmployeeGeneralInfo'),
						@AdminEmpID, @EntityStructureId,
						(SELECT ID FROM [DBO].[ManagementStructureLevel] WHERE Code = @MasterCompnanyCode AND MasterCompanyId = @FromMasterComanyID),
						(SELECT (Code + '-' + Description) FROM [DBO].[ManagementStructureLevel] WHERE Code = @MasterCompnanyCode AND MasterCompanyId = @FromMasterComanyID),
						(SELECT ID FROM [DBO].[ManagementStructureLevel] WHERE Code = '1000' AND MasterCompanyId = @FromMasterComanyID),
						(SELECT (Code + '-' + Description) FROM [DBO].[ManagementStructureLevel] WHERE Code = '1000' AND MasterCompanyId = @FromMasterComanyID),
						NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
						@FromMasterComanyID, @UserName, @UserName, GETDATE(), GETDATE(), 1, 0,
						(SELECT (Code + '-' + Description) FROM [DBO].[ManagementStructureLevel] WHERE Code = '1000' AND MasterCompanyId = @FromMasterComanyID),
						('<p> LE :  '+ @MasterCompnanyCode + '-' + @MasterCompnanyName + '</p><p> BU :   1000 - MRO</p>')
					END

					UPDATE EMPs
					SET EMPs.Migrated_Id = @AdminEmpID,
					EMPs.SuccessMsg = 'Record migrated successfully'
					FROM [Quantum_Staging].DBO.Employees EMPs WHERE EMPs.SysUserId = @CurrentSysUserId;

					SET @MigratedRecords = @MigratedRecords + 1;
				END
				ELSE
				BEGIN
					UPDATE IMs
					SET IMs.ErrorMsg = ISNULL(@ErrorMsg, '') + '<p>Employee record already exists</p>'
					FROM [Quantum_Staging].DBO.ItemMasters IMs WHERE IMs.ItemMasterId = @CurrentSysUserId;

					SET @RecordExits = @RecordExits + 1;
				END
			END

			SET @LoopID = @LoopID + 1;
		END
	END

	COMMIT TRANSACTION

	SET @Processed = @ProcessedRecords;
	SET @Migrated = @MigratedRecords;
	SET @Failed = @RecordsWithError;
	SET @Exists = @RecordExits;

	SELECT @Processed, @Migrated, @Failed, @Exists;
  END TRY
  BEGIN CATCH
    IF @@trancount > 0
	  ROLLBACK TRAN;
	  SELECT
    ERROR_NUMBER() AS ErrorNumber,
    ERROR_STATE() AS ErrorState,
    ERROR_SEVERITY() AS ErrorSeverity,
    ERROR_PROCEDURE() AS ErrorProcedure,
    ERROR_LINE() AS ErrorLine,
    ERROR_MESSAGE() AS ErrorMessage;
	  DECLARE @ErrorLogID int
	  ,@DatabaseName varchar(100) = DB_NAME()
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE---------------------------------------
	  ,@AdhocComments varchar(150) = 'MigrateItemMasterRecords'
	  ,@ProcedureParameters varchar(3000) = '@Parameter1 = ' + ISNULL(CAST(@FromMasterComanyID AS VARCHAR(10)), '') + ''
	  ,@ApplicationName varchar(100) = 'PAS'
	  -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
	  RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)  
	  RETURN (1);  
	 END CATCH  
END