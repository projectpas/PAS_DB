/***************************************************************  
 ** File: [USP_GetPublicationAttachmentDetailsByIDNew]            
 ** Author: Ayushi Patel  
 ** Description: Get publication attachment details by PublicationId
 ** Purpose:   
 ** Date:  04-JUN-2025  

 ** Change History             
 **************************************************************             
 ** PR   Date				Author  				Change Description              
 ** --   --------			-------				--------------------------------            
    1    2025-06-04		  Ayushi Patel				Created
 ***************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_GetPublicationAttachmentDetailsByIDNew]
    @PublicationId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    BEGIN TRY
	DECLARE @PublicationModuleId INT = (SELECT TOP 1 AttachmentModuleId FROM DBO.AttachmentModule WITH(NOLOCK) WHERE Name = 'Publication');
        SELECT 
            ty.Name AS TagTypeName,
            ty.TagTypeId AS TagType,
            atd.Name AS DocName,
            atd.Memo AS DocMemo,
            atd.Description AS DocDescription,
            atd.FileName,
            atd.Link,
            atd.AttachmentDetailId,
            atd.AttachmentId,
            atd.CreatedBy,
            atd.UpdatedBy,
            atd.UpdatedDate,
            atd.CreatedDate,
            CAST(atd.FileSize AS VARCHAR(20)) + ' MB' AS FileSize,
            ISNULL(atd.IsActive,0) AS IsActive
        FROM dbo.TagType ty WITH (NOLOCK)
        INNER JOIN dbo.AttachmentDetails atd WITH (NOLOCK) ON ty.TagTypeId = CAST(atd.TypeId AS BIGINT)
        INNER JOIN dbo.Attachment at WITH (NOLOCK) ON atd.AttachmentId = at.AttachmentId
        WHERE at.ReferenceId = @PublicationId
            AND at.ModuleId = @PublicationModuleId 
            AND ISNULL(atd.IsDeleted,0) = 0
    END TRY
   BEGIN CATCH
		SELECT
		ERROR_NUMBER() AS ErrorNumber,
		ERROR_STATE() AS ErrorState,
		ERROR_SEVERITY() AS ErrorSeverity,
		ERROR_PROCEDURE() AS ErrorProcedure,
		ERROR_LINE() AS ErrorLine,
		ERROR_MESSAGE() AS ErrorMessage;
        DECLARE @ErrorLogID INT, 
                @DatabaseName VARCHAR(100) = DB_NAME(),
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
                @AdhocComments VARCHAR(150) = 'USP_GetPublicationAttachmentDetailsByIDNew',
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