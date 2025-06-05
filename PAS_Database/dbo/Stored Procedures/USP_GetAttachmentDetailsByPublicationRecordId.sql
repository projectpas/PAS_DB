/***************************************************************  
 ** File:  [USP_GetAttachmentDetailsByPublicationRecordId]            
 ** Author: Ayushi Patel  
 ** Description: Gets attachment details for Publication module by PublicationRecordId  
 ** Purpose:   
 ** Date:  30-May-2025  

 ** Change History             
 **************************************************************             
 ** PR   Date				Author  				Change Description              
 ** --   --------			-------				--------------------------------            
    1    2025-05-30		  Ayushi Patel				Created
	
 ***************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_GetAttachmentDetailsByPublicationRecordId]
    @PublicationRecordId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    BEGIN TRY
	DECLARE @PublicationModuleId INT = (SELECT TOP 1 AttachmentModuleId FROM DBO.AttachmentModule WITH(NOLOCK) WHERE Name = 'Publication');
        SELECT
            ad.AttachmentDetailId,
            ad.AttachmentId,
            ad.FileName,
            ad.Description,
            ad.Link,
            ad.FileFormat,
            ad.FileSize,
            ad.FileType,
            ad.CreatedDate,
            ad.UpdatedDate,
            ad.CreatedBy,
            ad.UpdatedBy,
            ISNULL(ad.IsActive,0) AS IsActive,
            ISNULL(ad.IsDeleted,0) AS IsDeleted,
            ad.Name,
            ad.Memo,
            ad.TypeId
        FROM dbo.Attachment a WITH (NOLOCK)
        INNER JOIN dbo.AttachmentDetails ad WITH (NOLOCK) ON a.AttachmentId = ad.AttachmentId
        WHERE 
            ISNULL(ad.IsDeleted,0) = 0
            AND a.ModuleId = @PublicationModuleId 
            AND a.ReferenceId = @PublicationRecordId
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
                @AdhocComments VARCHAR(150) = 'USP_GetAttachmentDetailsByPublicationRecordId',
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