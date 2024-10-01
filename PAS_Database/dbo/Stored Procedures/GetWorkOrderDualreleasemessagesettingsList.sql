/*************************************************************               
 ** File:   [GetWorkOrderDualreleasemessagesettingsList]               
 ** Author: AMIT GHEDIYA    
 ** Description: This stored procedure is used to get WorkOrder Dualrelease Message Settings List.   
 ** Purpose:             
 ** Date:   10/01/2024            
              
 ** PARAMETERS:               
 @MasterCompanyId BIGINT       
             
 ** RETURN VALUE:               
      
 **************************************************************               
  ** Change History               
 **************************************************************               
 ** PR   Date         Author			Change Description                
 ** --   --------     ------------			--------------------------------              
    1    10/01/2024   AMIT GHEDIYA		Created    
         
--EXEC [GetWorkOrderDualreleasemessagesettingsList] 1  
**************************************************************/    
CREATE      PROCEDURE [dbo].[GetWorkOrderDualreleasemessagesettingsList]    
 @MasterCompanyId  BIGINT = 0,
 @WorkOrderDualReleaseSettingId BIGINT = 0
AS    
BEGIN    
   SET NOCOUNT ON;    
   BEGIN TRY    
   BEGIN    
		IF(@WorkOrderDualReleaseSettingId > 0)
		BEGIN
			SELECT 
				  WOS.WorkOrderDualReleaseSettingId,
				  WOT.Description AS 'WorkOrderType',
				  WOT.Id AS 'WorkOrderTypeId',
				  COU.countries_name AS 'CountriesName',
				  COU.countries_id AS 'CountriesId',
				  WOS.Dualreleaselanguage,
				  'EASA' AS 'FormType'
		    FROM WorkOrderDualReleaseSettings WOS WITH(NOLOCK)
		    JOIN WorkOrderType WOT WITH(NOLOCK) ON WOT.Id = WOS.WorkOrderTypeId
		    JOIN Countries COU WITH(NOLOCK) ON COU.countries_id = WOS.CountriesId
		    WHERE WOS.MasterCompanyId = @MasterCompanyId AND WOS.WorkOrderDualReleaseSettingId = @WorkOrderDualReleaseSettingId;
		END
		ELSE
		BEGIN
			SELECT 
				  WOS.WorkOrderDualReleaseSettingId,
				  WOT.Description AS 'WorkOrderType',
				  WOT.Id AS 'WorkOrderTypeId',
				  COU.countries_name AS 'CountriesName',
				  COU.countries_id AS 'CountriesId',
				  WOS.Dualreleaselanguage,
				  'EASA' AS 'FormType'
		    FROM WorkOrderDualReleaseSettings WOS WITH(NOLOCK)
		    JOIN WorkOrderType WOT WITH(NOLOCK) ON WOT.Id = WOS.WorkOrderTypeId
		    JOIN Countries COU WITH(NOLOCK) ON COU.countries_id = WOS.CountriesId
		    WHERE WOS.MasterCompanyId = @MasterCompanyId;
		END
   END    
   END TRY        
  BEGIN CATCH          
   IF @@trancount > 0    
    PRINT 'ROLLBACK'    
    ROLLBACK TRAN;    
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()     
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
              , @AdhocComments     VARCHAR(150)    = 'GetWorkOrderDualreleasemessagesettingsList'     
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@MasterCompanyId, '') + ''    
              , @ApplicationName VARCHAR(100) = 'PAS'    
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------    
              exec spLogException     
        @DatabaseName           =  @DatabaseName    
                     , @AdhocComments          =  @AdhocComments    
                     , @ProcedureParameters    =  @ProcedureParameters    
         , @ApplicationName        =  @ApplicationName    
                     , @ErrorLogID             =  @ErrorLogID OUTPUT ;    
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)    
              RETURN(1);    
  END CATCH    
END