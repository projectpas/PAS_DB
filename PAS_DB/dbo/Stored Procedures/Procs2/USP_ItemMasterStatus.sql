
-- ---------------------------------------------------------------------------------------------------
-- Stored Procedure: DBO.USP_ItemMasterStatus   (source: PAS_DB/dbo/Stored Procedures/Procs2/USP_ItemMasterStatus.sql)
-- ---------------------------------------------------------------------------------------------------
/*************************************************************           
 ** File:		 [USP_ItemMasterStatus]           
 ** Author:		 Divyesh Kathiriya
 ** Description: This Stored Procedure Is Used To Update ItemMaster Status.
 ** Purpose:         
 ** Date:   20-August-2025 
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   -------------		----------------	--------------------------------          
    1    20-August-2025		Divyesh Kathiriya	Created
	2    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
    
 -- EXEC [USP_ItemMasterStatus] @ItemMasterid=35, @UpdatedBy=N'DANE PERK', @Status=N'Active'
**************************************************************/
CREATE     PROCEDURE [DBO].[USP_ItemMasterStatus]
@ItemMasterid BIGINT = 0,
@UpdatedBy VARCHAR(256),
@Status BIT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
	BEGIN TRANSACTION

	DECLARE @MasterPartId AS BIGINT;
	SELECT @MasterPartId = [MasterPartId] FROM [DBO].[ItemMaster] WITH(NOLOCK) WHERE [ItemMasterId] = @ItemMasterid AND ISNULL(dbo.ItemMaster.IsNonStock,0) = 0 ;	

	IF(ISNULL(@ItemMasterid, 0) > 0)		
	BEGIN

		UPDATE [DBO].[ItemMaster] 
		SET	[IsActive] = @Status, [UpdatedBy] = @UpdatedBy, [UpdatedDate] = GETUTCDATE()
		WHERE [ItemMasterid] = @ItemMasterid;		
		
		UPDATE [DBO].[MasterParts] 
		SET	[IsActive] = @Status, [UpdatedBy] = @UpdatedBy, [UpdatedDate] = GETUTCDATE()
		WHERE [MasterPartId] = @MasterPartId;
	END

	COMMIT  TRANSACTION
	END TRY 
	BEGIN CATCH
	IF @@trancount > 0  
		PRINT 'ROLLBACK'  
		ROLLBACK TRAN;  
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_ItemMasterStatus'
			  , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = '''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)

		RETURN (1); 
	END CATCH

END