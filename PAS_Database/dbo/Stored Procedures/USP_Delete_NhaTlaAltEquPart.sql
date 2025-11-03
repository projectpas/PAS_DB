/*************************************************************           
 ** File:   [USP_Delete_NhaTlaAltEquPart]           
 ** Author:   Sahdev Saliya
 ** Description: This stored procedure is used to DeleteNhaTlaAltEquPart List
 ** Purpose:         
 ** Date:   31-10-2025       
          
 ** RETURN VALUE:           
  
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** S NO   Date            Author          Change Description              
 ** --   --------         -------          --------------------------------            
    1    31-10-2025    Sahdev Saliya       Created  

	exec [dbo].[USP_Delete_NhaTlaAltEquPart]
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_Delete_NhaTlaAltEquPart]
    @MappingId BIGINT = NULL,
    @UpdatedBy VARCHAR(256) = NULL 
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON;

	BEGIN TRY
    DECLARE @Count INT;

    SELECT @Count = COUNT(1) FROM [dbo].Nha_Tla_Alt_Equ_ItemMapping WITH (NOLOCK) WHERE ItemMappingId = @MappingId;

    IF (@Count > 0)
    BEGIN
        UPDATE [dbo].Nha_Tla_Alt_Equ_ItemMapping
        SET 
            IsDeleted = 1,
            UpdatedDate = GETUTCDATE(),
            UpdatedBy = @UpdatedBy
        WHERE ItemMappingId = @MappingId;
    END
    END TRY 
    BEGIN CATCH
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_Delete_NhaTlaAltEquPart'
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