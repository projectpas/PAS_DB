/*************************************************************           
 ** File:   [USP_GetWorkOrderQuoteSettingsByTypeList]           
 ** Author:   Sahdev Saliya
 ** Description: This stored procedure is used to Get WorkOrder Quote Settings By Type List
 ** Purpose:         
 ** Date:   05-05-2025       
          
 ** RETURN VALUE:           
  
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** S NO   Date            Author          Change Description              
 ** --   --------         -------          --------------------------------            
    1    05-05-2025    Sahdev Saliya       Created  

**************************************************************/  
CREATE   PROCEDURE [USP_GetWorkOrderQuoteSettingsByTypeList]
      @MasterCompanyId BIGINT,
      @WorkOrderTypeId BIGINT 
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON;

	BEGIN TRY

			SELECT 
				wos.WorkOrderQuoteSettingId,
				wos.WorkOrderTypeId,
				wos.Prefix,
				wos.Sufix,
				wos.StartCode,
				wot.Description AS workOrderType,
				wos.ValidDays,
				wos.MasterCompanyId,
				wos.IsActive,
				wos.CreatedBy,
				wos.CreatedDate,
				wos.UpdatedBy,
				wos.UpdatedDate
			FROM [dbo].WorkOrderQuoteSettings wos WITH(NOLOCK)
			INNER JOIN [dbo].WorkOrderType wot WITH(NOLOCK) ON wos.WorkOrderTypeId = wot.Id
			WHERE wos.WorkOrderTypeId = @WorkOrderTypeId
			ORDER BY wos.UpdatedDate DESC;
	END TRY    
	BEGIN CATCH      
				IF @@trancount > 0
					PRINT 'ROLLBACK'
					DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

	-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
				  , @AdhocComments     VARCHAR(150)    = 'USP_GetWorkOrderQuoteSettingsByTypeList' 
				  , @ProcedureParameters VARCHAR(3000)  =  '@Parameter1 = '''+ ISNULL(@MasterCompanyId, '') + ''',  
                    @Parameter2 = ' + ISNULL(@WorkOrderTypeId ,'') 
			 
				  , @ApplicationName VARCHAR(100) = 'PAS'
	-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

				  exec spLogException 
						   @DatabaseName			= @DatabaseName
						 , @AdhocComments			= @AdhocComments
						 , @ProcedureParameters		= @ProcedureParameters
						 , @ApplicationName			= @ApplicationName
						 , @ErrorLogID              = @ErrorLogID OUTPUT ;
				  RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
				  RETURN
	END CATCH
END