/*************************************************************           
 ** File:   [USP_GetCustomerContactATAMapping]           
 ** Author:  Ekta Chandegra
 ** Description: This stored procedure is used GetCustomerContactATAMapping
 ** Purpose:         
 ** Date:   13/05/2025      
          
 ** PARAMETERS: @CustomerContactId BIGINT ,  @IsDeleted BIT
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    05/13/2025  Ekta Chandegra     Created
     
exec [dbo].[USP_GetCustomerContactATAMapping] @CustomerContactId=6575,@IsDeleted=0
************************************************************************/

CREATE   PROCEDURE [dbo].[USP_GetCustomerContactATAMapping]
    @CustomerContactId BIGINT,
    @IsDeleted BIT
AS
BEGIN
    SET NOCOUNT ON;
	BEGIN TRY
		SELECT 
			ca.CustomerContactATAMappingId,
			ca.CustomerId,
			ca.ATAChapterId,
			ca.ATAChapterCode,
			ISNULL(atasub.ATASubChapterCode, '') AS ATASubChapterCode,
			ca.ATASubChapterId,
			ISNULL(atasub.Description, '') AS ATASubChapterDescription,
			ATAChapterName = ca.Level1 
							 + CASE WHEN ISNULL(ca.Level2, '') <> '' THEN '-' + ca.Level2 ELSE '' END
							 + CASE WHEN ISNULL(ca.Level3, '') <> '' THEN '-' + ca.Level3 ELSE '' END,
			ca.Level1,
			ca.Level2,
			ca.Level3
		FROM [dbo].[CustomerContactATAMapping] ca WITH(NOLOCK)
		LEFT JOIN [dbo].[ATASubChapter] atasub WITH(NOLOCK) ON ca.ATASubChapterId = atasub.ATASubChapterId
		WHERE ca.CustomerContactId = @CustomerContactId AND ca.IsDeleted = ISNULL(@IsDeleted,0);
	END TRY
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'USP_GetCustomerContactATAMapping' 
            , @ProcedureParameters VARCHAR(3000)  = ''
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