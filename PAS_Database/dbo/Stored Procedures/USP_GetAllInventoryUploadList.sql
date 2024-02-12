/*************************************************************           
 ** File:   [USP_GetAllInventoryUploadList]           
 ** Author:  Vishal Suthar
 ** Description: This stored procedure is used to get all Inventory Upload records
 ** Purpose:         
 ** Date:   11/02/2024      
          
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   ----------  -----------	--------------------------------          
    1    11/02/2024  Vishal Suthar	Created
     
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetAllInventoryUploadList]
	@MasterCompanyId int
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
		SELECT InvUpload.ILSInventoryUploadId,
			InvUpload.EitReceived,
			InvUpload.EmailSent,
			InvUpload.ErrDescription,
			InvUpload.InventoryLoadId,
			InvUpload.FilePath,
			InvUpload.CreatedBy,
			InvUpload.UpdatedBy,
			InvUpload.CreatedDate,
			InvUpload.UpdatedDate,
			InvUpload.IsActive,
			InvUpload.MasterCompanyId,
			InvUpload.IsDeleted
		FROM DBO.[ILSInventoryUpload] InvUpload WITH (NOLOCK)
		WHERE InvUpload.MasterCompanyId = @MasterCompanyId;
	END TRY    
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'USP_GetAllInventoryUploadList' 
        , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = ' + ISNULL(@MasterCompanyId,'') + ''
        , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
        exec spLogException 
                @DatabaseName           = @DatabaseName
                , @AdhocComments          = @AdhocComments
                , @ProcedureParameters = @ProcedureParameters
                , @ApplicationName        =  @ApplicationName
                , @ErrorLogID                    = @ErrorLogID OUTPUT ;
        RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
        RETURN(1);
	END CATCH
END