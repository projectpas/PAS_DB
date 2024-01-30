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
    2     25-01-2024   Ekta Chandegra	   IsDeleted, IsActive fields are added
    3     30-01-2024   Ekta Chandegra	   Add masterCompanyId parameter

EXEC [GetDocumentDetailsByReferenceId] 411, 1

**************************************************************/ 

CREATE  PROCEDURE [dbo].[GetDocumentDetailsByReferenceId]
	@ReferenceId BIGINT = NULL,
	@MasterCompanyId BIGINT = NULL
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY 
		
		SELECT  cdd.DocName , cdd.IsActive,cdd.IsDeleted, ad.FileName,ad.FileType,ad.Link,
		ad.FileSize, ad.AttachmentId
		FROM DBO.AttachmentDetails ad 
		INNER JOIN DBO.CommonDocumentDetails cdd WITH (NOLOCK) ON ad.AttachmentId = cdd.AttachmentId 
		WHERE cdd.MasterCompanyId = @MasterCompanyId AND cdd.ReferenceId = @ReferenceId AND cdd.IsActive = 1 AND cdd.IsDeleted = 0 
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