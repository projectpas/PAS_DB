/*************************************************************             
 ** File:   [USP_DeleteSubWorkOrderMaterials]             
 ** Author:  Amit Ghediya  
 ** Description: This stored procedure is used to delete SubWorkOrder Materials.  
 ** Purpose:           
 ** Date:    11/04/2025     
            
 ** PARAMETERS: @subWorkOrderMaterialId bigint  
           
 ** RETURN VALUE:             
 **************************************************************             
 ** Change History             
 **************************************************************             
 ** PR   Date         Author				Change Description              
 ** --   --------     -------			--------------------------------            
    1    11/04/2025  Amit Ghediya			Created  
       
-- EXEC USP_DeleteSubWorkOrderMaterials 128,'AMIT GHEDIYA'  
************************************************************************/  
CREATE     PROCEDURE [dbo].[USP_DeleteSubWorkOrderMaterials]  
	@SubWorkOrderMaterialsId BIGINT,
    @UpdatedBy VARCHAR(100)
AS  
BEGIN  
	 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
	 SET NOCOUNT ON;  
	 BEGIN TRANSACTION;
	 BEGIN TRY  
	  
			DECLARE @SubWorkOrderId BIGINT;

		    -- Delete SubWorkOrderStockLineReserve if exists
			IF EXISTS(SELECT TOP 1 SWOSReserveId FROM [DBO].[SubWorkOrderStockLineReserve] WITH(NOLOCK) WHERE [SubWorkOrderMaterialsId] = @SubWorkOrderMaterialsId)
			BEGIN
				 DELETE FROM [DBO].[SubWorkOrderStockLineReserve] WHERE [SubWorkOrderMaterialsId] = @SubWorkOrderMaterialsId;
			END
			

			-- Delete SubWorkOrderMaterialStockLine if exists
			IF EXISTS(SELECT TOP 1 SWOMStockLineId FROM [DBO].[SubWorkOrderMaterialStockLine] WITH(NOLOCK) WHERE [SubWorkOrderMaterialsId] = @SubWorkOrderMaterialsId)
			BEGIN
				 DELETE FROM [DBO].[SubWorkOrderMaterialStockLine] WHERE [SubWorkOrderMaterialsId] = @SubWorkOrderMaterialsId;
			END
			
			-- Get SubWorkOrderId before deleting material if exists
			IF EXISTS(SELECT TOP 1 SubWorkOrderMaterialsId FROM [DBO].[SubWorkOrderMaterials] WITH(NOLOCK) WHERE [SubWorkOrderMaterialsId] = @SubWorkOrderMaterialsId)
			BEGIN
				 SELECT 
					@SubWorkOrderId = SubWorkOrderId
				 FROM [DBO].[SubWorkOrderMaterials] 
				 WHERE [SubWorkOrderMaterialsId] = @SubWorkOrderMaterialsId;

				-- Call for UnMap PO.
				EXEC [DBO].[USP_UnMappedPOByWorkOrderMaterialsId] 
					 @SubWorkOrderMaterialsId,
					 0,  -- false for kit
					 1,  -- true for subWO
					 @SubWorkOrderId, -- for ReferenceId
					 0, -- false for POId
					 @UpdatedBy;

				-- Delete SubWorkOrderMaterials
				DELETE FROM SubWorkOrderMaterials WHERE SubWorkOrderMaterialsId = @SubWorkOrderMaterialsId;
			END

		 COMMIT TRANSACTION;
	 END TRY      
     BEGIN CATCH        
     IF @@trancount > 0  
		PRINT 'ROLLBACK'  
		ROLLBACK TRANSACTION; 
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
--		--------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
		         , @AdhocComments     VARCHAR(150)    = 'USP_DeleteSubWorkOrderMaterials'   
		         , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@SubWorkOrderMaterialsId, '') + ''  
		         , @ApplicationName VARCHAR(100) = 'PAS'  
--		--------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
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