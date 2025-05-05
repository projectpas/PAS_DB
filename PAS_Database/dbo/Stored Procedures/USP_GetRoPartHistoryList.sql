/*************************************************************           
 ** File:   [USP_GetRoPartHistoryList]           
 ** Author:   Sahdev Saliya
 ** Description: This stored procedure is used to Get RO Part History List
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
CREATE   PROCEDURE [dbo].[USP_GetRoPartHistoryList]
    @RepairOrderPartId BIGINT
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON;

    BEGIN TRY

			SELECT 
				ROP.RepairOrderPartAuditId,
				ROP.RepairOrderPartRecordId,
				ROP.RepairOrderId,
				RO.RepairOrderNumber,
				ROP.PartNumber,
				ROP.PartDescription,
				ROP.StockType,
				ROP.Manufacturer,
				ROP.Priority,
				ROP.NeedByDate,
				ROP.Condition,
				ROP.PurchaseOrderNumber,
				ROP.WorkOrderNo,
				ROP.SubWorkOrderNo,
				ROP.SalesOrderNo,
				ROP.ItemType,
				ROP.GLAccount,
				ROP.EstRecordDate,
				ROP.CreatedDate,
				ROP.CreatedBy,
				ROP.UpdatedDate,
				ROP.UpdatedBy
			FROM [dbo].RepairOrderPartAudit ROP WITH(NOLOCK)	
			INNER JOIN [dbo].RepairOrder RO WITH(NOLOCK) ON ROP.RepairOrderId = RO.RepairOrderId
			WHERE 
				ROP.RepairOrderPartRecordId = @RepairOrderPartId
    END TRY    
	BEGIN CATCH      
				IF @@trancount > 0
					PRINT 'ROLLBACK'
					DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

	-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
				  , @AdhocComments     VARCHAR(150)    = 'USP_GetRoPartHistoryList' 
				  , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = ''' + CAST(ISNULL(@RepairOrderPartId, '') AS varchar(100)) 
			 
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