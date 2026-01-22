--exec USP_AccountingAccountListById @AccountingCalendarId=107,@periodName=N'Mar - 2023'

/*************************************************************             
 ** File:   [USP_Open_close_ledgerbyId]             
 ** Author:   
 ** Description: This stored procedure is used to populate Calendar Listing.      
 ** Purpose:           
 ** Date:     
            
 ** PARAMETERS:  
           
 ** RETURN VALUE:             
 **************************************************************             
 ** Change History             
 **************************************************************             
 ** PR   Date         Author  Change Description              
 ** --   --------     -------  --------------------------------            
 1    30/08/2022   subhash saliya Changes ledger id  
 2    14/06/2024   Hemant saliya  Added MasterCopant in Where condition fot filter records 

    -- exec USP_Open_close_ledgerbyId 1,1,2022   
**************************************************************/  
CREATE     PROCEDURE [dbo].[USP_AccountingAccountListById]  
@AccountingCalendarId bigint,  
@periodName varchar(50)  
  
AS  
 BEGIN  
  
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
  SET NOCOUNT ON;  
  DECLARE @RecordFrom int;  
  DECLARE @IsActive bit = 1  
  DECLARE @Count Int;  
  DECLARE @PageSize Int =10  
  
  BEGIN TRY  
   BEGIN TRANSACTION  
    BEGIN  
  
    DECLARE @MasterCompanyId INT =0  
  
    SELECT @MasterCompanyId = MasterCompanyId FROM dbo.AccountingCalendar WITH(NOLOCK) WHERE AccountingCalendarId = @AccountingCalendarId  

	SELECT AC.AccountingCalendarId AccountingCalendarId, AC.Name, AC.Description as Description, AC.FiscalName,AC.FiscalYear,  
			AC.Quater, AC.Period, AC.FromDate,AC.ToDate, AC.PeriodName, AC.Notes, AC.MasterCompanyId,AC.CreatedBy,AC.UpdatedBy,  
			AC.CreatedDate, AC.UpdatedDate, AC.IsActive, AC.IsDeleted, AC.Status, AC.LegalEntityId,AC.isUpdate,AC.IsAdjustPeriod,  
			AC.NoOfPeriods, AC.PeriodType, AC.ledgerId, LE.Name LagalEntity,  
			CASE WHEN AC.isaccStatusName=1 THEN 'Open' ELSE 'Closed' END as ACCStatusName,  
				AC.AccountingCalendarId as ACCReferenceId,  
			CASE WHEN AC.isacpStatusName=1 THEN 'Open' ELSE 'Closed' END as ACPStatusName,  
				AC.AccountingCalendarId as ACPReferenceId,  
			CASE WHEN AC.isacrStatusName=1 THEN 'Open' ELSE 'Closed' END as ACRStatusName,  
				AC.AccountingCalendarId as ACRReferenceId,  
			CASE WHEN AC.isassetStatusName=1 THEN 'Open' ELSE 'Closed' END  as AssetStatusName,  
				AC.AccountingCalendarId as AssetReferenceId,  
			CASE WHEN AC.isinventoryStatusName=1 THEN 'Open' ELSE 'Closed' END as InventoryStatusName,  
				AC.AccountingCalendarId as InventoryReferenceId  
     FROM dbo.AccountingCalendar AC WITH(NOLOCK)  
		INNER JOIN dbo.LegalEntity as LE WITH(NOLOCK) ON LE.LegalEntityId = AC.LegalEntityId  
     WHERE AC.IsDeleted = 0 AND AC.IsActive = 1 AND UPPER(AC.PeriodName) = UPPER(@periodName) 
		AND AC.MasterCompanyId = @MasterCompanyId
       
    END  
   COMMIT  TRANSACTION  
  
  END TRY      
  BEGIN CATCH   
  
  IF @@trancount > 0  
    PRINT 'ROLLBACK'  
                    ROLLBACK TRAN;  
     DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'USP_AccountingCalendarList'   
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '+ ISNULL(@AccountingCalendarId, '') + ',   
                @Parameter2 = ' + ISNULL(@periodName,'') + ''   
              
              , @ApplicationName VARCHAR(100) = 'PAS'  
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
  
              exec spLogException   
                       @DatabaseName   = @DatabaseName  
                     , @AdhocComments   = @AdhocComments  
                     , @ProcedureParameters  = @ProcedureParameters  
                     , @ApplicationName   =  @ApplicationName  
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;  
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)  
              RETURN(1);  
        END CATCH    
END