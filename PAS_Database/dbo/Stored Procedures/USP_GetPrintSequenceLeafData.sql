/*************************************************************           
 ** File:   [USP_GetPrintSequenceLeafData]      
 ** Author:  Bhargav Saliya
 ** Description: This stored procedure is used Get Sequence Data
 ** Purpose:         
 ** Date:   21/01/2026     
         
 ** PARAMETERS:    @RountingStructureId   bigint     
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    21/01/2026  Bhargav Saliya     Created

************************************************************************/
CREATE     PROCEDURE [dbo].[USP_GetPrintSequenceLeafData]
@RountingStructureId BIGINT = NULL,
@MasterCompanyId BIGINT = NULL
AS 
BEGIN
	SET NOCOUNT ON;  
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
	SELECT LeafNodeId
		   ,L.[Name]
		   ,L.[PrintSequenceNumber]
		   ,L.[MasterCompanyId]
		   ,L.[ReportingStructureId]
	FROM dbo.[LeafNode] L WITH(NOLOCK)
	WHERE L.ReportingStructureId = @RountingStructureId AND MasterCompanyId = @MasterCompanyId AND ISNULL(IsActive,0) = 1 AND ISNULL(IsDeleted,0) = 0
	ORDER BY L.[PrintSequenceNumber]
	END TRY
	BEGIN CATCH
	 DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'GetCustomerTicketList'
			,@ProcedureParameters VARCHAR(3000) =
			'@Parameter1 = '''+ ISNULL(@RountingStructureId, '') + ''',   
			 @Parameter2 = ' + ISNULL(@MasterCompanyId,'') + ','   
            ,@ApplicationName VARCHAR(100) = 'PAS'        
-----------------------------PLEASE DO NOT EDIT BELOW----------------------------------------        
              exec spLogException         
                       @DatabaseName           = @DatabaseName        
                     , @AdhocComments          = @AdhocComments        
                     , @ProcedureParameters = @ProcedureParameters        
                     , @ApplicationName        =  @ApplicationName        
                     , @ErrorLogID   = @ErrorLogID OUTPUT ;        
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)        
              RETURN(1); 				
	END CATCH
END