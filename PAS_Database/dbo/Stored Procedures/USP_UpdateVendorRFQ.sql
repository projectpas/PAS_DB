/*************************************************************           
 ** File:   [USP_UpdateVendorRFQ]           
 ** Author:  Amit Ghediya
 ** Description: This stored procedure is used to Update VendorRFQ
 ** Purpose:         
 ** Date:   02-Sep-2025   
          
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date					Author					Change Description            
 ** --   --------				-------					--------------------------------          
    1    02-Sep-2025			Amit Ghediya			Created
    2    13-Oct-2025			Devendra Shekh			Added ILSRFQDetailId Check 
     
-- EXEC USP_UpdateVendorRFQ
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_UpdateVendorRFQ]
	@ILSRFQDetailId BIGINT = NULL,
	@VendorId BIGINT = NULL,
	@ItemSupplierPartId BIGINT = NULL,
	@VendorName VARCHAR(200) = NULL,
	@MasterCompanyId INT = NULL
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
	BEGIN

		--DECLARE @VendorName VARCHAR(150) ='';
		--SELECT @VendorName = [VendorName] FROM [dbo].[VendorRFQPart] WITH(NOLOCK) WHERE ItemSupplierPartId = @ItemSupplierPartId AND [ILSRFQDetailId] = @ILSRFQDetailId;

		UPDATE VRFQP
		SET	
			VRFQP.VendorId = @VendorId
		FROM [dbo].[VendorRFQPart] VRFQP WITH(NOLOCK)
		WHERE LOWER(TRIM(VRFQP.VendorName)) = LOWER(TRIM(@VendorName)) AND VRFQP.MasterCompanyId = @MasterCompanyId;
		
	END
	END TRY    
	BEGIN CATCH      
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'USP_UpdateVendorRFQ' 
            , @ProcedureParameters VARCHAR(3000) = '@ILSRFQDetailId = ''' + CAST(ISNULL(@ILSRFQDetailId, '') as varchar(100))
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