/*************************************************************
 ** File:  [usp_MergePurchaseOrderPartReference] 
 ** Author:   Devendra Shekh
 ** Description: This stored procedure is used to save the Purchase Order Part Reference
 ** Date:  12-Dec-2025
 **************************************************************
  ** Change History
 **************************************************************
 ** PR   Date				Author				Change Description            
 ** --   --------			-------				--------------------------------          
    1    12-Dec-2025		Devendra Shekh		  Created

**************************************************************/ 
CREATE   PROCEDURE [dbo].[usp_MergePurchaseOrderPartReference]
(
    @tbl_PurchaseOrderPartReferenceType [dbo].[PurchaseOrderPartReferenceType] READONLY
)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
	BEGIN

		DECLARE @Now DATETIME2(7) = GETUTCDATE();

		MERGE [dbo].[PurchaseOrderPartReference] AS T
		USING @tbl_PurchaseOrderPartReferenceType AS S
			ON T.PurchaseOrderPartReferenceId = S.PurchaseOrderPartReferenceId

		WHEN MATCHED THEN
			UPDATE SET 
				T.PurchaseOrderId = S.PurchaseOrderId,
				T.PurchaseOrderPartId = S.PurchaseOrderPartId,
				T.ModuleId = S.ModuleId,
				T.ReferenceId = S.ReferenceId,
				T.Qty = S.Qty,
				T.RequestedQty = S.RequestedQty,
				T.ReservedQty = S.ReservedQty,
				T.IssuedQty = S.IssuedQty,
				T.MasterCompanyId = S.MasterCompanyId,
				T.UpdatedBy = S.UpdatedBy,
				T.UpdatedDate = @Now,
				T.IsActive = 1,
				T.IsDeleted = 0

		WHEN NOT MATCHED THEN
			INSERT (PurchaseOrderId, PurchaseOrderPartId, ModuleId, ReferenceId, Qty, RequestedQty, ReservedQty, IssuedQty, MasterCompanyId, CreatedBy, UpdatedBy, CreatedDate, UpdatedDate, IsActive, IsDeleted)
			VALUES (S.PurchaseOrderId, S.PurchaseOrderPartId, S.ModuleId, S.ReferenceId, S.Qty, S.RequestedQty, S.ReservedQty, S.IssuedQty, S.MasterCompanyId, S.CreatedBy, S.UpdatedBy, @Now, @Now, 1, 0);
    
		DECLARE @PurchaseOrderPartId BIGINT;
		DECLARE cur CURSOR FAST_FORWARD FOR
		SELECT [PurchaseOrderPartId] FROM @tbl_PurchaseOrderPartReferenceType;

		OPEN cur;
		FETCH NEXT FROM cur INTO @PurchaseOrderPartId;

		WHILE @@FETCH_STATUS = 0
		BEGIN
			EXEC [dbo].[sp_UpdatePOPartReferenceDetail] @PurchaseOrderPartId;
			FETCH NEXT FROM cur INTO @PurchaseOrderPartId;
		END

		CLOSE cur;
		DEALLOCATE cur;
	END
	END TRY
	BEGIN CATCH      
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			, @AdhocComments     VARCHAR(150)    = 'usp_MergePurchaseOrderPartReference' 
			, @ProcedureParameters VARCHAR(3000)  = ''
			, @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException 
			@DatabaseName				= @DatabaseName
			, @AdhocComments			= @AdhocComments
			, @ProcedureParameters		= @ProcedureParameters
			, @ApplicationName			= @ApplicationName
			, @ErrorLogID				= @ErrorLogID OUTPUT ;
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
		RETURN(1);
	END CATCH
END