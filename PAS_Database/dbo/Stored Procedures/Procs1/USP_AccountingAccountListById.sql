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
  Declare @IsActive bit = 1  
  Declare @Count Int;  
  Declare @PageSize Int =10  
  
  BEGIN TRY  
   BEGIN TRANSACTION  
    BEGIN  
  
    Declare @MasterCompanyId int =0  
  
    select @MasterCompanyId = MasterCompanyId from AccountingCalendar WITH(NOLOCK)  where AccountingCalendarId=@AccountingCalendarId  
   Select AC.AccountingCalendarId AccountingCalendarId, AC.Name, AC.Description as Description, AC.FiscalName,AC.FiscalYear,  
     AC.Quater, AC.Period, AC.FromDate,AC.ToDate, AC.PeriodName, AC.Notes, AC.MasterCompanyId,AC.CreatedBy,AC.UpdatedBy,  
     AC.CreatedDate, AC.UpdatedDate, AC.IsActive, AC.IsDeleted, AC.Status, AC.LegalEntityId,AC.isUpdate,AC.IsAdjustPeriod,  
     AC.NoOfPeriods, AC.PeriodType, AC.ledgerId, LE.Name LagalEntity,  
     Case when AC.isaccStatusName=1 then 'Open' else 'Closed' end as ACCStatusName,  
     AC.AccountingCalendarId as ACCReferenceId,  
     Case when AC.isacpStatusName=1 then 'Open' else 'Closed' end as ACPStatusName,  
      AC.AccountingCalendarId as ACPReferenceId,  
     Case when AC.isacrStatusName=1 then 'Open' else 'Closed' end as ACRStatusName,  
      AC.AccountingCalendarId as ACRReferenceId,  
     Case when AC.isassetStatusName=1 then 'Open' else 'Closed' end  as AssetStatusName,  
      AC.AccountingCalendarId as AssetReferenceId,  
     Case when AC.isinventoryStatusName=1 then 'Open' else 'Closed' end as InventoryStatusName,  
     AC.AccountingCalendarId as InventoryReferenceId  
  
     from AccountingCalendar AC WITH(NOLOCK)  
       
     --LEFT join AccountsPayableResult as ACPResult  WITH(NOLOCK) on  ACPResult.LegalEntityId = RS.LegalEntityId --and UPPER(PeriodName)=UPPER(@periodName)   
     --LEFT join AccountsReceivableResult as ACRResult  WITH(NOLOCK) on  ACRResult.LegalEntityId = RS.LegalEntityId --and UPPER(PeriodName)=UPPER(@periodName)   
    -- LEFT join AccountingCalendar as AC_Max WITH(NOLOCK) on  AC_Max.AccountingCalendarId = RS.ReferenceId_Max  
    -- LEFT join AccountingCalendar as AC_Min WITH(NOLOCK) on  AC_Min.AccountingCalendarId = RS.ReferenceId_MIn  
     inner join LegalEntity as LE WITH(NOLOCK) on  LE.LegalEntityId = AC.LegalEntityId  
     WHERE AC.IsDeleted = 0 AND AC.IsActive = 1 and UPPER(AC.PeriodName)=UPPER(@periodName) 


  --   ;With Result AS(  
  --     SELECT Max(Name) as Name,PeriodName,Max(FiscalYear) as FiscalYear, min(AccountingCalendarId) as ReferenceId_MIn,  
  --     max(AccountingCalendarId) as ReferenceId_Max, LegalEntityId, Max(ledgerId) as ledgerId,max(Description) as Descriptionmax,'AccountingCalendar' as TableName,  
  --     max(StartDate) as StartDate,max(EndDate) as EndDate,max(Status) as StatusName   
  --     from AccountingCalendar WITH(NOLOCK)  
  --     WHERE IsDeleted =0 AND IsActive=1 AND UPPER(PeriodName)=UPPER(@periodName)  
  --     GROUP BY PeriodName,LegalEntityId  
  --   ) , 
  --   --,AccountsPayableResult AS(  
  --   --  SELECT Max(Name) as Name,PeriodName,Max(FiscalYear) as FiscalYear , min(AccountsPayableCalendarId) as ReferenceId_MIn,  
  --   --  max(AccountsPayableCalendarId) as ReferenceId_Max, LegalEntityId, Max(ledgerId) as ledgerId,max(Description) as Descriptionmax,'AccountsPayableResult' as TableName,  
  --   --  max(StartDate) as StartDate,max(EndDate) as EndDate,max(Status) as StatusName  
  --   --  from AccountsPayableCalendar WITH(NOLOCK)  
  --   --  WHERE IsDeleted =0 AND IsActive=1 AND MasterCompanyId=@MasterCompanyId  AND UPPER(PeriodName)=UPPER(@periodName)  
  --   --  GROUP BY PeriodName, LegalEntityId  
  --   --)  
  --   --,AccountsReceivableResult AS(  
  --   --  SELECT Max(Name) as Name,PeriodName,Max(FiscalYear) as FiscalYear , min(AccountsReceivableCalendarId) as ReferenceId_MIn,  
  --   --  max(AccountsReceivableCalendarId) as ReferenceId_Max, LegalEntityId, Max(ledgerId) as ledgerId,max(Description) as Descriptionmax,'AccountsReceivableCalendar' as TableName,  
  --   --  max(StartDate) as StartDate,max(EndDate) as EndDate,max(Status) as StatusName  
  --   --  from AccountsReceivableCalendar WITH(NOLOCK)  
  --   --  WHERE IsDeleted =0 AND IsActive=1 AND MasterCompanyId=@MasterCompanyId  AND UPPER(PeriodName)=UPPER(@periodName)  
  --   --  GROUP BY PeriodName, LegalEntityId  
  --   --), 
	 
	 --FinalResult AS(  
  --   Select RS.ReferenceId_Max AccountingCalendarId, RS.Name, RS.Descriptionmax as Description, AC_Max.FiscalName,RS.FiscalYear,  
  --   AC_Max.Quater, AC_Max.Period, AC_Min.FromDate,AC_Max.ToDate, AC_Max.PeriodName, AC_Max.Notes, AC_Max.MasterCompanyId,AC_Max.CreatedBy,AC_Max.UpdatedBy,  
  --   AC_Max.CreatedDate, AC_Max.UpdatedDate, AC_Max.IsActive, AC_Max.IsDeleted, AC_Max.Status, AC_Max.LegalEntityId,AC_Max.isUpdate,AC_Max.IsAdjustPeriod,  
  --   AC_Max.NoOfPeriods, AC_Max.PeriodType, AC_Max.ledgerId, LE.Name LagalEntity,  
  --   RS.StatusName as ACCStatusName,  
  --   RS.ReferenceId_Max as ACCReferenceId,  
  --   ISNULL(ACPResult.StatusName,'') as ACPStatusName,  
  --   ISNULL(ACPResult.ReferenceId_Max,0) as ACPReferenceId,  
  --   ISNULL(ACRResult.StatusName,'') as ACRStatusName,  
  --   ISNULL(ACRResult.ReferenceId_Max,0) as ACRReferenceId,  
  --   ''  as AssetStatusName,  
  --   0 as AssetReferenceId,  
  --   '' as InventoryStatusName,  
  --   0 as InventoryReferenceId  
  
  --   from Result RS WITH(NOLOCK)  
       
  --   --LEFT join AccountsPayableResult as ACPResult  WITH(NOLOCK) on  ACPResult.LegalEntityId = RS.LegalEntityId --and UPPER(PeriodName)=UPPER(@periodName)   
  --   --LEFT join AccountsReceivableResult as ACRResult  WITH(NOLOCK) on  ACRResult.LegalEntityId = RS.LegalEntityId --and UPPER(PeriodName)=UPPER(@periodName)   
  --   LEFT join AccountingCalendar as AC_Max WITH(NOLOCK) on  AC_Max.AccountingCalendarId = RS.ReferenceId_Max  
  --   LEFT join AccountingCalendar as AC_Min WITH(NOLOCK) on  AC_Min.AccountingCalendarId = RS.ReferenceId_MIn  
  --   inner join LegalEntity as LE WITH(NOLOCK) on  LE.LegalEntityId = RS.LegalEntityId  
  --   WHERE AC_Max.IsDeleted = 0 AND AC_Max.IsActive = 1 and UPPER(RS.PeriodName)=UPPER(@periodName)   
  --   ),  
  --   ResultCount AS(SELECT COUNT(AccountingCalendarId) AS totalItems FROM FinalResult)  
  --   SELECT * INTO #TempResult from  FinalResult    
  
  --   SELECT *, @Count As NumberOfItems FROM #TempResult  
  --   ORDER BY     
  --    1  Desc  
  
       
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