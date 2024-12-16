-- =============================================
-- Author:		<Ayesha Sultana>
-- Create date: <30-1-2024>
-- Description:	<AssetAttributeTypeForSSRS,,>
-- =============================================
/*************************************************************           
 ** File:   [InventoryStatusForSSRS]           
 ** Author:   Ayesha Sultana
 ** Description: This SP to get all the inventory statuses
 ** Purpose:         
 ** Date:   10-JAN-2024    
          
 ** PARAMETERS:           
   
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** S NO   Date         Author  			Change Description            
 ** --   --------		-------				--------------------------------          
	1	 10-01-2024		Ayesha Sultana		Created
	2    12-12-2024     ABHISHEK JIRAWLA    Change made for Asset Inventory Status and Asset Available Status
     
**************************************************************/
CREATE   PROCEDURE [dbo].[InventoryStatusForSSRS]	
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
			SELECT AIS.AssetInventoryStatusId, AIS.[Status], AIS.MasterCompanyId
			FROM AssetInventoryStatus AIS WITH (NOLOCK)
			WHERE AIS.IsActive = 1 AND AIS.IsDeleted = 0
			UNION ALL
			SELECT AAS.AssetAvailableStatusId AS AssetInventoryStatusId, AAS.[Status], AAS.MasterCompanyId
			FROM AssetAvailableStatus AAS WITH (NOLOCK)
			WHERE AAS.IsActive = 1 AND AAS.IsDeleted = 0;
	END TRY
	BEGIN CATCH
    ROLLBACK TRANSACTION

    DECLARE @ErrorLogID int,
        @DatabaseName varchar(100) = DB_NAME(),
        -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        @AdhocComments varchar(150) = '[InventoryStatusForSSRS]',
        @ProcedureParameters varchar(3000) = '@Parameter1 = ''',
        @ApplicationName varchar(100) = 'PAS'
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC Splogexception @DatabaseName = @DatabaseName,
			@AdhocComments = @AdhocComments,
			@ProcedureParameters = @ProcedureParameters,
			@ApplicationName = @ApplicationName,
			@ErrorLogID = @ErrorLogID OUTPUT;

    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
    RETURN (1);
  END CATCH
 END