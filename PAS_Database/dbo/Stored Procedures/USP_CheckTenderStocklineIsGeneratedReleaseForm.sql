/********************************************************************************           
 ** File:     [USP_CheckTenderStocklineIsGeneratedReleaseForm]           
 ** Author:	  Moin Bloch
 ** Description: This SP IS Used to check Tendor Stockline is Generated 8130 Form or not
 ** Purpose:         
 ** Date:   02/04/2024	          
 ** PARAMETERS:       
 ** RETURN VALUE:     
 **************************************************************    
 ** Change History           
 **************************************************************           
 ** PR   	Date			Author					Change Description            
 ** --   	--------		-------				--------------------------------     
	1		02/04/2024		Moin Bloch			CREATED

	EXEC [USP_CheckTenderStocklineIsGeneratedReleaseForm] 3784,3282,1
**********************************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_CheckTenderStocklineIsGeneratedReleaseForm]
@WorkOrderId  BIGINT,
@WorkOrderPartNumberId BIGINT,
@MasterCompanyId INT                 -- 
AS 
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
		BEGIN TRY
		
		SELECT SL.[StockLineId],						
			   IM.[PartNumber],
			   SL.[StockLineNumber],	
			   ISNULL(SL.[ControlNumber], '') AS 'ControlNumber',
			   ISNULL(SL.[SerialNumber], '') AS 'SerialNumber',
			   ISNULL(SL.[Condition], '') AS 'Condition'		   
		  FROM [dbo].[Stockline] SL WITH (NOLOCK)
				INNER JOIN [dbo].[WorkOrder] WO WITH (NOLOCK) ON WO.WorkOrderId = SL.WorkOrderId
				INNER JOIN [dbo].[WorkOrderPartNumber] WOP WITH (NOLOCK) ON WO.WorkOrderId = WOP.WorkOrderId AND WOP.ID = @WorkOrderPartNumberId
				 LEFT JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON SL.ItemMasterId = IM.ItemMasterId
		  WHERE (SL.[IsDeleted] = 0) AND (SL.[IsActive] = 1)			     
				AND SL.[MasterCompanyId] = @MasterCompanyId 
				AND SL.[WorkOrderId] = @WorkOrderId 
				AND SL.[IsTurnIn] = 1
				AND WOP.[ID] = @WorkOrderPartNumberId 
				AND SL.[WorkOrderPartNoId] = @WorkOrderPartNumberId 
				AND SL.[StockLineId] NOT IN(SELECT [StocklineId] FROM [dbo].[WorkOrderPartNumber] WITH(NOLOCK) WHERE [WorkOrderId] = @WorkOrderId AND [ID] = @WorkOrderPartNumberId)
				AND ISNULL(SL.[IsGenerateReleaseForm],0) = 0

		END TRY    
		BEGIN CATCH      		
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_CheckTenderStocklineIsGeneratedReleaseForm' 
               ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@WorkOrderId, '') AS VARCHAR(100))  
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName           =  @DatabaseName
                     , @AdhocComments          =  @AdhocComments
                     , @ProcedureParameters	   =  @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID             =  @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
END