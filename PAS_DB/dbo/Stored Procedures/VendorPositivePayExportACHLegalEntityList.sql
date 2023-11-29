/*************************************************************           
 ** File:   [VendorPositivePayExportACHLegalEntityList]           
 ** Author:   MOIN BLOCH
 ** Description: This stored procedure is used Get Vendor Positive Pay Export ACH Legal Entity List
 ** Purpose:         
 ** Date:   09/18/2023
          
 ** PARAMETERS:           
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    09/18/2023   MOIN BLOCH    CREATED   

-- EXEC VendorPositivePayExportACHLegalEntityList NULL,NULL,1

**************************************************************/

CREATE   PROCEDURE [dbo].[VendorPositivePayExportACHLegalEntityList]
@VendorIds VARCHAR(250) = NULL,
@ReadyToPayIds varchar(250) = NULL,
@MasterCompanyId INT = NULL
AS  
BEGIN 
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
 BEGIN TRY    
 
	IF(@VendorIds = '')
		SET @VendorIds = NULL;
	IF(@ReadyToPayIds = '')
		SET @ReadyToPayIds = NULL;

	DECLARE @PaymentMethodId int = NULL
	DECLARE @ACHTransferPaymentMethodId INT
	 SELECT @ACHTransferPaymentMethodId = [VendorPaymentMethodId] FROM [dbo].[VendorPaymentMethod] WHERE [Description] ='ACH Transfer';
	
	SELECT DISTINCT LEE.[LegalEntityId]
	FROM [dbo].[VendorReadyToPayDetails] VRP  WITH(NOLOCK)
	 INNER JOIN [dbo].[Vendor] VN WITH(NOLOCK) ON VRP.VendorId = VN.VendorId
	  LEFT JOIN [dbo].[VendorPaymentDetails] RRH  WITH(NOLOCK) ON VRP.[ReceivingReconciliationId] = RRH.[ReceivingReconciliationId]
	  LEFT JOIN [dbo].[VendorReadyToPayHeader] VRH WITH(NOLOCK) ON VRP.ReadyToPayId = VRH.ReadyToPayId
	  LEFT JOIN [dbo].[VendorDomesticWirePayment] VVP WITH(NOLOCK) ON VVP.VendorId = VN.VendorId
	  LEFT JOIN [dbo].[DomesticWirePayment] DWP WITH(NOLOCK) ON DWP.DomesticWirePaymentId = VVP.DomesticWirePaymentId
	  LEFT JOIN [dbo].[PaymentMethod] PM WITH(NOLOCK) ON PM.PaymentMethodId = VRP.PaymentMethodId			 
	 INNER JOIN [dbo].[EntityStructureSetup] ESS WITH(NOLOCK) ON ESS.EntityStructureId = VRH.ManagementStructureId
	 INNER JOIN [dbo].[ManagementStructureLevel] MSL WITH(NOLOCK) ON MSL.ID = ESS.Level1Id
           INNER JOIN [dbo].[LegalEntity] LEE WITH(NOLOCK) ON LEE.LegalEntityId = MSL.LegalEntityId			 	 
	WHERE (VRP.[MasterCompanyId] = @MasterCompanyId) 
		  AND (VRP.[PaymentMethodId] = @ACHTransferPaymentMethodId) AND
			  (@ReadyToPayIds IS NULL OR VRP.ReadyToPayId IN (SELECT Item FROM dbo.SplitString(@ReadyToPayIds,','))) AND
		      (@VendorIds IS NULL OR VRP.VendorId IN (SELECT Item FROM dbo.SplitString(@VendorIds,','))) 	
	
  END TRY      
  BEGIN CATCH        
   IF @@trancount > 0  
    PRINT 'ROLLBACK'      
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'VendorPositivePayExportACHLegalEntityList'   
              , @ProcedureParameters VARCHAR(3000)  = '@MasterCompanyId = '''+ ISNULL(@MasterCompanyId, '') + ''  
              , @ApplicationName VARCHAR(100) = 'PAS'  
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
              exec spLogException   
                       @DatabaseName           =  @DatabaseName  
                     , @AdhocComments          =  @AdhocComments  
                     , @ProcedureParameters    =  @ProcedureParameters  
                     , @ApplicationName        =  @ApplicationName  
                     , @ErrorLogID             =  @ErrorLogID OUTPUT ;  
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)  
              RETURN(1);  
  END CATCH  
END