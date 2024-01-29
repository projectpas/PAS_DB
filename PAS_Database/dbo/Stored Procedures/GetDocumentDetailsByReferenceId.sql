/*************************************************************           
 ** File:  [GetDocumentDetailsByReferenceId]  
 ** Author:   Ekta Chandegra
 ** Description: Retrieve Documents list based on refferenceId
 ** Purpose:         
 ** Date:   16 January 2024
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR     Date         Author		     	Change Description            
 ** --    --------     -------			-------------------------------          
    1     16-01-2024   Ekta Chandegra	   Created
    2     26-01-2024   Ekta Chandegra	   Add fields IsDeleted, IsActive

EXEC [GetDocumentDetailsByReferenceId] 3616

**************************************************************/ 

CREATE  PROCEDURE [dbo].[GetDocumentDetailsByReferenceId]
	@ReferenceId BIGINT = NULL
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY 
		
		SELECT  cdd.DocName , ad.FileName,ad.FileType,ad.Link,
		ad.FileSize, ad.AttachmentId, ad.IsDeleted, ad.IsActive
		FROM DBO.AttachmentDetails ad 
		INNER JOIN DBO.CommonDocumentDetails cdd WITH (NOLOCK) ON ad.AttachmentId = cdd.AttachmentId 
		WHERE cdd.ReferenceId = @ReferenceId AND cdd.IsDeleted = 0 AND cdd.IsActive = 1
	END TRY
	BEGIN CATCH
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = '[GetDocumentDetailsByReferenceId]' 
            , @ProcedureParameters VARCHAR(3000)  = ''
            , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
            exec spLogException 
                    @DatabaseName			= @DatabaseName
                    , @AdhocComments			= @AdhocComments
                    , @ProcedureParameters		= @ProcedureParameters
                    , @ApplicationName			=  @ApplicationName
                    , @ErrorLogID              = @ErrorLogID OUTPUT ;
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
            RETURN(1);
    END CATCH 
END