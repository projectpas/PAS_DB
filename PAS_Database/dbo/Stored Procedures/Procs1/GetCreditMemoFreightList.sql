
/*************************************************************           
 ** File:   [GetCreditMemoFreightList]           
 ** Author:  Moin Bloch
 ** Description: This stored procedure is used to Get Credit Memo Freight List Details
 ** Purpose:         
 ** Date:   17/05/2022      
          
 ** PARAMETERS: @CreditMemoHeaderId bigint
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    17/05/2022  Moin Bloch     Created
     
-- EXEC GetCreditMemoFreightList 8,0
************************************************************************/

CREATE PROCEDURE [dbo].[GetCreditMemoFreightList]
@CreditMemoHeaderId BIGINT,
@IsDeleted bit,
@Opr int
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY	
	IF(@Opr=1)
	BEGIN
	SELECT [CreditMemoFreightId]
          ,[CreditMemoHeaderId]
          ,[CreditMemoDetailId]
          ,[ItemMasterId]
          ,[PartNumber]
          ,[ShipViaId]
          ,[ShipViaName]
          ,[MarkupPercentageId]
          ,[MarkupFixedPrice]
          ,[HeaderMarkupId]
          ,[BillingMethodId]
          ,[BillingRate]
          ,[BillingAmount]
          ,[HeaderMarkupPercentageId]
          ,[Weight]
          ,[UOMId]
          ,[UOMName]
          ,[Length]
          ,[Width]
          ,[Height]
          ,[DimensionUOMId]
          ,[DimensionUOMName]
          ,[CurrencyId]
          ,[CurrencyName]
          ,[Amount]
          ,[Memo]
          ,[MasterCompanyId]
          ,[CreatedBy]
          ,[UpdatedBy]
          ,[CreatedDate]
          ,[UpdatedDate]
          ,[IsActive]
          ,[IsDeleted]
      FROM [dbo].[CreditMemoFreight] WITH (NOLOCK) WHERE CreditMemoHeaderId=@CreditMemoHeaderId AND IsDeleted=@IsDeleted;
	END
	BEGIN
	SELECT [CreditMemoFreightId]
          ,[CreditMemoHeaderId]
          ,[CreditMemoDetailId]
          ,[ItemMasterId]
          ,[PartNumber]
          ,[ShipViaId]
          ,[ShipViaName]
          ,[MarkupPercentageId]
          ,[MarkupFixedPrice]
          ,[HeaderMarkupId]
          ,[BillingMethodId]
          ,[BillingRate]
          ,[BillingAmount]
          ,[HeaderMarkupPercentageId]
          ,[Weight]
          ,[UOMId]
          ,[UOMName]
          ,[Length]
          ,[Width]
          ,[Height]
          ,[DimensionUOMId]
          ,[DimensionUOMName]
          ,[CurrencyId]
          ,[CurrencyName]
          ,[Amount]
          ,[Memo]
          ,[MasterCompanyId]
          ,[CreatedBy]
          ,[UpdatedBy]
          ,[CreatedDate]
          ,[UpdatedDate]
          ,[IsActive]
          ,[IsDeleted]
      FROM [dbo].[CreditMemoFreightAudit] WITH (NOLOCK) WHERE [CreditMemoFreightId]=@CreditMemoHeaderId;
	END
	END TRY    
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'GetCreditMemoFreightList' 
        ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@CreditMemoHeaderId, '') AS varchar(100))			   
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