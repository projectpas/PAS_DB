/*************************************************************           
 ** File:  [RPT_CustomerRMATermConditionById]           
 ** Author:  Amit Ghediya
 ** Description: This stored procedure is used to Get CustomerRMA Terms Condition
 ** Purpose:         
 ** Date:   18/04/2023      
          
 ** PARAMETERS: @MasterCompanyId BIGINT
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    18/04/2023  Amit Ghediya    Created
     
-- EXEC RPT_CustomerRMATermConditionById 1
************************************************************************/
CREATE     PROCEDURE [dbo].[RPT_CustomerRMATermConditionById] 
	@MasterCompanyId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY	

	DECLARE @EmailTemplateTypeId BIGINT;

	SELECT @EmailTemplateTypeId = EmailTemplateTypeId from EmailTemplateType WHERE EmailTemplateType='CustomerRMAPDF';

	IF EXISTS(SELECT TOP 1 TermsConditionId FROM TermsCondition WHERE EmailTemplateTypeId = @EmailTemplateTypeId AND MasterCompanyId = @MasterCompanyId AND IsActive = 1 AND IsDeleted = 0)
	BEGIN 
		SELECT 
			TOP 1 ISNULL(description,'') AS description
		FROM TermsCondition WITH (NOLOCK)
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
        , @AdhocComments     VARCHAR(150)    = 'RPT_CustomerRMATermConditionById' 
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