/*************************************************************           
 ** File:     [GetPMAPartNumbersByPartId]           
 ** Author:	  Vishal Suthar
 ** Description: This SP is Used to Get PMA part details
 ** Purpose:         
 ** Date:   10/30/2025 
          
 ** PARAMETERS:             
         
 ** RETURN VALUE:           
  
 ************************************************************************
  ** Change History           
 ************************************************************************
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------
	1    10/30/2025   Vishal Suthar		Created
	2    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0

************************************************************************/
CREATE   PROCEDURE [dbo].[GetPMAPartNumbersByPartId]
    @PartId INT
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
		SELECT IM.*
		FROM dbo.ItemMaster IM WITH (NOLOCK)
		INNER JOIN dbo.ItemMaster IM1 WITH (NOLOCK) ON IM.IsOemPNId = IM1.ItemMasterId
		WHERE IM.IsActive = 1 AND IM.IsDeleted = 0 
		AND IM.IsOemPNId = @PartId AND ISNULL(IM.IsNonStock,0) = 0 AND ISNULL(IM1.IsNonStock,0) = 0 ;
	END TRY
	BEGIN CATCH      
	IF @@trancount > 0
		PRINT 'ROLLBACK'
		ROLLBACK TRAN;
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'GetPMAPartNumbersByPartId' 
        , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@PartId, '') + ''
        , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
        EXEC spLogException 
                @DatabaseName = @DatabaseName
                , @AdhocComments = @AdhocComments
                , @ProcedureParameters = @ProcedureParameters
                , @ApplicationName = @ApplicationName
                , @ErrorLogID = @ErrorLogID OUTPUT;
        RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
        RETURN(1);
	END CATCH
END