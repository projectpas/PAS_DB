/*************************************************************           
 ** File:  [RPT_PrintSalesOrderTermCondiitonById]           
 ** Author:  Amit Ghediya
 ** Description: This stored procedure is used to Get Print SalesOrder Data By MasterCompanyId
 ** Purpose:         
 ** Date:   01/10/2024      
          
 ** PARAMETERS: @MasterCompanyId BIGINT
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    01/10/2024  Amit Ghediya    Created
     
-- EXEC RPT_PrintSalesOrderTermCondiitonById 1
************************************************************************/
CREATE       PROCEDURE [dbo].[RPT_PrintSalesOrderTermCondiitonById] 
	@MasterCompanyId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY	

	DECLARE @EmailTemplateTypeId BIGINT;

	SELECT @EmailTemplateTypeId = EmailTemplateTypeId from dbo.EmailTemplateType WITH (NOLOCK) WHERE EmailTemplateType='SalesOrderPrintPDF';

	IF EXISTS(SELECT TOP 1 TermsConditionId FROM dbo.TermsCondition WITH (NOLOCK) WHERE EmailTemplateTypeId = @EmailTemplateTypeId AND MasterCompanyId = @MasterCompanyId AND IsActive = 1 AND IsDeleted = 0)
	BEGIN 
		SELECT 
			TOP 1 ISNULL(description,'') AS description
		FROM dbo.TermsCondition WITH (NOLOCK)
		WHERE EmailTemplateTypeId = @EmailTemplateTypeId 
		AND MasterCompanyId = @MasterCompanyId AND IsActive = 1 AND IsDeleted = 0;		
	END
	ELSE
	BEGIN 
		SELECT '' AS description;
	END	

  END TRY    
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'RPT_PrintSalesOrderTermCondiitonById' 
        ,@ProcedureParameters VARCHAR(3000) = '@MasterCompanyId = ''' + CAST(ISNULL(@MasterCompanyId, '') AS varchar(100))			   
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