  
/*************************************************************             
 ** File:   [GetLaborOHSettingsByManagementStructureId]             
 ** Author:   Hemant Saliya  
 ** Description: This Stored Procedure is used Get Labor OHSettings By ManagementStructureId      
 ** Purpose:           
 ** Date:   12/30/2020          
            
 ** PARAMETERS: @UserType varchar(60)     
           
 ** RETURN VALUE:             
    
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author  Change Description              
 ** --   --------     -------  --------------------------------            
    1    05/20/2020   Hemant Saliya Created  
 2    07/10/2020   Hemant Saliya Added Quote Average Rate  
       
-- EXEC [GetLaborOHSettingsByManagementStructureId] 67, 1  
**************************************************************/  
  
CREATE   PROCEDURE [dbo].[GetLaborOHSettingsByManagementStructureId]  
 @ManagementStructureId INT,  
 @MasterCompanyId INT  
AS  
BEGIN  
 SET NOCOUNT ON;  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
  
 DECLARE @ManagementStructureIds as VARCHAR(500);  
 DECLARE @IsMSExist as INT;  
  
 BEGIN TRY  
  BEGIN TRANSACTION  
   BEGIN  
    IF((SELECT COUNT(*) FROM dbo.LaborOHSettings LO WITH(NOLOCK) WHERE LO.ManagementStructureId = @ManagementStructureId AND LO.MasterCompanyId = @MasterCompanyId AND LO.IsDeleted = 0 AND LO.IsActive = 1) > 0 )  
    BEGIN  
     SELECT TOP 1  
      LO.LaborOHSettingsId,  
      LO.LaborHoursId,  
      LO.LaborRateId,  
      LO.MasterCompanyId,  
      LO.IsActive,  
      LO.CreatedBy,  
      LO.UpdatedBy,  
      LO.CreatedDate,  
      LO.UpdatedDate,  
      LO.ManagementStructureId,  
      --LO.AverageRate,  
      --LO.QuoteAverageRate,
	  0 AS AverageRate,
	  0 AS QuoteAverageRate,
      --CASE WHEN ISNULL(LO.HourlyRate, 0) = 0 THEN 0 ELSE LO.HourlyRate END AS HourlyRate,  
	  0 AS HourlyRate,  
      LO.laborHoursMedthodId,  
      LO.BurdenRateId,  
      --CASE WHEN ISNULL(LO.FlatAmount, 0) = 0 THEN 0 ELSE LO.FlatAmount END AS FlatAmount,    
      --CASE WHEN ISNULL(LO.FlatAmountWeek, 0) = 0 THEN 0 ELSE LO.FlatAmountWeek END AS FlatAmountWeek,    
	  0 AS FlatAmount,    
      0 AS FlatAmountWeek,    
      CASE WHEN LO.LaborRateId = 1 THEN 'Use Individual Technician/Mechanic Labor Rate' ELSE 'Use Average Rate Of ALL Technician/Mechanic' END AS LaborRateIdText,    
      CASE WHEN LO.LaborHoursId = 1 THEN 'Assign Hours By Specific Actions' ELSE 'Assign Total Hours To Work Order' END AS LaborHoursIdText,  
      CASE WHEN LO.BurdenRateId = 1 THEN 'As A % Of Technician/Mechanic Hourly Rate' WHEN LO.BurdenRateId = 2 THEN 'Flat Amount Per Hour' ELSE 'Flat Amount Per Work Order' END AS BurdenRateIdText,  
      --FC.CurrencyId AS FunctionalCurrencyId,  
      --FC.Code AS FunctionalCurrencyCode,  
      --FC.Symbol AS FunctionalCurrencySymbol,  
      --TC.CurrencyId AS TransactionalCurrencyId,  
      --TC.Code AS TransactionalCurrencyCode,  
      --TC.Symbol AS TransactionalCurrencySymbol,  
      LO.Level1 AS levelCode1,  
      LO.Level2 AS levelCode2,  
      LO.Level3 AS levelCode3,  
      LO.Level4 AS levelCode4  
     FROM dbo.LaborOHSettings LO WITH(NOLOCK)  
      --LEFT JOIN dbo.Currency FC WITH(NOLOCK) on LO.FunctionalCurrencyId = FC.CurrencyId  
      --LEFT JOIN dbo.Currency TC WITH(NOLOCK) on LO.FunctionalCurrencyId = TC.CurrencyId  
     WHERE LO.MasterCompanyId = @MasterCompanyID AND LO.ManagementStructureId = @ManagementStructureId AND LO.IsDeleted = 0 AND LO.IsActive = 1  
    END  
    ELSE  
    BEGIN  
     EXEC dbo.GetAllChieldManagmentStructureDetailsByManagementStructureId @ManagementStructureId, @ManagementStructureIds = @ManagementStructureIds OUTPUT    
      
     IF OBJECT_ID(N'tempdb..#tmpManagementStructureIds') IS NOT NULL  
     BEGIN  
      DROP TABLE #tmpManagementStructureIds  
     END  
  
     CREATE TABLE #tmpManagementStructureIds(ManagementStructureId INT NULL)  
  
     INSERT INTO #tmpManagementStructureIds SELECT ITEM FROM dbo.SplitString(@ManagementStructureIds, ',')   
      
     SELECT TOP 1  
      LO.LaborOHSettingsId,  
      LO.LaborHoursId,  
      LO.LaborRateId,  
      LO.MasterCompanyId,  
      LO.IsActive,  
      LO.CreatedBy,  
      LO.UpdatedBy,  
      LO.CreatedDate,  
      LO.UpdatedDate,  
      LO.ManagementStructureId,  
     --LO.AverageRate,  
      --LO.QuoteAverageRate,
	  0 AS AverageRate,
	  0 AS QuoteAverageRate,
      --CASE WHEN ISNULL(LO.HourlyRate, 0) = 0 THEN 0 ELSE LO.HourlyRate END AS HourlyRate,  
	  0 HourlyRate,  
      LO.laborHoursMedthodId,  
      LO.BurdenRateId,  
      --CASE WHEN ISNULL(LO.FlatAmount, 0) = 0 THEN 0 ELSE LO.FlatAmount END AS FlatAmount,    
      --CASE WHEN ISNULL(LO.FlatAmountWeek, 0) = 0 THEN 0 ELSE LO.FlatAmountWeek END AS FlatAmountWeek,  
	  0 AS FlatAmount,    
      0 AS FlatAmountWeek,    
      CASE WHEN LO.LaborRateId = 1 THEN 'Use Individual Technician/Mechanic Labor Rate' ELSE 'Use Average Rate Of ALL Technician/Mechanic' END AS LaborRateIdText,    
      CASE WHEN LO.LaborHoursId = 1 THEN 'Assign Hours By Specific Actions' ELSE 'Assign Total Hours To Work Order' END AS LaborHoursIdText,  
      CASE WHEN LO.BurdenRateId = 1 THEN 'As A % Of Technician/Mechanic Hourly Rate' WHEN LO.BurdenRateId = 2 THEN 'Flat Amount Per Hour' ELSE 'Flat Amount Per Work Order' END AS BurdenRateIdText,  
      --FC.CurrencyId AS FunctionalCurrencyId,  
      --FC.Code AS FunctionalCurrencyCode,  
      --FC.Symbol AS FunctionalCurrencySymbol,  
      --TC.CurrencyId AS TransactionalCurrencyId,  
      --TC.Code AS TransactionalCurrencyCode,  
      --TC.Symbol AS TransactionalCurrencySymbol,  
      LO.Level1 AS levelCode1,  
      LO.Level2 AS levelCode2,  
      LO.Level3 AS levelCode3,  
      LO.Level4 AS levelCode4  
     FROM dbo.LaborOHSettings LO WITH(NOLOCK)  
      --LEFT JOIN dbo.Currency FC WITH(NOLOCK) on LO.FunctionalCurrencyId = FC.CurrencyId  
      --LEFT JOIN dbo.Currency TC WITH(NOLOCK) on LO.FunctionalCurrencyId = TC.CurrencyId  
      JOIN #tmpManagementStructureIds tmpMn ON LO.ManagementStructureId = tmpMn.ManagementStructureId  
     WHERE LO.MasterCompanyId = @MasterCompanyID AND LO.IsDeleted = 0 AND LO.IsActive = 1  
  
     IF OBJECT_ID(N'tempdb..#tmpManagementStructureIds') IS NOT NULL  
     BEGIN  
      DROP TABLE #tmpManagementStructureIds  
     END  
    END  
   END  
  COMMIT  TRANSACTION  
  
 END TRY      
 BEGIN CATCH        
  IF @@trancount > 0  
   PRINT 'ROLLBACK'  
   ROLLBACK TRAN;  
   DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
  
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            , @AdhocComments     VARCHAR(150)    = 'GetLaborOHSettingsByManagementStructureId'   
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ManagementStructureId, '') + ''',  
             @Parameter3 = ' + ISNULL(CAST(@MasterCompanyId AS varchar(10)) ,'') +''  
            , @ApplicationName VARCHAR(100) = 'PAS'  
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
  
            exec spLogException   
                    @DatabaseName           = @DatabaseName  
                    , @AdhocComments          = @AdhocComments  
                    , @ProcedureParameters = @ProcedureParameters  
                    , @ApplicationName        =  @ApplicationName  
                    , @ErrorLogID                    = @ErrorLogID OUTPUT ;  
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)  
            RETURN(1);  
 END CATCH  
END