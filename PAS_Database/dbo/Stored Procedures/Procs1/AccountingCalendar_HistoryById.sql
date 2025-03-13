/***************************************************************  
 ** File:   [AccountingCalendar_HistoryById]             
 ** Author:   Unknown
 ** Description: This stored procedure is used to Get Accounting Calendar History List
 ** Date:  Unknown
            
  ** Change History             
 **************************************************************             
 ** PR   Date				Author  				Change Description              
 ** --   --------			-------				--------------------------------            
    1    ***********		Unknown				Created
    2    05-Mar-2025		Divyesh Kathiriya	Update CreatedDate and UpdateDate based on Employee time zone 
		
	exec dbo.AccountingCalendar_HistoryById @AccReferenceId=314,@TableName=N'Inventory',@PeriodName=N'MAR - 2025',@EmployeeId=226
**************************************************************/


CREATE     PROCEDURE [dbo].[AccountingCalendar_HistoryById]
@AccReferenceId int,
@TableName varchar(100),
@PeriodName varchar(256),
@EmployeeId bigint
 
--select * from AccountingCalendarHistory

AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN 
			DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
				
			SELECT 
					@CurrntEmpTimeZoneDesc = COALESCE(
						ETZ.[Description],  -- Prefer Employee's TimeZone description if available
						LTZ.[Description]   -- Fallback to LegalEntity's TimeZone description
					)
				FROM 
					dbo.Employee E WITH (NOLOCK) 
				LEFT JOIN 
					dbo.TimeZone ETZ WITH (NOLOCK) 
					ON E.TimeZoneId = ETZ.TimeZoneId
				LEFT JOIN 
					dbo.LegalEntity LE WITH (NOLOCK) 
					ON E.LegalEntityId = LE.LegalEntityId
				LEFT JOIN 
					dbo.TimeZone LTZ WITH (NOLOCK) 
					ON LE.TimeZoneId = LTZ.TimeZoneId
				WHERE 
					E.EmployeeId = @EmployeeId; -- Use appropriate filter for the specific employee
				
				SELECT 
					ACC.[AccountingCalendarHistoryId],
					ACC.[ReferenceId] as [ReferenceId],
					ACC.[PeriodName],
					ACC.[TableName],
					ACC.[StatusName],
					ACC.[LegalEntityId],
					ACC.[LegalEntityName],
					ACC.[ledgerId],
					ACC.[ledgerName],
					ACC.[MasterCompanyId],
					ACC.[CreatedBy],
					ACC.[UpdatedBy],
					CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
						CASE WHEN CAST(ACC.CreatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(ACC.CreatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
				    ELSE (CAST(ACC.CreatedDate AS DATETIME)) END CreatedDate,
				    CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
						CASE WHEN CAST(ACC.UpdatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(ACC.UpdatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
				    ELSE (CAST(ACC.UpdatedDate AS DATETIME)) END UpdatedDate,
					ACC.[IsActive]
				FROM [DBO].AccountingCalendarHistory ACC WITH (NOLOCK) 
				
				WHERE ACC.ReferenceId = @AccReferenceId and @TableName = ACC.[TableName] and @PeriodName=ACC.[PeriodName] order by AccountingCalendarHistoryId desc
			
                
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				--PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'AccountingCalendar_HistoryById' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@AccReferenceId, '')+'@Parameter2 = '''+ ISNULL(@TableName, '')+'@Parameter3 = '''+ ISNULL(@PeriodName, '') + ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName         = @ApplicationName
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
END