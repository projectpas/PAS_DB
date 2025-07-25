/*************************************************************           
 ** File:   [usp_GetIntegrationCustomerById]           
 ** Author:  Devendra Shekh	
 ** Description: This stored procedure is used Get Integration Customer by Id and Type Id
 ** Purpose:         
 ** Date:   23-July-2025 
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date			Author				Change Description            
 ** --   --------		-------				--------------------------------          
    1    23-July-2025	Devendra Shekh			Created
    2    25-July-2025	Devendra Shekh			added IsMRO Field

-- EXEC usp_GetIntegrationCustomerById 9,2 
************************************************************************/
CREATE   PROCEDURE [dbo].[usp_GetIntegrationCustomerById]
@ReferenceId BIGINT = NULL,
@TypeId INT = NULL
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON;

	BEGIN TRY

		DECLARE @InventorySearchType INT = 1, @ReceivedRFQType INT = 2, @SendRFQListType INT = 3;

		IF(@InventorySearchType = @TypeId)
		BEGIN
			SELECT	[RepairStation] AS CustomerName, 
					[AddressLine1] AS Address1,
					[AddressLine2] AS Address2,
					[City] AS City,
					[State] AS State, 
					[PostalCode] AS PostalCode,				 
					[Country] AS Country, 
					[IsMRO] AS IsMRO 
			FROM [dbo].[IntegrationMaster] WITH(NOLOCK)
			WHERE [IntegrationMasterId] = @ReferenceId;
		END
		ELSE IF(@ReceivedRFQType = @TypeId)
		BEGIN
			SELECT	[BuyerCompanyName] AS CustomerName, 
					[BuyerAddress] AS Address1,
					'' AS Address2,
					[BuyerCity] AS City,
					[BuyerState] AS State, 
					[BuyerZip] AS PostalCode,				 
					[BuyerCountry] AS Country,
					[IsMRO] AS IsMRO 
			FROM [dbo].[CustomerRfq] WITH(NOLOCK)
			WHERE [CustomerRfqId] = @ReferenceId;
		END
		ELSE IF(@SendRFQListType = @TypeId)
		BEGIN
			SELECT	'' AS CustomerName, '' AS AddressLine1, '' AS Address2, '' AS City, '' AS State, '' AS PostalCode, '' AS Country, 0 as [IsMRO]
		END	

	END TRY    
	BEGIN CATCH      
		ROLLBACK TRAN;
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'usp_GetCustomerRfqDetails' 
        , @ProcedureParameters VARCHAR(3000) = '@CustomerRfqId = ''' + CAST(ISNULL(@ReferenceId, '') as varchar(100))
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