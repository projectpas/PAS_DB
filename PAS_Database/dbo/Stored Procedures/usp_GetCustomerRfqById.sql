/*************************************************************           
 ** File:   [usp_GetCustomerRfqById]           
 ** Author:  Devendra Shekh	
 ** Description: This stored procedure is used Get Customer Rfq by Id
 ** Purpose:         
 ** Date:   22-July-2025 
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date			Author				Change Description            
 ** --   --------		-------				--------------------------------          
    1    22-July-2025	Devendra Shekh			Created
-- EXEC usp_GetCustomerRfqById 7 
************************************************************************/
CREATE   PROCEDURE [dbo].[usp_GetCustomerRfqById]
@CustomerRfqId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON;

	BEGIN TRY

		SELECT	[CustomerRfqId], [RfqId], [RfqCreatedDate], [IntegrationPortalId], [Type], [Notes],
				[BuyerName], [BuyerCompanyName], [BuyerAddress], [BuyerCity], [BuyerCountry], [BuyerState], [BuyerZip],
				[LinePartNumber], [LineDescription], [IsQuote], [AltPartNumber], [Condition], [Quantity],
				[MasterCompanyId], [CreatedBy], [CreatedDate], [UpdatedBy], [UpdatedDate], [IsActive], [IsDeleted]
		FROM [dbo].[CustomerRfq] WITH(NOLOCK)
		WHERE [CustomerRfqId] = @CustomerRfqId;

	END TRY    
	BEGIN CATCH      
		ROLLBACK TRAN;
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'usp_GetCustomerRfqDetails' 
        , @ProcedureParameters VARCHAR(3000) = '@CustomerRfqId = ''' + CAST(ISNULL(@CustomerRfqId, '') as varchar(100))
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