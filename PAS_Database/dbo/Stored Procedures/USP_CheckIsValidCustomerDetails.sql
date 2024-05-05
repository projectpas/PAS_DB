/*********************             
 ** File:   UPDATE CUSTOMER IN WO           
 ** Author:  HEMANT SALIYA  
 ** Description: This SP Is Used to Check Is allowed to Reopen WO
 ** Purpose:           
 ** Date:   14-APRIL-2024
    
 ************************************************************             
  ** Change History             
 ************************************************************             
 ** PR   Date         Author			Change Description              
 ** --   --------     -------			--------------------------------            
    1    05/01/2024   HEMANT SALIYA      Created  

DECLARE @IsValidCustomerContact BIT;      
DECLARE @IsValidCustomerShipping BIT;
EXECUTE USP_CheckIsValidCustomerDetails 14, 3462, @IsValidCustomerContact OUTPUT, @IsValidCustomerShipping OUTPUT

*************************************************************/   
  
CREATE    PROCEDURE [dbo].[USP_CheckIsValidCustomerDetails] 	
@CustomerId BIGINT = NULL,  
@WorkOrderPartNoId BIGINT = NULL,  
@IsValidCustomerContact BIT = 0 OUTPUT,  
@IsValidCustomerShipping BIT = 0 OUTPUT
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
 BEGIN TRY

		DECLARE @IsContactGenerated BIT = 0;
		DECLARE @InvoiceStatus VARCHAR(100) = NULL;
		DECLARE @IsShippingDone BIT = 0;

		SELECT @IsValidCustomerContact = CASE WHEN ISNULL(CO.WorkPhone, '') <> '' THEN 1 ELSE 0 END 
		FROM dbo.CustomerContact CC WITH(NOLOCK) 
			JOIN dbo.Contact CO WITH(NOLOCK) ON CO.ContactId = CC.ContactId 
		WHERE CustomerId = @CustomerId AND ISNULL(CC.IsDefaultContact, 0) = 1 AND CC.IsDeleted = 0 AND CC.IsActive = 1

		SELECT @IsShippingDone = CASE WHEN COUNT(WOS.WorkOrderShippingId) > 0 THEN 1 ELSE 0 END 
		FROM dbo.WorkOrderShipping WOS WITH (NOLOCK) 
			JOIN dbo.WorkOrderShippingItem WOSI WITH (NOLOCK) ON WOSI.WorkOrderShippingId = WOS.WorkOrderShippingId 
		WHERE WOSI.WorkOrderPartNumId = @workOrderPartNoId

		IF(ISNULL(@IsShippingDone,0) > 0)
		BEGIN
			SELECT @IsValidCustomerShipping = CASE WHEN COUNT(CS.CustomerDomensticShippingId) > 0 THEN 1 ELSE 0 END 
			FROM dbo.CustomerDomensticShipping CS WITH(NOLOCK) 		
				JOIN dbo.[Address] A WITH(NOLOCK) ON CS.AddressId = A.AddressId 
			WHERE CustomerId = @CustomerId AND ISNULL(CS.IsPrimary, 0) = 1 AND CS.IsDeleted = 0 AND CS.IsActive = 1
		END
		ELSE
		BEGIN
			SET @IsValidCustomerShipping = 1;
		END

		SELECT @IsValidCustomerContact, @IsValidCustomerShipping; 

 END TRY      
 BEGIN CATCH  
  DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
        , @AdhocComments     VARCHAR(150)    = 'USP_CheckIsValidCustomerDetails'   
        ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@CustomerId, '') AS varchar(100))   
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
 END CATCH  
END