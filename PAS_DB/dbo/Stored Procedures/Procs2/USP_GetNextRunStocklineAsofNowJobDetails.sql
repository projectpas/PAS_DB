/*************************************************************             
 ** File:  [USP_GetNextRunStocklineAsofNowJobDetails]
 ** Author:  Moin Bloch  
 ** Description: This stored procedure is used to get Next Stockline As of Now Job Details
 ** Purpose:           
 ** Date:   11/09/2025            
 ** PARAMETERS:            
 ** RETURN VALUE:             
 **************************************************************             
 ** Change History             
 **************************************************************             
 ** PR   Date         Author		Change Description              
 ** --   --------     -------		--------------------------------            
    1    11/09/2025   MOIN BLOCH		Created  
	2    25/09/2025   MOIN BLOCH		added GroupById
	3    03/10/2025   MOIN BLOCH		Updated Datatype of ExecutionDate & Added New Fields
	4    28/11/2025   Devendra Shekh	Passed '0' as [TagType]
	5    13/02/2026   Devendra Shekh	Added IsRunDaily
	6    18/02/2026   Devendra Shekh	Added NextDayDate
	7    12/08/2026   Vishal Suthar		Avoid NULL RunDate/NextDayDate in None branch (was causing "Nullable object must have a value" in app)

--  EXEC [dbo].[USP_GetNextRunStocklineAsofNowJobDetails] 1
************************************************************************/    
CREATE   PROCEDURE [dbo].[USP_GetNextRunStocklineAsofNowJobDetails]
@MasterCompanyId INT=NULL,
@ReportType INT=NULL
AS
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;   
 BEGIN TRY  
	    DECLARE @Monthly INT = 1;
		DECLARE @Weekly INT = 2;
		DECLARE @None INT = 0;
		DECLARE @IsWeeklyOrMonthly INT= NULL;
		DECLARE @ExecutionDate INT = NULL;
		DECLARE @RunDate DATE = NULL;
		DECLARE @StartDate DATE = NULL;	
		DECLARE @NextRunDate DATE = NULL;
		DECLARE @NextMonthDate DATE = NULL;
		DECLARE @NextDayDate DATE = NULL;
		DECLARE @WeeklyName VARCHAR(10) = NULL;
		DECLARE @Id BIGINT= NULL;
		DECLARE @DayOfMonth INT = 0;
		DECLARE @HasJobSetting BIT = 0;
		DECLARE @ExcludedLocations NVARCHAR(500) = NULL
		DECLARE @MSLevel NVARCHAR(500) = NULL
		DECLARE @Location NVARCHAR(500) = NULL
		DECLARE @ManagementStructureId BIGINT = NULL
		DECLARE @GroupById INT = 0 
		DECLARE @ViewType VARCHAR(20) = NULL
		DECLARE @IsInvoice BIT = 0,@IsCredits BIT = 0,@IsDeposit BIT = 0,@IsUnappliedAmounts BIT = 0,@IsRunDaily BIT = 0;

		SELECT @Id = [Id],
		  	   @IsWeeklyOrMonthly = ISNULL([IsWeeklyOrMonthly],0),
		       @ExecutionDate = [ExecutionDate],
			   @WeeklyName = [WeeklyName],
			   @ExcludedLocations = ISNULL([ExcludedLocations],''),
			   @MSLevel = ISNULL(Level1Ids, '') + '!' + 
			              ISNULL(Level2Ids, '') + '!' + 
						  ISNULL(Level3Ids, '') + '!' + 
						  ISNULL(Level4Ids, '') + '!' +
						  ISNULL(Level5Ids, '') + '!' +
						  ISNULL(Level6Ids, '') + '!' +
						  ISNULL(Level7Ids, '') + '!' +
						  ISNULL(Level8Ids, '') + '!' +
						  ISNULL(Level9Ids, '') + '!' +
						  ISNULL(Level10Ids, ''),
			  @Location = ISNULL(SiteIds, '') + '!' + 
			             ISNULL(WarehouseIds, '') + '!' + 
						 ISNULL(LocationIds, '') + '!' + 
						 ISNULL(ShelfIds, '') + '!' + 
						 ISNULL(BinIds, ''), 
			  @ManagementStructureId = [ManagementStructureId],
			  @GroupById = ISNULL([GroupById],0),
			  @ViewType = [ViewType],
			  @IsInvoice =  ISNULL([IsInvoice],0), 
			  @IsCredits =  ISNULL([IsCredits],0), 
			  @IsDeposit =  ISNULL([IsDeposit],0), 
			  @IsUnappliedAmounts =  ISNULL([IsUnappliedAmounts],0),
			  @IsRunDaily =  ISNULL([IsRunDaily],0)
		FROM [dbo].[AsOfDateSettings] WITH(NOLOCK)
	   WHERE [MasterCompanyId] = @MasterCompanyId
		 AND [ReportType] = @ReportType  

	    IF(@Id > 0)
		BEGIN
			IF(@IsWeeklyOrMonthly = @Monthly)
			BEGIN
				SET @DayOfMonth = @ExecutionDate 	
				SET @RunDate = DATEFROMPARTS(YEAR(GETUTCDATE()), MONTH(GETUTCDATE()), @DayOfMonth);
				SET @StartDate = DATEADD(MONTH, -1, @RunDate);
				SET @NextMonthDate = DATEADD(MONTH, 1, @RunDate);
				SET @NextDayDate = DATEADD(DAY, 1, GETUTCDATE());
				SET @HasJobSetting = 1
			END
			IF(@IsWeeklyOrMonthly = @Weekly)
			BEGIN				
				;WITH WeekDays AS
				(
					SELECT d = DATEADD(DAY, v.number, DATEADD(WEEK, DATEDIFF(WEEK, 0, GETUTCDATE()), 0))
					FROM master.dbo.spt_values v
					WHERE v.type = 'P' AND v.number BETWEEN 0 AND 6
				)
				SELECT TOP 1 @RunDate = d FROM WeekDays WHERE DATENAME(WEEKDAY, d) = @WeeklyName;

				SET @StartDate = DATEADD(WEEK, -1, @RunDate);
				SET @NextMonthDate = DATEADD(WEEK, 1, @RunDate);				
				SET @NextDayDate = DATEADD(DAY, 1, GETUTCDATE());				
				SET @HasJobSetting = 1;
			END
			IF(@IsWeeklyOrMonthly = @None)
			BEGIN
			    SET @StartDate = NULL;
				SET @RunDate = GETUTCDATE();
				SET @NextMonthDate = NULL;
				SET @NextDayDate = DATEADD(DAY, 1, GETUTCDATE());
				SET @HasJobSetting = 0;
			END
		END
		ELSE
		BEGIN
			SET @RunDate = GETUTCDATE();
			SET @NextDayDate = DATEADD(DAY, 1, GETUTCDATE());
			SET @HasJobSetting = 0;
		END

		SELECT @StartDate [StartDate],
		       @RunDate [RunDate],
			   @NextMonthDate [NextRunDate],
			   @HasJobSetting [HasJobSetting],
			   CASE WHEN @IsWeeklyOrMonthly IN (@Monthly, @Weekly)
			             AND CAST(@RunDate AS DATE) = CAST(GETUTCDATE() AS DATE)
			        THEN 1 ELSE 0 END [IsRunJob],
			   @ExcludedLocations [ExcludedLocations],
			   @MSLevel [MSLevel],
			   @Location [Location],
			   '0' [TagType],			   
			   1  [IsCustomerStock],
			   @ManagementStructureId [ManagementStructureId],
			   @GroupById [GroupById],
			   @ViewType  [ViewType],
			   @IsInvoice [IsInvoice], 
			   @IsCredits [IsCredits], 
			   @IsDeposit [IsDeposit], 
			   @IsUnappliedAmounts [IsUnappliedAmounts],
			   @IsRunDaily [IsRunDaily],
			   @NextDayDate [NextDayDate]
 END TRY   
 BEGIN CATCH        
  IF @@trancount > 0  
  PRINT 'ROLLBACK'      
	SELECT
    ERROR_NUMBER() AS ErrorNumber,
    ERROR_STATE() AS ErrorState,
    ERROR_SEVERITY() AS ErrorSeverity,
    ERROR_PROCEDURE() AS ErrorProcedure,
    ERROR_LINE() AS ErrorLine,
    ERROR_MESSAGE() AS ErrorMessage;
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'USP_GetNextRunStocklineAsofNowJobDetails'   
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ CAST(ISNULL('', '') AS VARCHAR(100))              
             + '@Parameter4 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(100))              
              , @ApplicationName VARCHAR(100) = 'PAS'  
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------------------------------------  
              exec spLogException   
                       @DatabaseName           = @DatabaseName  
                     , @AdhocComments          = @AdhocComments  
                     , @ProcedureParameters    = @ProcedureParameters  
                     , @ApplicationName        =  @ApplicationName  
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;  
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)  
              RETURN(1);  
 END CATCH  
END