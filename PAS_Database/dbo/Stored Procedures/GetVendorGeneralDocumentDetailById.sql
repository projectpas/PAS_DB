/*************************************************************
** File:   [GetVendorGeneralDocumentDetailById]        
** Author:  Ayushi Patel
** Description: To get Vendor General Document Detail By Id
** Purpose: 
** Date:   02/05/2025     
        
** PARAMETERS: 
    @ReferenceId BIGINT,
    @ModuleId INT

** RETURN VALUE: None
**************************************************************           
** Change History           
**************************************************************           
** PR   Date         Author		    Change Description            
** --   --------     -------		--------------------------------          
   1    02/05/2025   Ayushi Patel    Created

--exec [dbo].[GetVendorGeneralDocumentDetailById]  4777,3
************************************************************************/ 
CREATE   PROCEDURE dbo.GetVendorGeneralDocumentDetailById
    @ReferenceId BIGINT,
    @ModuleId INT
AS
BEGIN
  SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	BEGIN TRY
    SELECT atd.*
    FROM DBO.Attachment at WITH (NOLOCK)
    INNER JOIN DBO.AttachmentDetails atd WITH (NOLOCK) ON at.AttachmentId = atd.AttachmentId
    WHERE 
        at.ReferenceId = @ReferenceId
        AND at.ModuleId = @ModuleId
        AND ISNULL(atd.IsActive,0) = 1
        AND ISNULL(atd.IsDeleted,0) = 0;
	END TRY
    BEGIN CATCH
        DECLARE @ErrorLogID INT, 
                @DatabaseName VARCHAR(100) = DB_NAME(),
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
                @AdhocComments VARCHAR(150) = 'GetVendorGeneralDocumentDetailById',
                @ProcedureParameters VARCHAR(3000) = '',
                @ApplicationName VARCHAR(100) = 'PAS';
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
        EXEC dbo.spLogException 
            @DatabaseName = @DatabaseName,
            @AdhocComments = @AdhocComments,
            @ProcedureParameters = @ProcedureParameters,
            @ApplicationName = @ApplicationName,
            @ErrorLogID = @ErrorLogID OUTPUT;

        RAISERROR ('Unexpected Error Occurred. Inform Support with Error Number: %d', 16, 1, @ErrorLogID);
        RETURN (1);
    END CATCH
END