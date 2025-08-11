/*************************************************************             
 ** File:   [usp_GetEmailCustomerRFQbyId]             
 ** Author:   Devendra Shekh    
 ** Description: Get Customer RFQ Details By Id
 ** Date:   08-Aug-2025 
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** S NO	Date				Author				Change Description              
 ** --		--------			-------				--------------------------------            
 **	1		08-Aug-2025		Devendra Shekh			Created
 
EXECUTE [dbo].[usp_GetEmailCustomerRFQbyId] 122
**************************************************************/  
CREATE   PROCEDURE [dbo].[usp_GetEmailCustomerRFQbyId]
@CustomerRfqId BIGINT = NULL
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON
	BEGIN TRY
		BEGIN

			SELECT	[CustomerRfqId], [RfqId], [RfqCreatedDate], [IntegrationPortalId], [Type], [Notes], [BuyerName], [BuyerCompanyName], [BuyerAddress], [BuyerCity], [BuyerCountry], 
					[BuyerState], [BuyerZip], [LinePartNumber], [LineDescription], [AltPartNumber], [Quantity], [Condition], [MasterCompanyId], [CreatedBy], [CreatedDate],
					[UpdatedBy], [UpdatedDate], [IsActive], [IsDeleted], [IsQuote], [IsMRO], [ModuleId], [ReferenceId]
			FROM [dbo].[CustomerRfq] WITH(NOLOCK) WHERE [CustomerRfqId] = @CustomerRfqId;

			SELECT	[CustomerRfqPartMappingId], [CustomerRfqId], [Notes], [PartNumber], [PartDescription], [AltPartNumber], [Quantity], [Condition], [MasterCompanyId], [CreatedBy], [CreatedDate],
					[UpdatedBy], [UpdatedDate], [IsActive], [IsDeleted]
			FROM [dbo].[CustomerRfqPartMapping] WITH(NOLOCK) WHERE [CustomerRfqId] = @CustomerRfqId;
			
		END
	END TRY    
	BEGIN CATCH      
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
	-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
		, @AdhocComments     VARCHAR(150)    = 'usp_GetEmailCustomerRFQbyId' 
		, @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@CustomerRfqId, '')+''
		, @ApplicationName VARCHAR(100) = 'PAS'
	-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException 
				@DatabaseName           = @DatabaseName
				, @AdhocComments          = @AdhocComments
				, @ProcedureParameters = @ProcedureParameters
				, @ApplicationName        =  @ApplicationName
				, @ErrorLogID                    = @ErrorLogID OUTPUT ;
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
		RETURN(1);
	END CATCH
END