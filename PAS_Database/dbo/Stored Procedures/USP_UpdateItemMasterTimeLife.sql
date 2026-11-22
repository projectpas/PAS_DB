/*************************************************************
 ** File:   [USP_UpdateItemMasterTimeLife]
 ** Description: Updates only the Life Limited flag (isTimeLife) of one Item Master. Used by the Receiving PO "Life Limited Part"
                 toggle instead of loading and saving the whole ItemMaster entity (EF) - that failed (500) for Asset Item Masters.
 ** Date:   20-NOV-2026
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author          Change Description
 ** --   --------     -------         --------------------------------
    1    20-NOV-2026  RAJESH GAMI     [PN-18624] Created

-- EXEC [dbo].[USP_UpdateItemMasterTimeLife] @ItemMasterId = 97942, @Active = 1
************************************************************************/
CREATE PROCEDURE [dbo].[USP_UpdateItemMasterTimeLife]
	@ItemMasterId BIGINT,
	@Active BIT
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		UPDATE [dbo].[ItemMaster]
		SET [isTimeLife] = @Active,
			[UpdatedDate] = GETDATE()
		WHERE [ItemMasterId] = @ItemMasterId;

		SELECT @@ROWCOUNT AS [RowsUpdated];
	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = DB_NAME()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			, @AdhocComments VARCHAR(150) = 'USP_UpdateItemMasterTimeLife'
			, @ProcedureParameters VARCHAR(3000) = '@ItemMasterId = ' + CONVERT(VARCHAR(20), ISNULL(@ItemMasterId, 0)) + ', @Active = ' + CONVERT(VARCHAR(5), ISNULL(@Active, 0))
			, @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException
			  @DatabaseName = @DatabaseName
			, @AdhocComments = @AdhocComments
			, @ProcedureParameters = @ProcedureParameters
			, @ApplicationName = @ApplicationName
			, @ErrorLogID = @ErrorLogID OUTPUT;
		RAISERROR('Something went wrong (error log id : %d)', 16, 1, @ErrorLogID);
		RETURN(1);
	END CATCH
END
