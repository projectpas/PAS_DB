/*************************************************************
 ** File:   [USP_SetWorkOrderMaterialsCustomerSupplied]
 ** Author: Rajesh Gami
 ** Description: Sets / clears the Customer Supplied Part (CSP) flag of Work Order material lines (called after the material is saved)
 ** Date:   12-Nov-2026
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date           Author        Change Description
 ** --   --------       -------       --------------------------------
    1    12-Nov-2026    RAJESH GAMI   [PN-18508] Created. Kept separate from USP_CreateWorkOrderMaterials / WorkOrderMaterialsType so the shared table type and the existing create/update flows are untouched.
 **************************************************************
-- EXEC dbo.USP_SetWorkOrderMaterialsCustomerSupplied @WorkOrderMaterialsIds = '101,102', @IsCustomerSuppliedPart = 1, @UpdatedBy = 'ADMIN'
************************************************************************/

CREATE OR ALTER PROCEDURE [dbo].[USP_SetWorkOrderMaterialsCustomerSupplied]
	@WorkOrderMaterialsIds VARCHAR(MAX),
	@IsCustomerSuppliedPart BIT,
	@UpdatedBy VARCHAR(256)
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		UPDATE WOM
		SET WOM.IsCustomerSuppliedPart = @IsCustomerSuppliedPart,
			WOM.UpdatedBy = @UpdatedBy,
			WOM.UpdatedDate = GETUTCDATE()
		FROM dbo.WorkOrderMaterials WOM
		WHERE WOM.WorkOrderMaterialsId IN (SELECT CAST(Item AS BIGINT) FROM dbo.SPLITSTRING(@WorkOrderMaterialsIds, ',') WHERE ISNUMERIC(Item) = 1)
			AND ISNULL(WOM.IsCustomerSuppliedPart, 0) <> @IsCustomerSuppliedPart;

		SELECT @@ROWCOUNT AS RowsUpdated;
	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = DB_NAME()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			, @AdhocComments VARCHAR(150) = 'USP_SetWorkOrderMaterialsCustomerSupplied'
			, @ProcedureParameters VARCHAR(3000) = '@WorkOrderMaterialsIds = ' + ISNULL(@WorkOrderMaterialsIds, '')
			, @ApplicationName VARCHAR(100) = 'PAS'
------------------------------------PLEASE DO NOT EDIT BELOW--------------------------------------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName, @AdhocComments = @AdhocComments, @ProcedureParameters = @ProcedureParameters, @ApplicationName = @ApplicationName, @ErrorLogID = @ErrorLogID OUTPUT;
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
		RETURN(1);
	END CATCH
END
