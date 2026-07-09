/*************************************************************             
 ** File:   [USP_CreateSubWorkOrderMaterialsStoclkine]             
 ** Author:   Devendra Shekh
 ** Description: This stored procedure is used Create work order materials
 ** Date:   28-April-2025         
 **************************************************************             
 ** Change History             
 **************************************************************             
 ** PR   Date					Author						Change Description              
 ** --   --------				-------					--------------------------------            
 ** 1    10-MAY-2025			Devendra Shekh				Created
 2    09/July/2026			RAJESH GAMI				[PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0
       
**************************************************************/  
  
CREATE   PROCEDURE [dbo].[USP_CreateSubWorkOrderMaterialsStoclkine]  
	@tbl_SubWorkOrderMaterialsType [SubWorkOrderMaterialsType] READONLY
AS  
BEGIN  
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
	SET NOCOUNT ON;  
  
	BEGIN TRY  
	BEGIN TRANSACTION

		DECLARE @CreatedMaterial VARCHAR(100) = 'Created-Updated';

		INSERT INTO [dbo].[SubWorkOrderMaterialStockLine] ([SubWorkOrderMaterialsId], [StocklineId], [ItemMasterId], [ConditionId], [ProvisionId], [Quantity], [QtyReserved], [QtyIssued], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate],
		[IsActive], [IsDeleted], [UnitCost], [ExtendedCost], [UnitPrice], [Figure], [Item], [ReferenceNumber]) 
		SELECT TMP.[SubWorkOrderMaterialsId], TMP.[StocklineId], TMP.[ItemMasterId], [ConditionCodeId], [ProvisionId], [StocklineQuantity], 0, 0, TMP.[MasterCompanyId], TMP.[CreatedBy], TMP.[UpdatedBy], GETUTCDATE(), GETUTCDATE(),
		1, 0, TMP.[UnitCost], TMP.[ExtendedCost], STK.[PurchaseOrderUnitCost], TMP.Figure, TMP.[Item], @CreatedMaterial		
		FROM @tbl_SubWorkOrderMaterialsType TMP
		LEFT JOIN [DBO].[StockLine] STK WITH(NOLOCK) ON TMP.StockLineId = STK.StockLineId AND ISNULL(STK.IsNonStock,0) = 0
		 
	COMMIT TRANSACTION  
	END TRY      
	BEGIN CATCH        
		IF @@trancount > 0  
		ROLLBACK TRAN;  
		DECLARE	@ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
				, @AdhocComments     VARCHAR(150)    = 'USP_CreateSubWorkOrderMaterialsStoclkine'   
				, @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = ''' 
				, @ApplicationName VARCHAR(100) = 'PAS'  
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
				EXEC	spLogException   
						@DatabaseName   = @DatabaseName  
						, @AdhocComments   = @AdhocComments  
						, @ProcedureParameters  = @ProcedureParameters  
						, @ApplicationName         = @ApplicationName  
						, @ErrorLogID              = @ErrorLogID OUTPUT ;  
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)  
              RETURN(1);  
	END CATCH  
END