/*************************************************************           
 ** File:   [USP_GetEditReturnReasonById]           
 ** Author:   Sahdev Saliya
 ** Description: This stored procedure is used to Get EditReturnReasonById List
 ** Purpose:         
 ** Date:   04-06-2025       
          
 ** RETURN VALUE:           
  
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** S NO   Date            Author          Change Description              
 ** --   --------         -------          --------------------------------            
    1    04-06-2025    Sahdev Saliya       Created  

**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_GetEditReturnReasonById]
    @ReasonId BIGINT
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON;
         BEGIN TRY

			SELECT 
				 VRR.VendorRMAReturnReasonId
				,VRR.Reason
				,ISNULL(VRR.Memo, '') AS Memo
				,VRR.MasterCompanyId
				,VRR.CreatedBy
			FROM [dbo].[VendorRMAReturnReason] VRR WITH(NOLOCK)
			WHERE VRR.[VendorRMAReturnReasonId] = @ReasonId;
		 END TRY    

BEGIN CATCH      
				IF @@trancount > 0
					PRINT 'ROLLBACK'
					DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

	-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
				  , @AdhocComments     VARCHAR(150)    = 'USP_GetEditReturnReasonById' 
				  , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ReasonId, '')
			 
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