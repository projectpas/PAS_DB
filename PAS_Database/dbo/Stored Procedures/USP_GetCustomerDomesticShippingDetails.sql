
/*************************************************************           
 ** File:   [USP_GetCustomerDomesticShippingDetails]           
 ** Author:  Ayushi Patel
 ** Description: This stored procedure is used to Get Customer Domestic Shipping Details BY Customer id
 ** Purpose:         
 ** Date:   31/03/2025      
          
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   ----------  -----------		--------------------------------          
    1    31/03/2025   Ayushi Patel		Created
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetCustomerDomesticShippingDetails]
    @customerId BIGINT
AS
BEGIN
--exec USP_GetCustomerDomesticShippingDetails 4278
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  BEGIN TRY
  BEGIN TRANSACTION
	BEGIN				
		
		  
	 SELECT 
        lec.CustomerDomensticShippingShipViaId AS CustomerDomensticShippingShipViaId,
		sv.ShippingViaId AS ShippingViaId,
        sv.Name,
        lec.ShippingAccountinfo AS ShippingAccountInfo,
        lec.Memo,
        lec.IsPrimary,
        sv.ShippingViaId AS ShipViaId,
        lec.CustomerDomensticShippingId AS ShippingId,
        ST.ShippingTermsId,
        ST.[Name] AS ShippingTerms
    FROM dbo.CustomerDomensticShippingShipVia lec WITH (NOLOCK)
    JOIN dbo.ShippingVia sv WITH (NOLOCK)  
        ON sv.ShippingViaId = lec.ShipViaId
    LEFT JOIN dbo.ShippingTerms ST WITH (NOLOCK) 
        ON ST.ShippingTermsId = lec.ShippingTermsId
    WHERE lec.CustomerId = @customerId 
        AND ISNULL(lec.IsDeleted, 0) = 0 
        AND ISNULL(lec.IsActive, 1) = 1;
		
	END
	COMMIT  TRANSACTION
  END TRY
  BEGIN CATCH
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
		DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,@AdhocComments varchar(150) = '[USP_GetCustomerDomesticShippingDetails]',
            @ProcedureParameters varchar(3000) = '@customerId = ''' + CAST(ISNULL(@customerId, '') AS varchar(100)),
            @ApplicationName varchar(100) = 'PAS'
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
    EXEC spLogException @DatabaseName = @DatabaseName,
                        @AdhocComments = @AdhocComments,
                        @ProcedureParameters = @ProcedureParameters,
                        @ApplicationName = @ApplicationName,
                        @ErrorLogID = @ErrorLogID OUTPUT;
    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
    RETURN (1);
  END CATCH
END